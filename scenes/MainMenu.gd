extends Control

func _ready():
	print("MainMenu: Ready")
	if not has_node("/root/SceneController"):
		push_error("MainMenu: SceneController autoload not found!")
	else:
		print("MainMenu: SceneController found")

func _on_new_game_pressed():
	print("MainMenu: New Game pressed")
	if SceneController:
		SceneController.change_to_scene("Match")
	else:
		push_error("SceneController is null")

func _on_shop_pressed():
	print("MainMenu: Shop pressed")
	if SceneController:
		SceneController.change_to_scene("Shop")
	else:
		push_error("SceneController is null")

func _on_settings_pressed():
	print("MainMenu: Settings pressed")
	# Placeholder for settings logic
	pass

func _on_exit_pressed():
	print("MainMenu: Exit pressed")
	get_tree().quit()
