extends Node2D

@export var max_speed := 500.0

@export var max_scroll_speed := 500.0

# Button to use for the standard left mouse button.
@export var joy_left_mouse_button: JoyButton = JOY_BUTTON_A

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
	# TODO: We probably shouldn't set this here.
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	last_mouse_pos = get_global_mouse_position()
	
	# Default to using the first joypad.
	var joypad_device_ids := Input.get_connected_joypads()
	if joypad_device_ids && joypad_device_ids.size() > 0:
		joystick_device_id = joypad_device_ids[0]


func _process(delta: float) -> void:
	#var focus_owner = get_viewport().gui_get_focus_owner()	
	#var mouse_over = get_viewport().gui_get_mouse_over()
	# print(mouse_over)
	# get_viewport().find_control()
	
	#var found_control = get_viewport().gui_find_control(get_global_mouse_position())
	#var found_control2 = get_viewport().gui_find_control(last_mouse_pos + Vector2(25,0))
	#prints(mouse_over, found_control, found_control2)
	
	var mouse_over := find_control_under_mouse()
	
	var input_dir := Vector2(Input.get_joy_axis(joystick_device_id, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y));
	# Dead zone checks
	if abs(input_dir.x) < 0.2:
		input_dir.x = 0;
	if abs(input_dir.y) < 0.2:
		input_dir.y= 0;
		
	#var input_dir = Input.get_vector("mouse_left", "mouse_right", "mouse_up", "mouse_down")	
	var current_velocity = max_speed * input_dir;
	var mouse_move = current_velocity * delta
		
	var is_left_button_pressed = false
	if joy_left_mouse_button != JOY_BUTTON_INVALID:
		is_left_button_pressed = Input.is_joy_button_pressed(joystick_device_id, joy_left_mouse_button)
	
	# NOTE: Buttons should have Focus Mode set to None to work with this.
	# TODO: Check if hovering over over a scroll box and send scroll messages for right-stick movement.
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
		Input.parse_input_event(event)
	elif !is_left_button_pressed && was_left_button_pressed:
		var event = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = get_viewport().get_mouse_position()
		event.pressed = false
		Input.parse_input_event(event)

	was_left_button_pressed = is_left_button_pressed
	
	if (mouse_move != Vector2.ZERO):
		mouse_move += movement_remainder
		var int_mouse_move = Vector2(int(mouse_move.x), int(mouse_move.y))
		movement_remainder = mouse_move - int_mouse_move
		var new_mouse_pos = last_mouse_pos + int_mouse_move
		Input.warp_mouse(new_mouse_pos)
		last_mouse_pos = new_mouse_pos
		# TODO: Is there an appropriate event to feed through system?
		#   Mouse cursor is not updated appropriately when moving mouse with gamepad.
		#   If you gamepad click on button and move away from button, it does not detect that you 
		#   are no longer over the button.
	else:
		movement_remainder = Vector2.ZERO
		
		
	# Check for scrolling.
	var scroll_container = find_containing_scroll_container(mouse_over)
	if scroll_container:
		var scroll_dir := Vector2(Input.get_joy_axis(joystick_device_id, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y));
		# Dead zone checks
		if abs(scroll_dir.x) < 0.2:
			scroll_dir.x = 0;
		if abs(scroll_dir.y) < 0.2:
			scroll_dir.y= 0;
		if scroll_dir != Vector2.ZERO:
			scroll_remainder += Vector2(scroll_dir.x * max_scroll_speed * delta, scroll_dir.y * max_scroll_speed * delta)
			var scroll_x := roundf(scroll_remainder.x)
			var scroll_y := roundf(scroll_remainder.y)
			scroll_container.scroll_horizontal = scroll_container.scroll_horizontal + scroll_x
			scroll_container.scroll_vertical = scroll_container.scroll_vertical + scroll_y
			scroll_remainder -= Vector2(scroll_x, scroll_y)
		else:
			scroll_remainder = Vector2.ZERO
	
func _input(event):
	# TODO: Monitor InputEventJoypadMotion, InputEventJoypadButton
	#prints("_input", event)
	if event is InputEventMouseMotion:
		last_mouse_pos = event.position
	
func find_control_under_mouse() -> Control:
	# TODO: Use new methods added in branch.
	var control := find_control_at_pos(get_tree().root, last_mouse_pos)
	return control

func find_control_at_pos(node: Node, pos: Vector2) -> Control:
	if !node:
		return null
		
	for child_node in node.get_children():
		var child_control := find_control_at_pos(child_node, last_mouse_pos)
		if child_control:
			return child_control
	
	if node is Control:
		if (node as Control).get_global_rect().has_point(pos):
			return node
	
	return null
	
func find_containing_scroll_container(node: Node) -> ScrollContainer:
	if node is ScrollContainer:
		return node
		
	if node:
		return find_containing_scroll_container(node.get_parent())
		
	return null
