extends KinematicBody2D

var move = Vector2(0,0)
var minimum_move = 2

var wall_jump_distance = 8 # relative to tile-size
var air_jump = 0
var wall_jump = 0
var facing = 0
var aim = 0 # multiply by 45 degrees 


export var Speed = 2048
export var Drag = 8
export var Gravity = 16
export var JumpForce = -512
export var AirJumps = 1
export var WallJumps = 3
export var WallJumpForce = -256

onready var arm = get_node("arm")
onready var weapons = [get_node("arm/gun_normal"), get_node("arm/gun_grenade"),]
export var current_weapon = 0

onready var drop_check = get_node("Drop_Down_Check")

func _input(event):
	# input for falling through 'pass' tiles
	if event.is_action_pressed("aim_down") and drop_check.is_colliding():
		position.y += 1

func update_aim():
	var manual_aim_up = Input.get_action_strength("aim_up_right") - Input.get_action_strength("aim_up_left")
	var manual_aim_down = Input.get_action_strength("aim_down_right") - Input.get_action_strength("aim_down_left")
	var auto_aim = Input.get_action_strength("aim_up") - Input.get_action_strength("aim_down")
	if manual_aim_up:
		aim = int(manual_aim_up)
	elif manual_aim_down:
		aim = int(manual_aim_down)
	# If not manually aiming, figure it out with up and down.
	else: 
		if facing:
			aim = round(facing)*2
			if aim < 0:
				aim += auto_aim
			elif aim > 0:
				aim -= auto_aim
		elif auto_aim:
			aim = (auto_aim-1)*2
	aim = int(aim+8)%8
	
	arm.rotation = deg2rad(aim*45)
	arm.apply_scale(Vector2(1,1))

func update_jump():
	if is_on_floor():
		air_jump = 0
		wall_jump = 0
	if Input.is_action_just_pressed("jump"): 
		var space_state = get_world_2d().direct_space_state
		var to = global_position + Vector2(facing * wall_jump_distance, 0)
		var wall_ray_results = space_state.intersect_ray(global_position, to, [self])
		if is_on_floor():
			pass
		elif len(wall_ray_results) > 0 and wall_jump < WallJumps:
			wall_jump += 1
			move.x += (facing * WallJumpForce)
		elif air_jump < AirJumps:
			air_jump += 1
		else:
			return
		move.y = JumpForce

func _physics_process(delta):
	facing = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	move.x += (Speed * facing) * delta
	move.y += Gravity
	move = move_and_slide(move, Vector2.UP)
	
	update_jump()
	update_aim()
	weapons[current_weapon].update_weapon(delta, aim, Input.get_action_strength("attack_a"))
	
	move.x /= 1+(Drag*delta)
	if abs(move.x) < minimum_move: move.x = 0