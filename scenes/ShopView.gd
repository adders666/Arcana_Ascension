extends Control

func _on_back_pressed():
	if SceneController:
		SceneController.change_to_scene("MainMenu")

func _on_buy_husk_pressed():
	print("Buying Soul Husk...")

func _on_buy_stitch_pressed():
	print("Buying Spirit Stitch...")
