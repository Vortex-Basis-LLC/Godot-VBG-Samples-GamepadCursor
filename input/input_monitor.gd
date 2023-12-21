extends Node
class_name InputMonitor

enum PreferredInputType {
	UNKNOWN = 0,
	KEYBOARD = 1,
	MOUSE = 2,
	KEYBOARD_MOUSE = 3,
	GAMEPAD = 4,
	TOUCH = 5
}

signal preferred_input_type_changed;

var last_keyboard_used_time_msec: int = 0
var last_mouse_used_time_msec: int = 0
var last_gamepad_used_time_msec: int = 0
var last_touch_used_time_msec: int = 0

var _has_used_keyboard: bool = false
var _has_used_mouse: bool = false
var _has_used_gamepad: bool = false
var _has_used_touch: bool = false

var _last_known_preferred_input_type := PreferredInputType.UNKNOWN


func _input(event):
	if event is InputEventMouseMotion || event is InputEventMouseButton:
		report_mouse_used()
	elif event is InputEventJoypadMotion || event is InputEventJoypadButton:
		report_gamepad_used()
	elif event is InputEventScreenTouch:
		report_touch_used()
	elif event is InputEventKey:
		report_keyboard_used()


func is_mouse_preferred() -> bool:
	return (_last_known_preferred_input_type == PreferredInputType.KEYBOARD_MOUSE)


func report_mouse_used():
	_has_used_mouse = true
	last_mouse_used_time_msec = Time.get_ticks_msec()
	_update_preferred_input_type()
	
func report_gamepad_used():
	_has_used_gamepad = true
	last_gamepad_used_time_msec = Time.get_ticks_msec()
	_update_preferred_input_type()

func report_keyboard_used():
	_has_used_keyboard = true
	last_keyboard_used_time_msec = Time.get_ticks_msec()
	_update_preferred_input_type()

func report_touch_used():
	_has_used_touch = true
	last_touch_used_time_msec = Time.get_ticks_msec()
	_update_preferred_input_type()


func get_preferred_input_type() -> PreferredInputType:
	return _last_known_preferred_input_type


func _determine_preferred_input_type() -> PreferredInputType:
	if (last_gamepad_used_time_msec > last_mouse_used_time_msec \
		&& last_gamepad_used_time_msec > last_keyboard_used_time_msec \
		&& last_gamepad_used_time_msec > last_touch_used_time_msec):
		return PreferredInputType.GAMEPAD

	if (last_touch_used_time_msec > last_keyboard_used_time_msec \
		&& last_touch_used_time_msec > last_touch_used_time_msec):
		return PreferredInputType.TOUCH
	
	if (!_has_used_mouse):
		return PreferredInputType.KEYBOARD
	else:
		return PreferredInputType.KEYBOARD_MOUSE


func _update_preferred_input_type() -> void:
	var new_preferred_input_type := _determine_preferred_input_type()
	if new_preferred_input_type != _last_known_preferred_input_type:
		_last_known_preferred_input_type = new_preferred_input_type
		preferred_input_type_changed.emit()
