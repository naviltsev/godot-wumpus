extends Node
class_name Wumpus

var is_asleep: bool = true
var current_room_vertice: int

func move():
	if is_asleep:
		return

	var connections = MazeConfig.vertice_connections[current_room_vertice]
	if randi_range(0, 100) > 25: # move
		current_room_vertice = connections.pick_random()
		print("SNARF moved to %d" % current_room_vertice)
	else:
		print("SNARF stays")
