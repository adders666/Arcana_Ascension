extends Node

# Dictionary to hold scene paths. 
# In a real project, verify these paths exist.
var scenes = {
	"MainMenu": "res://scenes/MainMenu.tscn",
	"Match": "res://scenes/Match.tscn",
	"Shop": "res://scenes/Shop.tscn"
}

var current_scene = null

func _ready():
	var root = get_tree().root
	# The last child of root is usually the current scene (after Autoloads)
	current_scene = root.get_child(root.get_child_count() - 1)
	print("SceneController initialized. Current scene: ", current_scene.name)

func change_to_scene(scene_name: String):
	if scene_name in scenes:
		call_deferred("_deferred_change_scene", scenes[scene_name])
	else:
		push_error("SceneController: Scene not found in registry: " + scene_name)

func _deferred_change_scene(path: String):
	# It is safe to remove the current scene
	if current_scene:
		current_scene.free()
	
	# Load the new scene
	var s = ResourceLoader.load(path)
	if s:
		current_scene = s.instantiate()
		get_tree().root.add_child(current_scene)
		get_tree().current_scene = current_scene
		print("SceneController: Changed to " + path)
	else:
		push_error("SceneController: Failed to load scene at " + path)
