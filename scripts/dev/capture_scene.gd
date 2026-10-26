extends SceneTree
## 无窗口截图工具：godot --path . --script res://scripts/dev/capture_scene.gd -- <scene> <out.png>

var _frames := 0
var _scene_path := "res://scenes/battle/battle.tscn"
var _out_path := "res://docs/images/scene_capture.png"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_scene_path = args[0]
	if args.size() > 1:
		_out_path = args[1]
	var packed := load(_scene_path) as PackedScene
	if packed == null:
		push_error("[capture] 无法加载: %s" % _scene_path)
		quit(1)
		return
	root.add_child(packed.instantiate())


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < 10:
		return false
	var img := root.get_texture().get_image()
	img.save_png(_out_path)
	print("[capture] %s -> %s %s" % [_scene_path, _out_path, img.get_size()])
	quit()
	return true
