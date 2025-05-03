extends Node2D
signal combat_finished(winner)

const API_URL = "https://api.openai.com/v1/chat/completions"
const API_KEY = "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"

var questions = [
	{
		"question": "Mi Magyarország fővárosa?",
		"answers": ["Bécs", "Budapest", "Debrecen"],
		"correct": 1
	},
	{
		"question": "Mennyi 7 * 8?",
		"answers": ["54", "56", "64"],
		"correct": 1
	},
	{
		"question": "Melyik évben volt az 1848 ben?\\",
		"answers": ["1848", "1956", "1789"],
		"correct": 0
	}
]

var current_question = {}
var opponent_health = 3
var player_health = 3

func _ready():
	randomize()
	load_new_question()
	for i in range(3):
		$UI/Buttons/GridContainer.get_node("Answer%d" % i).pressed.connect(_on_answer_pressed.bind(i))
	$UI/Buttons/GridContainer/HelpButton.pressed.connect(_on_help_pressed)
	$UI/HTTPRequest.request_completed.connect(_on_request_completed)
	update_opponent_health()
	update_player_health()

func load_new_question():
	current_question = questions[randi() % questions.size()]
	$UI/QuestionLabel.text = current_question["question"]

	for i in range(3):
		var answer_button = $UI/Buttons/GridContainer.get_node("Answer%d" % i)
		answer_button.text = current_question["answers"][i]
		answer_button.disabled = false

func _on_answer_pressed(index):
	if index == current_question["correct"]:
		$UI/QuestionLabel.text += "\\n✅ Helyes válasz! Sebzés!"
		opponent_health -= 1
		update_opponent_health()
		if opponent_health <= 0:
			$UI/QuestionLabel.text += "\\n🎉 Győztél az ellenfél felett!"
			disable_all_buttons()
			await get_tree().create_timer(1.5).timeout
			emit_signal("combat_finished", "player")
			
		return
	else:
		$UI/QuestionLabel.text += "\\n❌ Rossz válasz! Sebzést kaptál!"
		player_health -= 1
		update_player_health()
		if player_health <= 0:
			$UI/QuestionLabel.text += "\\n💀 Veszítettél!"
			disable_all_buttons()
			await get_tree().create_timer(1.5).timeout
			emit_signal("combat_finished", "opponent")
			
			return
			disable_all_buttons()

func disable_all_buttons():
	for i in range(3):
		$UI/Buttons/GridContainer.get_node("Answer%d" % i).disabled = true

func update_opponent_health():
	$UI/OpponentHealthLabel.text = "Ellenfél életereje: %d" % opponent_health

func _on_help_pressed():
	if $UI/HTTPRequest.get_http_client_status() == HTTPClient.STATUS_REQUESTING:
		$UI/QuestionLabel.text += "\n⏳ Várj, amíg a segítség megérkezik..."
		return
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + API_KEY
	]

	var body = {
		"model": "gpt-4",
		"messages": [
			{"role": "system", "content": "Segíts a játékosnak eldönteni, melyik a helyes válasz egy oktatási játékban."},
			{"role": "user", "content": "Kérdés: " + current_question["question"] + "\\nVálaszok: " + str(current_question["answers"])}
		],
		"max_tokens": 100
	}

	var json = JSON.stringify(body)
	var err = $UI/HTTPRequest.request(API_URL, headers, HTTPClient.METHOD_POST, json)
	if err != OK:
		$UI/QuestionLabel.text += "\\n⚠️ Hiba történt a segítség kérésnél!"

func _on_request_completed(_result, _code, _headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	if json and "choices" in json:
		var reply = json["choices"][0]["message"]["content"]
		$UI/QuestionLabel.text += "\\n💬 Tipp: " + reply
		
func update_player_health():
	$UI/PlayerHealthLabel.text = "Te életerőd: %d" % player_health
	
func initialize(actors):
	print("Combat initialize() meghívva a következő szereplőkkel:")
	print(actors)
	reset_combat()
	
func reset_combat():
	opponent_health = 3
	player_health = 3
	update_opponent_health()
	update_player_health()
	$UI/QuestionLabel.text = ""
	for i in range(3):
		var answer_button = $UI/Buttons/GridContainer.get_node("Answer%d" % i)
		answer_button.disabled = false
		answer_button.text = ""
		load_new_question()
