extends SceneTree
## 战斗骨架单测（headless）：
##   godot --headless --path . -s res://scripts/dev/test_battle.gd
## 全部通过退出码 0，否则 1。未接入 GUT，用最简断言。

var _fail: int = 0
var _pass: int = 0


func _initialize() -> void:
	_test_armor_reduces_damage()
	_test_amp_scales_damage()
	_test_attack_target_range()
	_test_move_target_nearest()
	_test_strong_side_wins()
	_test_determinism()

	if _fail == 0:
		print("战斗单测通过：%d/%d" % [_pass, _pass + _fail])
	else:
		print("战斗单测失败：%d 通过, %d 失败" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)


func _assert(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		print("  FAIL: ", msg)


func _make(id: String, side: int, x: int, y: int, hp: int, atk: int, defense: int, atk_range: int, atk_speed: int, move_ticks: int) -> BattleUnit:
	var u := BattleUnit.new(id, side)
	u.x = x
	u.y = y
	u.max_hp = hp
	u.hp = hp
	u.atk = atk
	u.defense = defense
	u.attack_range = atk_range
	u.atk_speed = atk_speed
	u.move_ticks = move_ticks
	u.max_mana = 0   # 关闭技能，便于聚焦普攻/移动
	return u


func _test_armor_reduces_damage() -> void:
	var no_armor := BattleSim.raw_damage(100.0, 0.0, 1.0, 1.0)
	var armor := BattleSim.raw_damage(100.0, 20.0, 1.0, 1.0)
	_assert(no_armor > armor and armor > 0.0, "护甲应降低伤害且为正")


func _test_amp_scales_damage() -> void:
	var base := BattleSim.raw_damage(100.0, 0.0, 1.0, 1.0)
	var doubled := BattleSim.raw_damage(100.0, 0.0, 2.0, 1.0)
	_assert(is_equal_approx(doubled, base * 2.0), "增伤乘区应线性放大")


func _test_attack_target_range() -> void:
	var u := _make("p", 0, 0, 0, 50, 10, 0, 1, 10, 3)
	var far := _make("e1", 1, 0, 3, 50, 10, 0, 1, 10, 3)
	var near := _make("e2", 1, 0, 1, 50, 10, 0, 1, 10, 3)
	var arr: Array = [u, far, near]
	_assert(BattleSim.select_attack_target(u, arr) == near, "射程内应选最近敌人")
	var out: Array = [u, far]
	_assert(BattleSim.select_attack_target(u, out) == null, "射程外无攻击目标")


func _test_move_target_nearest() -> void:
	var u := _make("p", 0, 0, 0, 50, 10, 0, 1, 10, 3)
	var near := _make("e1", 1, 1, 0, 50, 10, 0, 1, 10, 3)
	var far := _make("e2", 1, 5, 0, 50, 10, 0, 1, 10, 3)
	var arr: Array = [u, far, near]
	_assert(BattleSim.select_move_target(u, arr) == near, "移动目标应为最近敌人")


func _test_strong_side_wins() -> void:
	var sim := BattleSim.new(1)
	sim.add_unit(_make("p", 0, 0, 0, 300, 60, 5, 1, 5, 3))
	sim.add_unit(_make("e", 1, 1, 0, 30, 5, 0, 1, 10, 3))
	var winner := sim.run()
	_assert(winner == 0, "强侧应获胜")
	_assert(sim.tick <= BattleSim.MAX_TICKS, "应在 tick 上限内结束")


func _test_determinism() -> void:
	var a := BattleSim.new(777)
	a.add_unit(_make("p", 0, 0, 0, 120, 20, 3, 1, 8, 3))
	a.add_unit(_make("e", 1, 1, 0, 120, 20, 3, 1, 8, 3))
	a.run()

	var b := BattleSim.new(777)
	b.add_unit(_make("p", 0, 0, 0, 120, 20, 3, 1, 8, 3))
	b.add_unit(_make("e", 1, 1, 0, 120, 20, 3, 1, 8, 3))
	b.run()

	var same := a.tick == b.tick and a.units[0].hp == b.units[0].hp and a.units[1].hp == b.units[1].hp
	_assert(same, "同 seed 应得到完全相同的结果（确定性）")
