@tool
extends EditorPlugin

const SETTINGS_KEY: String = "folder_autocolor/config/rules"
const COLOR_DICT_PATH: String = "file_customization/folder_colors"


func _enter_tree() -> void:
	if not ProjectSettings.has_setting(SETTINGS_KEY):
	
		# Get default folder colours
		var defaults: Array[FolderColorEntry] = _get_defaults()
		
		# Initialize with an empty array of our custom resource type
		ProjectSettings.set_setting(SETTINGS_KEY, defaults)
	
	# Tell the editor this is an Array of FolderColorEntry resources
	var info: Dictionary[String, Variant] = {
		"name": SETTINGS_KEY,
		"type": TYPE_ARRAY,
		"hint": PROPERTY_HINT_TYPE_STRING,
		"hint_string": "24/17:FolderColorEntry" # Magic string for Array[Resource]
	}
	ProjectSettings.add_property_info(info)
	
	get_editor_interface().get_resource_filesystem().filesystem_changed.connect(_update_folder_colors)

func _update_folder_colors() -> void:
	var rules = ProjectSettings.get_setting(SETTINGS_KEY, [])
	var current_colors = ProjectSettings.get_setting(COLOR_DICT_PATH, {})
	var changed: bool = false
	
	var folders: Array[String] = _get_all_folders("res://")
	
	for path in folders:
		var folder_name: String = path.get_base_dir().get_file().to_lower()
		
		for rule in rules:
			if rule is FolderColorEntry and rule.folder_name.to_lower() == folder_name:
				var target_color: String = rule.get_color_string()
				if current_colors.get(path) != target_color:
					current_colors[path] = target_color
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
	
	
func _get_defaults() -> Array[FolderColorEntry]:
		var defaults:Array[FolderColorEntry] = []
		
		defaults.append(_add_default.call("addons", FolderColorEntry.FolderColor.GRAY))
		defaults.append(_add_default.call("scenes", FolderColorEntry.FolderColor.BLUE))
		defaults.append(_add_default.call("assets", FolderColorEntry.FolderColor.RED))
		defaults.append(_add_default.call("components", FolderColorEntry.FolderColor.ORANGE))
		defaults.append(_add_default.call("materials", FolderColorEntry.FolderColor.YELLOW))
		defaults.append(_add_default.call("scripts", FolderColorEntry.FolderColor.PURPLE))
		defaults.append(_add_default.call("resources", FolderColorEntry.FolderColor.GREEN))
		defaults.append(_add_default.call("shaders", FolderColorEntry.FolderColor.PINK))
		defaults.append(_add_default.call("test", FolderColorEntry.FolderColor.TEAL))
		
		return defaults
	
	
func _add_default(folder: String, color_idx: int) -> FolderColorEntry:
		var entry: FolderColorEntry = FolderColorEntry.new()
		entry.folder_name = folder
		entry.color = color_idx # Refers to the Enum index in FolderColorEntry
		return entry