extends Node2D
## 准备阶段（角色商店 / 站位）场景骨架。

func _ready() -> void:
	print("[Prepare] 准备阶段骨架就绪（难度 %d）" % Game.difficulty)
