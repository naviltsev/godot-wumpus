extends Node

@onready var rtl: RichTextLabel  = %RichTextLabel
@onready var action_buttons_container: HBoxContainer = %ActionButtonsContainer
@onready var context_buttons_container: GridContainer = %ContextButtonsContainer
@onready var selected_room_buttons_container: HBoxContainer = %SelectedRoomButtonsContainer
@onready var arrows_count_label: Label = %ArrowsCount

# Globals to keep vertice indices of hazards - pits, bats, wumpus
var bat_vertices: Array[int]
var pit_vertices: Array[int]
var wumpus_vertice: int

# Is Wumpus asleep?
var wumpus_asleep = true

# Rooms to shoot at
var shoot_room_vertices: Array[int]
# Helper array to keep clicked shoot room buttons
var _shoot_room_buttons: Array[Button]

# Global to keep current room vertice and name
var current_room_vertice: int
var current_room_name: int

# Vertice IDs connected to the current_room
var connected_vertices = []
# Same, but in connected_rooms we keep room "names" instead of vertice IDs
var connected_rooms = []

# Last clicked action - move or shoot
var clicked_action: String

# arrows count
var arrows_count = 5

signal move_at(vertice_id: int)
signal shoot_at(vertice_id: int)

# Maze
var maze = Maze.new()

func _ready():
	start(true, false)
	tell_room_name()
	tell_connected_room_names()

	tell_status_update()

func hide_restart_button():
	action_buttons_container.get_node("MoveButton").visible = true
	action_buttons_container.get_node("ShootButton").visible = true
	action_buttons_container.get_node("ConfirmShootButton").visible = false
	action_buttons_container.get_node("GoBackButton").visible = false
	action_buttons_container.get_node("RestartButton").visible = false

func show_restart_button():
	action_buttons_container.get_node("MoveButton").visible = false
	action_buttons_container.get_node("ShootButton").visible = false
	action_buttons_container.get_node("ConfirmShootButton").visible = false
	action_buttons_container.get_node("GoBackButton").visible = false
	action_buttons_container.get_node("RestartButton").visible = true

func show_post_shoot_buttons():
	action_buttons_container.get_node("MoveButton").visible = false
	action_buttons_container.get_node("ShootButton").visible = false
	action_buttons_container.get_node("ConfirmShootButton").visible = true
	action_buttons_container.get_node("GoBackButton").visible = true
	action_buttons_container.get_node("RestartButton").visible = false

func hide_post_shoot_buttons():
	action_buttons_container.get_node("MoveButton").visible = true
	action_buttons_container.get_node("ShootButton").visible = true
	action_buttons_container.get_node("ConfirmShootButton").visible = false
	action_buttons_container.get_node("GoBackButton").visible = false
	action_buttons_container.get_node("RestartButton").visible = false

func start(reshuffle_rooms: bool, clear_text_window: bool = false):
	hide_restart_button()

	arrows_count = 5
	update_arrows_count()
	
	wumpus_asleep = true
	clicked_action = ""
	shoot_room_vertices = []

	if clear_text_window:
		rtl.text = ""

	# reshuffle maze
	if reshuffle_rooms:
		maze.shuffle_rooms()

	# setup hazards first
	setup_hazards()

	# then randomly chose start room
	setup_start_room()

func _post_turn_updates():
	connected_rooms = []
	connected_vertices = maze.vertice_connections[current_room_vertice]
	for v in connected_vertices:
		connected_rooms.append(maze.vertice_to_room[v])

func update_arrows_count():
	arrows_count_label.text = str(arrows_count)

func tell_room_name():
	append_new_line("\n[b][color=black][bgcolor=green]You are on page %d[/bgcolor][/color][/b]" % current_room_name) 

func tell_connected_room_names():
	append_new_line("You can visit pages %d, %d and %d" % connected_rooms)

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
	for v in connected_vertices:
		if bat_vertices.has(v):
			ret["bat"] = true
		if pit_vertices.has(v):
			ret["pit"] = true
		if v == wumpus_vertice:
			ret["wumpus"] = true

	if ret["bat"]: # viral storm
		append_new_line("\tI feel engagement")
	if ret["pit"]: # clickbait loop
		append_new_line("\tI hear clicks")
	if ret["wumpus"]: # SNARF
		append_new_line("\tIt smells like SNARF code")

func setup_hazards():
	bat_vertices = []
	pit_vertices = []

	var vertices = range(1, 21)
	for i in range(0, 2):
		vertices.shuffle()
		var bat = vertices[randi_range(0, vertices.size()-1)]
		vertices.erase(bat)
		bat_vertices.append(bat)
		print("viral storm room ", maze.vertice_to_room[bat])

	for i in range(0, 2):
		vertices.shuffle()
		var pit = vertices[randi_range(0, vertices.size()-1)]
		vertices.erase(pit)
		pit_vertices.append(pit)
		print("clickbait loop room ", maze.vertice_to_room[pit])

	vertices.shuffle()
	var wumpus = vertices[randi_range(0, vertices.size()-1)]
	vertices.erase(wumpus)
	wumpus_vertice = wumpus
	print("SNARF room ", maze.vertice_to_room[wumpus])

# picks random room based
# takes hazards into account and doesn't pick the room occupied by a hazard
func pick_random_room() -> int:
	var all_vertices = range(1, 21)
	for v in bat_vertices:
		all_vertices.erase(v)
	for v in pit_vertices:
		all_vertices.erase(v)
	all_vertices.erase(wumpus_vertice)

	return all_vertices[randi_range(0, all_vertices.size()-1)]

