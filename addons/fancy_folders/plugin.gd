@tool
extends EditorPlugin

const SETTINGS_KEY: String = "folder_autocolor/config/targets"
const COLOR_DICT_PATH: String = "file_customization/folder_colors"

# Default fallback targets (as user-editable strings)
var default_targets_lines: Array[String] = [
	"scripts=purple",
	"scenes=blue",
	"assets=red",
	"components=orange",
	"materials=yellow",
	"resources=green",
	"shaders=pink",
	"test=teal",
	"addons=gray",
]

func _enter_tree() -> void:
	if not ProjectSettings.has_setting(SETTINGS_KEY):
		ProjectSettings.set_setting(SETTINGS_KEY, default_targets_lines)

	# Make it show as an Array in Project Settings (editable list of strings)
	var info: Dictionary[String, Variant] = {
		"name": SETTINGS_KEY,
		"type": TYPE_ARRAY,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "Each entry: folder=color (e.g. scripts=purple or scenes=#3a7bd5)"
	}
	ProjectSettings.add_property_info(info)
	ProjectSettings.set_initial_value(SETTINGS_KEY, default_targets_lines)

	var fs: EditorFileSystem = get_editor_interface().get_resource_filesystem()
	fs.filesystem_changed.connect(_update_folder_colors)
	_update_folder_colors()

func _update_folder_colors() -> void:
	var lines: Array = ProjectSettings.get_setting(SETTINGS_KEY, default_targets_lines)
	var targets: Dictionary = _parse_targets(lines)

	var current_colors = ProjectSettings.get_setting(COLOR_DICT_PATH, {})
	var folders: Array[String] = _get_all_folders("res://")
	var changed: bool = false

	for path in folders:
		var folder_name: String = path.get_base_dir().get_file().to_lower()
		if targets.has(folder_name):
			var color_value = targets[folder_name] # string like "purple" or "#rrggbb"
			if current_colors.get(path) != color_value:
				current_colors[path] = color_value
				changed = true

	if changed:
		ProjectSettings.set_setting(COLOR_DICT_PATH, current_colors)
		ProjectSettings.save()

func _parse_targets(lines: Array) -> Dictionary:
	var out: Dictionary = {}
	for raw in lines:
		if typeof(raw) != TYPE_STRING:
			continue
		var s := String(raw).strip_edges()
		if s.is_empty() or s.begins_with("#"):
			continue

		var eq := s.find("=")
		if eq == -1:
			continue

		var key := s.substr(0, eq).strip_edges().to_lower()
		var val := s.substr(eq + 1).strip_edges()
		if key.is_empty() or val.is_empty():
			continue

		out[key] = val
	return out
	

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