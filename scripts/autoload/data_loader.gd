extends Node
## 数据加载器（autoload 单例）。
##
## 从 res://data/ 读取由飞书子表导出的 JSON（数组，元素为一行，字段名 = 表头英文 key），
## 按 id 建立索引，供游戏逻辑只读访问。
##
## 管线：飞书子表 → 导出 JSON → data/<表名>.json → 本加载器。
## 例：get_row("equipment", "EQP_001").stat_atk

const DATA_DIR := "res://data/"

## 逻辑表名 → 文件名（不含 .json）。需与 data/ 下文件一致。
const TABLES := {
	"effects": "effects",
	"equipment": "equipment",
	"items": "items",
	"relics": "relics",
	"synergies": "synergies",
	"skills": "skills",
	"blessings": "blessings",
}

var _tables: Dictionary = {}   ## 表名 -> Array[Dictionary]
var _index: Dictionary = {}    ## 表名 -> { id -> Dictionary }


func _ready() -> void:
	reload()


## 重新加载全部表（支持热重载 / 开发期重读）。
func reload() -> void:
	_tables.clear()
	_index.clear()
	for table_name: String in TABLES:
		var rows: Array = _load_table(TABLES[table_name])
		_tables[table_name] = rows
		var idx: Dictionary = {}
		for row: Dictionary in rows:
			var id: String = str(row.get("id", ""))
			if id != "":
				idx[id] = row
		_index[table_name] = idx


func _load_table(file_base: String) -> Array:
	var path: String = DATA_DIR + file_base + ".json"
	if not FileAccess.file_exists(path):
		push_warning("[DataLoader] 缺少数据文件: %s" % path)
		return []
	var text: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_ARRAY:
		push_error("[DataLoader] %s 不是 JSON 数组" % path)
		return []
	return parsed


## 整张表（返回 Array[Dictionary]，元素为一行）。
func table(table_name: String) -> Array:
	return _tables.get(table_name, [])


## 按 id 取一行；不存在返回空字典。
func get_row(table_name: String, id: String) -> Dictionary:
	var idx: Dictionary = _index.get(table_name, {})
	return idx.get(id, {})


func has(table_name: String, id: String) -> bool:
	var idx: Dictionary = _index.get(table_name, {})
	return idx.has(id)


## 按字段等值筛选，如 get_where("equipment", "rarity", "传说")。
func get_where(table_name: String, key: String, value: Variant) -> Array:
	var out: Array = []
	for row: Dictionary in table(table_name):
		if row.get(key) == value:
			out.append(row)
	return out


## 取某列全部值。
func column(table_name: String, key: String) -> Array:
	var out: Array = []
	for row: Dictionary in table(table_name):
		out.append(row.get(key))
	return out


## 便捷：按 id 取效果定义（效果表）。
func get_effect(effect_id: String) -> Dictionary:
	return get_row("effects", effect_id)
