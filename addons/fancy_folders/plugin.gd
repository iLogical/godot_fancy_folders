@tool
extends EditorPlugin

const SETTINGS_KEY: String = "folder_autocolor/config/targets"
const COLOR_DICT_PATH: String = "file_customization/folder_colors"

# Default fallback targets
var default_targets: Dictionary[String, String] = {
	"scripts": "purple",
	"scenes": "blue",
	"assets": "red",
	"components": "orange",
	"materials": "yellow",
	"resources": "green",
	"shaders": "pink",
	"test": "teal",
	"addons": "gray"
}

func _enter_tree() -> void:
	# 1. Register the setting if it doesn't exist
	if not ProjectSettings.has_setting(SETTINGS_KEY):
		ProjectSettings.set_setting(SETTINGS_KEY, default_targets)
	
	# 2. Add property info so it shows up nicely in the UI
	var info: Dictionary[String, Variant] = {
		"name": SETTINGS_KEY,
		"type": TYPE_DICTIONARY,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "Folder Name (Key) to Color Name (Value)"
	}
	ProjectSettings.add_property_info(info)
	ProjectSettings.set_initial_value(SETTINGS_KEY, default_targets)
	
	# 3. Connect filesystem signals
	var fs: EditorFileSystem = get_editor_interface().get_resource_filesystem()
	fs.filesystem_changed.connect(_update_folder_colors)
	_update_folder_colors()

func _exit_tree() -> void:
	var fs: EditorFileSystem = get_editor_interface().get_resource_filesystem()
	if fs.filesystem_changed.is_connected(_update_folder_colors):
		fs.filesystem_changed.disconnect(_update_folder_colors)

func _update_folder_colors() -> void:
	# Always pull the latest targets from Project Settings
	var targets = ProjectSettings.get_setting(SETTINGS_KEY, default_targets)
	var current_colors = ProjectSettings.get_setting(COLOR_DICT_PATH, {})
	
	var folders: Array[String] = _get_all_folders("res://")
	var changed: bool = false
	
	for path in folders:
		var folder_name: String = path.get_base_dir().get_file().to_lower()
		if targets.has(folder_name):
			var color = targets[folder_name]
			if current_colors.get(path) != color:
				current_colors[path] = color
				changed = true
	
	if changed:
		ProjectSettings.set_setting(COLOR_DICT_PATH, current_colors)
		ProjectSettings.save()

func _get_all_folders(path: String) -> Array[String]:
	var results: Array[String] = []
	var dir: DirAccess = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and not file_name.begins_with("."):
				var full_path: String = path + file_name + "/"
				results.append(full_path)
				results.append_array(_get_all_folders(full_path))
			file_name = dir.get_next()
	return results