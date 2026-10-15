class_name DataEnums
extends RefCounted
## 数据枚举与「字符串 → 枚举」映射。
## 表里存的是字符串（部分中文、部分英文 token），代码里用整数枚举，避免字符串魔法。
## 用法：DataEnums.rarity("普通") -> DataEnums.Rarity.COMMON（未知返回 -1）。

enum Rarity { COMMON, GOOD, EXCELLENT, HERO, LEGEND, MYTH }
enum Category { RACE, CLASS }
enum EquipRarity { BASIC, FINE, LEGEND, MYTH }
enum SkillType { DAMAGE, HEAL, SHIELD, AOE, DOT, BUFF, DEBUFF, CONTROL, SUMMON, UTILITY }
enum EffectKind { BUFF, DEBUFF, DAMAGE, HEAL, SHIELD, DOT, CONTROL, SUMMON, UTILITY }
enum EffectTarget { SELF, ALLY_SINGLE, ALLY_ALL, ENEMY_SINGLE, ENEMY_ALL, LOWEST_HP_ALLY, HIGHEST_ATK_ENEMY, ALL }
enum EffectTrigger { PASSIVE, ON_CAST, ON_HIT, ON_HURT, ON_DEATH, ON_KILL, BATTLE_START, TURN_START, AURA }
enum Stat { ATK, AP, DEF, HP, CRIT, AMP, RES, ATK_SPEED, MOVE_SPEED, MANA, GOLD }
enum Op { ADD, MUL_FLAT, MUL_PCT, SET }

const RARITY := {
	"普通": Rarity.COMMON, "common": Rarity.COMMON,
	"优秀": Rarity.GOOD, "good": Rarity.GOOD,
	"卓越": Rarity.EXCELLENT, "excellent": Rarity.EXCELLENT,
	"英雄": Rarity.HERO, "hero": Rarity.HERO,
	"传说": Rarity.LEGEND, "legend": Rarity.LEGEND, "legendary": Rarity.LEGEND,
	"神话": Rarity.MYTH, "myth": Rarity.MYTH, "mythic": Rarity.MYTH,
}

const CATEGORY := {
	"种族": Category.RACE, "race": Category.RACE,
	"职业": Category.CLASS, "class": Category.CLASS, "job": Category.CLASS,
}

const EQUIP_RARITY := {
	"基础": EquipRarity.BASIC, "basic": EquipRarity.BASIC,
	"优质": EquipRarity.FINE, "fine": EquipRarity.FINE,
	"传说": EquipRarity.LEGEND, "legend": EquipRarity.LEGEND,
	"神话": EquipRarity.MYTH, "myth": EquipRarity.MYTH,
}

const SKILL_TYPE := {
	"damage": SkillType.DAMAGE, "heal": SkillType.HEAL, "shield": SkillType.SHIELD,
	"aoe": SkillType.AOE, "dot": SkillType.DOT, "buff": SkillType.BUFF,
	"debuff": SkillType.DEBUFF, "control": SkillType.CONTROL, "summon": SkillType.SUMMON, "utility": SkillType.UTILITY,
}

const EFFECT_KIND := {
	"buff": EffectKind.BUFF, "debuff": EffectKind.DEBUFF, "damage": EffectKind.DAMAGE,
	"heal": EffectKind.HEAL, "shield": EffectKind.SHIELD, "dot": EffectKind.DOT,
	"control": EffectKind.CONTROL, "summon": EffectKind.SUMMON, "utility": EffectKind.UTILITY,
}

const EFFECT_TARGET := {
	"self": EffectTarget.SELF, "ally_single": EffectTarget.ALLY_SINGLE, "ally_all": EffectTarget.ALLY_ALL,
	"enemy_single": EffectTarget.ENEMY_SINGLE, "enemy_all": EffectTarget.ENEMY_ALL,
	"lowest_hp_ally": EffectTarget.LOWEST_HP_ALLY, "highest_atk_enemy": EffectTarget.HIGHEST_ATK_ENEMY, "all": EffectTarget.ALL,
}

const EFFECT_TRIGGER := {
	"passive": EffectTrigger.PASSIVE, "on_cast": EffectTrigger.ON_CAST, "on_hit": EffectTrigger.ON_HIT,
	"on_hurt": EffectTrigger.ON_HURT, "on_death": EffectTrigger.ON_DEATH, "on_kill": EffectTrigger.ON_KILL,
	"battle_start": EffectTrigger.BATTLE_START, "turn_start": EffectTrigger.TURN_START, "aura": EffectTrigger.AURA,
}

const STAT := {
	"atk": Stat.ATK, "ap": Stat.AP, "def": Stat.DEF, "hp": Stat.HP, "crit": Stat.CRIT,
	"amp": Stat.AMP, "res": Stat.RES, "atk_speed": Stat.ATK_SPEED, "move_speed": Stat.MOVE_SPEED,
	"mana": Stat.MANA, "gold": Stat.GOLD,
}

const OP := {
	"add": Op.ADD, "mul_flat": Op.MUL_FLAT, "mul_pct": Op.MUL_PCT, "set": Op.SET,
}


static func _lookup(map: Dictionary, s: Variant) -> int:
	var key := str(s).strip_edges().to_lower()
	if map.has(key):
		return map[key]
	return map.get(str(s).strip_edges(), -1)


static func rarity(s: Variant) -> int:
	return _lookup(RARITY, s)

static func category(s: Variant) -> int:
	return _lookup(CATEGORY, s)

static func equip_rarity(s: Variant) -> int:
	return _lookup(EQUIP_RARITY, s)

static func skill_type(s: Variant) -> int:
	return _lookup(SKILL_TYPE, s)

static func effect_kind(s: Variant) -> int:
	return _lookup(EFFECT_KIND, s)

static func effect_target(s: Variant) -> int:
	return _lookup(EFFECT_TARGET, s)

static func effect_trigger(s: Variant) -> int:
	return _lookup(EFFECT_TRIGGER, s)

static func stat(s: Variant) -> int:
	return _lookup(STAT, s)

static func op(s: Variant) -> int:
	return _lookup(OP, s)
