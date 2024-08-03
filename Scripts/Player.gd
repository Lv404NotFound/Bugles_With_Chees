extends CharacterBody3D

# Player Nodes

@onready var head = $nek/Head # Reference to the player's head node
@onready var standing_collision_shape = $standing_Collision_shape # Reference to the standing collision shape
@onready var crouching_collision_shape = $Crouching_Collision_shape # Reference to the crouching collision shape
@onready var ray_cast_3d = $RayCast3D # Reference to the RayCast3D node for detecting collisions
@onready var ray_cast_3d_climbing = $RayCast3DClimbing # Reference to the RayCast3D node for detecting climbable surfaces
@onready var nek = $nek # Reference to the player's neck node
@onready var camera_3d = $nek/Head/eyes/Camera3D
@onready var eyes = $nek/Head/eyes
@onready var animation_player = $nek/Head/eyes/AnimationPlayer

# Speed Vars
var current_speed = 5.0 # Variable to store the current speed of the player

var walking_speed = 5.0 # Speed when the player is walking
var sprinting_speed = 8.0 # Speed when the player is sprinting
var crouching_speed = 3.0 # Speed when the player is crouching
var climbing_speed = 3.0 # Speed when the player is climbing

# States
var walking = false
var sprinting = false
var crouching = false
var free_looking = false
var sliding = false
var climbing = false # New state for climbing

# Slide vars
var slide_timer = 0.0
var slide_timer_max = 1.0
var slide_vector = Vector2.ZERO
var slide_speed = 10.0

# head bobbing vars
const head_bobbing_Sprinting_speed = 22.0
const head_bobbing_walking_speed = 14.0
const head_bobbing_crouching_speed = 10.0

const head_bobbing_Sprinting_intensity = 0.02
const head_bobbing_walking_intensity = 0.1
const head_bobbing_crouching_intensity = 0.05

var head_bobbing_vector = Vector2.ZERO
var head_bobbing_index = 0.0
var head_bobbing_current_intensity = 0.0

# Movement states
const jump_velocity = 4.5 # Velocity applied when the player jumps

var crouching_depth = -0.5 # Depth to which the player crouches

var lerp_speed = 10.0 # Speed at which the interpolation happens
var air_lerp_speed = 3.0

var free_look_tilt_amount = 8 # Amount of tilt when free looking

var last_velocity = Vector3.ZERO

# Input vars
const mouse_sens = 0.4 # Mouse sensitivity
var direction = Vector3.ZERO # Direction vector for player movement

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") # Gravity value from project settings

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) # Capture the mouse for first-person movement

func _input(event):
	if event is InputEventMouse: # Check if the event is a mouse event
		if free_looking:
			nek.rotate_y(deg_to_rad(-event.relative.x * mouse_sens)) # Rotate the neck horizontally based on mouse movement
			nek.rotation.y = clamp(nek.rotation.y, deg_to_rad(-120), deg_to_rad(120)) # Clamp the neck rotation to prevent over-rotation
		else:
			rotate_y(deg_to_rad(-event.relative.x * mouse_sens)) # Rotate the player horizontally based on mouse movement
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens)) # Rotate the head vertically based on mouse movement
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89)) # Clamp the head rotation to prevent over-rotation

