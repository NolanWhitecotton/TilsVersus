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
const boardSize = 5;
var isMoving = false;
var cookies=[];

func generateCookies():
	#reset vars
	for i in range(boardSize):
		cookies.append([]);
		
	var selectedColors = [0,0,0,0,0] # the count of each color
	
	# generate 5 of each tile randomly placed
	for x in range(boardSize): #TODO replace x, y with r, c
		for y in range(boardSize):
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
			var num = randi() % (boardSize-1);
			while(selectedColors[num]>boardSize+1):
				num = randi() % (boardSize-1);

			# set the cookie color
			new_cookie.get_node("cookie").texture=colors[num];
			selectedColors[num]+=1;


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize();
	generateCookies();


enum lineType {row, col}
enum direction {pos, neg}
func rotateCookieLine(lineType, linePosition, direction):
	#todo this might need a delta
	# spawn a decoy of the same color as the one that is going to wrapped
	
	# start moving the cookies in the propper direction
	
	# once the animation is done wrap the propper cookie to the other side
	
	# delete the decoy cookie
	print("MOVE: linetype=" + str(lineType) + " linePos=" + str(linePosition) + " dir=" + str(direction)); 


func handleCursorMovement():
	var cursorMoveOffset = 64;
	var cursor = find_node("cursor");
	var cookieOffset = 64;
	
	if(not isMoving):
		# moving cursor
		if Input.is_action_just_pressed("cursor_up") and cursor.position.y>0:
			cursor.position.y -= cursorMoveOffset;
		if Input.is_action_just_pressed("cursor_down") and cursor.position.y<cookieOffset*(boardSize-1):
			cursor.position.y += cursorMoveOffset;
		if Input.is_action_just_pressed("cursor_left") and cursor.position.x>0:
			cursor.position.x -= cursorMoveOffset;
		if Input.is_action_just_pressed("cursor_right") and cursor.position.x<cookieOffset*(boardSize-1):
			cursor.position.x += cursorMoveOffset;
	else:
		var selectedRow = 0; # todo calculate selected row
		var selectedCol = 0;
		if Input.is_action_just_pressed("cursor_up"):
			rotateCookieLine(lineType.col, direction.neg, selectedCol);
		if Input.is_action_just_pressed("cursor_down"):
			rotateCookieLine(lineType.col, direction.pos, selectedCol);
		if Input.is_action_just_pressed("cursor_left"):
			rotateCookieLine(lineType.row, direction.neg, selectedRow);
		if Input.is_action_just_pressed("cursor_right"):
			rotateCookieLine(lineType.row, direction.pos, selectedRow);

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
