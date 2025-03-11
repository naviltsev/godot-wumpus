extends Node

# UI elements
@onready var main_text: RichTextLabel = %MainText
@onready var instructions_text: RichTextLabel = %InstructionsText
@onready var title_text: RichTextLabel = %TitleText
@onready var room_label: Label = %RoomLabel
@onready var bolts_label: Label = %BoltsLabel
@onready var command_buttons: HBoxContainer = %CommandButtons
@onready var action_buttons: HBoxContainer = %ActionButtons
@onready var room_buttons: HBoxContainer = %RoomButtons

# Game state
var maze = Maze.new()
var _selected_room_buttons: Array[Button]

signal move_at(vertice_id: int)
signal shoot_at(vertice_id: int)

func _ready():
	start_game(true, false)
	tell_room_name()
	tell_connected_room_names()
	tell_status_update()

func start_game(reshuffle_rooms: bool, clear_text_window: bool = false):
	show_command_buttons()
	
	Global.arrows_count = 5
	update_stats()
	
	Global.wumpus_asleep = true
	Global.shoot_room_vertices = []

	if clear_text_window:
		main_text.text = ""

	if reshuffle_rooms:
		maze.shuffle_rooms()

	setup_hazards()
	setup_start_room()

func update_stats():
	room_label.text = "ROOM: %d" % Global.current_room_name
	bolts_label.text = "BOLTS: %d" % Global.arrows_count

func show_command_buttons():
	command_buttons.visible = true
	action_buttons.visible = false
	room_buttons.visible = false

func show_action_buttons():
	command_buttons.visible = false
	action_buttons.visible = true
	room_buttons.visible = true

func tell_room_name():
	append_new_line("\n[color=#00FF00]You are on page %d[/color]" % Global.current_room_name) 

func tell_connected_room_names():
	append_new_line("[color=#00FF00]You can visit pages %d, %d and %d[/color]" % Global.connected_rooms)

func tell_status_update():
	var ret = {
		"bat": false,
		"pit": false,
		"wumpus": false,
	}
	for v in Global.connected_vertices:
		if Global.bat_vertices.has(v):
			ret["bat"] = true
		if Global.pit_vertices.has(v):
			ret["pit"] = true
		if v == Global.wumpus_vertice:
			ret["wumpus"] = true

	if ret["bat"]:
		append_new_line("\t[color=#00FF00]I feel engagement[/color]")
	if ret["pit"]:
		append_new_line("\t[color=#00FF00]I hear clicks[/color]")
	if ret["wumpus"]:
		append_new_line("\t[color=#00FF00]It smells like SNARF code[/color]")

func setup_hazards():
	Global.bat_vertices = []
	Global.pit_vertices = []

	var vertices = range(1, 21)
	for i in range(0, 2):
		vertices.shuffle()
		var bat = vertices[randi_range(0, vertices.size()-1)]
		vertices.erase(bat)
		Global.bat_vertices.append(bat)

	for i in range(0, 2):
		vertices.shuffle()
		var pit = vertices[randi_range(0, vertices.size()-1)]
		vertices.erase(pit)
		Global.pit_vertices.append(pit)

	vertices.shuffle()
	var wumpus = vertices[randi_range(0, vertices.size()-1)]
	vertices.erase(wumpus)
	Global.wumpus_vertice = wumpus

func pick_random_room() -> int:
	var all_vertices = range(1, 21)
	for v in Global.bat_vertices:
		all_vertices.erase(v)
	for v in Global.pit_vertices:
		all_vertices.erase(v)
	all_vertices.erase(Global.wumpus_vertice)

	return all_vertices[randi_range(0, all_vertices.size()-1)]

func setup_start_room():
	Global.current_room_vertice = pick_random_room()
	Global.current_room_name = maze.vertice_to_room[Global.current_room_vertice]
	update_room_connections()

func update_room_connections():
	Global.connected_rooms = []
	Global.connected_vertices = maze.vertice_connections[Global.current_room_vertice]
	for v in Global.connected_vertices:
		Global.connected_rooms.append(maze.vertice_to_room[v])

func move_wumpus():
	if Global.wumpus_asleep:
		return

	var connections = maze.vertice_connections[Global.wumpus_vertice]
	if randi_range(0, 100) > 25:
		Global.wumpus_vertice = connections.pick_random()
	else:
		pass

func append_new_line(text: String = ""):
	main_text.text += text + "\n"

func append_text(text: String = ""):
	main_text.text += text

func populate_room_buttons(vertice_ids: Array, room_names: Array):
	clear_room_buttons()

	for idx in range(0, 3):
		var b = Button.new()
		b.text = str(room_names[idx])
		b.pressed.connect(on_room_button_pressed.bind(vertice_ids[idx]))
		room_buttons.add_child(b)

func clear_room_buttons():
	for b in room_buttons.get_children():
		b.queue_free()

func on_room_button_pressed(vertice_id: int):
	clear_room_buttons()
	show_command_buttons()

	Global.current_room_vertice = vertice_id
	Global.current_room_name = maze.vertice_to_room[Global.current_room_vertice]
	update_room_connections()
	update_stats()

	tell_room_name()

	if Global.bat_vertices.has(Global.current_room_vertice):
		append_new_line("[color=#00FF00]There's a Viral Storm! It took you to another page![/color]")
		setup_start_room()
		update_stats()
		tell_room_name()
	elif Global.pit_vertices.has(Global.current_room_vertice):
		append_new_line("[color=#00FF00]You stuck in a Clickbait Loop... forever![/color]")
		show_command_buttons()
	elif Global.current_room_vertice == Global.wumpus_vertice:
		append_new_line("[color=#00FF00]You found SNARF! But it found you too...[/color]")
		show_command_buttons()
	else:
		tell_connected_room_names()
		tell_status_update()

func _on_move_button_pressed():
	populate_room_buttons(Global.connected_vertices, Global.connected_rooms)
	show_action_buttons()

func _on_shoot_button_pressed():
	if Global.arrows_count <= 0:
		append_new_line("[color=#00FF00]You're out of Critical Thinking Bolts![/color]")
		return

	populate_room_buttons(Global.connected_vertices, Global.connected_rooms)
	show_action_buttons()

func _on_detect_button_pressed():
	tell_status_update()

func _on_help_button_pressed():
	instructions_text.visible = true

func _on_hide_instructions_button_pressed():
	instructions_text.visible = false

func _on_confirm_button_pressed():
	var target_vertice = Global.connected_vertices[0]  # First connected room
	Global.arrows_count -= 1
	update_stats()

	if target_vertice == Global.wumpus_vertice:
		append_new_line("[color=#00FF00]You defeated SNARF with your Critical Thinking![/color]")
		show_command_buttons()
	else:
		append_new_line("[color=#00FF00]Your Critical Thinking Bolt missed![/color]")
		Global.wumpus_asleep = false
		move_wumpus()
		
		if Global.wumpus_vertice == Global.current_room_vertice:
			append_new_line("[color=#00FF00]SNARF found you![/color]")
			show_command_buttons()
		else:
			tell_status_update()

func _on_cancel_button_pressed():
	show_command_buttons()
