extends Node2D

class_name Board

# dynamic textures
var cursor_texture = preload("res://Objects/Board/cursor.png")
var cursor_texture_selected = preload("res://Objects/Board/cursor_selected.png")

# scenes
var cookie_template = preload("res://Objects/Cookie/cookie.tscn")

# globals
const BOARD_SIZE = 5
var cookie_grid=[]
var is_moving = false
export var health_x_offset = 0
export var isAI = false

var AI_delay_seconds  = 0.5 #TODO let the AI check the score and modify this value to adjust

#enums
enum LineType {ROW, COLUMN}
enum LineSign {POSITIVE=1, NEGATIVE=-1}

var ai_completing_color = -1
var ai_line_type
var ai_line_pos
var AI_time_until_move

# generates the 5x5 grid of cookies
func generate_cookie_grid():
	#append once for each row of the array
	for _i in range(BOARD_SIZE):
		cookie_grid.append([])
	
	# generate 5 of each tile randomly placed
	for r in range(BOARD_SIZE):
		for c in range(BOARD_SIZE):
			# create the cookie
			var new_cookie = cookie_template.instance()
			find_node("cookies").add_child(new_cookie)
			cookie_grid[r].append(new_cookie)

			# set cookie position
			new_cookie.position.x += r*64
			new_cookie.position.y += c*64

			# pick the cookie color
			var color = randi() % 4
			
			# set the cookie color
			new_cookie.set_color(color)
	
	handle_line_match_detection()
	find_node("health").value=0


# Called when the node enters the scene tree for the first time.
func _ready():
	find_node("health").margin_left = health_x_offset
	find_node("health").margin_right = health_x_offset
	
	randomize()
	generate_cookie_grid()
	
	ai_set_line_typepos()
	
	AI_time_until_move = AI_delay_seconds


# starts the cookie moving animation
func start_line_move(lineType, lineDirection, linePosition):
	for i in range(BOARD_SIZE):
		var wrap
		if lineDirection == LineSign.POSITIVE:
			wrap = i==BOARD_SIZE-1 #TODO this only works on positive directions
		else:
			wrap = i==0
		if lineType==LineType.COLUMN:
			var r = linePosition
			var c = i
			cookie_grid[r][c].start_move_animation(lineType, lineDirection, linePosition, wrap)
		else:
			var r = i
			var c = linePosition
			cookie_grid[r][c].start_move_animation(lineType, lineDirection, linePosition, wrap)
	finish_line_move(lineType, lineDirection, linePosition)

func finish_line_move(lineType, lineDirection, linePosition):	
	# TODO fix the lack of new cookie. At the begining of the 
	# animation spawn a fake cookie, move it too, then delete it
	# this fix should probably be done by adding a script to cookie
	# then letting the cookie handle its own moving
	
	# update cookies
	var posToWrap = 0 if lineDirection==LineSign.NEGATIVE else BOARD_SIZE-1
	var posToWrapto = 0 if lineDirection==LineSign.POSITIVE else BOARD_SIZE-1
	
	if(lineType==LineType.ROW):
		var tempCookie = cookie_grid[posToWrap][linePosition]
		if(lineDirection==LineSign.POSITIVE): # if row positive
			for curCookie in range(BOARD_SIZE-2, -1, -1):
				cookie_grid[curCookie+1][linePosition] = cookie_grid[curCookie][linePosition]
		else: # if row negative
			for curCookie in range(0, BOARD_SIZE-1, 1):
				cookie_grid[curCookie][linePosition] = cookie_grid[curCookie+1][linePosition]
		cookie_grid[posToWrapto][linePosition] = tempCookie
		
	else: #columns
		var tempCookie = cookie_grid[linePosition][posToWrap]
		if(lineDirection==LineSign.POSITIVE): # if col positive
			for curCookie in range(BOARD_SIZE-2, -1, -1):
				cookie_grid[linePosition][curCookie+1] = cookie_grid[linePosition][curCookie]
		else: # if col negative
			for curCookie in range(0, BOARD_SIZE-1, 1):
				cookie_grid[linePosition][curCookie] = cookie_grid[linePosition][curCookie+1]
		cookie_grid[linePosition][posToWrapto] = tempCookie
		
	# check for match
	handle_line_match_detection()
				


