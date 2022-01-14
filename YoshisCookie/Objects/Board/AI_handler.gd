extends Node2D

class_name AI_handler

var board

var AI_delay_seconds  = 0.5 #TODO let the AI check the score and modify this value to adjust

var ai_completing_color = -1
var ai_line_type
var ai_line_pos
var AI_time_until_move


func _init(working_board):
	board = working_board
	
	AI_time_until_move = AI_delay_seconds
	
	select_possible_color()
	ai_set_line_typepos()


func select_possible_color():
	var valid_colors = get_all_possible_colors()
	
	var selecting = valid_colors[randi() % valid_colors.size()]
	ai_completing_color = selecting


func ai_set_line_typepos():
	ai_line_type =  board.LineType.COLUMN if randi()%2 else board.LineType.ROW 
	ai_line_pos = randi() % board.BOARD_SIZE


func do_ai_steps():	
	if not board.animation_in_progress():
		# pick a color to solve
		
		# check the pieces that need to be solved
		var to_get_in_place = get_incomplete_in_line(ai_line_type, ai_line_pos, ai_completing_color)
		
		var piece_y
		var piece_x
		# find a piece that matches the color we are solving that is not in the right place
		var found = false
		for r in range(board.BOARD_SIZE):
			if(found):
				break
			if(ai_line_type==board.LineType.COLUMN) and ai_line_pos==r: #skip if its the one we're solving
				continue 
			for c in range(board.BOARD_SIZE):
				if(ai_line_type==board.LineType.ROW) and ai_line_pos==c: #skip if its the one we're solving
					continue 
				if board.cookie_grid[r][c].get_color()==ai_completing_color:
					piece_y = c
					piece_x = r
					found = true
					break
		
		# The anchor is the position which the cursor would have
		# to be in such that the cookie we are moving is either in the row or 
		# column of the cursor and the position we are moving it to is in the other.
		var ai_anchor_x
		var ai_anchor_y
		
		# Gets the piece on one of the right axes, then the other.
		var first_axis_type
		var first_axis_pos
		var second_axis_pos 

		if(ai_line_type==board.LineType.ROW):
			ai_anchor_x = to_get_in_place[0]
			ai_anchor_y = piece_y
			first_axis_type = board.LineType.COLUMN
			first_axis_pos = ai_anchor_x
			second_axis_pos = ai_anchor_y
		else:
			ai_anchor_x = piece_x
			ai_anchor_y = to_get_in_place[0]
			first_axis_type = board.LineType.ROW
			first_axis_pos = ai_anchor_y
			second_axis_pos = ai_anchor_x
		
		#TODO delay for cursor
		board.cursor.position.x = ai_anchor_x*64
		board.cursor.position.y = ai_anchor_y*64 
			
		#if moving to the first axis or the second
		# TODO let the AI move in the other direction if it is optimal
		if(get_incomplete_in_line(first_axis_type,first_axis_pos,ai_completing_color).size()==board.BOARD_SIZE):#if there is no goal color in the current col, then move right
			board.start_line_move(ai_line_type, board.LineSign.POSITIVE, second_axis_pos)
		else:
			board.start_line_move(first_axis_type, board.LineSign.POSITIVE, to_get_in_place[0])


func move_cursor(delta):
	AI_time_until_move -= delta
	if(AI_time_until_move<=0):
		do_ai_steps()
		AI_time_until_move = AI_delay_seconds
	return


func handle_completion():
	select_possible_color()
	ai_set_line_typepos()


func get_all_possible_colors():
	var possible = []
	
	for testing in range(5):# for every color
		var count = 0
		for r in range(board.BOARD_SIZE):#for every place on the board
			for c in range(board.BOARD_SIZE):
				if (board.cookie_grid[r][c].get_color()==testing):
					count += 1
		if count >= 5:
			possible.append(testing)
			
	return possible


func get_incomplete_in_line(var lineType, var linePos, var goalColor):
	var incomplete = []
	for checking in range(board.BOARD_SIZE):
		if lineType==board.LineType.COLUMN:
			if(board.cookie_grid[linePos][checking].get_color()!=goalColor):
				incomplete.append(checking)
		else:
			if(board.cookie_grid[checking][linePos].get_color()!=goalColor):
				incomplete.append(checking)
				
	return incomplete


func _process(_delta):
	update()


func _draw():
	if 0: #debug ai drawing
		var pos = ai_line_pos*64
		if ai_line_type==board.LineType.COLUMN:
			draw_line(Vector2(pos,-64), Vector2(pos,352), Color(255,255,255), 20)
		else:
			draw_line(Vector2(-64,pos), Vector2(352,pos), Color(255,255,255), 20)
		pass
