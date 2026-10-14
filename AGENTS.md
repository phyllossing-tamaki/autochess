# 项目上下文（opencode 会自动读取）

## 项目
- 类型：像素风自走棋（Auto Chess）独立游戏
- 引擎：**Godot 4.x**，脚本语言 **GDScript**
- 渲染：`gl_compatibility`（2D 像素，兼容性优先）
- 逻辑分辨率 640x360，`canvas_items` 拉伸 + `keep` 比例，纹理过滤为 **Nearest**

## 目录约定
- `scenes/`   场景（.tscn）
- `scripts/`  GDScript（.gd）
- `assets/sprites/` 像素图集、精灵
- `assets/audio/`   BGM / 音效
- `assets/fonts/`   位图字体
- `data/`     棋子 / 羁绊 / 关卡等配置（优先 json 或 .tres）

## 常用命令
本机未把 Godot 装到系统 PATH；项目自带便携版在 `tools/godot/`（仅 `.bat` 脚本入库，编辑器 exe 已在 .gitignore 忽略，每台机器各自放置）。
- 编辑器打开：`godot --path . --editor` 或 `tools\godot\editor.bat`
- 直接运行：`godot --path .` 或 `tools\godot\run.bat`
- 无窗口导入（CI/校验资源）：`godot --headless --path . --import` 或 `tools\godot\import.bat`
- 运行测试：`godot --headless --path . -s addons/gut/gut_cmdln.gd`（若接入 GUT）
- 关键：GitHub 需走本机代理 `http://127.0.0.1:7897`（已写入 git 全局 `http.https://github.com.proxy`）

## 代码风格
- 遵循 Godot 官方 GDScript 风格指南；缩进用 **制表符（Tab）**
- 节点用 `@onready var x: Type = $Path`，类型注解尽量补全
- 信号用 `signal_name.connect(_on_x)` 的新式写法
- 命名：节点/文件 snake_case，类 `class_name` 用 PascalCase

## 开发约定
- 改动 .gd/.tscn 后建议在 Godot 编辑器内确认无报错再提交

## 双设备同步（重要）
- 仓库：GitHub 私有仓库 + **Git LFS**
- **绝不提交** `.godot/`、`export_presets.cfg`（已在 .gitignore）
- 开始工作前：`git pull --rebase`
- 收工前：`git add -A && git commit -m "..." && git push`
- 新机器首次：`git clone <url>` 后执行 `git lfs pull`
- 二进制美术资源走 LFS；不要手动修改 LFS 指针文件
- `.tscn` / `.tres` 为文本格式，冲突时手动合并，勿用并集合并
- 每次切换设备前务必提交并推送，避免两端各自修改同一场景

## 工作日志（飞书）
- 文档：**工作日志** → https://my.feishu.cn/wiki/D8UNwjAzIiTRBpkOsHMcINMznEP
- 约定：每次收工 `git commit + push` 后，在飞书「工作日志」文档**按日期追加**一条记录，说明当日完成的工作与改动，并附本次提交信息（commit 短 hash + 一句话）。
- 追加位置：文档末尾（按日期递增，最新在最后）。
- 相关工具与凭据：见 `tools/feishu/`；凭据放仓库根 `.env`（已 gitignore）。

## 数据管线（飞书 → 代码）
- 子表（两行表头：第 1 行英文 key、第 2 行中文；数据从第 3 行起）→ `tools/feishu/export.mjs` 导出为 `data/*.json` → `DataLoader`（autoload）读取。
- 字段名必须与表头英文 key 一致；跨表关联统一走 `id` / `effect_id`。
- 运行：`node tools/feishu/export.mjs`；校验：`godot --headless --path . -s res://scripts/dev/validate_data.gd`。
