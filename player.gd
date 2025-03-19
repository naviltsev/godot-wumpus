extends Object
class_name Player

# Global to keep current room vertice and name
var current_room_vertice: int
var current_room_name: int

func move(new_vertice: int):
	current_room_vertice = new_vertice
	current_room_name = MazeConfig.vertice_to_room[current_room_vertice]
