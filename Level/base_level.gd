extends Node2D

@onready var control: Control = $CharacterBody2D/Control
@onready var container: VBoxContainer = $CharacterBody2D/Control/VBoxContainer
@onready var continue_btn: Button = $CharacterBody2D/Control/VBoxContainer/Continue

@onready var line_edit: LineEdit = $CharacterBody2D/Control/VBoxContainer/HBoxContainer/LineEdit
var finished := false

func _ready() -> void:
	control.process_mode = Node.PROCESS_MODE_ALWAYS
	container.visible = false
	if not GameManager.game_lost.is_connected(_on_game_lost):
		GameManager.game_lost.connect(_on_game_lost)
	GameManager.start_run()


func _exit_tree() -> void:
	if GameManager.game_lost.is_connected(_on_game_lost):
		GameManager.game_lost.disconnect(_on_game_lost)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if finished:
			# oyun bitti: ESC menüyü açık tutar, devam ettirmez
			_pause_game()
		elif get_tree().paused:
			_resume_game()
		else:
			_pause_game()
		get_viewport().set_input_as_handled()


func _pause_game() -> void:
	get_tree().paused = true
	container.visible = true
	continue_btn.disabled = finished
	if finished:
		line_edit.grab_focus()
	else:
		continue_btn.grab_focus()


func _resume_game() -> void:
	get_tree().paused = false
	container.visible = false


func _on_continue_pressed() -> void:
	_resume_game()


func _on_new_run_pressed() -> void:
	get_tree().paused = false
	GameManager.player_name = line_edit.text.strip_edges()
	get_tree().change_scene_to_file("res://Level/base_level1final.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_game_lost() -> void:
	get_tree().reload_current_scene()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if finished:
		return
	if body is CharacterBody2D:
		finished = true
		GameManager.finish_game()
		_pause_game()   
