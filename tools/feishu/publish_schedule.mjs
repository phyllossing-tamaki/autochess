#!/usr/bin/env node
// 把 docs/schedule.md 的日粒度排期发布为一张新的飞书表格（spreadsheet）。
// 用法：node tools/feishu/publish_schedule.mjs [--wiki]
//   --wiki  额外把新表格挂到 autochess 的 wiki 空间（可能因权限失败，失败不影响表格创建）

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const BASE = "https://open.feishu.cn/open-apis";
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "..", "..");
const WIKI_SPACE = "7567229295170519043";
const FOLDER_TOKEN = "nodcnKrRmeIdE8sDJ4rYHlCRSjh";

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

async function token() {
	const res = await fetch(BASE + "/auth/v3/tenant_access_token/internal", {
		method: "POST",
		headers: { "Content-Type": "application/json; charset=utf-8" },
		body: JSON.stringify({ app_id: env.FEISHU_APP_ID, app_secret: env.FEISHU_APP_SECRET }),
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

const milestones = [
	["阶段", "目标", "起止", "工作日"],
	["P1C 数据表补齐", "6 张子表落地并填全量", "10-14 ~ 10-27", "12"],
	["P1D 口径对齐", "稀有度/定价/节点/名单统一", "10-28 ~ 10-31", "4"],
	["P1E 平衡首轮", "解卡关、胜率曲线合理", "11-02 ~ 11-07", "6"],
	["P2A 肉鸽壳/局外", "局外房间、难度、终局、存档、干预", "11-09 ~ 12-05", "24"],
	["P2B 表现层", "色块→像素、动画、飘字、特效", "12-07 ~ 12-22", "14"],
	["P3A 内容量产", "事件50/装备70/角色立绘", "12-23 ~ 01-16", "21"],
	["P3B 音频+三语", "BGM/音效 + 中英日本地化", "01-18 ~ 01-30", "11"],
	["P3C Boss/关卡/羁绊", "Boss 设计、地图、羁绊扩充", "02-01 ~ 02-27", "15"],
	["P4A 平衡+难度曲线", "参数扫描调参、10 级难度", "03-01 ~ 03-20", "18"],
	["P4B Steam Demo/打包", "页面/Demo/打包/Steamworks", "03-22 ~ 04-03", "11"],
	["P4C 发布前打磨", "测试、字体、无障碍、发布", "04-05 ~ 04-17", "11"],
	["Buffer", "风险缓冲", "04-19 ~ 04-30", "—"],
];

const daily = [
	["阶段", "日期", "星期", "任务", "产出 / 验收"],
	["P1C", "10-14", "三", "建 6 张子表骨架（装备/卷轴/药剂/羁绊/技能/赐福）+ 字段规范", "6 张空表 + 字段说明"],
	["P1C", "10-15", "四", "装备表字段定案 + 填写 1~20（含 4 级武器分级规则）", "装备表前 20"],
	["P1C", "10-16", "五", "装备表填至 70；词条/乘区归属（atk/def/amp/crit）标注", "装备表 70 全量"],
	["P1C", "10-17", "六", "法术卷轴表 20 条（战斗/经济两类）", "卷轴表 20"],
	["P1C", "10-18", "日", "休息", "—"],
	["P1C", "10-19", "一", "药剂表 10 条（敌我双用标注）", "药剂表 10"],
	["P1C", "10-20", "二", "羁绊表：定义 + 数值梯度（2/3/4 档加成）", "羁绊表"],
	["P1C", "10-21", "三", "技能表：模板与分类（damage/heal/shield/aoe/dot/buff…）", "技能模板"],
	["P1C", "10-22", "四", "技能表：首批 20 技能", "技能表 20"],
	["P1C", "10-23", "五", "技能表：覆盖 46 单位 + 怪物技能", "技能表全量"],
	["P1C", "10-24", "六", "神明赐福表复核 10 条 + 预留扩展列", "赐福表"],
	["P1C", "10-25", "日", "休息", "—"],
	["P1C", "10-26", "一", "角色表补全：神话稀有度、去重（芙蕾雅）、修 bd 空列", "角色表干净"],
	["P1C", "10-27", "二", "角色表 sheet2 数值补全（站位定案）；怪物表 41 只战斗数值补全", "两表数值完整"],
	["P1D", "10-28", "三", "稀有度 6 档 ↔ 定价（传说/神话）定案；写回策划案", "定价规则确认"],
	["P1D", "10-29", "四", "节点/地图口径统一（3 阶段 ×10 节点 vs 3 图）；35 角色名单定案", "口径 1 页"],
	["P1D", "10-30", "五", "release JSON 全量填充；data_loader.DATASET 切 release", "release 可运行"],
	["P1D", "10-31", "六", "数据一致性校验脚本（表 ↔ JSON 对账）", "校验通过"],
	["P1E", "11-02", "一", "run_sweep 多 seed 取证（前期胜率/卡关点）", "基线曲线"],
	["P1E", "11-03", "二", "降前期敌方强度 / 提高经济与星级成长", "调参方案落地"],
	["P1E", "11-04", "三", "失败也给成长（避免重试阵容不变死循环）", "反卡关机制"],
	["P1E", "11-05", "四", "参数扫描复验（暴击/护甲系数/攻速）", "曲线回归"],
	["P1E", "11-06", "五", "playcheck 完整多局跑通（无卡关）", "playcheck 全通"],
	["P1E", "11-07", "六", "P1 里程碑评审 + 同步飞书排期", "里程碑达成"],
	["P2A", "11-09", "一", "局外房间骨架（赛博酒保式小房间场景）", "房间可进入"],
	["P2A", "11-10", "二", "公司福利系统（入局 buff）", "福利可选可生效"],
	["P2A", "11-11", "三", "永久商店（购买永久加成）", "永久加成落地"],
	["P2A", "11-12", "四", "一次性道具带入局内（选商品→带入）", "带入闭环"],
	["P2A", "11-13", "五", "难度系统 1~10 数据 + 每级专属 debuff", "难度表"],
	["P2A", "11-14", "六", "难度选择 UI + 影响战斗数值", "难度生效"],
	["P2A", "11-15", "日", "休息", "—"],
	["P2A", "11-16", "一", "存档系统（局外进度/解锁/设置）", "存档读写"],
	["P2A", "11-17", "二", "局外元进度（解锁道具/圣物/卡牌）", "解锁生效"],
	["P2A", "11-18", "三", "终局分支 A：继续打工线", "分支 A"],
	["P2A", "11-19", "四", "终局分支 B：爆了单干 + 自定义初始角色", "分支 B"],
	["P2A", "11-20", "五", "剧情/引导文本（画饼→弊端→终局）", "文本入表"],
	["P2A", "11-21", "六", "局外 ↔ 局内数据串联自测", "串联通过"],
	["P2A", "11-22", "日", "休息", "—"],
	["P2A", "11-23", "一", "多回合成长曲线 + 失败成长曲线", "成长曲线"],
	["P2A", "11-24", "二", "通关/失败结算打磨（复用 flow_overlay）", "结算 UI"],
	["P2A", "11-25", "三", "战斗干预：技能手动释放", "手动技能"],
	["P2A", "11-26", "四", "药水敌我双用", "药水干预"],
	["P2A", "11-27", "五", "支援法术（战斗向）", "战斗法术"],
	["P2A", "11-28", "六", "支援法术（经济向）", "经济法术"],
	["P2A", "11-29", "日", "休息", "—"],
	["P2A", "11-30", "一", "肉鸽壳整体串联回归（--flowtest）", "全流程通"],
	["P2A", "12-01", "二", "打包内部 Demo（自测版）", "Demo 可跑"],
	["P2A", "12-02", "三", "试玩反馈收集", "反馈清单"],
	["P2A", "12-03", "四", "按反馈修复（第一批）", "修复"],
	["P2A", "12-04", "五", "按反馈修复（第二批）", "修复"],
	["P2A", "12-05", "六", "P1+P2A 里程碑评审 + 同步飞书", "里程碑达成"],
	["P2B", "12-07", "一", "像素图替换准备态色块（unit_token）", "准备态全像素"],
	["P2B", "12-08", "二", "像素图替换战斗态色块（battle_board）", "战斗态全像素"],
	["P2B", "12-09", "三", "移动动画（帧动画接入）", "移动帧"],
	["P2B", "12-10", "四", "攻击动画", "攻击帧"],
	["P2B", "12-11", "五", "受击/死亡动画", "受击帧"],
	["P2B", "12-12", "六", "技能施法动画 + 前摇可视（蓝量/施法条）", "施法表现"],
	["P2B", "12-13", "日", "休息", "—"],
	["P2B", "12-14", "一", "伤害飘字（暴击/治疗/护盾分色）", "飘字"],
	["P2B", "12-15", "二", "命中顿帧 + 受击反馈", "打击感"],
	["P2B", "12-16", "三", "光效（技能/升级/羁绊激活）", "光效"],
	["P2B", "12-17", "四", "镜头微震 / 慢动作（大招/胜负）", "镜头"],
	["P2B", "12-18", "五", "棋盘/地块美术（高地/掩体/荆棘/治疗泉/金币矿/迷雾）", "地块美术"],
	["P2B", "12-19", "六", "UI 皮肤（商店/备战席/信息面板统一像素风）", "UI 统一"],
	["P2B", "12-20", "日", "休息", "—"],
	["P2B", "12-21", "一", "音效占位接入（攻击/技能/UI）", "音效占位"],
	["P2B", "12-22", "二", "表现层性能自测（60fps 目标）+ 里程碑评审", "表现层达成"],
	["P3A", "12-23~12-26", "三~六", "事件 E011~E035（25 个，含选项效果结构化）", "事件 35"],
	["P3A", "12-27", "日", "休息", "—"],
	["P3A", "12-28~12-31", "一~四", "事件 E036~E050（补足 50）+ 权重调优", "事件 50"],
	["P3A", "01-01~01-02", "五~六", "装备补到 70 的落表/落 JSON 核对", "装备 70"],
	["P3A", "01-03", "日", "休息", "—"],
	["P3A", "01-04~01-09", "一~六", "角色立绘/图标（占位→正式，按 16 逻辑像素规范）", "立绘批次1"],
	["P3A", "01-10", "日", "休息", "—"],
	["P3A", "01-11~01-16", "一~六", "角色立绘批次2 + 怪物美术 + 技能图标", "美术达标"],
	["P3B", "01-18~01-20", "一~三", "凯尔特神话 BGM（主菜单/战斗/局外/Boss）", "BGM 4 首"],
	["P3B", "01-21~01-22", "四~五", "音效全量（攻击/技能/升星/羁绊/UI）", "音效全量"],
	["P3B", "01-23", "六", "字符串表结构抽取（所有 UI 文案 key 化）", "i18n 结构"],
	["P3B", "01-24", "日", "休息", "—"],
	["P3B", "01-25~01-27", "一~三", "英文翻译校对", "en 完成"],
	["P3B", "01-28~01-30", "四~六", "日文翻译校对（优先）+ 字体/换行适配", "ja 完成"],
	["P3C", "02-01~02-03", "一~三", "3 阶段 ×3 地图设计（节点布局/特殊地块）", "9 张图"],
	["P3C", "02-04", "四", "阶段 Boss ×3 设计（机制/破绽/掉落）", "Boss 设计稿"],
	["P3C", "02-05~02-14", "—", "春节假期", "—"],
	["P3C", "02-15~02-18", "一~四", "Boss 实现（招式循环/阶段切换）", "Boss 可打"],
	["P3C", "02-19~02-21", "五~六", "羁绊池扩充（战斗/经济/神话系）", "羁绊 15+"],
	["P3C", "02-22", "日", "休息", "—"],
	["P3C", "02-23~02-27", "一~六", "精英/休息/行商节点变体 + 关卡平衡初调", "节点丰富"],
	["P4A", "03-01~03-06", "一~六", "run_sweep 全参数扫描（攻/防/暴击/蓝/经济/概率）", "参数报告"],
	["P4A", "03-07", "日", "休息", "—"],
	["P4A", "03-08~03-13", "一~六", "10 级难度曲线（每级 debuff 强度梯度）", "难度曲线"],
	["P4A", "03-14", "日", "休息", "—"],
	["P4A", "03-15~03-20", "一~六", "稀有度概率/掉落/经济曲线终调 + 回归", "平衡收敛"],
	["P4B", "03-22~03-24", "一~三", "Steam 页面素材（截图/预告/GIF 钩子三秒可懂）", "页面素材"],
	["P4B", "03-25~03-27", "四~六", "Demo 切包（限定内容）+ 存档隔离", "Demo 版"],
	["P4B", "03-28", "日", "休息", "—"],
	["P4B", "03-29~04-01", "一~四", "Steamworks 集成（成就/云存档/统计）", "SDK 接入"],
	["P4B", "04-02~04-03", "五~六", "多平台打包测试（Windows 优先）", "打包通过"],
	["P4C", "04-05~04-08", "一~四", "全流程回归测试（新档/读档/各结局）", "回归清单"],
	["P4C", "04-09~04-11", "五~日", "无障碍（难度倍率/瞄准辅助/QTE 可关）", "无障碍项"],
	["P4C", "04-12~04-14", "一~三", "Bug 修复 + 崩溃日志复核", "缺陷收敛"],
	["P4C", "04-15~04-17", "四~六", "发布候选版（RC）+ 商店文案/价格定档", "RC 冻结"],
	["Buffer", "04-19~04-30", "—", "风险缓冲 / 好评率提升（表现与手感打磨）/ 发布", "发布"],
];

async function main() {
	const args = process.argv.slice(2);
	const t = await token();

	const created = await call(t, "POST", "/sheets/v3/spreadsheets", {
		title: "AutoChess 自走棋 · 完整项目排期（日粒度）",
		folder_token: FOLDER_TOKEN,
	});
	const ssToken = created.spreadsheet.spreadsheet_token;
	const url = created.spreadsheet.url;

	const q = await call(t, "GET", `/sheets/v3/spreadsheets/${ssToken}/sheets/query`);
	const defId = q.sheets[0].sheet_id;
	await call(t, "POST", `/sheets/v2/spreadsheets/${ssToken}/sheets_batch_update`, {
		requests: [{ updateSheet: { properties: { sheetId: defId, title: "每日排期" } } }],
	});
	const add = await call(t, "POST", `/sheets/v2/spreadsheets/${ssToken}/sheets_batch_update`, {
		requests: [{ addSheet: { properties: { title: "里程碑总览", index: 0 } } }],
	});
	const msId = add.replies[0].addSheet.properties.sheetId;

	async function write(range, values) {
		return call(t, "PUT", `/sheets/v2/spreadsheets/${ssToken}/values`, {
			valueRange: { range, values },
		});
	}
	await write(`${defId}!A1:E${daily.length}`, daily);
	await write(`${msId}!A1:D${milestones.length}`, milestones);

	let wiki = "skipped";
	if (args.includes("--wiki")) {
		try {
			await call(t, "POST", `/wiki/v2/spaces/${WIKI_SPACE}/nodes`, {
				obj_type: "sheet",
				node_type: "origin",
				obj_token: ssToken,
			});
			wiki = "ok";
		} catch (e) {
			wiki = "failed: " + e.message;
		}
	}

	fs.writeFileSync(path.join(ROOT, "docs", ".feishu_schedule.json"), JSON.stringify({ ssToken, url, wiki }, null, 2), "utf8");
	console.log("spreadsheet_token=" + ssToken);
	console.log("url=" + url);
	console.log("wiki=" + wiki);
}

main().catch((e) => {
	console.error("ERROR:", e.message);
	process.exitCode = 1;
});
