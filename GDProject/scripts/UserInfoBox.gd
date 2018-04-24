extends Panel

export(StyleBoxFlat) var warningStyle

const FADE_IN_TIME = 0.3
const FADE_OUT_TIME = 0.5
const TIMEOUT = 4.5
const PREPHASE = TIMEOUT + FADE_OUT_TIME
var remaining_time = TIMEOUT + FADE_IN_TIME + FADE_OUT_TIME

var boxHeight

func set_info(text):
	$Label.text = text

func set_warning():
	add_stylebox_override("panel", warningStyle)

func _ready():
	modulate.a = 0
	boxHeight = ($Label.get_line_height() + 10) * $Label.get_line_count() + 10
	set_custom_minimum_size(Vector2(50, boxHeight))

func _process(delta):
	remaining_time -= delta
	
	if remaining_time > PREPHASE:
		modulate.a = 1 - ((remaining_time - PREPHASE) / FADE_IN_TIME)
	
	if remaining_time <= FADE_OUT_TIME:
		var state = (remaining_time / FADE_OUT_TIME)
		modulate.a = state
		set_custom_minimum_size(Vector2(50, boxHeight * state))
	
	if remaining_time <= 0:
		queue_free()
