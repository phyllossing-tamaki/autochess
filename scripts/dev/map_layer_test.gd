extends Node2D
## 战斗地图分层测试（占位美术）：背景 / 96 地砖 / 角色 / 阴影 / 网格。
## 按键：G 网格，B 背景，T 地砖，U 单位。

const CELL := 96.0
const COLS := 8
const ROWS := 4
const ORIGIN := Vector2(416.0, 258.0)
const HERO_H := 4
const HERO_V := 5
const TOTAL_FRAMES := 20

const HERO_A := "res://assets/sprites/units/hero_sheet.png"
const HERO_B := "res://assets/sprites/units/hero_sheet2.png"
const MON_DRAGON := "res://assets/sprites/units/monster_stone_dragon.png"
const MON_HYDRA := "res://assets/sprites/units/monster_hydra.png"
const MON_GOLEM := "res://assets/sprites/units/monster_golem.png"

var _show_grid := true
var _hero_sprites: Array[Sprite2D] = []
var _feet: Array[Vector2] = []
var _frame: int = 0
var _acc: float = 0.0
var _label: Label

@onready var _background: Sprite2D = $Background
@onready var _board: TileMapLayer = $Board
@onready var _units: Node2D = $Units


func _ready() -> void:
	_paint_board()
	_spawn_units()
	_make_hud()
	queue_redraw()


func _process(delta: float) -> void:
	_acc += delta
	if _acc >= 0.05:
		_acc = 0.0
		_frame = (_frame + 1) % TOTAL_FRAMES
		for s: Sprite2D in _hero_sprites:
			s.frame = _frame


func _paint_board() -> void:
	_board.clear()
	for gy in ROWS:
		for gx in COLS:
			var variant := 0 if (gx + gy) % 2 == 0 else 1
			if (gx * 3 + gy * 5) % 11 == 0:
				variant = 2
			elif (gx * 5 + gy * 7) % 13 == 0:
				variant = 3
			_board.set_cell(Vector2i(gx, gy), 0, Vector2i(variant, 0))
	print("[MapLayerTest] board %dx%d tiles=%d" % [COLS, ROWS, _board.get_used_cells().size()])


func _spawn_units() -> void:
	_add_hero(HERO_A, 1, 1, 0.0)
	_add_hero(HERO_B, 0, 2, 4.0)
	_add_monster(MON_DRAGON, 6, 0, 211.0)
	_add_monster(MON_HYDRA, 7, 2, 183.0)
	_add_monster(MON_GOLEM, 5, 1, 101.0)
	print("[MapLayerTest] units=%d" % _feet.size())


func _add_hero(path: String, gx: int, gy: int, offset_y: float) -> void:
	var tex := load(path) as Texture2D
	if tex == null:
		push_warning("[MapLayerTest] 缺少: %s" % path)
		return
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.hframes = HERO_H
	spr.vframes = HERO_V
	spr.frame = 0
	spr.centered = true
	spr.offset = Vector2(0, offset_y)
	spr.position = ORIGIN + Vector2((gx + 0.5) * CELL, (gy + 0.5) * CELL)
	_units.add_child(spr)
	_hero_sprites.append(spr)
	_feet.append(ORIGIN + Vector2(gx * CELL + CELL * 0.5, gy * CELL + CELL * 0.88))


func _add_monster(path: String, gx: int, gy: int, feet_y: float) -> void:
	var tex := load(path) as Texture2D
	if tex == null:
		push_warning("[MapLayerTest] 缺少: %s" % path)
		return
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.centered = false
	spr.flip_h = true
	var left := ORIGIN + Vector2(gx * CELL, gy * CELL)
	spr.position = Vector2(left.x + (CELL - tex.get_width()) * 0.5, left.y + CELL * 0.88 - feet_y)
	_units.add_child(spr)
	_feet.append(left + Vector2(CELL * 0.5, CELL * 0.88))


func _make_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_label = Label.new()
	_label.position = Vector2(24, 18)
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_color", Color(0.92, 0.90, 0.96))
	_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	_label.add_theme_constant_override("shadow_offset_x", 2)
	_label.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(_label)
	_update_hud()


func _update_hud() -> void:
	_label.text = "MAP LAYER TEST · 1600×900 · 8×4 · cell 96 · placeholder art\n" \
		+ "G 网格 %s   B 背景 %s   T 地砖 %s   U 单位 %s" % [
			"ON" if _show_grid else "OFF",
			"ON" if _background.visible else "OFF",
			"ON" if _board.visible else "OFF",
			"ON" if _units.visible else "OFF",
		]


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_G:
				_show_grid = not _show_grid
				queue_redraw()
			KEY_B:
				_background.visible = not _background.visible
			KEY_T:
				_board.visible = not _board.visible
			KEY_U:
				_units.visible = not _units.visible
				queue_redraw()
			_:
				return
		_update_hud()


func _draw() -> void:
	if _units.visible:
		for foot: Vector2 in _feet:
			draw_set_transform(foot, 0.0, Vector2(1.0, 0.40))
			draw_circle(Vector2.ZERO, CELL * 0.30, Color(0.0, 0.0, 0.0, 0.35))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if not _show_grid:
		return
	var col := Color(0.30, 0.84, 1.0, 0.35)
	for i in COLS + 1:
		var x := ORIGIN.x + i * CELL
		draw_line(Vector2(x, ORIGIN.y), Vector2(x, ORIGIN.y + ROWS * CELL), col, 1.0)
	for j in ROWS + 1:
		var y := ORIGIN.y + j * CELL
		draw_line(Vector2(ORIGIN.x, y), Vector2(ORIGIN.x + COLS * CELL, y), col, 1.0)
	draw_rect(Rect2(ORIGIN, Vector2(COLS * CELL, ROWS * CELL)), Color(0.30, 0.84, 1.0, 0.8), false, 2.0)
	var font := ThemeDB.fallback_font
	draw_string(font, ORIGIN + Vector2(4, -10), "ORIGIN (416, 258)  8×4 / 96", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.6, 0.9, 1.0, 0.9))
