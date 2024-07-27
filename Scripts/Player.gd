extends CharacterBody3D

@onready var head = $Head
@onready var standing_collision_shape = $standing_Collision_shape
@onready var crouching_collision_shape = $Crouching_Collision_shape
@onready var ray_cast_3d = $RayCast3D

var current_speed = 5.0

var walking_speed = 5.0
var sprting_speed = 8.0
var crouching_speed = 3.0

const jump_velocity = 4.5

const mouse_sens = 0.4

var lerp_speed = 10.0
var direction = Vector3.ZERO
var crouching_depth = -0.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event):
	if event is InputEventMouse:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
		head.rotation.x = clamp(head.rotation.x,deg_to_rad(-89),deg_to_rad(89))
		
	
	
	
func _physics_process(delta):
	# Add the gravity.
	
	if Input.is_action_pressed("crouch"):
		current_speed = crouching_speed
		head.position.y =lerp(head.position.y,1.8 + crouching_depth, delta * lerp_speed)
		standing_collision_shape.disabled = true
		crouching_collision_shape.disabled = false
		
	elif !ray_cast_3d.is_colliding():
		standing_collision_shape.disabled = false
		crouching_collision_shape.disabled = true
		head.position.y =lerp(head.position.y,1.8, delta * lerp_speed)
		if Input.is_action_pressed("sprint"):
			current_speed = sprting_speed
		else:
					current_speed = walking_speed


	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backwards")
	direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),delta*lerp_speed)
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
