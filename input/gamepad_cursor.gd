extends Node2D

@export var max_speed := 400.0

# Button to use for the standard left mouse button.
@export var joy_left_mouse_button: JoyButton = JOY_BUTTON_A

# Remember where mouse was after the last frame.
var last_mouse_pos: Vector2

# Leftover non-integer movement from prior frame.
var movement_remainder: Vector2 = Vector2.ZERO

var was_button_pressed := false

# Device id to use for joystick 
# TODO: Look into Input.get_connected_joypads() and Input.connect("joy_connection_changed",...)
#   to auto-detect joystick device id to use (or just watch for which one is being used if possible)
var joystick_device_id := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# TODO: We probably shouldn't set this here.
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	last_mouse_pos = get_global_mouse_position()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#var focus_owner = get_viewport().gui_get_focus_owner()	
	#var mouse_over = get_viewport().gui_get_mouse_over()
	# print(mouse_over)
	# get_viewport().find_control()
	
	#var found_control = get_viewport().gui_find_control(get_global_mouse_position())
	#var found_control2 = get_viewport().gui_find_control(last_mouse_pos + Vector2(25,0))
	#prints(mouse_over, found_control, found_control2)
	
	var input_dir := Vector2(Input.get_joy_axis(joystick_device_id, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y));
	# Dead zone checks
	if abs(input_dir.x) < 0.2:
		input_dir.x = 0;
	if abs(input_dir.y) < 0.2:
		input_dir.y= 0;
		
	#var input_dir = Input.get_vector("mouse_left", "mouse_right", "mouse_up", "mouse_down")	
	var current_velocity = max_speed * input_dir;
	var mouse_move = current_velocity * delta
		
	var is_button_pressed = false
	if joy_left_mouse_button != JOY_BUTTON_INVALID:
		is_button_pressed = Input.is_joy_button_pressed(joystick_device_id, joy_left_mouse_button)
	
	# NOTE: Buttons should have Focus Mode set to None to work with this.
	# TODO: Check if hovering over over a scroll box and send scroll messages for right-stick movement.
	if is_button_pressed && !was_button_pressed:
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
	elif !is_button_pressed && was_button_pressed:
		var event = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = get_viewport().get_mouse_position()
		event.pressed = false
		Input.parse_input_event(event)

	was_button_pressed = is_button_pressed
	
	if (mouse_move != Vector2.ZERO):
		mouse_move += movement_remainder
		var int_mouse_move = Vector2(int(mouse_move.x), int(mouse_move.y))
		movement_remainder = mouse_move - int_mouse_move
		var new_mouse_pos = last_mouse_pos + int_mouse_move
		Input.warp_mouse(new_mouse_pos)
		last_mouse_pos = new_mouse_pos
	else:
		movement_remainder = Vector2.ZERO
	
func _input(event):
	if event is InputEventMouseMotion:
		last_mouse_pos = event.position
