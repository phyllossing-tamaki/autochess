#!/usr/bin/env node
// 飞书（Feishu / Lark）自建应用 CLI 小工具。
// 凭据读取仓库根目录的 .env（已被 .gitignore 忽略）。
//
// 用法：
//   node tools/feishu/feishu.mjs token
//   node tools/feishu/feishu.mjs list
//   node tools/feishu/feishu.mjs meta <docId>
//   node tools/feishu/feishu.mjs read <docId>
//   node tools/feishu/feishu.mjs blocks <docId>
//   node tools/feishu/feishu.mjs send <receiveId> <text...>
//
// 依赖：Node 18+（使用内置 fetch），无需 npm install。

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const BASE = "https://open.feishu.cn/open-apis";
const __dirname = path.dirname(fileURLToPath(import.meta.url));

function loadEnv() {
	let dir = process.cwd();
	for (let i = 0; i < 6; i++) {
		const p = path.join(dir, ".env");
		if (fs.existsSync(p)) return p;
		const up = path.dirname(dir);
		if (up === dir) break;
		dir = up;
	}
	// 回退到仓库根（脚本位于 <root>/tools/feishu/）
	return path.join(__dirname, "..", "..", ".env");
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

async function api(pathname, { method = "GET", body, token, query } = {}) {
	const url = new URL(BASE + pathname);
	if (query) for (const [k, v] of Object.entries(query)) url.searchParams.set(k, v);
	const headers = { "Content-Type": "application/json; charset=utf-8" };
	if (token) headers.Authorization = `Bearer ${token}`;
	const res = await fetch(url, {
		method,
		headers,
		body: body ? JSON.stringify(body) : undefined,
	});
	const json = await res.json();
	if (json.code !== 0) {
		throw new Error(`Feishu API ${pathname} failed: code=${json.code} msg=${json.msg}`);
	}
	return json.data;
}

async function token() {
	if (!APP_ID || !APP_SECRET) throw new Error("缺少 FEISHU_APP_ID / FEISHU_APP_SECRET（检查 .env）");
	const url = new URL(BASE + "/auth/v3/tenant_access_token/internal");
	const res = await fetch(url, {
		method: "POST",
		headers: { "Content-Type": "application/json; charset=utf-8" },
		body: JSON.stringify({ app_id: APP_ID, app_secret: APP_SECRET }),
	});
	const json = await res.json();
	if (json.code !== 0) throw new Error(`获取 token 失败: code=${json.code} msg=${json.msg}`);
	return json.tenant_access_token;
}

async function main() {
	const [cmd, ...args] = process.argv.slice(2);
	switch (cmd) {
		case "token": {
			console.log(await token());
			break;
		}
		case "list": {
			const t = await token();
			const data = await api("/drive/v1/files", { token: t, query: { page_size: 200 } });
			for (const f of data.files) console.log(`${f.type}\t${f.token}\t${f.name}\t${f.url}`);
			break;
		}
		case "meta": {
			const t = await token();
			const data = await api(`/docx/v1/documents/${args[0]}`, { token: t });
			console.log(JSON.stringify(data.document, null, 2));
			break;
		}
		case "read": {
			const t = await token();
			const data = await api(`/docx/v1/documents/${args[0]}/raw_content`, { token: t });
			process.stdout.write(data.content || "");
			break;
		}
		case "blocks": {
			const t = await token();
			const data = await api(`/docx/v1/documents/${args[0]}/blocks`, {
				token: t,
				query: { page_size: 500 },
			});
			console.log(JSON.stringify(data, null, 2));
			break;
		}
		case "send": {
			const [receiveId, ...rest] = args;
			const text = rest.join(" ");
			const t = await token();
			const data = await api("/im/v1/messages", {
				method: "POST",
				token: t,
				query: { receive_id_type: "open_id" },
				body: { receive_id: receiveId, msg_type: "text", content: JSON.stringify({ text }) },
			});
			console.log(JSON.stringify(data, null, 2));
			break;
		}
		default:
			console.log("用法: node tools/feishu/feishu.mjs <token|list|meta|read|blocks|send> [args]");
			process.exitCode = cmd ? 1 : 0;
	}
}

main().catch((e) => {
	console.error("ERROR:", e.message);
	process.exitCode = 1;
});
