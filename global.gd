extends Node

# Rooms to shoot at
var shoot_room_vertices: Array[int]

# Vertice IDs connected to the current_room
var connected_vertices = []
# Same, but in connected_rooms we keep room "names" instead of vertice IDs
var connected_rooms = []

# arrows left
var arrows_count = 5

signal update_room_connections(maze: Maze)

func _ready():
	update_room_connections.connect(_update_room_connections)

# accept maze
func _update_room_connections(maze: Maze):
	connected_rooms = []
	connected_vertices = MazeConfig.vertice_connections[maze.player.current_room_vertice]
	for v in connected_vertices:
		connected_rooms.append(MazeConfig.vertice_to_room[v])
