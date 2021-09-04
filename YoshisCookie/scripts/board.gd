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
	get_node("HealthNode").position.x = 100;
	get_node("HealthNode").position.y = 100;


# starts the cookie moving animation
func start_line_move(lineType, lineDirection, linePosition):
	if(moving_animation_progress == 0):
		# save the motion for the animation
		animation_line_type = lineType
		animation_line_direction = lineDirection
		animation_line_position = linePosition
		
		moving_animation_progress=1 #start the animation
		
		print("MOVE: linetype=" + str(lineType) + " linePos=" 
			+ str(linePosition) + " dir=" + str(lineDirection)) 

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


# handles user input and moves the cursor accordingly
func handle_cursor_movement():
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


func handle_completed_line(type, pos):
	print("found " + str(type) + ", " + str(pos))
	
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
		var current_cookie = cookie_grid[r][c];
		current_cookie.find_node("cookie").texture=cookie_colors[color]
		# TODO cookie positions aren't tracked properly, only the sprite is at
		# the apparent position, the node2d is at (0,0), this should be changed
		# for now, this particle thing is a hack to get it working
		current_cookie.find_node("MatchParticles").position.x=current_cookie.find_node("cookie").position.x;
		current_cookie.find_node("MatchParticles").position.y=current_cookie.find_node("cookie").position.y;
		current_cookie.find_node("MatchParticles").emitting = true;


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
			current_cookie.find_node("MatchParticles").position.x=current_cookie.find_node("cookie").position.x;
			current_cookie.find_node("MatchParticles").position.y=current_cookie.find_node("cookie").position.y;
			current_cookie.find_node("MatchParticles").emitting = true;



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	handle_cursor_movement()
	handle_animation_motion()
