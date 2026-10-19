#!/usr/bin/env node
// 飞书子表 → 项目 data/*.json 导出器。
// 约定：子表为两行表头（第 1 行英文 key，第 2 行中文说明），数据从第 3 行开始。
// 输出：data/<name>.json（数组，元素为一行对象，字段名 = 英文 key），供 data_loader.gd 读取。
//
// 用法：
//   node tools/feishu/export.mjs             # 导出全部
//   node tools/feishu/export.mjs equipment   # 只导出指定表（可多个）
//
// 凭据来源：环境变量 FEISHU_APP_ID / FEISHU_APP_SECRET，或仓库根目录 .env（已被 .gitignore 忽略）。
// 依赖：Node 18+（使用内置 fetch），无需 npm install。

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const BASE = "https://open.feishu.cn/open-apis";
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "..", "..");
const OUT_DIR = path.join(ROOT, "data");

// 表定义：逻辑名（= 输出文件名）→ 飞书 wiki 节点 token。
const TABLES = [
	{ name: "effects", node: "XE6Zw0SojicEIlkCPYLca6TKnbg" },
	{ name: "equipment", node: "QqZ9wGQCUiLOcwknfXhcg0AunTb" },
	{ name: "items", node: "MdDVwELRhi11hgkGmPacMACBndf" },
	{ name: "relics", node: "EIUSw1vPOi3rKvkraNEcW9OHn9c" },
	{ name: "synergies", node: "XdCVw3iY2iJglCkbCCyc9IAQn4b" },
	{ name: "skills", node: "U8jUwYlB2ijBAhkFSxscNBbKnrf" },
	{ name: "blessings", node: "KPlwwgjQcil54JkzEjncd8drnJb" },
	{ name: "occupations", node: "MrSiw6CnmiIgd3k1xIxcw1mjnEe" },
	{ name: "events", node: "DytDwqxUSiFSxvk2x1TcDQ2qneh" },
	{ name: "characters", node: "PebAwqrUliKNcLkralpckJkvnzh" },
	{ name: "monsters", node: "Bqe7wJXkiixVKCkfSGQc2g95nqg" },
	{ name: "probabilities", node: "S7WKw1cr0i5Hv6ksRPncBK2LnHr" },
];

const KEYS_ROW = 0;   // 第 1 行（0 基）：英文 key
const DATA_ROW = 2;   // 第 3 行（0 基）起：数据

function loadEnv() {
	let dir = process.cwd();
	for (let i = 0; i < 6; i++) {
		const p = path.join(dir, ".env");
		if (fs.existsSync(p)) return p;
		const up = path.dirname(dir);
		if (up === dir) break;
		dir = up;
	}
	return path.join(ROOT, ".env");
}

function parseEnv(file) {
	const out = {};
	if (!fs.existsSync(file)) return out;
	for (const line of fs.readFileSync(file, "utf8").split(/\r?\n/)) {
		const m = line.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$/);
		if (m) out[m[1]] = m[2].replace(/^["']|["']$/g, "");
	}
	return out;
}

const env = parseEnv(loadEnv());
const APP_ID = process.env.FEISHU_APP_ID || env.FEISHU_APP_ID;
const APP_SECRET = process.env.FEISHU_APP_SECRET || env.FEISHU_APP_SECRET;

async function token() {
	if (!APP_ID || !APP_SECRET) throw new Error("缺少 FEISHU_APP_ID / FEISHU_APP_SECRET（检查 .env）");
	const res = await fetch(BASE + "/auth/v3/tenant_access_token/internal", {
		method: "POST",
		headers: { "Content-Type": "application/json; charset=utf-8" },
		body: JSON.stringify({ app_id: APP_ID, app_secret: APP_SECRET }),
	});
	const json = await res.json();
	if (json.code !== 0) throw new Error(`获取 token 失败: code=${json.code} msg=${json.msg}`);
	return json.tenant_access_token;
}

async function api(pathname, { token: t, query } = {}) {
	const url = new URL(BASE + pathname);
	if (query) for (const [k, v] of Object.entries(query)) url.searchParams.set(k, v);
	const res = await fetch(url, {
		headers: { "Content-Type": "application/json; charset=utf-8", Authorization: `Bearer ${t}` },
	});
	const json = await res.json();
	if (json.code !== 0) throw new Error(`API ${pathname} 失败: code=${json.code} msg=${json.msg}`);
	return json.data;
}

// 单元格值归一化：数字保留；纯数字字符串转数值；空 → ""；富文本 → 文本。
function coerce(v) {
	if (v === null || v === undefined) return "";
	if (typeof v === "number" || typeof v === "boolean") return v;
	if (Array.isArray(v)) return v.map((e) => (e && e.text ? e.text : "")).join("");
	if (typeof v === "object") return v.text ?? JSON.stringify(v);
	const s = String(v).trim();
	if (s === "") return "";
	if (/^-?\d+$/.test(s)) return Number.parseInt(s, 10);
	if (/^-?\d+\.\d+$/.test(s)) return Number.parseFloat(s);
	return s;
}

async function exportTable(t, def) {
	const node = await api("/wiki/v2/spaces/get_node", { token: t, query: { token: def.node } });
	if (node.node.obj_type !== "sheet") throw new Error(`${def.name}: 节点不是电子表格 (${node.node.obj_type})`);
	const sheetToken = node.node.obj_token;
	const meta = await api(`/sheets/v3/spreadsheets/${sheetToken}/sheets/query`, { token: t });
	const sheetId = meta.sheets[0].sheet_id;
	const data = await api(`/sheets/v2/spreadsheets/${sheetToken}/values/${sheetId}!A1:Z200`, { token: t });
	const values = data.valueRange.values || [];

	const keys = (values[KEYS_ROW] || []).map((k) => String(k ?? "").trim());
	if (keys.length === 0) throw new Error(`${def.name}: 缺少表头（第 1 行英文 key）`);

	const rows = [];
	for (let r = DATA_ROW; r < values.length; r++) {
		const raw = values[r] || [];
		const obj = {};
		let empty = true;
		keys.forEach((k, c) => {
			if (!k) return;
			const val = coerce(raw[c]);
			obj[k] = val;
			if (val !== "") empty = false;
		});
		if (empty || obj.id === undefined || obj.id === "") continue; // 跳过空行/无 id 行
		rows.push(obj);
	}
	return { title: node.node.title, rows };
}

async function main() {
	const only = process.argv.slice(2).filter((a) => !a.startsWith("-"));
	const defs = only.length ? TABLES.filter((t) => only.includes(t.name)) : TABLES;
	if (defs.length === 0) {
		console.error("没有匹配的表:", only.join(", "));
		console.error("可选:", TABLES.map((t) => t.name).join(", "));
		process.exitCode = 1;
		return;
	}
	const t = await token();
	if (!fs.existsSync(OUT_DIR)) fs.mkdirSync(OUT_DIR, { recursive: true });
	for (const def of defs) {
		const { title, rows } = await exportTable(t, def);
		const file = path.join(OUT_DIR, `${def.name}.json`);
		fs.writeFileSync(file, JSON.stringify(rows, null, "\t") + "\n", "utf8");
		console.log(`${def.name.padEnd(12)} ${String(rows.length).padStart(3)} 行  <=  ${title}`);
	}
	console.log("导出完成 →", OUT_DIR);
}

main().catch((e) => {
	console.error("ERROR:", e.message);
	process.exitCode = 1;
});
