extends SceneTree
## 数据校验器 / linter（headless）：
##   godot --headless --path . -s res://scripts/dev/validate_data.gd
##
## 检查项：id 存在且唯一、id 前缀、必填字段、枚举合法性、跨表引用、数值范围。
## 无问题退出码 0，有问题退出码 1。

const SCHEMA := {
	"effects": {
		"prefix": "EFF_",
		"required": ["id", "name_zh", "kind", "target", "trigger", "stat", "op", "value"],
		"enums": {"kind": "effect_kind", "target": "effect_target", "trigger": "effect_trigger", "stat": "stat", "op": "op"},
	},
	"equipment": {
		"prefix": "EQP_",
		"required": ["id", "name_zh", "rarity", "cost"],
		"refs": {"effect_id": "effects"},
		"enums": {"rarity": "rarity"},
		"ranges": {"cost": [0, 9999]},
	},
	"items": {
		"prefix": "ITM_",
		"required": ["id", "name_zh", "effect_id"],
		"refs": {"effect_id": "effects"},
		"ranges": {"cost": [0, 999]},
	},
	"relics": {
		"prefix": "REL_",
		"required": ["id", "name_zh", "effect_id"],
		"refs": {"effect_id": "effects"},
		"enums": {"rarity": "rarity"},
	},
	"synergies": {
		"prefix": "SYN_",
		"required": ["id", "name_zh", "category"],
		"enums": {"category": "category"},
		"ranges": {"tier1_count": [0, 99], "tier2_count": [0, 99], "tier3_count": [0, 99]},
	},
	"skills": {
		"prefix": "SKL_",
		"required": ["id", "name_zh", "type", "effect_id"],
		"refs": {"effect_id": "effects"},
		"enums": {"type": "skill_type"},
		"ranges": {"max_mana": [0, 9999], "cast_time": [0, 999]},
	},
	"blessings": {
		"prefix": "CB_",
		"required": ["id", "name_zh", "effect_id"],
		"refs": {"effect_id": "effects"},
		"enums": {"rarity": "rarity"},
	},
	"occupations": {
		"prefix": "OCC_",
		"required": ["id", "difficulty"],
		"refs": {"effect_id": "effects"},
		"ranges": {"difficulty": [1, 10]},
	},
}


func _initialize() -> void:
	var loader: Node = load("res://scripts/autoload/data_loader.gd").new()
	loader.reload()

	var errors: Array = []
	var total: int = 0
	for table_name: String in loader.TABLES:
		var rows: Array = loader.table(table_name)
		total += rows.size()
		var spec: Dictionary = SCHEMA.get(table_name, {})
		var seen: Dictionary = {}
		for row: Dictionary in rows:
			_check_row(table_name, row, spec, loader, seen, errors)
		print("  %-12s %d 行" % [table_name, rows.size()])

	if errors.is_empty():
		print("数据校验通过：表=%d, 行=%d, 问题=0" % [loader.TABLES.size(), total])
	else:
		print("---- 问题 %d 处 ----" % errors.size())
		for e: String in errors:
			print("  ", e)
		print("数据校验失败：表=%d, 行=%d, 问题=%d" % [loader.TABLES.size(), total, errors.size()])

	loader.free()
	quit(1 if not errors.is_empty() else 0)


func _check_row(table_name: String, row: Dictionary, spec: Dictionary, loader: Node, seen: Dictionary, errors: Array) -> void:
	var id: String = str(row.get("id", ""))
	if id == "":
		errors.append("[%s] 缺少 id" % table_name)
		return
	if seen.has(id):
		errors.append("[%s] id 重复: %s" % [table_name, id])
	seen[id] = true

	var prefix: String = str(spec.get("prefix", ""))
	if prefix != "" and not id.begins_with(prefix):
		errors.append("[%s] id 前缀应为 %s: %s" % [table_name, prefix, id])

	for field: String in spec.get("required", []):
		if _is_blank(row.get(field, null)):
			errors.append("[%s] %s 缺必填字段 %s" % [table_name, id, field])

	var enums: Dictionary = spec.get("enums", {})
	for field: String in enums:
		if row.has(field) and not _is_blank(row[field]):
			if _enum_value(enums[field], row[field]) < 0:
				errors.append("[%s] %s 字段 %s 取值非法: %s" % [table_name, id, field, str(row[field])])

	var refs: Dictionary = spec.get("refs", {})
	for field: String in refs:
		var ref_id: String = str(row.get(field, ""))
		if ref_id != "" and not loader.has(refs[field], ref_id):
			errors.append("[%s] %s 引用的 %s=%s 在 %s 中不存在" % [table_name, id, field, ref_id, refs[field]])

	var ranges: Dictionary = spec.get("ranges", {})
	for field: String in ranges:
		if row.has(field) and not _is_blank(row[field]):
			var v: Variant = row[field]
			if typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT:
				errors.append("[%s] %s 字段 %s 应为数值: %s" % [table_name, id, field, str(v)])
			else:
				var lo: float = ranges[field][0]
				var hi: float = ranges[field][1]
				if v < lo or v > hi:
					errors.append("[%s] %s 字段 %s=%s 超出范围 [%s,%s]" % [table_name, id, field, str(v), str(lo), str(hi)])


func _is_blank(v: Variant) -> bool:
	return v == null or str(v).strip_edges() == ""


func _enum_value(parser_name: String, value: Variant) -> int:
	match parser_name:
		"rarity": return DataEnums.rarity(value)
		"category": return DataEnums.category(value)
		"skill_type": return DataEnums.skill_type(value)
		"effect_kind": return DataEnums.effect_kind(value)
		"effect_target": return DataEnums.effect_target(value)
		"effect_trigger": return DataEnums.effect_trigger(value)
		"stat": return DataEnums.stat(value)
		"op": return DataEnums.op(value)
	return -2
