extends Control

const API_URL = "https://api.openai.com/v1/chat/completions"
const API_KEY = "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"

var player_ref = null

func set_player(player):
	player_ref = player
func _ready():
	await get_tree().process_frame
	
	$Panel/CloseButton.pressed.connect(_on_close_pressed)
	$HTTPRequest.request_completed.connect(_on_request_completed)
	var send_button = $Panel/VBoxContainer.get_node_or_null("SendButton")
	print("SEND BUTTON =", send_button)
	if send_button:
		send_button.pressed.connect(_on_send_pressed)
	else:
			print("⚠️ Nem található a SendButton!")
	
func _on_close_pressed():
	print("❌ Bezárás gomb megnyomva")
	if player_ref:
		print("✔ Player visszakapja a mozgást")
		player_ref.can_move = true
	else:
		print("❌ Player referencia nem elérhető")

	# 💥 Végigmegyünk a hierarchy-n, amíg el nem érjük a ChatGptDialogue-t
	var node = self
	while node != null and node.name != "ChatGptDialogue":
		node = node.get_parent()

	if node:
		print("🧨 Töröljük a dialógus ablakot:", node.name)
		node.queue_free()
	else:
		print("⚠️ Nem találtam a ChatGptDialogue root-ot")
func _on_send_pressed():
	if $HTTPRequest.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	var question = $Panel/VBoxContainer/InputField.text.strip_edges()
	if question == "":
		return
	$Panel/OutputLabel.text = "🧠 Kérés feldolgozása..."
	$Panel/VBoxContainer/SendButton.disabled = true
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + API_KEY
		]
	var body = {
		"model": "gpt-3.5-turbo",
		"messages": [
			{"role": "system", "content": "Te egy hasznos NPC vagy egy játékban. Rövid, barátságos válaszokat adj!"},
			{"role": "user", "content": question}
		],
		"max_tokens": 100
	}
	var json = JSON.stringify(body)
	var err = $HTTPRequest.request(API_URL, headers, HTTPClient.METHOD_POST, json)
	if err != OK:
		$Panel/OutputLabel.text = "⚠️ Hiba a kérés küldésekor."

func _on_request_completed(result, response_code, headers, body):
	var body_text = body.get_string_from_utf8()
	print("📦 Teljes válasz:", body_text)

	var json = JSON.new()
	var error = json.parse(body_text)

	if error != OK:
		print("❌ JSON parsing hiba:", error)
		return

	var data = json.data
	print("🧪 Visszakapott dict:", data)

	if not data.has("choices"):
		print("❌ Nincs 'choices' mező! Valószínűleg hibaüzenet jött.")
		$Panel/OutputLabel.text = "⚠️ Hiba: " + str(data)
		return

	var content = data["choices"][0]["message"]["content"]
	$Panel/OutputLabel.text = content

		
