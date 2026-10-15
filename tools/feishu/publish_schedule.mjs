#!/usr/bin/env node
// 把 docs/schedule.md 的排期（里程碑总览 + 每日排期两张 markdown 表）发布/更新到飞书表格。
// docs/schedule.md 是唯一真源（由飞书导出），本脚本反向「以 md 为准」发布，避免硬编码过期数据。
//
// 用法：
//   node tools/feishu/publish_schedule.mjs                 # 新建一张表格并写入，记录到 docs/.feishu_schedule.json
//   node tools/feishu/publish_schedule.mjs --token=<ss>    # 覆盖更新已有表格（按 sheet 标题定位）
//   node tools/feishu/publish_schedule.mjs --wiki          # 额外挂到 autochess wiki 空间（可能因权限失败）
//   node tools/feishu/publish_schedule.mjs --dry           # 只解析并打印行数，不发布
//
// 凭据：环境变量 FEISHU_APP_ID / FEISHU_APP_SECRET，或仓库根 .env。依赖 Node 18+。

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const BASE = "https://open.feishu.cn/open-apis";
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "..", "..");
const MD_PATH = path.join(ROOT, "docs", "schedule.md");
const META_PATH = path.join(ROOT, "docs", ".feishu_schedule.json");
const WIKI_SPACE = "7567229295170519043";
const FOLDER_TOKEN = "nodcnKrRmeIdE8sDJ4rYHlCRSjh";
const MAX_ROWS = 200;

