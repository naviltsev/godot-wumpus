class_name Maze

# inner 5
# 1, 2, 3, 4, 5
# they connect to middle 5
# 6, 7, 8, 9, 10
# middle five has also
# 11, 12, 13, 14, 15
# they connect to outer 5
# 16, 17, 18, 19, 20
var vertice_connections: Dictionary = {
	1: [2, 5, 8],
	2: [1, 3, 10],
	3: [2, 4, 12], 
	4: [3, 5, 14],
	5: [1, 4, 6],
	6: [5, 7, 15],
	7: [6, 8, 17],
	8: [1, 7, 9],
	9: [8, 10, 18],
	10: [2, 9, 11],
	11: [10, 12, 19],
	12: [3, 11, 13],
	13: [12, 14, 20],
	14: [4, 13, 15],
	15: [6, 14, 16],
	16: [15, 17, 20],
	17: [7, 16, 18],
	18: [9, 17, 19],
	19: [11, 18, 20],
	20: [13, 16, 19],
}

var vertice_to_room: Dictionary

func shuffle_rooms():
	var room_names = range(1, 21)
	#room_names.shuffle()

	for vertice in range(1, 21):
		vertice_to_room[vertice] = room_names[vertice-1]

	print(vertice_to_room)
