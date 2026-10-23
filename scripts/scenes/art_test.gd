extends Node2D
## 美术预览（测试用，不入数据）：左侧英雄、右侧怪物（原生尺寸、朝左）。
## 仅用于判断不同素材同屏的比例 / 像素密度 / 朝向；不参与战斗逻辑。

const GROUND_Y := 680.0
const HERO_A := "res://assets/sprites/units/hero_sheet.png"
const HERO_B := "res://assets/sprites/units/hero_sheet2.png"
const MON_A := "res://assets/sprites/units/monster_stone_dragon.png"
const MON_B := "res://assets/sprites/units/monster_hydra.png"
const MON_C := "res://assets/sprites/units/monster_golem.png"
const HFRAMES := 4
const VFRAMES := 5
const TOTAL_FRAMES := 20

var _hero_sprites: Array[Sprite2D] = []
var _marks: Array[Dictionary] = []   # {x, label}
var _frame: int = 0
var _acc: float = 0.0


func _ready() -> void:
	_add_hero(HERO_A, 300.0, 104.0, "hero_sheet 128")
	_add_hero(HERO_B, 500.0, 100.0, "hero_sheet2 128")
	_add_monster(MON_A, 960.0, "stone dragon 256")
	_add_monster(MON_B, 1230.0, "hydra 256")
	_add_monster(MON_C, 1450.0, "golem 128")
	queue_redraw()


func _add_hero(path: String, foot_x: float, max_y: float, label: String) -> void:
	var tex: Texture2D = load(path)
	if tex == null:
		push_warning("[ArtTest] 缺少: %s" % path)
		return
	var frame_w: float = tex.get_width() / HFRAMES
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.hframes = HFRAMES
	spr.vframes = VFRAMES
	spr.frame = 0
	spr.centered = false
	spr.position = Vector2(foot_x - frame_w * 0.5, GROUND_Y - max_y)
	add_child(spr)
	_hero_sprites.append(spr)
	_marks.append({"x": foot_x, "label": label})


func _add_monster(path: String, foot_x: float, label: String) -> void:
	var tex: Texture2D = load(path)
	if tex == null:
		push_warning("[ArtTest] 缺少: %s" % path)
		return
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.centered = false
	spr.flip_h = true   # 怪物原图朝右，翻转后朝左
	spr.position = Vector2(foot_x - tex.get_width() * 0.5, GROUND_Y - tex.get_height())
	add_child(spr)
	_marks.append({"x": foot_x, "label": label})


func _process(delta: float) -> void:
	_acc += delta
	if _acc >= 0.05:
		_acc = 0.0
		_frame = (_frame + 1) % TOTAL_FRAMES
		for s: Sprite2D in _hero_sprites:
			s.frame = _frame


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1600, 900)), Color(0.07, 0.06, 0.09))
	draw_line(Vector2(40, GROUND_Y), Vector2(1560, GROUND_Y), Color(0.35, 0.33, 0.42), 2.0)
	var font := ThemeDB.fallback_font
	for m in _marks:
		var x: float = m["x"]
		draw_set_transform(Vector2(x, GROUND_Y), 0.0, Vector2(1.0, 0.35))
		draw_circle(Vector2.ZERO, 60.0, Color(0.0, 0.0, 0.0, 0.30))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_string(font, Vector2(x - 90.0, GROUND_Y + 34.0), str(m["label"]), HORIZONTAL_ALIGNMENT_CENTER, 180.0, 18, Color(0.8, 0.8, 0.85))
	draw_string(font, Vector2(40, 70), "ART TEST — 左: 英雄 128 | 右: 怪物 原生尺寸（朝左） | 1600x900", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color.WHITE)
	draw_string(font, Vector2(40, 108), "hero: 4x5=20 帧攻击循环；monster: 单帧静态", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.7, 0.7, 0.75))
