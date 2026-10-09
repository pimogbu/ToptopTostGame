# RichTextLabel scripti
extends RichTextLabel

@export var font_size: int = 200
@export var wave_amp: float = 45.0
@export var wave_freq: float = 6.0

var _last_second: int = -1


func _ready() -> void:
	bbcode_enabled = true
	fit_content = true
	scroll_active = false
	autowrap_mode = TextServer.AUTOWRAP_OFF
	clip_contents = false

	add_theme_font_size_override("normal_font_size", font_size)
	add_theme_font_size_override("bold_font_size", font_size)

	pivot_offset = size / 2.0
	resized.connect(func() -> void: pivot_offset = size / 2.0)


func _process(_delta: float) -> void:
	# Süreyi doğrudan Autoload'dan alır
	var current_time: float = GameManager.elapsed_time

	var minutes: int = int(current_time / 60.0)
	var seconds: int = int(fmod(current_time, 60.0))

	if seconds != _last_second:
		_last_second = seconds
		_trigger_tick_punch()

	text = _build_timer_bbcode(minutes, seconds)


func _build_timer_bbcode(mins: int, secs: int) -> String:
	var outline_w: int = maxi(int(font_size * 0.18), 4)
	return (
		"[center]"
		+ "[wave amp=%.1f freq=%.1f connected=1]" % [wave_amp, wave_freq]
		+ "[outline_size=%d][outline_color=#04111f]" % outline_w
		+ " [color=#00f0ff][b]%02d[/b][/color]" % mins
		+ "[pulse color=#ffffff freq=2.0 ease=-2.0][color=#e0f7fa]:[/color][/pulse]"
		+ "[color=#00f0ff][b]%02d[/b][/color] " % secs
		+ "[/outline_color][/outline_size]"
		+ "[/wave]"
		+ "[/center]"
	)


func _trigger_tick_punch() -> void:
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.08)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12)
