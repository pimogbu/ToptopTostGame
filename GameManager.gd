extends Node

signal game_lost

const TIME_LIMIT := 180.0

var elapsed_time: float = 0.0
var is_timer_running: bool = false
var level: int = 1
var player_name: String = ""

func _ready() -> void:
	level = 1

func _process(delta: float) -> void:
	if not is_timer_running:
		return
	elapsed_time += delta
	if elapsed_time >= TIME_LIMIT:
		_lose_game()

func start_run() -> void:
	elapsed_time = 0.0
	is_timer_running = true

func reset_timer() -> void:
	start_run()

func _lose_game() -> void:
	is_timer_running = false
	elapsed_time = TIME_LIMIT
	print("Süre doldu, oyun kaybedildi. Kayıt yok.")
	game_lost.emit()

func finish_game() -> void:
	if not is_timer_running:
		return
	if elapsed_time > TIME_LIMIT:
		return
	is_timer_running = false
	save_data_to_json()

func save_data_to_json() -> void:
	var file_path := "user://leaderboard.json"
	var all_data: Array = []

	if FileAccess.file_exists(file_path):
		var read_file := FileAccess.open(file_path, FileAccess.READ)
		if read_file:
			var content := read_file.get_as_text()
			read_file.close()

			var parsed = JSON.parse_string(content)
			if parsed is Array:
				all_data = parsed
			elif parsed is Dictionary:
				all_data.append(parsed)

	var new_entry: Dictionary = {
		"name": player_name,
		#"level": level,
		"time": snappedf(elapsed_time, 0.01),
		"timestamp": Time.get_datetime_string_from_system()
	}
	all_data.append(new_entry)

	var write_file := FileAccess.open(file_path, FileAccess.WRITE)
	if write_file:
		write_file.store_string(JSON.stringify(all_data, "\t"))
		write_file.close()
		print("Kayıt eklendi! Bitiş süresi: ", snappedf(elapsed_time, 0.01), " sn")
	else:
		printerr("Dosya yazma hatası: ", FileAccess.get_open_error())
