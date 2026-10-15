class_name Economy
extends RefCounted
## 经济与定价常量（镜像《肉鸽自走棋-策划案》rev1283 / 飞书「AutoChess · 数值表」）。
## 数值源以飞书为准；此处供代码快速读取，改动请同步飞书与策划案。
## 注意：下列稀有度价格为「角色（棋子）」价格，与【装备价格无关】。

## 角色（棋子）购买价格：普通/优秀/卓越/英雄/传说/神话（对应 DataEnums.Rarity）
const UNIT_RARITY_COST: Array[int] = [100, 200, 500, 900, 1500, 3000]

## 队伍等级上限（彩蛋 / 随机事件可升至 6）
const LEVEL_MAX: int = 5
const LEVEL_MAX_EASTER: int = 6
## 升级费用（1→2 ... 5→6）
const LEVEL_UP_COST: Array[int] = [100, 200, 300, 400, 500]

## 经济：每回合基础金币
const GOLD_PER_ROUND: int = 3
## 连败补偿（暂定）
const LOSS_COMPENSATION: Array[int] = [10, 15, 15, 20]

## 升星倍率（1★ / 2★ / 3★，作用于 hp / atk）
const STAR_HP_MULT: Array[float] = [1.0, 1.8, 2.8]
const STAR_ATK_MULT: Array[float] = [1.0, 1.8, 2.8]

## 升星规则：三合一（集齐 3 个相同角色合成升 1 星）
const STAR_UP_RULE: String = "merge3"


## 按角色稀有度枚举取购买价格；越界返回 -1。
static func unit_rarity_cost(rarity: int) -> int:
	if rarity < 0 or rarity >= UNIT_RARITY_COST.size():
		return -1
	return UNIT_RARITY_COST[rarity]


## 按星级(1~3)取倍率。
static func star_hp_mult(star: int) -> float:
	return STAR_HP_MULT[clampi(star - 1, 0, STAR_HP_MULT.size() - 1)]

static func star_atk_mult(star: int) -> float:
	return STAR_ATK_MULT[clampi(star - 1, 0, STAR_ATK_MULT.size() - 1)]
