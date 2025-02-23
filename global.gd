extends Node

# Globals to keep vertice indices of hazards - pits, bats, wumpus
var bat_vertices: Array[int]
var pit_vertices: Array[int]
var wumpus_vertice: int

# Is Wumpus asleep?
var wumpus_asleep = true

# Rooms to shoot at
var shoot_room_vertices: Array[int]

# Global to keep current room vertice and name
var current_room_vertice: int
var current_room_name: int

# Vertice IDs connected to the current_room
var connected_vertices = []
# Same, but in connected_rooms we keep room "names" instead of vertice IDs
var connected_rooms = []

# arrows left
var arrows_count = 5
