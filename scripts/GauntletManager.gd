extends Node

var current_match_index = 0
const MAX_MATCHES = 10

func start_gauntlet():
	current_match_index = 0
	print("Gauntlet Started: Match 1")
	# Load Match Scene via SceneController
	SceneController.change_to_scene("Match")

func complete_match(winner: String):
	if winner == "player":
		print("Gauntlet: Match ", current_match_index + 1, " Won!")
		current_match_index += 1
		
		# Rewards
		# CollectionManager.add_card(...) 
		
		if current_match_index >= MAX_MATCHES:
			print("Gauntlet Completed! Victory!")
			SceneController.change_to_scene("MainMenu") # Or Victory Screen
		else:
			print("Advancing to Match ", current_match_index + 1)
			SceneController.change_to_scene("Match") # Reload for next match
			
	else:
		print("Gauntlet: Match Lost!")
		CollectionManager.damage_highest_tier_card()
		# Retry? Or Game Over? GDD implies "Loss causes collection damage", suggests run continues or fails?
		# Roguelike usually implies Game Over or Retry with penalty.
		# I'll restart the match (Retry) but with damaged collection.
		SceneController.change_to_scene("Match")
