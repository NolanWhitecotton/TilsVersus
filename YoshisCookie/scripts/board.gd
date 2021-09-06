extends Node2D

# dynamic textures
var cursor_texture = preload("res://sprites/cursor.png")
var cursor_texture_selected = preload("res://sprites/cursor_selected.png")
var cookie_colors = [
	preload("res://sprites/blue.png"),
	preload("res://sprites/purple.png"),
	preload("res://sprites/red.png"),
	preload("res://sprites/white.png"),
	preload("res://sprites/gold.png")
	]

# scenes
var cookie_template = preload("res://scenes/cookie.tscn")

# globals
const BOARD_SIZE = 5
var cookie_grid=[]
var is_moving = false
export var health_x_offset = 0
export var isAI = false

#enums
enum LineType {ROW, COLUMN}
enum LineSign {POSITIVE=1, NEGATIVE=-1}

#moving animation stuff
var moving_animation_progress=0
var animation_line_type
var animation_line_direction
var animation_line_position

# generates the 5x5 grid of cookies
func generate_cookie_grid():
	#reset vars
	for _i in range(BOARD_SIZE):
		cookie_grid.append([])
		
	var selectedColors = [0,0,0,0,0] # the count of each color
	
	# generate 5 of each tile randomly placed
	for r in range(BOARD_SIZE):
		for c in range(BOARD_SIZE):
			# create the cookie
			var new_cookie = cookie_template.instance()
			find_node("cookies").add_child(new_cookie)
			cookie_grid[r].append(new_cookie)

			# set cookie position
			new_cookie.get_node("cookie").position.x += r*64
			new_cookie.get_node("cookie").position.y += c*64

			# pick the cookie color
			# TODO, this algorithm is wrong, the cookies can spawn in any
			# amount as long as adding it doesn't complete a row
			var num = randi() % 4
			while(selectedColors[num]>BOARD_SIZE+1):
				num = randi() % 4

			# set the cookie color
			new_cookie.get_node("cookie").texture=cookie_colors[num]
			selectedColors[num]+=1


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	generate_cookie_grid()
	find_node("health").margin_left = health_x_offset
	find_node("health").margin_right = health_x_offset


# starts the cookie moving animation
func start_line_move(lineType, lineDirection, linePosition):
	if(moving_animation_progress == 0):
		# save the motion for the animation
		animation_line_type = lineType
		animation_line_direction = lineDirection
		animation_line_position = linePosition
		
		moving_animation_progress=1 #start the animation
		
		#print("MOVE: linetype=" + str(lineType) + " linePos=" 
		#	+ str(linePosition) + " dir=" + str(lineDirection)) 

func finish_line_move():
	# end animation
	moving_animation_progress = 0
	
	# TODO fix the lack of new cookie. At the begining of the 
	# animation spawn a fake cookie, move it too, then delete it
	
	# update cookies
	var posToWrap = 0 if animation_line_direction==LineSign.NEGATIVE else BOARD_SIZE-1
	var posToWrapto = 0 if animation_line_direction==LineSign.POSITIVE else BOARD_SIZE-1
	
	if(animation_line_type==LineType.ROW):
		var tempCookie = cookie_grid[posToWrap][animation_line_position]
		if(animation_line_direction==LineSign.POSITIVE): # if row positive
			for curCookie in range(BOARD_SIZE-2, -1, -1):
				cookie_grid[curCookie+1][animation_line_position] = cookie_grid[curCookie][animation_line_position]
		else: # if row negative
			for curCookie in range(0, BOARD_SIZE-1, 1):
				cookie_grid[curCookie][animation_line_position] = cookie_grid[curCookie+1][animation_line_position]
		cookie_grid[posToWrapto][animation_line_position] = tempCookie
		
		# wrap real edge cookie
		tempCookie.get_node("cookie").position.x -= 64*BOARD_SIZE*animation_line_direction
	else: #columns
		var tempCookie = cookie_grid[animation_line_position][posToWrap]
		if(animation_line_direction==LineSign.POSITIVE): # if col positive
			for curCookie in range(BOARD_SIZE-2, -1, -1):
				cookie_grid[animation_line_position][curCookie+1] = cookie_grid[animation_line_position][curCookie]
		else: # if col negative
			for curCookie in range(0, BOARD_SIZE-1, 1):
				cookie_grid[animation_line_position][curCookie] = cookie_grid[animation_line_position][curCookie+1]
		cookie_grid[animation_line_position][posToWrapto] = tempCookie
		
		# wrap real edge cookie
		tempCookie.get_node("cookie").position.y -= 64*BOARD_SIZE*animation_line_direction
		
	# check for match
	handle_line_match_detection()
				


