class_name BattleUnit
extends RefCounted
## 战斗单位数据结构（扁平化，全程整数/网格坐标）。
## 对应策划案第十章「2. 棋子数据结构」。

enum State { IDLE, MOVE, ATTACK, CAST, DEAD }

var id: String = ""
var side: int = 0            ## 0 = 玩家（左），1 = 敌方（右）
var job: String = ""         ## 职业
var star: int = 1

var max_hp: int = 1
var hp: int = 1
var atk: int = 0
var defense: int = 0
var amp_mult: float = 1.0    ## 增伤乘区（默认 1.0）

var atk_speed: int = 10      ## 每 N tick 攻击一次
var attack_range: int = 1    ## 射程（格，切比雪夫）
var move_ticks: int = 3      ## 每 N tick 走一格

var max_mana: int = 100
var mana: int = 0
var cast_time: int = 3       ## 施法前摇 tick
var cast_cd: int = 0
var skill_id: String = ""

var x: int = 0
var y: int = 0
var state: int = State.IDLE
var atk_cd: int = 0
var move_cd: int = 0


func _init(p_id: String = "", p_side: int = 0) -> void:
	id = p_id
	side = p_side


## 从数据行（角色表/怪物表导出的一行）构建单位。
static func from_row(row: Dictionary, p_side: int, px: int, py: int) -> BattleUnit:
	var u := BattleUnit.new(str(row.get("id", "unit")), p_side)
	u.max_hp = int(row.get("hp", 1))
	u.hp = u.max_hp
	u.atk = int(row.get("atk", 0))
	u.defense = int(row.get("def", 0))
	u.atk_speed = int(row.get("atk_speed", 10))
	u.attack_range = int(row.get("range", 1))
	u.max_mana = int(row.get("mana", 0))
	u.skill_id = str(row.get("skill_id", ""))
	u.x = px
	u.y = py
	return u


func is_alive() -> bool:
	return hp > 0


func distance_to(other: BattleUnit) -> int:
	return maxi(absi(x - other.x), absi(y - other.y))


## 朝目标移动一格（贪心：先缩 x，再缩 y），整数网格。
func step_toward(target: BattleUnit) -> void:
	if x != target.x:
		x += signi(target.x - x)
	elif y != target.y:
		y += signi(target.y - y)
