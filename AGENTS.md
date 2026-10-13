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
- 编辑器打开：`godot --path . --editor`
- 直接运行：`godot --path .`
- 运行主场景：`godot --path . res://scenes/main.tscn`
- 无窗口导入（CI/校验资源）：`godot --headless --path . --import`
- 运行测试：`godot --headless --path . -s addons/gut/gut_cmdln.gd`（若接入 GUT）

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
