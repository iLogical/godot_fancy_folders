extends Resource
class_name FolderColorEntry

# This exported enum creates the dropdown automatically
enum FolderColor { RED, ORANGE, YELLOW, GREEN, TEAL, BLUE, PURPLE, PINK, GRAY }

@export var folder_name: String = ""
@export var color: FolderColor = FolderColor.GRAY

# Helper to get the lowercase string Godot needs
func get_color_string() -> String:
	return FolderColor.keys()[color].to_lower()