func _physics_process(delta):
	# Getting movement input.
	var input_dir = Input.get_vector("left", "right", "forward", "backwards") # Get the input direction vector

	# Handle crouching
	if Input.is_action_pressed("crouch") or sliding: # Check if the crouch action is pressed or the player is sliding
		current_speed = crouching_speed # Set the current speed to crouching speed
		head.position.y = lerp(head.position.y, crouching_depth, delta * lerp_speed) # Smoothly transition the head position to the crouching position

		standing_collision_shape.disabled = true # Disable the standing collision shape
		crouching_collision_shape.disabled = false # Enable the crouching collision shape

		# Slide begin
		if sprinting and input_dir != Vector2.ZERO:
			sliding = true
			slide_timer = slide_timer_max
			slide_vector = input_dir
			free_looking = true

		sprinting = false
		walking = false
		crouching = true

	elif !ray_cast_3d.is_colliding(): # Check if the RayCast3D is not colliding
		standing_collision_shape.disabled = false # Enable the standing collision shape
		crouching_collision_shape.disabled = true # Disable the crouching collision shape
		head.position.y = lerp(head.position.y, 0.0, delta * lerp_speed) # Smoothly transition the head position back to the standing position

		if Input.is_action_pressed("sprint"): # Check if the sprint action is pressed
			current_speed = sprinting_speed # Set the current speed to sprinting speed

			sprinting = true
			walking = false
			crouching = false

		else:
			current_speed = walking_speed # Set the current speed to walking speed
			sprinting = false
			walking = true
			crouching = false

	# Handle free looking
	if Input.is_action_pressed("free_look") or sliding:
		free_looking = true

		if sliding:
			eyes.rotation.z = lerp(eyes.rotation.z,-deg_to_rad(7.0),delta*lerp_speed)
		else:
			eyes.rotation.z = -deg_to_rad(nek.rotation.y * free_look_tilt_amount)
	else:
		free_looking = false
		nek.rotation.y = lerp(nek.rotation.y, 0.0, delta * lerp_speed)
		eyes.rotation.z = lerp(eyes.rotation.z, 0.0, delta * lerp_speed)

	# Handle sliding
	if sliding:
		slide_timer -= delta
		if slide_timer <= 0:
			sliding = false
			free_looking = false

	# Handle head bobbing
	if sprinting:
		head_bobbing_current_intensity = head_bobbing_Sprinting_intensity
		head_bobbing_index += head_bobbing_Sprinting_speed * delta
	elif walking:
		head_bobbing_current_intensity = head_bobbing_walking_intensity
		head_bobbing_index += head_bobbing_walking_speed * delta
	elif crouching:
		head_bobbing_current_intensity = head_bobbing_crouching_intensity
		head_bobbing_index += head_bobbing_crouching_speed * delta

	if is_on_floor() && !sliding && input_dir != Vector2.ZERO:
		head_bobbing_vector.y = sin(head_bobbing_index)
		head_bobbing_vector.x = sin(head_bobbing_index/2)+0.5

		eyes.position.y = lerp(eyes.position.y, head_bobbing_vector.y*(head_bobbing_current_intensity/2.0), delta*lerp_speed)
		eyes.position.x = lerp(eyes.position.x, head_bobbing_vector.x*head_bobbing_current_intensity, delta*lerp_speed)

	else:
		eyes.position.y = lerp(eyes.position.y, 0.0, delta*lerp_speed)
		eyes.position.x = lerp(eyes.position.x, 0.0, delta*lerp_speed)

	# Apply gravity if not on the floor
	if not is_on_floor(): 
		velocity.y -= gravity * delta 

	# Handle jumping
	if Input.is_action_just_pressed("jump") and is_on_floor(): 
		velocity.y = jump_velocity 
		sliding = false
		animation_player.play("jumping")

	# Landing
	if is_on_floor():
		if last_velocity.y < -10.0:
			animation_player.play("Roll")
		elif last_velocity.y < -4.0:
			animation_player.play("Landing")

	# Handle movement and deceleration
	if is_on_floor():
		direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * lerp_speed) 
	else:
		direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * air_lerp_speed) 
	if sliding:
		if input_dir != Vector2.ZERO:
			direction = (transform.basis * Vector3(slide_vector.x, 0, slide_vector.y)).normalized()

	if direction:
		velocity.x = direction.x * current_speed 
		velocity.z = direction.z * current_speed 

		if sliding:
			velocity.x = direction.x * (slide_timer + 0.1) * slide_speed
			velocity.z = direction.z * (slide_timer + 0.1) * slide_speed

	else:
		velocity.x = move_toward(velocity.x, 0, current_speed) 
		velocity.z = move_toward(velocity.z, 0, current_speed) 

	# Handle wall climbing
	if ray_cast_3d_climbing and ray_cast_3d_climbing.is_colliding() and Input.is_action_pressed("climb"):
		climbing = true
	else:
		climbing = false

	if climbing:
		velocity = Vector3.ZERO
		direction = Vector3.ZERO
		velocity.y = climbing_speed

	last_velocity = velocity
	move_and_slide()