# controls the moving animations and moves the cookies
func handle_animation_motion():
	if moving_animation_progress != 0:
		if moving_animation_progress == 5: # if animation should end
			finish_line_move()
		else: # if an animation is progress
			moving_animation_progress += 1
			for i in range(BOARD_SIZE):
				if animation_line_type==LineType.COLUMN:
					var r = animation_line_position
					var c = i
					cookie_grid[r][c].get_node("cookie").position.y+=16 * animation_line_direction
				else:
					var r = i
					var c = animation_line_position
					cookie_grid[r][c].get_node("cookie").position.x+=16 * animation_line_direction


func get_all_possible_colors():
	var possible = []
	
	for testing in range(5):# for every color
		var count = 0
		for r in range(BOARD_SIZE):#for every place on the board
			for c in range(BOARD_SIZE):
				if (cookie_grid[r][c].find_node("cookie").texture==cookie_colors[testing]):
					count += 1
		if count >= 5:
			possible.append(testing)
			
	print(possible)
	return possible


func select_possible_color():
	var valid_colors = get_all_possible_colors()
	var selecting = valid_colors[randi() % valid_colors.size()]
	print("selecting=" + str(selecting))
	return selecting



var ai_completing_color = -1
var ai_line_type
var ai_line_pos


func get_incomplete_in_line(var lineType, var linePos, var goalColor):
	var incomplete = []
	for checking in range(5):
		if lineType==LineType.COLUMN:
			if(cookie_grid[linePos][checking].find_node("cookie").texture!=cookie_colors[goalColor]):
				incomplete.append(checking)
		else:
			if(cookie_grid[checking][linePos].find_node("cookie").texture!=cookie_colors[goalColor]):
				incomplete.append(checking)
				
	return incomplete


func ai_set_line_typepos():
	# TODO this is called every frame, call it only when
	# the new line color is picked, probably put it in the line completion area
	# so that the AI doesnt pick a new row every frame
	ai_line_type =  LineType.ROW
	ai_line_pos = 0
	#ai_line_pos = randi() % 5
	#TODO make AI calculated and not hardcoded
	#TODO make AI  work on columns not just rows

var ai_anchor_x
var ai_anchor_y

func do_ai_steps():
	if moving_animation_progress == 0:
		#ai_completing_color = 0
		if(ai_completing_color==-1):
			ai_completing_color = select_possible_color()
			
		ai_set_line_typepos()	
		var to_get_in_place = get_incomplete_in_line(ai_line_type, ai_line_pos, ai_completing_color);
		#select the color and linepos to complete

		var piece_y=-1;
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
				if cookie_grid[r][c].find_node("cookie").texture==cookie_colors[ai_completing_color]:
					piece_y = c
					found = true
					break
		
		#set the anchor
		if(ai_line_type==LineType.ROW):#TODO cols
			ai_anchor_x = to_get_in_place[0]
			ai_anchor_y = piece_y
			
		#set the cursor to the anchor position
		var cursor = find_node("cursor")
		cursor.position.x = (to_get_in_place[0])*64
		cursor.position.y = (piece_y)*64
		
		
		var countInCol = get_incomplete_in_line(LineType.COLUMN,ai_anchor_x,ai_completing_color).size()
		if(countInCol==BOARD_SIZE):#if incomplete in row is empty, then move right
			start_line_move(LineType.ROW, LineSign.POSITIVE, ai_anchor_y)
		else:
			#move down until piece is in place
			start_line_move(LineType.COLUMN, LineSign.POSITIVE, to_get_in_place[0])


