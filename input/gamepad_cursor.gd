extends Node2D

# This is the internal device id used by Godot, so mouse events don't show
# as actual mouse usage.
const INTERNAL_DEVICE_ID := -2

@export var max_speed := 500.0

@export var max_friction_speed := 200.0

@export var max_scroll_speed := 500.0

# Button to use for the standard left mouse button.
@export var joy_left_mouse_button: JoyButton = JOY_BUTTON_A

@export var joy_deadzone = 0.2

# Remember where mouse was after the last frame.
var last_mouse_pos: Vector2

# Leftover non-integer movement from prior frame.
var movement_remainder: Vector2 = Vector2.ZERO
# Leftover non-integer scrolling from prior frame.
var scroll_remainder: Vector2 = Vector2.ZERO

var was_left_button_pressed := false

# Device id to use for joystick (-1 for none)
var joystick_device_id := -1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Listen for joy_connection_changed and automatically use first device_id
	# if no explicit joystick_device_id has been provided.
	Input.connect("joy_connection_changed", self._on_joy_connection_changed)
	
	# NOTE: Set mouse to visible before using this: Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	#   It is assumed programs will control mouse visibility from a more central location.
	last_mouse_pos = get_global_mouse_position()
	
	# Default to using the first joypad.
	var joypad_device_ids := Input.get_connected_joypads()
	if joypad_device_ids && joypad_device_ids.size() > 0:
		joystick_device_id = joypad_device_ids[0]


func _on_joy_connection_changed(device_id, connected):
	if connected:
		if joystick_device_id == -1:
			joystick_device_id = device_id
	else:
		if joystick_device_id == device_id:
			joystick_device_id = -1
		

func _process(delta: float) -> void:
	var mouse_over := find_control_under_mouse()
	
	handle_left_button()
	handle_scrolling(delta, mouse_over)
	
	var input_dir := Vector2(Input.get_joy_axis(joystick_device_id, JOY_AXIS_LEFT_X), Input.get_joy_axis(joystick_device_id, JOY_AXIS_LEFT_Y));
	input_dir = apply_joy_deadzone(input_dir)

	var speed_to_use: float = max_speed
	if should_apply_friction(mouse_over):
		speed_to_use = max_friction_speed

	var current_velocity = speed_to_use * input_dir;
	var mouse_move = current_velocity * delta

	if (mouse_move != Vector2.ZERO):
		mouse_move += movement_remainder
		var int_mouse_move = Vector2(int(mouse_move.x), int(mouse_move.y))
		movement_remainder = mouse_move - int_mouse_move
		var new_mouse_pos = last_mouse_pos + int_mouse_move
		
		var event = InputEventMouseMotion.new()
		event.position = new_mouse_pos
		event.relative = int_mouse_move
		event.device = INTERNAL_DEVICE_ID
		
		Input.parse_input_event(event)
		
		Input.warp_mouse(new_mouse_pos)
		last_mouse_pos = new_mouse_pos
	else:
		movement_remainder = Vector2.ZERO


func _input(event):
	if event is InputEventMouseMotion:
		var mouse_event := event as InputEventMouseMotion
		last_mouse_pos = mouse_event.position


var _missing_get_hovered_method_shown = false

func find_control_under_mouse() -> Control:
	var viewport := get_viewport()
	if !viewport.has_method("gui_get_hovered_control"):
		if !_missing_get_hovered_method_shown:
			print("ERROR: You must update to Godot 4.3 to get viewport's gui_get_hovered_control method.")
			_missing_get_hovered_method_shown = true
		return null
	
	return viewport.gui_get_hovered_control()
	
	
func find_containing_scroll_container(node: Node) -> ScrollContainer:
	if node is ScrollContainer:
		return node
		
	if node:
		return find_containing_scroll_container(node.get_parent())
		
	return null


func handle_scrolling(delta: float, mouse_over: Control) -> void:
	var scroll_container = find_containing_scroll_container(mouse_over)
	if scroll_container:
		var scroll_dir := Vector2(Input.get_joy_axis(joystick_device_id, JOY_AXIS_RIGHT_X), Input.get_joy_axis(joystick_device_id, JOY_AXIS_RIGHT_Y));
		scroll_dir = apply_joy_deadzone(scroll_dir)
		
		if scroll_dir != Vector2.ZERO:
			scroll_remainder += Vector2(scroll_dir.x * max_scroll_speed * delta, scroll_dir.y * max_scroll_speed * delta)
			var scroll_x := roundf(scroll_remainder.x)
			var scroll_y := roundf(scroll_remainder.y)
			scroll_container.scroll_horizontal = scroll_container.scroll_horizontal + scroll_x
			scroll_container.scroll_vertical = scroll_container.scroll_vertical + scroll_y
			scroll_remainder -= Vector2(scroll_x, scroll_y)
		else:
			scroll_remainder = Vector2.ZERO


func handle_left_button() -> void:
	var is_left_button_pressed = false
	if joy_left_mouse_button != JOY_BUTTON_INVALID:
		is_left_button_pressed = Input.is_joy_button_pressed(joystick_device_id, joy_left_mouse_button)
	
	# NOTE: Buttons should have Focus Mode set to None to work properly.
	if is_left_button_pressed && !was_left_button_pressed:
		# NOTE: We seem to need to clear focus before trying to simulate the mouse button press,
		#   but more investigation may be needed to see specific reason this was needed.
		var focus_owner = get_viewport().gui_get_focus_owner()
		if focus_owner:
			focus_owner.release_focus()
			
		var event = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = get_viewport().get_mouse_position()
		event.pressed = true
		event.device = INTERNAL_DEVICE_ID
		Input.parse_input_event(event)
	elif !is_left_button_pressed && was_left_button_pressed:
		var event = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = get_viewport().get_mouse_position()
		event.pressed = false
		event.device = INTERNAL_DEVICE_ID
		Input.parse_input_event(event)

	was_left_button_pressed = is_left_button_pressed
	
	
func apply_joy_deadzone(vec: Vector2) -> Vector2:
	if abs(vec.x) < joy_deadzone:
		vec.x = 0.0
	else:
		vec.x = (vec.x - joy_deadzone) / (1.0 - joy_deadzone)
		
	if abs(vec.y) < joy_deadzone:
		vec.y = 0.0
	else:
		vec.y = (vec.y - joy_deadzone) / (1.0 - joy_deadzone)
		
	return vec
	
	
func should_apply_friction(control: Control) -> bool:
		if control is Button:
			return true
			
		return false
