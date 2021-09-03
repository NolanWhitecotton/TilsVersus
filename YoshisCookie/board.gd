extends Node2D

# dynamic textures
var cursor_texture = preload("res://sprites/cursor.png");
var cursor_texture_selected = preload("res://sprites/cursor_selected.png");
var colors = [
	preload("res://sprites/blue.png"),
	preload("res://sprites/purple.png"),
	preload("res://sprites/red.png"),
	preload("res://sprites/white.png"),
	preload("res://sprites/gold.png")
	]

# scenes
var cookie_template = preload("res://scripts/cookie.tscn");

# globals
const BOARD_SIZE = 5;
var cookies=[];
var isMoving = false;

#moving animation stuff
var movingAnimationInProgress=0;
var animationLineType;
var animationLineDirection;
var animationLinePosition;

 
func generateCookies():
	#reset vars
	for i in range(BOARD_SIZE):
		cookies.append([]);
		
	var selectedColors = [0,0,0,0,0] # the count of each color
	
	# generate 5 of each tile randomly placed
	for x in range(BOARD_SIZE): #TODO replace x, y with r, c
		for y in range(BOARD_SIZE):
			# create the cookie
			var new_cookie = cookie_template.instance();
			find_node("cookies").add_child(new_cookie);
			cookies[x].append(new_cookie);

			# set cookie position
			new_cookie.get_node("cookie").position.x += x*64;
			new_cookie.get_node("cookie").position.y += y*64;

			# pick the cookie color
			# TODO, this algorithm is wrong, the cookies can spawn in any
			# amount as long as adding it doesn't complete a row
			var num = randi() % (BOARD_SIZE-1);
			while(selectedColors[num]>BOARD_SIZE+1):
				num = randi() % (BOARD_SIZE-1);

			# set the cookie color
			new_cookie.get_node("cookie").texture=colors[num];
			selectedColors[num]+=1;


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize();
	generateCookies();

enum type {row, col}
enum direction {pos=1, neg=-1}
func rotateCookieLine(lineType, lineDirection, linePosition):
	if(movingAnimationInProgress == 0):
		# save the motion for the animation
		animationLineType = lineType;
		animationLineDirection = lineDirection;
		animationLinePosition = linePosition;
		
		movingAnimationInProgress=1; #start the animation
		
		print("MOVE: linetype=" + str(lineType) + " linePos=" 
			+ str(linePosition) + " dir=" + str(lineDirection)); 

func handleAnimationMotion():
	if movingAnimationInProgress != 0:
		if movingAnimationInProgress == 5: # if animation should end
			# end animation
			movingAnimationInProgress = 0;
			
			if(animationLineType==type.row):
				# TODO generealize this to work on other row and on cols
				# update cookies
				print("temp = " + str(BOARD_SIZE-1))
				var tempCookie = cookies[BOARD_SIZE-1][animationLinePosition];
				for curCookie in range(BOARD_SIZE-2, -1, -1):
					print("Rotating: " + str(curCookie+1) + " = " + str(curCookie))
					cookies[curCookie+1][animationLinePosition] = cookies[curCookie][animationLinePosition];
					
				print("Wrapping: " + str(0) + " = temp")
				cookies[0][animationLinePosition] = tempCookie; #todo make this line check the row
				
				# wrap real edge cookie
				tempCookie.get_node("cookie").position.x -= 64*BOARD_SIZE*animationLineDirection;
					
		else: # if an animation is progress
			print("moving")
			movingAnimationInProgress += 1;
			for i in range(BOARD_SIZE):
				if animationLineType==type.col:
					var r = animationLinePosition;
					var c = i;
					cookies[r][c].get_node("cookie").position.y+=16 * animationLineDirection;
				else:
					var r = i;
					var c = animationLinePosition;
					cookies[r][c].get_node("cookie").position.x+=16 * animationLineDirection;
		#todo this might need a delta
		# spawn a decoy of the same color as the one that is going to wrapped
		
		# start moving the cookies in the propper direction
		
		# once the animation is done wrap the propper cookie to the other side
		
		# delete the decoy cookie


func handleCursorMovement():
	var cursorMoveOffset = 64;
	var cursor = find_node("cursor");
	var cookieOffset = 64;
	
	if(not isMoving):
		# moving cursor
		if Input.is_action_just_pressed("cursor_up") and cursor.position.y>0:
			cursor.position.y -= cursorMoveOffset;
		if Input.is_action_just_pressed("cursor_down") and cursor.position.y<cookieOffset*(BOARD_SIZE-1):
			cursor.position.y += cursorMoveOffset;
		if Input.is_action_just_pressed("cursor_left") and cursor.position.x>0:
			cursor.position.x -= cursorMoveOffset;
		if Input.is_action_just_pressed("cursor_right") and cursor.position.x<cookieOffset*(BOARD_SIZE-1):
			cursor.position.x += cursorMoveOffset;
	else:
		var selectedRow = cursor.position.y/64; # todo calculate selected row
		var selectedCol = cursor.position.x/64;
		if Input.is_action_just_pressed("cursor_up"):
			rotateCookieLine(type.col, direction.neg, selectedCol);
		if Input.is_action_just_pressed("cursor_down"):
			rotateCookieLine(type.col, direction.pos, selectedCol);
		if Input.is_action_just_pressed("cursor_left"):
			rotateCookieLine(type.row, direction.neg, selectedRow);
		if Input.is_action_just_pressed("cursor_right"):
			rotateCookieLine(type.row, direction.pos, selectedRow);

	# handle selection toggle
	var cursor_sprite = find_node("cursor_sprite");

	if Input.is_action_just_pressed("select_move"):
		isMoving = true;
		cursor_sprite.texture = cursor_texture_selected;
	if Input.is_action_just_released("select_move"):
		isMoving = false;
		cursor_sprite.texture = cursor_texture;


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	handleCursorMovement();
	handleAnimationMotion();
