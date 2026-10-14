extends SceneTree
## 数据校验脚本（headless）：
##   godot --headless --path . -s res://scripts/dev/validate_data.gd
## 校验各 JSON 表可被 DataLoader 正常加载，并打印行数。无报错即退出码 0。


func _initialize() -> void:
	var loader: Node = load("res://scripts/autoload/data_loader.gd").new()
	loader.reload()
	var fail: int = 0
	var total: int = 0
	for table_name: String in loader.TABLES:
		var rows: Array = loader.table(table_name)
		total += rows.size()
		for row: Dictionary in rows:
			if str(row.get("id", "")) == "":
				push_error("[validate] %s 存在缺少 id 的行" % table_name)
				fail += 1
		print("  %-12s %d" % [table_name, rows.size()])
	print("DataLoader validate: total=%d, fail=%d" % [total, fail])
	loader.free()
	quit(1 if fail > 0 else 0)
