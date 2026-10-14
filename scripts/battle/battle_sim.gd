class_name BattleSim
extends RefCounted
## 确定性战斗模拟骨架（固定 Tick 循环 + 整数运算）。
## 对应策划案第十章「固定 Tick 循环 + 确定性模拟」。
##
## 设计纪律：
##  - 1 tick = 0.1s，全程整数；不用物理/浮点时间。
##  - 全局唯一随机源 rng，调用顺序固定 → 同 seed 结果可复现。
##  - 每 tick 每个存活单位只做一次动作（攻击 / 走一格 / 进入施法前摇）。
##
## 用法：
##   var sim := BattleSim.new(12345)
##   sim.add_unit(unit)
##   var winner := sim.run()   # 0 玩家胜 / 1 敌方胜 / -1 超时或同归于尽

const MAX_TICKS := 300        ## 30s
const ARMOR_K := 10.0         ## 护甲减伤系数：def/(def+K)
const CRIT_CHANCE := 0.1
const CRIT_MULT := 1.5
const MANA_ON_ATTACK := 10
const MANA_ON_HURT := 5

var units: Array[BattleUnit] = []
var tick: int = 0
var rng: RandomNumberGenerator


func _init(p_seed: int = 0) -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = p_seed


func add_unit(u: BattleUnit) -> void:
	units.append(u)


func side_alive(side: int) -> int:
	var n := 0
	for u: BattleUnit in units:
		if u.side == side and u.is_alive():
			n += 1
	return n


func is_over() -> bool:
	return side_alive(0) == 0 or side_alive(1) == 0


## 推进一整场，返回胜方（0/1），超时或同归于尽返回 -1。
func run() -> int:
	while not is_over() and tick < MAX_TICKS:
		step()
	if side_alive(1) == 0 and side_alive(0) > 0:
		return 0
	if side_alive(0) == 0 and side_alive(1) > 0:
		return 1
	return -1


## 推进一个 tick。
func step() -> void:
	tick += 1
	for u: BattleUnit in units:
		if u.is_alive():
			_update_unit(u)


func _update_unit(u: BattleUnit) -> void:
	if u.state == BattleUnit.State.CAST:
		u.cast_cd -= 1
		if u.cast_cd <= 0:
			_resolve_cast(u)
		return

	if u.atk_cd > 0:
		u.atk_cd -= 1
	if u.move_cd > 0:
		u.move_cd -= 1

	if u.max_mana > 0 and u.skill_id != "" and u.mana >= u.max_mana:
		u.state = BattleUnit.State.CAST
		u.cast_cd = u.cast_time
		return

	var target: BattleUnit = select_attack_target(u, units)
	if target != null:
		if u.atk_cd <= 0:
			_attack(u, target)
			u.atk_cd = u.atk_speed
		u.state = BattleUnit.State.ATTACK
	else:
		var mover: BattleUnit = select_move_target(u, units)
		if mover != null and u.move_cd <= 0:
			u.step_toward(mover)
			u.move_cd = u.move_ticks
			u.state = BattleUnit.State.MOVE


func _attack(attacker: BattleUnit, target: BattleUnit) -> void:
	attacker.mana = mini(attacker.max_mana, attacker.mana + MANA_ON_ATTACK)
	target.mana = mini(target.max_mana, target.mana + MANA_ON_HURT)
	var dmg: int = _compute_damage(attacker, target)
	target.hp = maxi(0, target.hp - dmg)
	if target.hp == 0:
		target.state = BattleUnit.State.DEAD


func _resolve_cast(u: BattleUnit) -> void:
	# 骨架实现：对射程内最近敌人造成 2×攻击的伤害，然后清蓝回待机。
	u.state = BattleUnit.State.IDLE
	u.mana = 0
	var target: BattleUnit = select_move_target(u, units)
	if target != null:
		var dmg: int = maxi(1, u.atk * 2)
		target.hp = maxi(0, target.hp - dmg)
		if target.hp == 0:
			target.state = BattleUnit.State.DEAD


func _compute_damage(attacker: BattleUnit, target: BattleUnit) -> int:
	var crit := CRIT_MULT if rng.randf() < CRIT_CHANCE else 1.0
	var raw := raw_damage(float(attacker.atk), float(target.defense), attacker.amp_mult, crit)
	return maxi(1, int(round(raw)))


## 纯函数伤害公式（不含随机，便于单测）：攻击区 × 增伤区 × 暴击区 × 抗性区。
static func raw_damage(atk: float, defense: float, amp: float, crit_mult: float) -> float:
	var resist := 1.0 - defense / (defense + ARMOR_K)
	return maxf(0.0, atk * amp * crit_mult * resist)


## 攻击目标 = 射程内最近的敌人（同距按最低血量、再按 id 固定顺序）。
static func select_attack_target(u: BattleUnit, all: Array) -> BattleUnit:
	var best: BattleUnit = null
	var best_d := 1 << 30
	var best_hp := 1 << 30
	for e: BattleUnit in all:
		if e.side == u.side or not e.is_alive():
			continue
		var d := u.distance_to(e)
		if d > u.attack_range:
			continue
		if d < best_d or (d == best_d and e.hp < best_hp):
			best = e
			best_d = d
			best_hp = e.hp
	return best


## 移动目标 = 全场最近的敌人。
static func select_move_target(u: BattleUnit, all: Array) -> BattleUnit:
	var best: BattleUnit = null
	var best_d := 1 << 30
	var best_hp := 1 << 30
	for e: BattleUnit in all:
		if e.side == u.side or not e.is_alive():
			continue
		var d := u.distance_to(e)
		if d < best_d or (d == best_d and e.hp < best_hp):
			best = e
			best_d = d
			best_hp = e.hp
	return best
