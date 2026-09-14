extends CanvasLayer

signal closed

var questions := [
	{"q": "以下哪一個顏色是暖色系？", "options": ["藍色", "紅色", "綠色"], "correct": 1},
	{"q": "一週有幾天？", "options": ["5天", "6天", "7天"], "correct": 2},
	{"q": "貓咪最常做的事情是？", "options": ["睡覺", "游泳", "開車"], "correct": 0},
]

var current_index := 0

@onready var question_label: Label = $Panel/VBox/QuestionLabel
@onready var options_box: VBoxContainer = $Panel/VBox/OptionsBox
@onready var feedback_label: Label = $Panel/VBox/FeedbackLabel
@onready var close_button: Button = $Panel/VBox/CloseButton

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)

func show_minigame() -> void:
	current_index = 0
	visible = true
	_show_question()

func _show_question() -> void:
	feedback_label.text = ""
	for child in options_box.get_children():
		child.queue_free()

	if current_index >= questions.size():
		question_label.text = "這輪答完了！"
		return

	var q: Dictionary = questions[current_index]
	question_label.text = q["q"]
	for i in q["options"].size():
		var btn := Button.new()
		btn.text = q["options"][i]
		btn.pressed.connect(_on_answer_pressed.bind(i))
		options_box.add_child(btn)

func _on_answer_pressed(index: int) -> void:
	var q: Dictionary = questions[current_index]
	if index == q["correct"]:
		feedback_label.text = "答對了！+10 金幣"
		Currency.add_coins(10)
	else:
		feedback_label.text = "答錯了，換下一題"
	current_index += 1
	await get_tree().create_timer(1.0).timeout
	_show_question()

func _on_close_pressed() -> void:
	visible = false
	closed.emit()
