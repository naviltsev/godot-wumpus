extends Node

# RichTextLabel's for main interaction and instructions text
@onready var rtl: RichTextLabel  = %RichTextLabel
@onready var instructions_rtl: RichTextLabel = %InstructionsRichTextLabel

# Bottom container - the one that contains buttons
@onready var bottom_container: VBoxContainer = %BottomContainer

# Button containers for action buttons (Move/Shoot), context buttons container (room number where to move or room numbers where to shoot),
# shoot buttons (Confirm/Back), post game buttons (Resart), and container for selected shoot room numbers
@onready var action_buttons_container: HBoxContainer = %ActionButtonsContainer
@onready var context_buttons_container: HFlowContainer = %ContextButtonsContainer
@onready var shoot_buttons_container: HBoxContainer = %ShootButtonsContainer
@onready var post_game_buttons_container: HBoxContainer = %PostGameButtonsContainer
@onready var selected_room_buttons_container: HBoxContainer = %SelectedRoomButtonsContainer

# Question mark button at the top right to display/hide instructions
@onready var show_instructions_button: Button = %ShowInstructionsButton
@onready var hide_instructions_button: Button = %HideInstructionsButton

# Arrows counter
@onready var arrows_count_label: Label = %ArrowsCount

# Helper array to keep clicked shoot room buttons
var _shoot_room_buttons: Array[Button]

signal move_at(vertice_id: int)
signal shoot_at(vertice_id: int)

# Maze
var maze = Maze.new()

func _ready():
	start_game(true, false)

	tell_room_name()
	tell_connected_room_names()
	tell_status_update()

func hide_restart_button():
	action_buttons_container.visible = true
	shoot_buttons_container.visible = false
	post_game_buttons_container.visible = false

func show_restart_button():
	action_buttons_container.visible = false
	shoot_buttons_container.visible = false
	post_game_buttons_container.visible = true

func show_post_shoot_buttons():
	action_buttons_container.visible = false
	shoot_buttons_container.visible = true
	post_game_buttons_container.visible = false

func hide_post_shoot_buttons():
	action_buttons_container.visible = true
	shoot_buttons_container.visible = false
	post_game_buttons_container.visible = false

func start_game(reshuffle_rooms: bool, clear_text_window: bool = false):
	rtl.visible = true
	instructions_rtl.visible = false

	hide_restart_button()

	Global.arrows_count = 5
	update_arrows_count()
	
	Global.wumpus_asleep = true
	Global.shoot_room_vertices = []

	if clear_text_window:
		rtl.text = ""

	# reshuffle maze
	if reshuffle_rooms:
		maze.shuffle_rooms()

	# setup hazards first
	setup_hazards()

	# then randomly chose start room
	setup_start_room()

func update_room_connections():
	Global.connected_rooms = []
	Global.connected_vertices = maze.vertice_connections[Global.current_room_vertice]
	for v in Global.connected_vertices:
		Global.connected_rooms.append(maze.vertice_to_room[v])

func update_arrows_count():
	arrows_count_label.text = str(Global.arrows_count)

func tell_room_name():
	append_new_line("\n[b][color=black][bgcolor=green]You are on page %d[/bgcolor][/color][/b]" % Global.current_room_name) 

func tell_connected_room_names():
	append_new_line("You can visit pages %d, %d and %d" % Global.connected_rooms)

# Tells status update - what do we know about adjacent rooms
# "I hear clicks" for clickbait loops
# "I feel engagement" for viral storms
# "It smells like SNARF code" for SNARF nearby
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

	if ret["bat"]: # viral storm
		append_new_line("\tI feel engagement")
	if ret["pit"]: # clickbait loop
		append_new_line("\tI hear clicks")
	if ret["wumpus"]: # SNARF
		append_new_line("\tIt smells like SNARF code")

