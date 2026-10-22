extends Node2D
## 战斗预览（临时）：1600x900，8x4 棋盘（每格 128），角色 128x128。
## 同时上阵两个角色：
##   CH_001 -> hero_sheet.png  |  CH_002 -> hero_sheet2.png
##   敌方 MON_001/MON_002 用同两张图镜像 + 红色调制（仅占位区分敌我）。
## 20 帧攻击动画循环，战斗结束 2 秒后自动重开。

const CELL := 96.0
const COLS := 8
const ROWS := 4
const ORIGIN := Vector2(416.0, 258.0)   # (1600 - 8*96)/2 = 416 ; (900 - 4*96)/2 = 258
const TICK_SECONDS := 0.1
const SHEET_A_PATH := "res://assets/sprites/units/hero_sheet.png"
const SHEET_B_PATH := "res://assets/sprites/units/hero_sheet2.png"
const HFRAMES := 4
const VFRAMES := 5
const TOTAL_FRAMES := 20

var sim: BattleSim
var _tick_timer: Timer
var _restart_timer: Timer
var _units: Array[BattleUnit] = []
var _sprites: Array[Sprite2D] = []
var _sheet_a: Texture2D = null
var _sheet_b: Texture2D = null
var _anim_frame: int = 0
var _result_text: String = ""


func _ready() -> void:
	_sheet_a = _load_tex(SHEET_A_PATH)
	_sheet_b = _load_tex(SHEET_B_PATH)

	_tick_timer = Timer.new()
	_tick_timer.wait_time = TICK_SECONDS
	_tick_timer.timeout.connect(_on_tick)
	add_child(_tick_timer)

	_restart_timer = Timer.new()
	_restart_timer.wait_time = 2.0
	_restart_timer.one_shot = true
	_restart_timer.timeout.connect(_start)
	add_child(_restart_timer)

	_start()


func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	push_warning("[Battle] 缺少精灵表: %s" % path)
	return null


func _start() -> void:
	for s: Sprite2D in _sprites:
		if is_instance_valid(s):
			s.queue_free()
	_sprites.clear()
	_units.clear()
	_anim_frame = 0
	_result_text = ""
	sim = BattleSim.new(12345)
	_add_unit("CH_001", 0, 1, 1, {"hp": 120, "atk": 20, "def": 5, "atk_speed": 8, "range": 1, "mana": 100}, _sheet_a, 0)
	_add_unit("CH_002", 0, 0, 2, {"hp": 80, "atk": 14, "def": 2, "atk_speed": 10, "range": 3, "mana": 100}, _sheet_b, 4)
	_add_unit("MON_001", 1, 6, 1, {"hp": 110, "atk": 18, "def": 4, "atk_speed": 9, "range": 1, "mana": 0}, _sheet_a, 0)
	_add_unit("MON_002", 1, 7, 2, {"hp": 70, "atk": 12, "def": 1, "atk_speed": 10, "range": 2, "mana": 0}, _sheet_b, 4)
	_update_visuals()
	_tick_timer.start()
	print("[Battle] start 1600x900 cell=%d units=%d (2 characters)" % [int(CELL), _units.size()])


func _add_unit(id: String, side: int, x: int, y: int, demo: Dictionary, tex: Texture2D, offset_y: float = 0.0) -> void:
	var row: Dictionary = DataLoader.get_character(id) if side == 0 else DataLoader.get_monster(id)
	var stats: Dictionary = demo
	if not row.is_empty() and str(row.get("hp", "")) != "":
		stats = row
	var u := BattleUnit.from_row(stats, side, x, y)
	u.id = id
	sim.add_unit(u)
	_units.append(u)

	var spr := Sprite2D.new()
	spr.texture = tex
	spr.hframes = HFRAMES
	spr.vframes = VFRAMES
	spr.frame = 0
	spr.centered = true
	spr.offset = Vector2(0, offset_y)
	spr.z_index = 1
	if side == 1:
		spr.flip_h = true
		spr.modulate = Color(1.0, 0.55, 0.55)
	add_child(spr)
	_sprites.append(spr)


func _on_tick() -> void:
	if sim.is_over() or sim.tick >= BattleSim.MAX_TICKS:
		_tick_timer.stop()
		var p := 0
		var e := 0
		for u: BattleUnit in _units:
			if u.is_alive():
				if u.side == 0:
					p += 1
				else:
					e += 1
		if e == 0 and p > 0:
			_result_text = "PLAYER WIN"
		elif p == 0 and e > 0:
			_result_text = "ENEMY WIN"
		else:
			_result_text = "DRAW / TIMEOUT"
		_update_visuals()
		print("[Battle] end tick=%d %s" % [sim.tick, _result_text])
		_restart_timer.start()
		return
	sim.step()
	_anim_frame = (_anim_frame + 2) % TOTAL_FRAMES
	_update_visuals()


func _update_visuals() -> void:
	for i in _units.size():
		var u: BattleUnit = _units[i]
		var spr: Sprite2D = _sprites[i]
		if not is_instance_valid(spr):
			continue
		spr.visible = u.is_alive()
		spr.frame = _anim_frame
		spr.position = ORIGIN + Vector2(u.x * CELL + CELL * 0.5, u.y * CELL + CELL * 0.5)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1600, 900)), Color(0.07, 0.06, 0.09))
	# 地砖底（占位：交替砖色 + 勾缝 + 左上高光）
	for gx in COLS:
		for gy in ROWS:
			var p := ORIGIN + Vector2(gx * CELL, gy * CELL)
			var base := Color(0.155, 0.145, 0.195) if (gx + gy) % 2 == 0 else Color(0.135, 0.125, 0.170)
			draw_rect(Rect2(p, Vector2(CELL, CELL)), base)
			draw_rect(Rect2(p, Vector2(CELL, CELL)), Color(0.08, 0.07, 0.11), false, 2.0)
			draw_line(p + Vector2(3, 3), p + Vector2(CELL - 3, 3), Color(0.24, 0.23, 0.30, 0.5), 1.0)
			draw_line(p + Vector2(3, 3), p + Vector2(3, CELL - 3), Color(0.24, 0.23, 0.30, 0.5), 1.0)
	# 单位脚下阴影（椭圆）
	for u: BattleUnit in _units:
		if not u.is_alive():
			continue
		var foot := ORIGIN + Vector2(u.x * CELL + CELL * 0.5, u.y * CELL + CELL * 0.88)
		draw_set_transform(foot, 0.0, Vector2(1.0, 0.40))
		draw_circle(Vector2.ZERO, CELL * 0.30, Color(0.0, 0.0, 0.0, 0.35))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for i in _units.size():
		var u: BattleUnit = _units[i]
		if not u.is_alive():
			continue
		if _sprites[i].texture == null:
			var p := ORIGIN + Vector2(u.x * CELL + 16, u.y * CELL + 16)
			var col := Color(0.3, 0.6, 1.0) if u.side == 0 else Color(1.0, 0.35, 0.35)
			draw_rect(Rect2(p, Vector2(CELL - 32, CELL - 32)), col)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(40, 60), "Preview 1600x900 | cell 96 | sprite 128x128 | A=hero1 B=hero2 | tick %d" % sim.tick, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
	if _result_text != "":
		draw_string(font, ORIGIN + Vector2(0, -24), _result_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color.YELLOW)