# handles user input and moves the cursor accordingly
func handle_cursor_movement():
	#todo comparing an enum to and int for no reason
	if get_parent().winner != 0: #if the game is over
		return
		
	if isAI:
		do_ai_steps()
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
				cursor.position.y = (BOARD_SIZE-1)*64
		if Input.is_action_just_pressed("cursor_down"):
			if cursor.position.y<cookieOffset*(BOARD_SIZE-1):
				cursor.position.y += cursorMoveOffset
			else:
				cursor.position.y = 0
		if Input.is_action_just_pressed("cursor_left"):
			if cursor.position.x>0:
				cursor.position.x -= cursorMoveOffset
			else:
				cursor.position.x = (BOARD_SIZE-1)*64
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
	print("Special match!") 



func add_points(points):
	find_node("health").value+=points


func handle_completed_line(type, pos):
	ai_completing_color = -1
	print("line completed")
	
	add_points(5)

	#get the color that was matched
	var completed_color
	if type==LineType.ROW:
		completed_color = cookie_grid[0][pos].find_node("cookie").texture
	else:
		completed_color = cookie_grid[pos][0].find_node("cookie").texture
	
	# replace the completed cookies
	var special_pos = randi() % (BOARD_SIZE-1) 
	if completed_color==cookie_colors[4]: 
		do_special_match()
		special_pos = -1
		 
	for cur in range(BOARD_SIZE):
		var r = cur if type==LineType.ROW else pos
		var c = cur if type!=LineType.ROW else pos
		
		var color = randi() % 4 if cur!=special_pos else 4
		var current_cookie = cookie_grid[r][c]
		current_cookie.find_node("cookie").texture=cookie_colors[color]
		# TODO cookie positions aren't tracked properly, only the sprite is at
		# the apparent position, the node2d is at (0,0), this should be changed
		# for now, this particle thing is a hack to get it working
		current_cookie.find_node("MatchParticles").position.x=current_cookie.find_node("cookie").position.x
		current_cookie.find_node("MatchParticles").position.y=current_cookie.find_node("cookie").position.y
		current_cookie.find_node("MatchParticles").emitting = true


# Checkes every line and row and if it finds a complete row, it calls 
# handle_completed_line() to take care of it
func handle_line_match_detection():
	for line in range(BOARD_SIZE):
		# detect cols
		#TODO dont use the texture to determine the type of cookie
		var firstColor = cookie_grid[line][0].find_node("cookie").texture
		var matches = true
		for c in range(1,BOARD_SIZE):
			if(cookie_grid[line][c].find_node("cookie").texture != firstColor):
				matches=false
				break
		if matches:
			handle_completed_line(LineType.COLUMN,line)
			
		# detect rows
		firstColor = cookie_grid[0][line].find_node("cookie").texture
		matches = true
		for r in range(1,BOARD_SIZE):
			if(cookie_grid[r][line].find_node("cookie").texture != firstColor):
				matches=false
				break
		if matches:
			handle_completed_line(LineType.ROW,line)
			


func test_particles():
	for r in range(BOARD_SIZE):
		for c in range(BOARD_SIZE):
			var current_cookie = cookie_grid[r][c]
			# TODO cookie positions aren't tracked properly, only the sprite is at
			# the apparent position, the node2d is at (0,0), this should be changed
			# for now, this particle thing is a hack to get it working
			current_cookie.find_node("MatchParticles").position.x=current_cookie.find_node("cookie").position.x
			current_cookie.find_node("MatchParticles").position.y=current_cookie.find_node("cookie").position.y
			current_cookie.find_node("MatchParticles").emitting = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	handle_cursor_movement()
	handle_animation_motion()
	
	# TODO remove this, this should only happen on _ready, this is for debugging
	find_node("health").margin_left = health_x_offset
	find_node("health").margin_right = health_x_offset