func setup_hazards():
	Global.bat_vertices = []
	Global.pit_vertices = []

	var vertices = range(1, 21)
	for i in range(0, 2):
		vertices.shuffle()
		var bat = vertices[randi_range(0, vertices.size()-1)]
		vertices.erase(bat)
		Global.bat_vertices.append(bat)
		print("viral storm room ", maze.vertice_to_room[bat])

	for i in range(0, 2):
		vertices.shuffle()
		var pit = vertices[randi_range(0, vertices.size()-1)]
		vertices.erase(pit)
		Global.pit_vertices.append(pit)
		print("clickbait loop room ", maze.vertice_to_room[pit])

	vertices.shuffle()
	var wumpus = vertices[randi_range(0, vertices.size()-1)]
	vertices.erase(wumpus)
	Global.wumpus_vertice = wumpus
	print("SNARF room ", maze.vertice_to_room[wumpus])

# picks random room based
# takes hazards into account and doesn't pick the room occupied by a hazard
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

func move_wumpus():
	if Global.wumpus_asleep:
		return

	var connections = maze.vertice_connections[Global.wumpus_vertice]
	if randi_range(0, 100) > 25: # move
		Global.wumpus_vertice = connections.pick_random()
		print("SNARF moved to %d" % Global.wumpus_vertice)
	else:
		print("SNARF stays")

func append_new_line(text: String = ""):
	rtl.text += text + "\n"

func append_text(text: String = ""):
	rtl.text += text

func clear_context_buttons():
	for b in context_buttons_container.get_children():
		b.queue_free()

func clear_selected_room_buttons():
	for b in selected_room_buttons_container.get_children():
		b.queue_free()

func populate_move_context_room_buttons(vertice_ids: Array, room_names: Array):
	clear_context_buttons()

	for idx in range(0, 3):
		var b = Button.new()
		b.text = "Page %s" % str(room_names[idx])
		b.pressed.connect(on_move_context_button_pressed.bind(vertice_ids[idx]))
		context_buttons_container.add_child(b)

func populate_shoot_context_room_buttons():
	clear_context_buttons()

	for vertice in range(1, 21):
		var b = Button.new()
		b.text = "Page %s" % str(vertice)
		b.pressed.connect(on_shoot_context_button_pressed.bind(b, vertice))
		context_buttons_container.add_child(b)

func on_shoot_context_button_pressed(b: Button, vertice_id: int):
	if Global.shoot_room_vertices.has(vertice_id):
		Global.shoot_room_vertices.erase(vertice_id)
		_shoot_room_buttons.erase(b)

		b.reparent(context_buttons_container)
	elif Global.shoot_room_vertices.size() < 5:
		Global.shoot_room_vertices.append(vertice_id)
		_shoot_room_buttons.append(b)

		b.reparent(selected_room_buttons_container)

	var all_buttons = context_buttons_container.get_children()

	if Global.shoot_room_vertices.size() >= 5:
		for rb in all_buttons:
			if _shoot_room_buttons.has(rb):
				continue
			rb.disabled = true
	else:
		for rb in all_buttons:
			rb.disabled = false

func on_move_context_button_pressed(vertice_id: int):
	clear_context_buttons()

	Global.current_room_vertice = vertice_id
	Global.current_room_name = maze.vertice_to_room[Global.current_room_vertice]
	update_room_connections()

	tell_room_name()

	var wumpus_moved_to_another_room = false
	if Global.bat_vertices.has(Global.current_room_vertice):
		append_new_line("There's a Viral Storm! It took you to another page!")
		setup_start_room()
		tell_room_name()
	elif Global.pit_vertices.has(Global.current_room_vertice):
		append_new_line("You stuck in a Clickbait Loop... forever!")
		show_restart_button()
		return
	elif Global.wumpus_vertice == Global.current_room_vertice:
		var was_asleep = false
		if Global.wumpus_asleep:
			was_asleep = true
			Global.wumpus_asleep = false

		var original_wumpus_vertice = Global.wumpus_vertice
		move_wumpus() # move_wumpus() will update wumpus_vertice with 75% chance
		wumpus_moved_to_another_room = true
		if original_wumpus_vertice == Global.wumpus_vertice:
			if was_asleep:
				append_new_line("You entered a SNARF page, activated it, and it... absorbed you... forever!")
			else:
				append_new_line("What a pity, you entered a SNARF page and it... disconnected you... forever!")
			show_restart_button()
			return
		else:
			if was_asleep:
				append_new_line("You entered a SNARF page, activated it, and SNARF has moved to a nearby page!")

	tell_connected_room_names()
	if not wumpus_moved_to_another_room:
		move_wumpus()
	tell_status_update()

