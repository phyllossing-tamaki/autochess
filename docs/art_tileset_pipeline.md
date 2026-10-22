# 地图集（Tileset）AI 生成管线（推荐）

> 适用：Godot 4、1600×900、战斗格 **96 原生 1:1**、角色 **128×128 1:1**、暗底发光奇幻。
> 状态：候选推荐（2026-10），非最终定稿。

## 结论

**PixelLab（出材质/地形）+ Tilesetter 或 SpriteLab（组 autotile）+ Aseprite（修缝 + 锁色）+ Godot TileSet。**
追求最高像素纯度的底图用 **Retro Diffusion** 补。

## 工具对比（2026 实况）

| 工具 | 定位 | 对 tileset 的关键能力 | 适合我们 |
|---|---|---|---|
| PixelLab | 全流程 AI 像素工具 | Create Tiles Pro 支持 96/128；可给 style 参考图；MCP/API 自动化 | 出 96 材质最对口 |
| SpriteLab | AI tileset 专用 | 直接出 15 片 corner autotile，导出 Godot 4 .tres / Tiled .tsx | 省去手拼 autotile |
| Tilesetter | 传统 tileset 生成器 | 从一张底材质自动生成 15/47 片 autotile，任意尺寸，导 Godot | 把 AI 材质变成 autotile |
| Retro Diffusion | 真像素模型 | 输出最“真像素”（网格/限色/无抗锯齿）；tileset 能力弱 | 底图质量兜底 |
| PIXL | LLM 原生 .pax 文本 tileset | 文本定义→渲染→导 Godot TileMap；可训练风格、本地 | 想 Git 友好/自动化可选 |
| PixelKiln | 命令行管线（调 PixelLab/RD API） | tiles/terrain/uiAsset/vfx 生成器 + 引擎导出 | 批量/可复现 |
| ComfyUI + SDXL/Flux + ControlNet(tile) + pixel LoRA | 本地自由组合 | 可做无缝材质、批量、风格锁定 | 有折腾预算时最强 |

## 推荐管线

### A. 省事版（先跑通）

1. **定规格**：战斗地砖 **96×96 原生**（不要 32 缩放 3×，否则与 128 角色像素密度不一致）；autotile 用 **15 片 corner**（Godot terrain）。
2. **风格锚定**：把 `assets/sprites/units/hero_sheet*.png` 当 style reference。
3. **生成材质**：PixelLab Create Tiles Pro（size 96）出 石砖/苔藓/水/悬崖 底材质 + 变体。
4. **组 autotile**：Tilesetter 或 SpriteLab 包成 15 片，导出 Godot `.tres` / PNG。
5. **后处理**：Aseprite 量化到规范调色板、修接缝、统一光源方向。
6. **Godot**：TileSet 96×96 + terrain 规则 + TileMapLayer；Nearest、无压缩。

### B. 质量优先

- 底图用 **Retro Diffusion**（最高纯度）→ Aseprite 修 → Tilesetter 组 autotile → Godot。
- 要“无缝/批量”：ComfyUI + **ControlNet tile** 生成可平铺材质，再走 Tilesetter。

## 4 个必须注意的坑

1. **像素密度**：底图必须 96 原生 1:1；非整数缩放会糊、与角色不搭。
2. **接缝**：AI 常“看着平铺、实际有缝”→ 做 offset-wrap 检查 / tileable 生成，再手修边。
3. **autotile 逻辑**：AI 不懂 15/47 片角/边规则 → 别让 AI 直接出 autotile，交给 Tilesetter/SpriteLab。
4. **调色板/光源**：统一量化到规范调色板、统一主光方向。

## 下一步（最小验证）

先做 **1 种地面（石砖）+ 1 种过渡（苔藓）+ 15 片 autotile @96**，接进现有战斗预览替换程序化地砖，确认密度/接缝/调色板 OK，再批量扩到水/悬崖/特殊地块。
