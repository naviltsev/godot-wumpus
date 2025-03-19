class_name Maze

var bat_vertices: Array[int]
var pit_vertices: Array[int]
#var wumpus_vertice: int

var player: Player
var wumpus: Wumpus

func initialize():
	player = Player.new()
	wumpus = Wumpus.new()
	
	# init hazards + setup Wumpus
	init_hazards()

	# init player
	init_player()

func init_hazards():
	bat_vertices = []
	pit_vertices = []

	var vertices = range(1, 21)
	for i in range(0, 2):
		vertices.shuffle()
		var bat = vertices[randi_range(0, vertices.size()-1)]
		vertices.erase(bat)
		bat_vertices.append(bat)
		print("viral storm room ", MazeConfig.vertice_to_room[bat])

	for i in range(0, 2):
		vertices.shuffle()
		var pit = vertices[randi_range(0, vertices.size()-1)]
		vertices.erase(pit)
		pit_vertices.append(pit)
		print("clickbait loop room ", MazeConfig.vertice_to_room[pit])

	vertices.shuffle()
	var wumpus_vertice = vertices[randi_range(0, vertices.size()-1)]
	vertices.erase(wumpus_vertice)
	wumpus.current_room_vertice = wumpus_vertice
	print("SNARF room ", MazeConfig.vertice_to_room[wumpus_vertice])

func init_player():
	player.move(pick_random_room())
	Global.update_room_connections.emit(self)

# picks random room based
# takes hazards into account and doesn't pick the room occupied by a hazard
func pick_random_room() -> int:
	var all_vertices = range(1, 21)
	for v in bat_vertices:
		all_vertices.erase(v)
	for v in pit_vertices:
		all_vertices.erase(v)
	all_vertices.erase(wumpus.current_room_vertice)

	return all_vertices[randi_range(0, all_vertices.size()-1)]
