extends Node
## 全局游戏状态骨架（autoload 单例）：难度、局外元进度、场景切换。

const PREPARE_SCENE := "res://scenes/prepare/prepare.tscn"
const BATTLE_SCENE := "res://scenes/battle/battle.tscn"
const META_SCENE := "res://scenes/meta/meta.tscn"

var difficulty: int = 1       ## 1~10
var run_seed: int = 0         ## 本局随机种子
var meta: Dictionary = {}     ## 局外元进度（解锁等），骨架占位


func goto(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)

func goto_prepare() -> void:
	goto(PREPARE_SCENE)

func goto_battle() -> void:
	goto(BATTLE_SCENE)

func goto_meta() -> void:
	goto(META_SCENE)
