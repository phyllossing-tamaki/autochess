extends Node
## 轻量本地化（autoload 单例）。
## 数据行里名称/描述字段按语言拆分（name_zh/en/ja、desc_*、effect_*），
## 这里按当前 locale 取对应字段，缺省回退中文。

var locale: String = "zh"   ## "zh" / "en" / "ja"


func set_locale(l: String) -> void:
	locale = l


func name_of(row: Dictionary) -> String:
	return _field(row, "name")


func desc_of(row: Dictionary) -> String:
	return _field(row, "desc")


func effect_of(row: Dictionary) -> String:
	return _field(row, "effect")


func _field(row: Dictionary, base: String) -> String:
	var key: String = base + "_" + locale
	if row.has(key):
		return str(row[key])
	var fallback: String = base + "_zh"
	if row.has(fallback):
		return str(row[fallback])
	return ""
