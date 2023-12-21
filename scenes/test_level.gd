extends Node3D

@export var input_monitor: InputMonitor

@onready var label_preferred_input = $CanvasLayer/MarginContainer/VBoxContainer/LabelPreferredInput
@onready var label_mouse_used_last = $CanvasLayer/MarginContainer/VBoxContainer/LabelMouseUsedLast
@onready var label_keyboard_used_last = $CanvasLayer/MarginContainer/VBoxContainer/LabelKeyboardUsedLast
@onready var label_gamepad_used_last = $CanvasLayer/MarginContainer/VBoxContainer/LabelGamepadUsedLast
@onready var label_touch_used_last = $CanvasLayer/MarginContainer/VBoxContainer/LabelTouchUsedLast


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_update_preferred_input_label()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	label_mouse_used_last.text = "Mouse Last Used:" + str(input_monitor.last_mouse_used_time_msec)
	label_keyboard_used_last.text = "Keyboard Last Used:" + str(input_monitor.last_keyboard_used_time_msec)
	label_gamepad_used_last.text = "Gamepad Last Used:" + str(input_monitor.last_gamepad_used_time_msec)
	label_touch_used_last.text = "Touch Last Used:" + str(input_monitor.last_touch_used_time_msec)

func _on_button_new_game_pressed() -> void:
	print("new game pressed")

func _on_button_exit_pressed() -> void:
	get_tree().quit()


func _on_button_custom_cursor_pressed():
	print("custom cursor button pressed")


func _on_input_monitor_preferred_input_type_changed():
	_update_preferred_input_label()

func _update_preferred_input_label():
	label_preferred_input.text = "Preferred Input: " + str(input_monitor._last_known_preferred_input_type)