func setup_start_room():
	current_room_vertice = pick_random_room()
	current_room_name = maze.vertice_to_room[current_room_vertice]
	_post_turn_updates()

func move_wumpus():
	if wumpus_asleep:
		return

	var connections = maze.vertice_connections[wumpus_vertice]
	if randi_range(0, 100) > 25: # move
		wumpus_vertice = connections.pick_random()
		print("SNARF moved to %d" % wumpus_vertice)
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
	if shoot_room_vertices.has(vertice_id):
		shoot_room_vertices.erase(vertice_id)
		_shoot_room_buttons.erase(b)

		b.reparent(context_buttons_container)
	elif shoot_room_vertices.size() < 5:
		shoot_room_vertices.append(vertice_id)
		_shoot_room_buttons.append(b)

		b.reparent(selected_room_buttons_container)

	var all_buttons = context_buttons_container.get_children()

	if shoot_room_vertices.size() >= 5:
		for rb in all_buttons:
			if _shoot_room_buttons.has(rb):
				continue
			rb.disabled = true
	else:
		for rb in all_buttons:
			rb.disabled = false

func on_move_context_button_pressed(vertice_id: int):
	clear_context_buttons()

	current_room_vertice = vertice_id
	current_room_name = maze.vertice_to_room[current_room_vertice]
	_post_turn_updates()
	
	#tell_status_update()
	tell_room_name()

	var wumpus_moved_to_another_room = false
	if clicked_action == "move":
		if bat_vertices.has(current_room_vertice):
			append_new_line("There's a Viral Storm! It took you to another page!")
			setup_start_room()
			tell_room_name()
		elif pit_vertices.has(current_room_vertice):
			append_new_line("You stuck in a Clickbait Loop... forever!")
			show_restart_button()
			return
		elif wumpus_vertice == current_room_vertice:
			var was_asleep = false
			if wumpus_asleep:
				was_asleep = true
				wumpus_asleep = false
			var original_wumpus_vertice = wumpus_vertice
			move_wumpus() # move_wumpus() will update wumpus_vertice with 75% chance
			wumpus_moved_to_another_room = true
			if original_wumpus_vertice == wumpus_vertice:
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
	clicked_action = "move"
	populate_move_context_room_buttons(connected_vertices, connected_rooms)

func _on_shoot_button_pressed() -> void:
	clicked_action = "shoot"
	show_post_shoot_buttons()
	populate_shoot_context_room_buttons()

func _on_restart_button_pressed() -> void:
	start(true, true)
	tell_room_name()
	tell_connected_room_names()
	tell_status_update()

func _on_go_back_button_pressed():
	clear_context_buttons()
	hide_post_shoot_buttons()
	shoot_room_vertices = []
	_shoot_room_buttons = []
	clicked_action = ""
	clear_selected_room_buttons()

func _on_confirm_shoot_button_pressed():
	arrows_count -= 1
	update_arrows_count()

	if arrows_count == 0:
		clear_selected_room_buttons()
		clear_context_buttons()

		append_new_line("\nYou're out of bolts!")
		show_restart_button()
		return

	hide_post_shoot_buttons()
	clear_context_buttons()
	clear_selected_room_buttons()

	var cur_vertice = current_room_vertice
	var cur_connections = []

	var arrow_flight_path = []
	
	# TODO check that room where you are now can not be selected!
	# TODO the arrow is too crooked - if current room is selected, any other should be chosen instead
	for v in shoot_room_vertices:
		cur_connections = maze.vertice_connections[cur_vertice].duplicate()

		# ensure the room the hunter is in will never be used in arrow flight path
		if cur_connections.has(current_room_vertice):
			cur_connections.erase(current_room_vertice)

		# check if next room of arrow's path is connected with the current room vertice
		if cur_connections.has(v):
			cur_vertice = v
		else: # otherwise choose random room among connected rooms
			while true:
				cur_vertice = cur_connections.pick_random()
				if !arrow_flight_path.has(cur_vertice):
					break

		arrow_flight_path.append(cur_vertice)

	shoot_room_vertices = []

	if wumpus_asleep == true:
		wumpus_asleep = false
		append_new_line("\nYou shot a bolt and activated SNARF!")

	append_new_line("\nBolt has visited the following pages: ")

	for v in arrow_flight_path:
		append_new_line("* Page %d" % v)
		if v == current_room_vertice:
			append_new_line("\tWhat a pity, the bolt returned to the page you're on and disconnected you ((")
			show_restart_button()
			return
		if v == wumpus_vertice:
			append_new_line("\tThe bolt has reached and deactivated SNARF... forever!")
			show_restart_button()
			return
		if bat_vertices.has(v):
			bat_vertices.erase(v)
			append_new_line("\tThe bolt managed to defuse the Viral Storm on page %d!" % v)

	#var original_wumpus_vertice = wumpus_vertice

	move_wumpus() # move_wumpus() will update wumpus_vertice with 75% chance
	if wumpus_vertice == current_room_vertice:
		append_new_line("\nThe SNARF has moved on to a nearby page, but what a pity, it was a page you're on! DISCONNECT!")
		show_restart_button()
		return

	tell_room_name()
	tell_connected_room_names()
	tell_status_update()
