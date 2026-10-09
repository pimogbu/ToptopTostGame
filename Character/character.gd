extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var jump_velocity: float = -950.0
@export var var_jump_time: float = 0.16

var _var_jump_timer: float = 0.0
@export var joystick_deadzone := 0.25

@export var speed := 500.0
@export var ground_accel := 3000.0
@export var air_accel := 1800.0

@export var dash_speed := 1200.0
@export var dash_time := 0.2
@export var coyote_time := 0.1
@export var jump_buffer_time := 0.1

@export var ghost_interval := 0.035
var _ghost_timer := 0.0

@export var input_delay := 0.1

var facing := 1
var is_dashing := false
var can_dash := true
var dash_dir := Vector2.ZERO

var _dash_timer := 0.0
var _coyote := 0.0
var _jump_buffer := 0.0

var _input_queue: Array[Dictionary] = []
var _inp: Dictionary = _neutral_input()


func _neutral_input() -> Dictionary:
	return {
		"x": 0.0,
		"jump_pressed": false,
		"jump_held": false,
		"dash_pressed": false,
		"up": false,
	}


func _sample_input() -> Dictionary:
	return {
		"x": Input.get_axis("ui_left", "ui_right"),
		"jump_pressed": Input.is_action_just_pressed("jump"),
		"jump_held": Input.is_action_pressed("jump"),
		"dash_pressed": Input.is_action_just_pressed("dash"),
		"up": Input.is_action_pressed("ui_up") or Input.get_axis("ui_down", "ui_up") > joystick_deadzone,
	}


func _update_delayed_input() -> void:
	var delay_frames := int(round(input_delay * Engine.physics_ticks_per_second))
	_input_queue.push_back(_sample_input())
	if _input_queue.size() > delay_frames:
		_inp = _input_queue.pop_front()
	else:
		_inp = _neutral_input()  


func _physics_process(delta: float) -> void:
	_update_delayed_input()

	var raw_x: float = _inp["x"]
	var dir_x := 0.0

	if abs(raw_x) > joystick_deadzone:
		dir_x = sign(raw_x)
		facing = int(dir_x)

	if is_on_floor():
		_coyote = coyote_time
		if not is_dashing and not can_dash:
			can_dash = true
			_set_grayscale(false)
	else:
		_coyote -= delta

	_jump_buffer -= delta
	if _inp["jump_pressed"]:
		_jump_buffer = jump_buffer_time

	if _inp["dash_pressed"] and can_dash and not is_dashing:
		_start_dash()

	if is_dashing:
		_dash_timer -= delta
		velocity = dash_dir * dash_speed

		_ghost_timer -= delta
		if _ghost_timer <= 0.0:
			_spawn_ghost()
			_ghost_timer = ghost_interval

		if _dash_timer <= 0.0:
			is_dashing = false
			velocity = dash_dir * speed
	else:
		if _jump_buffer > 0.0 and _coyote > 0.0:
			velocity.y = jump_velocity
			_var_jump_timer = var_jump_time
			_jump_buffer = 0.0
			_coyote = 0.0

		if _var_jump_timer > 0.0:
			_var_jump_timer -= delta
			if _inp["jump_held"]:
				velocity.y = jump_velocity
			else:
				_var_jump_timer = 0.0

		if not is_on_floor():
			velocity += get_gravity() * delta * 2.0

		var accel: float = ground_accel if is_on_floor() else air_accel
		velocity.x = move_toward(velocity.x, dir_x * speed, accel * delta)

	move_and_slide()


func _start_dash() -> void:
	var raw_x: float = _inp["x"]
	var x: float = signf(raw_x) if abs(raw_x) > joystick_deadzone else 0.0

	var up: bool = _inp["up"]

	dash_dir = Vector2(x, -1.0 if up else 0.0)
	if dash_dir == Vector2.ZERO:
		dash_dir = Vector2(facing, 0)
	dash_dir = dash_dir.normalized()

	is_dashing = true
	can_dash = false
	_dash_timer = dash_time
	_ghost_timer = 0.0

	_set_grayscale(true)


func _set_grayscale(active: bool) -> void:
	if sprite.material is ShaderMaterial:
		sprite.material.set_shader_parameter("grayscale_amount", 1.0 if active else 0.0)


func _spawn_ghost() -> void:
	var ghost := AnimatedSprite2D.new()
	ghost.sprite_frames = sprite.sprite_frames
	ghost.animation = sprite.animation
	ghost.frame = sprite.frame
	ghost.flip_h = sprite.flip_h
	ghost.scale = sprite.global_scale
	ghost.global_position = sprite.global_position

	ghost.top_level = true
	ghost.z_index = 1

	if sprite.material:
		ghost.material = sprite.material.duplicate()
		(ghost.material as ShaderMaterial).set_shader_parameter("grayscale_amount", 1.0)

	ghost.modulate = Color(1.0, 1.0, 1.0, 0.5)

	add_child(ghost)

	var tween := create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.2)
	tween.tween_callback(ghost.queue_free)
