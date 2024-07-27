extends CharacterBody3D

# Player Nodes

@onready var head = $nek/Head
@onready var standing_collision_shape = $standing_Collision_shape 
@onready var crouching_collision_shape = $Crouching_Collision_shape 
@onready var ray_cast_3d = $RayCast3D 
@onready var nek = $nek
@onready var camera_3d = $nek/Head/Camera3D

# Speed Vars

var current_speed = 5.0 

var walking_speed = 5.0 
var sprting_speed = 8.0 
var crouching_speed = 3.0 

# States
var walking = false
var sprinting = false
var crouching = false
var free_looking = false
var sliding = false

# slide vars

var slide_timer = 0.0
var slide_timer_max = 1.0
var slide_vector = Vector2.ZERO
var slide_speed = 10.0

# Movement states

const jump_velocity = 4.5 

var crouching_depth = -0.5 

var lerp_speed = 10.0 

var free_look_tilt_amount = 8

# Input vars

const mouse_sens = 0.4 
var direction = Vector3.ZERO 

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") 

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) 

func _input(event):
	
	if event is InputEventMouse: 
		if free_looking:
			nek.rotate_y(deg_to_rad(-event.relative.x * mouse_sens)) 
			nek.rotation.y = clamp(nek.rotation.y, deg_to_rad(-120), deg_to_rad(120))
		else:
			rotate_y(deg_to_rad(-event.relative.x * mouse_sens))  
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens)) 
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89)) 
		
func _physics_process(delta):
	# getting movement input.
	var input_dir = Input.get_vector("left", "right", "forward", "backwards") 
	# Handle crouching
	if Input.is_action_pressed("crouch"): 
		current_speed = crouching_speed 
		head.position.y = lerp(head.position.y, crouching_depth, delta * lerp_speed) 
		
		standing_collision_shape.disabled = true 
		crouching_collision_shape.disabled = false 
		
		#slide begin
		
		
		if sprinting && input_dir != Vector2.ZERO:
			sliding = true
			slide_timer = slide_timer_max
			slide_vector = input_dir
			free_looking = true
			
		
		sprinting = false
		walking = false
		crouching = true

	elif !ray_cast_3d.is_colliding(): 
		standing_collision_shape.disabled = false 
		crouching_collision_shape.disabled = true 
		head.position.y = lerp(head.position.y, 0.0, delta * lerp_speed) 
		
		if Input.is_action_pressed("sprint"): 
			current_speed = sprting_speed 
			
			sprinting = true
			walking = false
			crouching = false
			
		else:
			current_speed = walking_speed 
			sprinting = false
			walking = true
			crouching = false
	
	# Handle free looking
	if Input.is_action_pressed("free_look") || sliding:
		free_looking = true
		camera_3d.rotation.z = -deg_to_rad(nek.rotation.y*free_look_tilt_amount)
	else:
		free_looking = false
		nek.rotation.y = lerp(nek.rotation.y,0.0,delta*lerp_speed)
		camera_3d.rotation.z = lerp(camera_3d.rotation.z,0.0,delta*lerp_speed)
		
		#handle sliding
		if sliding:
			slide_timer -= delta
			if slide_timer <= 0:
				sliding = false
				free_looking = false

	# Apply gravity if not on the floor
	if not is_on_floor(): 
		velocity.y -= gravity * delta 

	# Handle jumping
	if Input.is_action_just_pressed("jump") and is_on_floor(): 
		velocity.y = jump_velocity 

	# Handle movement and deceleration
	direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * lerp_speed) 
	
	if sliding:
		direction =(transform.basis*Vector3(slide_vector.x,0,slide_vector.y)).normalized()
	
	if direction:
		velocity.x = direction.x * current_speed 
		velocity.z = direction.z * current_speed 
		
		if sliding:
			
			velocity.x = direction.x * slide_timer * slide_speed
			velocity.z = direction.z * slide_timer * slide_speed
			
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed) 
		velocity.z = move_toward(velocity.z, 0, current_speed) 

	move_and_slide() 