function parseEnv(file) {
	const out = {};
	if (!fs.existsSync(file)) return out;
	for (const line of fs.readFileSync(file, "utf8").split(/\r?\n/)) {
		const m = line.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$/);
		if (m) out[m[1]] = m[2].replace(/^["']|["']$/g, "");
	}
	return out;
}
const env = parseEnv(path.join(ROOT, ".env"));
const APP_ID = process.env.FEISHU_APP_ID || env.FEISHU_APP_ID;
const APP_SECRET = process.env.FEISHU_APP_SECRET || env.FEISHU_APP_SECRET;

async function token() {
	if (!APP_ID || !APP_SECRET) throw new Error("缺少 FEISHU_APP_ID / FEISHU_APP_SECRET（检查 .env）");
	const res = await fetch(BASE + "/auth/v3/tenant_access_token/internal", {
		method: "POST",
		headers: { "Content-Type": "application/json; charset=utf-8" },
		body: JSON.stringify({ app_id: APP_ID, app_secret: APP_SECRET }),
	});
	const j = await res.json();
	if (j.code !== 0) throw new Error(`token: ${j.code} ${j.msg}`);
	return j.tenant_access_token;
}

async function call(t, method, pathname, body) {
	const res = await fetch(BASE + pathname, {
		method,
		headers: { "Content-Type": "application/json; charset=utf-8", Authorization: `Bearer ${t}` },
		body: body ? JSON.stringify(body) : undefined,
	});
	const j = await res.json();
	if (j.code !== 0) throw new Error(`${pathname}: ${j.code} ${j.msg}`);
	return j.data;
}

// ---- 解析 markdown 表格 ----

function nextTableLine(lines, from) {
	for (let i = from + 1; i < lines.length; i++) if (lines[i].trim().startsWith("|")) return i;
	return -1;
}

function parseTable(lines, start) {
	const rows = [];
	for (let i = start; i < lines.length; i++) {
		const line = lines[i].trim();
		if (!line.startsWith("|")) break;
		if (/^\|[\s|:-]+\|?$/.test(line)) continue; // 分隔行 |---|---|
		rows.push(line.replace(/^\||\|$/g, "").split("|").map((c) => c.trim()));
	}
	return rows;
}

function parseSchedule(md) {
	const lines = md.split(/\r?\n/);
	const find = (title) => lines.findIndex((l) => l.trim() === title);
	const m = find("## 里程碑总览");
	const d = find("## 每日排期");
	if (m < 0 || d < 0) throw new Error("docs/schedule.md 缺少 '## 里程碑总览' 或 '## 每日排期'");
	const milestones = parseTable(lines, nextTableLine(lines, m));
	const daily = parseTable(lines, nextTableLine(lines, d));
	return { milestones, daily };
}

function esc(v) {
	return String(v ?? "").replace(/\t/g, " ");
}

// ---- 发布 ----

async function ensureSheets(t, ssToken, names) {
	const q = await call(t, "GET", `/sheets/v3/spreadsheets/${ssToken}/sheets/query`);
	const ids = {};
	for (const s of q.sheets) ids[s.title] = s.sheet_id;
	for (const name of names) {
		if (!ids[name]) {
			const add = await call(t, "POST", `/sheets/v2/spreadsheets/${ssToken}/sheets_batch_update`, {
				requests: [{ addSheet: { properties: { title: name, index: 0 } } }],
			});
			ids[name] = add.replies[0].addSheet.properties.sheetId;
		}
	}
	return ids;
}

async function writeGrid(t, ssToken, sheetId, rows) {
	await call(t, "PUT", `/sheets/v2/spreadsheets/${ssToken}/values`, {
		valueRange: { range: `${sheetId}!A1:Z${rows.length}`, values: rows },
	});
	// 清掉多余旧行
	const extra = [];
	for (let r = rows.length; r < MAX_ROWS; r++) extra.push(new Array(rows[0].length).fill(""));
	if (extra.length) {
		await call(t, "PUT", `/sheets/v2/spreadsheets/${ssToken}/values`, {
			valueRange: { range: `${sheetId}!A${rows.length + 1}:Z${MAX_ROWS}`, values: extra },
		});
	}
}

async function main() {
	const args = process.argv.slice(2);
	const dry = args.includes("--dry");
	const withWiki = args.includes("--wiki");
	const tokenArg = args.find((a) => a.startsWith("--token="));
	const updateToken = tokenArg ? tokenArg.slice("--token=".length) : null;

	const md = fs.readFileSync(MD_PATH, "utf8");
	const { milestones, daily } = parseSchedule(md);
	console.log(`解析 docs/schedule.md：里程碑 ${milestones.length} 行，每日排期 ${daily.length} 行`);
	if (dry) return;

	const t = await token();

	let ssToken = updateToken;
	if (!ssToken && fs.existsSync(META_PATH)) {
		try { ssToken = JSON.parse(fs.readFileSync(META_PATH, "utf8")).ssToken; } catch { /* ignore */ }
	}
	if (!ssToken) {
		const created = await call(t, "POST", "/sheets/v3/spreadsheets", {
			title: "AutoChess 自走棋 · 完整项目排期（日粒度）",
			folder_token: FOLDER_TOKEN,
		});
		ssToken = created.spreadsheet.spreadsheet_token;
		console.log("新建表格:", created.spreadsheet.url);
	} else {
		console.log("更新表格:", ssToken);
	}

	const ids = await ensureSheets(t, ssToken, ["每日排期", "里程碑总览"]);
	await writeGrid(t, ssToken, ids["每日排期"], daily);
	await writeGrid(t, ssToken, ids["里程碑总览"], milestones);

	let wiki = "skipped";
	if (withWiki) {
		try {
			await call(t, "POST", `/wiki/v2/spaces/${WIKI_SPACE}/nodes`, { obj_type: "sheet", node_type: "origin", obj_token: ssToken });
			wiki = "ok";
		} catch (e) {
			wiki = "failed: " + e.message;
		}
	}

	fs.writeFileSync(META_PATH, JSON.stringify({ ssToken, wiki }, null, 2), "utf8");
	console.log(`已发布：每日排期 ${daily.length} 行 / 里程碑 ${milestones.length} 行；wiki=${wiki}`);
}

main().catch((e) => {
	console.error("ERROR:", e.message);
	process.exitCode = 1;
});