func _on_move_button_pressed() -> void:
	populate_move_context_room_buttons(Global.connected_vertices, Global.connected_rooms)

func _on_shoot_button_pressed() -> void:
	show_post_shoot_buttons()
	populate_shoot_context_room_buttons()

func _on_restart_button_pressed() -> void:
	start_game(true, true)
	tell_room_name()
	tell_connected_room_names()
	tell_status_update()

func _on_go_back_button_pressed():
	clear_context_buttons()
	hide_post_shoot_buttons()
	Global.shoot_room_vertices = []
	_shoot_room_buttons = []
	clear_selected_room_buttons()

func _on_confirm_shoot_button_pressed():
	Global.arrows_count -= 1
	update_arrows_count()

	if Global.arrows_count == 0:
		clear_selected_room_buttons()
		clear_context_buttons()

		append_new_line("\nYou're out of bolts!")
		show_restart_button()
		return

	hide_post_shoot_buttons()
	clear_context_buttons()
	clear_selected_room_buttons()

	var cur_vertice = Global.current_room_vertice
	var cur_connections = []

	var arrow_flight_path = []
	
	# TODO check that room where you are now can not be selected!
	# TODO the arrow is too crooked - if current room is selected, any other should be chosen instead
	for v in Global.shoot_room_vertices:
		cur_connections = maze.vertice_connections[cur_vertice].duplicate()

		# ensure the room the hunter is in will never be used in arrow flight path
		if cur_connections.has(Global.current_room_vertice):
			cur_connections.erase(Global.current_room_vertice)

		# check if next room of arrow's path is connected with the current room vertice
		if cur_connections.has(v):
			cur_vertice = v
		else: # otherwise choose random room among connected rooms
			while true:
				cur_vertice = cur_connections.pick_random()
				if !arrow_flight_path.has(cur_vertice):
					break

		arrow_flight_path.append(cur_vertice)

	Global.shoot_room_vertices = []

	if Global.wumpus_asleep == true:
		Global.wumpus_asleep = false
		append_new_line("\nYou shot a bolt and activated SNARF!")

	append_new_line("\nBolt has visited the following pages: ")

	for v in arrow_flight_path:
		append_new_line("* Page %d" % v)
		if v == Global.current_room_vertice:
			append_new_line("\tWhat a pity, the bolt returned to the page you're on and disconnected you ((")
			show_restart_button()
			return
		if v == Global.wumpus_vertice:
			append_new_line("\tThe bolt has reached and deactivated SNARF... forever!")
			show_restart_button()
			return
		if Global.bat_vertices.has(v):
			Global.bat_vertices.erase(v)
			append_new_line("\tThe bolt managed to defuse the Viral Storm on page %d!" % v)

	move_wumpus() # move_wumpus() will update wumpus_vertice with 75% chance
	if Global.wumpus_vertice == Global.current_room_vertice:
		append_new_line("\nThe SNARF has moved on to a nearby page, but what a pity, it was a page you're on! DISCONNECT!")
		show_restart_button()
		return

	tell_room_name()
	tell_connected_room_names()
	tell_status_update()

func _on_show_instructions_button_pressed() -> void:
	bottom_container.visible = false
	rtl.visible = false
	instructions_rtl.visible = true

func _on_hide_instructions_button_pressed() -> void:
	bottom_container.visible = true
	rtl.visible = true
	instructions_rtl.visible = false
