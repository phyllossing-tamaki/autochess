extends Node2D
## 战斗预览（临时）：1600x900，8x4 棋盘（格 96）。
## 左：两个英雄（128，20 帧攻击循环）。
## 右：三只怪物（原图朝右，flip_h 翻转朝左；256 龙按 0.5 显示，128 傀儡 1.0）。
## 仅用于美术/比例/站位测试，数据不接角色表。

const CELL := 96.0
const COLS := 8
const ROWS := 4
const ORIGIN := Vector2(416.0, 258.0)
const TICK_SECONDS := 0.1

const HERO_A := "res://assets/sprites/units/hero_sheet.png"
const HERO_B := "res://assets/sprites/units/hero_sheet2.png"
const MON_DRAGON := "res://assets/sprites/units/monster_stone_dragon.png"
const MON_HYDRA := "res://assets/sprites/units/monster_hydra.png"
const MON_GOLEM := "res://assets/sprites/units/monster_golem.png"
const HERO_H := 4
const HERO_V := 5
const TOTAL_FRAMES := 20

var sim: BattleSim
var _tick_timer: Timer
var _restart_timer: Timer
var _units: Array[BattleUnit] = []
var _sprites: Array[Sprite2D] = []
var _hero_tex: Array[Texture2D] = []
var _mon_tex: Array[Texture2D] = []
var _anim_frame: int = 0
var _result_text: String = ""


func _ready() -> void:
	_hero_tex = [_load(HERO_A), _load(HERO_B)]
	_mon_tex = [_load(MON_DRAGON), _load(MON_HYDRA), _load(MON_GOLEM)]
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


func _load(p: String) -> Texture2D:
	if ResourceLoader.exists(p):
		return load(p)
	push_warning("[Battle] 缺少: %s" % p)
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
	# 左：英雄
	_add_hero("CH_001", 1, 1, {"hp": 120, "atk": 20, "def": 5, "atk_speed": 8, "range": 1, "mana": 100}, _hero_tex[0], 0.0)
	_add_hero("CH_002", 0, 2, {"hp": 80, "atk": 14, "def": 2, "atk_speed": 10, "range": 3, "mana": 100}, _hero_tex[1], 4.0)
	# 右：怪物（翻转朝左）
	_add_monster("MON_001", 6, 0, {"hp": 180, "atk": 22, "def": 8, "atk_speed": 9, "range": 1, "mana": 0}, _mon_tex[0], 1.0, 211.0)
	_add_monster("MON_002", 7, 2, {"hp": 150, "atk": 18, "def": 5, "atk_speed": 10, "range": 2, "mana": 0}, _mon_tex[1], 1.0, 183.0)
	_add_monster("MON_003", 5, 1, {"hp": 120, "atk": 16, "def": 10, "atk_speed": 8, "range": 1, "mana": 0}, _mon_tex[2], 1.0, 101.0)
	_update_visuals()
	_tick_timer.start()
	print("[Battle] preview units=%d (2 heroes + 3 monsters)" % _units.size())


func _make_unit(id: String, side: int, x: int, y: int, demo: Dictionary) -> BattleUnit:
	var row: Dictionary = DataLoader.get_character(id) if side == 0 else DataLoader.get_monster(id)
	var stats: Dictionary = demo
	if not row.is_empty() and str(row.get("hp", "")) != "":
		stats = row
	var u := BattleUnit.from_row(stats, side, x, y)
	u.id = id
	sim.add_unit(u)
	_units.append(u)
	return u


func _add_hero(id: String, x: int, y: int, demo: Dictionary, tex: Texture2D, offset_y: float) -> void:
	_make_unit(id, 0, x, y, demo)
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.hframes = HERO_H
	spr.vframes = HERO_V
	spr.frame = 0
	spr.centered = true
	spr.offset = Vector2(0, offset_y)
	spr.z_index = 1
	add_child(spr)
	_sprites.append(spr)


func _add_monster(id: String, x: int, y: int, demo: Dictionary, tex: Texture2D, scale_f: float, feet_y: float) -> void:
	_make_unit(id, 1, x, y, demo)
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.centered = false
	spr.flip_h = true
	spr.scale = Vector2(scale_f, scale_f)
	spr.set_meta("feet_y", feet_y)
	spr.z_index = 1
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
		_result_text = "PLAYER WIN" if e == 0 and p > 0 else ("ENEMY WIN" if p == 0 and e > 0 else "DRAW / TIMEOUT")
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
		var left := ORIGIN + Vector2(u.x * CELL, u.y * CELL)
		if spr.centered:
			if spr.hframes > 1:
				spr.frame = _anim_frame
			spr.position = left + Vector2(CELL * 0.5, CELL * 0.5)
		else:
			var ts := spr.texture.get_size() if spr.texture else Vector2(CELL, CELL)
			var s := spr.scale.x
			var feet := float(spr.get_meta("feet_y", ts.y))
			# 可见底边对齐到阴影中心（格底上方 0.12 格）
			spr.position = Vector2(left.x + (CELL - ts.x * s) * 0.5, left.y + CELL * 0.88 - feet * s)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1600, 900)), Color(0.07, 0.06, 0.09))
	for gx in COLS:
		for gy in ROWS:
			var p := ORIGIN + Vector2(gx * CELL, gy * CELL)
			var base := Color(0.155, 0.145, 0.195) if (gx + gy) % 2 == 0 else Color(0.135, 0.125, 0.170)
			draw_rect(Rect2(p, Vector2(CELL, CELL)), base)
			draw_rect(Rect2(p, Vector2(CELL, CELL)), Color(0.08, 0.07, 0.11), false, 2.0)
			draw_line(p + Vector2(3, 3), p + Vector2(CELL - 3, 3), Color(0.24, 0.23, 0.30, 0.5), 1.0)
			draw_line(p + Vector2(3, 3), p + Vector2(3, CELL - 3), Color(0.24, 0.23, 0.30, 0.5), 1.0)
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
	draw_string(font, Vector2(40, 60), "Preview 1600x900 | cell96 | L:2 heroes128 | R:3 monsters(flip, dragon x1.0) | tick %d" % sim.tick, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
	if _result_text != "":
		draw_string(font, ORIGIN + Vector2(0, -24), _result_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color.YELLOW)
