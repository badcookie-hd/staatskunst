extends RefCounted
const PATH = "user://settings.cfg"
var fullscreen = false
var vsync = true
var labels = true
var map_grid = true
var minimap = true
var animations = true
var zoom_speed = 1.0
var fps_limit = 60

func read(path: String = PATH):
	var config = ConfigFile.new()
	if config.load(path) != OK: return
	for key in ["fullscreen", "vsync", "labels", "map_grid", "minimap", "animations"]:
		var value = config.get_value("settings", key, get(key))
		if value is bool: set(key, value)
	zoom_speed = clampf(float(config.get_value("settings", "zoom_speed", 1.0)), 0.5, 2.0)
	fps_limit = int(config.get_value("settings", "fps_limit", 60))
	if fps_limit not in [30, 60, 120, 0]: fps_limit = 60

func save(path: String = PATH) -> Error:
	var config = ConfigFile.new()
	for key in ["fullscreen", "vsync", "labels", "map_grid", "minimap", "animations", "zoom_speed", "fps_limit"]: config.set_value("settings", key, get(key))
	return config.save(path)

func apply_display():
	Engine.max_fps = fps_limit
	if DisplayServer.get_name() == "headless": return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
