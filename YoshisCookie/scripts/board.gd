extends Node2D

# dynamic textures
var cursor_texture = preload("res://sprites/cursor.png")
var cursor_texture_selected = preload("res://sprites/cursor_selected.png")
var colors = [
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
var cookies=[]
var isMoving = false

#enums
enum type {row, col}
enum direction {pos=1, neg=-1}

#moving animation stuff
var movingAnimationInProgress=0
var animationLineType
var animationLineDirection
var animationLinePosition

# generates the  5x5 grid of cookies
func generateCookies():
	#reset vars
	for _i in range(BOARD_SIZE):
		cookies.append([])
		
	var selectedColors = [0,0,0,0,0] # the count of each color
	
	# generate 5 of each tile randomly placed
	for r in range(BOARD_SIZE):
		for c in range(BOARD_SIZE):
			# create the cookie
			var new_cookie = cookie_template.instance()
			find_node("cookies").add_child(new_cookie)
			cookies[r].append(new_cookie)

			# set cookie position
			new_cookie.get_node("cookie").position.x += r*64
			new_cookie.get_node("cookie").position.y += c*64

			# pick the cookie color
			# TODO, this algorithm is wrong, the cookies can spawn in any
			# amount as long as adding it doesn't complete a row
			var num = randi() % (BOARD_SIZE-1)
			while(selectedColors[num]>BOARD_SIZE+1):
				num = randi() % (BOARD_SIZE-1)

			# set the cookie color
			new_cookie.get_node("cookie").texture=colors[num]
			selectedColors[num]+=1


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	generateCookies()


# starts the cookie moving animation
func startLineMove(lineType, lineDirection, linePosition):
	if(movingAnimationInProgress == 0):
		# save the motion for the animation
		animationLineType = lineType
		animationLineDirection = lineDirection
		animationLinePosition = linePosition
		
		movingAnimationInProgress=1 #start the animation
		
		print("MOVE: linetype=" + str(lineType) + " linePos=" 
			+ str(linePosition) + " dir=" + str(lineDirection)) 

func finishLineMove():
	# end animation
			movingAnimationInProgress = 0
			
			# TODO fix the lack of new cookie. At the begining of the 
			# animation spawn a fake cookie, move it too, then delete it
			
			# update cookies
			if(animationLineType==type.row):
				var posToWrap = 0 if animationLineDirection==direction.neg else BOARD_SIZE-1
				var posToWrapto = 0 if animationLineDirection==direction.pos else BOARD_SIZE-1
				
				var tempCookie = cookies[posToWrap][animationLinePosition]
				if(animationLineDirection==direction.pos): # if row positive
					for curCookie in range(BOARD_SIZE-2, -1, -1):
						cookies[curCookie+1][animationLinePosition] = cookies[curCookie][animationLinePosition]
				else: # if row negative
					for curCookie in range(0, BOARD_SIZE-1, 1):
						cookies[curCookie][animationLinePosition] = cookies[curCookie+1][animationLinePosition]
				cookies[posToWrapto][animationLinePosition] = tempCookie
				
				# wrap real edge cookie
				tempCookie.get_node("cookie").position.x -= 64*BOARD_SIZE*animationLineDirection
			else: #columns
				var posToWrap = 0 if animationLineDirection==direction.neg else BOARD_SIZE-1
				var posToWrapto = 0 if animationLineDirection==direction.pos else BOARD_SIZE-1
				
				var tempCookie = cookies[animationLinePosition][posToWrap]
				if(animationLineDirection==direction.pos): # if col positive
					for curCookie in range(BOARD_SIZE-2, -1, -1):
						cookies[animationLinePosition][curCookie+1] = cookies[animationLinePosition][curCookie]
				else: # if col negative
					for curCookie in range(0, BOARD_SIZE-1, 1):
						cookies[animationLinePosition][curCookie] = cookies[animationLinePosition][curCookie+1]
				cookies[animationLinePosition][posToWrapto] = tempCookie
				
				# wrap real edge cookie
				tempCookie.get_node("cookie").position.y -= 64*BOARD_SIZE*animationLineDirection
				


# controls the moving animations and moves the cookies
func handleAnimationMotion():
	if movingAnimationInProgress != 0:
		if movingAnimationInProgress == 5: # if animation should end
			finishLineMove()
		else: # if an animation is progress
			movingAnimationInProgress += 1
			for i in range(BOARD_SIZE):
				if animationLineType==type.col:
					var r = animationLinePosition
					var c = i
					cookies[r][c].get_node("cookie").position.y+=16 * animationLineDirection
				else:
					var r = i
					var c = animationLinePosition
					cookies[r][c].get_node("cookie").position.x+=16 * animationLineDirection


# handles user input and moves the cursor accordingly
func handleCursorMovement():
	var cursorMoveOffset = 64
	var cursor = find_node("cursor")
	var cookieOffset = 64
	
	if(not isMoving):
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
			startLineMove(type.col, direction.neg, selectedCol)
		if Input.is_action_just_pressed("cursor_down"):
			startLineMove(type.col, direction.pos, selectedCol)
		if Input.is_action_just_pressed("cursor_left"):
			startLineMove(type.row, direction.neg, selectedRow)
		if Input.is_action_just_pressed("cursor_right"):
			startLineMove(type.row, direction.pos, selectedRow)

	# handle selection toggle
	var cursor_sprite = find_node("cursor_sprite")

	if Input.is_action_just_pressed("select_move"):
		isMoving = true
		cursor_sprite.texture = cursor_texture_selected
	if Input.is_action_just_released("select_move"):
		isMoving = false
		cursor_sprite.texture = cursor_texture


func handleCompletedLine(lineType, linePos):
	print("found " + str(lineType) + ", " + str(linePos))#TODO do something when there is a match


# Checkes every line and row and if it finds a complete row, it calls 
# handleCompletedLine() to take care of it
#TODO this doesn't need to be called every frame, only after a move
#TODO write detection
func handleLineMatchDetection():
	for line in range(BOARD_SIZE):
		# detect cols
		#TODO dont use the texutre to determine the type of cookie
		var firstColor = cookies[line][0].find_node("cookie").texture
		var matches = true
		for c in range(1,BOARD_SIZE):
			if(cookies[line][c].find_node("cookie").texture != firstColor):
				matches=false
				break
		if matches:
			handleCompletedLine(type.col,line)
			
		# detect rows
		firstColor = cookies[0][line].find_node("cookie").texture
		matches = true
		for r in range(1,BOARD_SIZE):
			if(cookies[r][line].find_node("cookie").texture != firstColor):
				matches=false
				break
		if matches:
			handleCompletedLine(type.row,line)
			


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	handleCursorMovement()
	handleAnimationMotion()
	handleLineMatchDetection()