func get_all_possible_colors():
	var possible = []
	
	for testing in range(5):# for every color
		var count = 0
		for r in range(BOARD_SIZE):#for every place on the board
			for c in range(BOARD_SIZE):
				if (cookie_grid[r][c].get_color()==testing):
					count += 1
		if count >= 5:
			possible.append(testing)
			
	return possible


func select_possible_color():
	var valid_colors = get_all_possible_colors()
	var selecting = valid_colors[randi() % valid_colors.size()]
	return selecting


func get_incomplete_in_line(var lineType, var linePos, var goalColor):
	var incomplete = []
	for checking in range(5):
		if lineType==LineType.COLUMN:
			if(cookie_grid[linePos][checking].get_color()!=goalColor):
				incomplete.append(checking)
		else:
			if(cookie_grid[checking][linePos].get_color()!=goalColor):
				incomplete.append(checking)
				
	return incomplete


func ai_set_line_typepos():
	ai_line_type =  LineType.COLUMN if randi()%2 else LineType.ROW 
	ai_line_pos = randi() % 5

var ai_anchor_x
var ai_anchor_y

func do_ai_steps():
	if not animation_in_progress():
		#ai_completing_color = 0
		if(ai_completing_color==-1):
			ai_completing_color = select_possible_color()
			
		#ai_set_line_typepos()
		var to_get_in_place = get_incomplete_in_line(ai_line_type, ai_line_pos, ai_completing_color)
		#TODO somehow this ^ is possible to return empty, not sure how a line could
		#be complete and not be detected, and it is very rare
		
		#select the color and linepos to complete
		var piece_y=-1
		var piece_x=-1
		# find a piece to move
		var found = false
		for r in range(BOARD_SIZE):
			if(found):
				break
			if(ai_line_type==LineType.COLUMN) and ai_line_pos==r: #skip if its the one we're solving
				continue 
			for c in range(BOARD_SIZE):
				if(ai_line_type==LineType.ROW) and ai_line_pos==c: #skip if its the one we're solving
					continue 
				if cookie_grid[r][c].get_color()==ai_completing_color:
					piece_y = c
					piece_x = r
					found = true
					break
		
		#set the anchor
		if(ai_line_type==LineType.ROW):
			ai_anchor_x = to_get_in_place[0]
			ai_anchor_y = piece_y
		else:
			ai_anchor_x = piece_x
			ai_anchor_y = to_get_in_place[0]
			
		#set the cursor to the anchor position
		var cursor = find_node("cursor")
		

		if(ai_line_type==LineType.ROW):
			cursor.position.x = (to_get_in_place[0])*64 #todo delay for cursor?
			cursor.position.y = (piece_y)*64
			var countInCol = get_incomplete_in_line(LineType.COLUMN,ai_anchor_x,ai_completing_color).size()
			if(countInCol==BOARD_SIZE):#if incomplete in row is empty, then move right
				start_line_move(LineType.ROW, LineSign.POSITIVE, ai_anchor_y) #todo let the ai move the optimal direction instead of always positive
			else:
				#move down until piece is in place
				start_line_move(LineType.COLUMN, LineSign.POSITIVE, to_get_in_place[0])
		else:
			cursor.position.y = (to_get_in_place[0])*64 #TODO delay for cursor
			cursor.position.x = (piece_x)*64
			var countInRow = get_incomplete_in_line(LineType.ROW,ai_anchor_y,ai_completing_color).size()
			if(countInRow==BOARD_SIZE):#if incomplete in row is empty, then move right
				start_line_move(LineType.COLUMN, LineSign.POSITIVE, ai_anchor_x)
			else:
				#move down until piece is in place
				start_line_move(LineType.ROW, LineSign.POSITIVE, to_get_in_place[0])


