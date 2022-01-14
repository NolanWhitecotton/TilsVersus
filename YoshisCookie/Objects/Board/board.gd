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
onready var cursor = find_node("cursor")
var AI_handler

#enums
enum LineType {ROW, COLUMN}
enum LineSign {POSITIVE=1, NEGATIVE=-1}

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
	
	AI_handler = load("res://Objects/Board/AI_handler.gd").new(self)


# starts the cookie moving animation
func start_line_move(lineType, lineDirection, linePosition):
	for i in range(BOARD_SIZE):
		var wrap
		if lineDirection == LineSign.POSITIVE:
			wrap = i==BOARD_SIZE-1
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
	
	# update cookies position in cookie_grid
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


# handles user input and moves the cursor accordingly
func handle_cursor_movement(delta):
	if get_parent().winner != Game.Players.NOONE: #if the game is over
		return
		
	if isAI:
		AI_handler.move_cursor(delta)
	
	var cursorMoveOffset = 64
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
		if not animation_in_progress():
			var selectedRow = cursor.position.y/64
			var selectedCol = cursor.position.x/64
			if Input.is_action_just_pressed("cursor_up"):
				start_line_move(LineType.COLUMN, LineSign.NEGATIVE, selectedCol)
			elif Input.is_action_just_pressed("cursor_down"):
				start_line_move(LineType.COLUMN, LineSign.POSITIVE, selectedCol)
			elif Input.is_action_just_pressed("cursor_left"):
				start_line_move(LineType.ROW, LineSign.NEGATIVE, selectedRow)
			elif Input.is_action_just_pressed("cursor_right"):
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
	if isAI:
		AI_handler.handle_completion()
	
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
		
	# check to see if the randomly generated cookies creates a match
	handle_line_match_detection()


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
