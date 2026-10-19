extends Node2D
## 最小可玩战斗场景：2v2 自动战斗（确定性 Tick）。
## 单位优先取数据（角色表/怪物表），数据未填时用 demo 数值兜底，保证能跑。
## 渲染：格网 + 色块单位 + 血条 + 顶部 HUD（纯色块占位，后续替换像素图）。

const CELL := 80.0
const COLS := 8
const ROWS := 4
const ORIGIN := Vector2(320.0, 200.0)
const TICK_SECONDS := 0.1

var sim: BattleSim
var _timer: Timer
var _units: Array[BattleUnit] = []


func _ready() -> void:
	_build_demo()
	_timer = Timer.new()
	_timer.wait_time = TICK_SECONDS
	_timer.timeout.connect(_on_tick)
	add_child(_timer)
	_timer.start()
	queue_redraw()
	print("[Battle] 战斗开始：%d 单位" % _units.size())


func _build_demo() -> void:
	sim = BattleSim.new(12345)
	_add_unit("CH_001", 0, 1, 1, {"hp": 120, "atk": 20, "def": 5, "atk_speed": 8, "range": 1, "mana": 100})
	_add_unit("CH_002", 0, 0, 2, {"hp": 80, "atk": 14, "def": 2, "atk_speed": 10, "range": 3, "mana": 100})
	_add_unit("MON_001", 1, 6, 1, {"hp": 110, "atk": 18, "def": 4, "atk_speed": 9, "range": 1, "mana": 0})
	_add_unit("MON_002", 1, 7, 2, {"hp": 70, "atk": 12, "def": 1, "atk_speed": 10, "range": 2, "mana": 0})


func _add_unit(id: String, side: int, x: int, y: int, demo: Dictionary) -> void:
	var row: Dictionary = DataLoader.get_character(id) if side == 0 else DataLoader.get_monster(id)
	var stats: Dictionary = demo
	# 数据已填（hp 非空）则优先用数据
	if not row.is_empty() and str(row.get("hp", "")) != "":
		stats = row
	var u := BattleUnit.from_row(stats, side, x, y)
	u.id = id
	sim.add_unit(u)
	_units.append(u)


func _on_tick() -> void:
	if sim.is_over() or sim.tick >= BattleSim.MAX_TICKS:
		_timer.stop()
		queue_redraw()
		print("[Battle] 结束 tick=%d over=%s" % [sim.tick, str(sim.is_over())])
		return
	sim.step()
	queue_redraw()


func _draw() -> void:
	# 棋盘
	for gx in COLS:
		for gy in ROWS:
			var p := ORIGIN + Vector2(gx * CELL, gy * CELL)
			draw_rect(Rect2(p, Vector2(CELL, CELL)), Color(0.12, 0.12, 0.16), false, 1.0)
	# 单位
	for u: BattleUnit in _units:
		if not u.is_alive():
			continue
		var p := ORIGIN + Vector2(u.x * CELL, u.y * CELL) + Vector2(8, 8)
		var size := Vector2(CELL - 16, CELL - 16)
		var col := Color(0.30, 0.60, 1.00) if u.side == 0 else Color(1.00, 0.35, 0.35)
		draw_rect(Rect2(p, size), col)
		# 血条
		var ratio := float(u.hp) / maxf(1.0, float(u.max_hp))
		draw_rect(Rect2(p + Vector2(0, -8), Vector2(size.x, 5)), Color(0.2, 0.2, 0.2))
		draw_rect(Rect2(p + Vector2(0, -8), Vector2(size.x * ratio, 5)), Color(0.3, 0.9, 0.3))
	# HUD
	var alive_p := 0
	var alive_e := 0
	for u: BattleUnit in _units:
		if u.is_alive():
			if u.side == 0:
				alive_p += 1
			else:
				alive_e += 1
	var font := ThemeDB.fallback_font
	var hud := "Tick %d   Player %d  vs  Enemy %d" % [sim.tick, alive_p, alive_e]
	draw_string(font, ORIGIN + Vector2(0, -48), hud, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
	if sim.is_over() or sim.tick >= BattleSim.MAX_TICKS:
		var result := "DRAW / TIMEOUT"
		if alive_e == 0 and alive_p > 0:
			result = "PLAYER WIN"
		elif alive_p == 0 and alive_e > 0:
			result = "ENEMY WIN"
		draw_string(font, ORIGIN + Vector2(0, -16), result, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color.YELLOW)