# handles user input and moves the cursor accordingly
func handle_cursor_movement(delta):
	if get_parent().winner != Game.Players.NOONE: #if the game is over
		return
		
	if isAI:
		AI_time_until_move -= delta
		if(AI_time_until_move<=0):
			do_ai_steps()
			AI_time_until_move = AI_delay_seconds
		return
	
	var cursorMoveOffset = 64
	var cursor = find_node("cursor")
	var cookieOffset = 64
	
	if(not is_moving):
		# moving cursor
		if Input.is_action_just_pressed("cursor_up"):
			if cursor.position.y>0:
				cursor.position.y -= cursorMoveOffset
			else:
				cursor.position.y = (BOARD_SIZE-1)*cursorMoveOffset
		if Input.is_action_just_pressed("cursor_down"):
			if cursor.position.y<cookieOffset*(BOARD_SIZE-1):
				cursor.position.y += cursorMoveOffset
			else:
				cursor.position.y = 0
		if Input.is_action_just_pressed("cursor_left"):
			if cursor.position.x>0:
				cursor.position.x -= cursorMoveOffset
			else:
				cursor.position.x = (BOARD_SIZE-1)*cursorMoveOffset
		if Input.is_action_just_pressed("cursor_right"):
			if cursor.position.x<cookieOffset*(BOARD_SIZE-1):
				cursor.position.x += cursorMoveOffset
			else:
				cursor.position.x = 0
	else:
		var selectedRow = cursor.position.y/64
		var selectedCol = cursor.position.x/64
		if Input.is_action_just_pressed("cursor_up"):
			start_line_move(LineType.COLUMN, LineSign.NEGATIVE, selectedCol)
		if Input.is_action_just_pressed("cursor_down"):
			start_line_move(LineType.COLUMN, LineSign.POSITIVE, selectedCol)
		if Input.is_action_just_pressed("cursor_left"):
			start_line_move(LineType.ROW, LineSign.NEGATIVE, selectedRow)
		if Input.is_action_just_pressed("cursor_right"):
			start_line_move(LineType.ROW, LineSign.POSITIVE, selectedRow)

	# handle selection toggle
	var cursor_sprite = find_node("cursor_sprite")

	if Input.is_action_just_pressed("select_move"):
		is_moving = true
		cursor_sprite.texture = cursor_texture_selected
	if Input.is_action_just_released("select_move"):
		is_moving = false
		cursor_sprite.texture = cursor_texture


func do_special_match():
	get_parent().affectOther(get_instance_id())


func add_points(points):
	find_node("health").value+=points


func handle_completed_line(type, pos):
	ai_completing_color = -1
	ai_set_line_typepos()
	
	add_points(5)

	#get the color that was matched
	var completed_color
	if type==LineType.ROW:
		completed_color = cookie_grid[0][pos].get_color()
	else:
		completed_color = cookie_grid[pos][0].get_color()
	
	# replace the completed cookies
	var special_pos = randi() % (BOARD_SIZE-1) 
	if completed_color==Cookie.Colors.GOLD: 
		do_special_match()
		special_pos = -1
		 
	for cur in range(BOARD_SIZE):
		var r = cur if type==LineType.ROW else pos
		var c = cur if type!=LineType.ROW else pos
		
		var color = randi() % 4 if cur!=special_pos else 4
		var current_cookie = cookie_grid[r][c]
		current_cookie.set_color(color)
		current_cookie.find_node("MatchParticles").emitting = true


# Checkes every line and row and if it finds a complete row, it calls 
# handle_completed_line() to take care of it
func handle_line_match_detection():
	for line in range(BOARD_SIZE):
		# detect cols
		var firstColor = cookie_grid[line][0].get_color()
		var matches = true
		for c in range(1,BOARD_SIZE):
			if(cookie_grid[line][c].get_color() != firstColor):
				matches=false
				break
		if matches:
			handle_completed_line(LineType.COLUMN,line)
			
		# detect rows
		firstColor = cookie_grid[0][line].get_color()
		matches = true
		for r in range(1,BOARD_SIZE):
			if(cookie_grid[r][line].get_color() != firstColor):
				matches=false
				break
		if matches:
			handle_completed_line(LineType.ROW,line)
			


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	handle_cursor_movement(delta)

func animation_in_progress():
	for r in range(BOARD_SIZE):
		for c in range(BOARD_SIZE):
			if cookie_grid[r][c].is_animating():
				return true
	return false
