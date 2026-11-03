extends CharacterBody3D

const SPEED = 4.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var target: Node3D 

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var vision_cone: Area3D = $VisionCone
@onready var ray_cast: RayCast3D = $RayCast3D # Siguraduhing may RayCast3D node ka sa loob ng Enemy (nakatutok sa harap/mata)

var player_in_vision_area: bool = false
var can_see_player: bool = false

func _ready():
	# Godot 4 quirk: Kailangan mag-antay ng isang frame para mag-sync ang NavMesh
	await get_tree().physics_frame
	
	target = get_tree().get_first_node_in_group("player")
	if target:
		print("Hinahabol ko si: ", target.name, " sa posisyon na: ", target.global_position)
		
	# I-konekta ang signals mula sa VisionCone Area3D kung wala pa sa Inspector
	if vision_cone:
		vision_cone.body_entered.connect(_on_vision_cone_body_entered)
		vision_cone.body_exited.connect(_on_vision_cone_body_exited)
	
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if target == null:
		return

	# 1. Line of Sight Check gamit ang RayCast3D
	if player_in_vision_area and target:
		# Ituro ang RayCast patungo sa pwesto ng player (hal. sa ulo o katawan)
		ray_cast.target_position = ray_cast.to_local(target.global_position + Vector3(0, 1, 0))
		ray_cast.force_raycast_update()
		
		# Kung ang natamaan ng RayCast ay ang Player at walang pader sa gitna
		if ray_cast.is_colliding() and ray_cast.get_collider() == target:
			can_see_player = true
		else:
			can_see_player = false
	else:
		can_see_player = false

	# 2. Kung nakikita ang player, saka lang hahabulin gamit ang NavAgent
	if can_see_player:
		nav_agent.target_position = target.global_position
		
		var next_path_position = nav_agent.get_next_path_position()
		var direction = global_position.direction_to(next_path_position)
		
		print("Can see player: ", can_see_player)
		
		direction.y = 0 
		direction = direction.normalized()

		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		# Kung hindi nakikita, hihinto muna o babagal ang kalaban
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

# Signals para sa Area3D Vision Cone
func _on_vision_cone_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_vision_area = true
		print("Pumasok ang player sa vision range!")

func _on_vision_cone_body_exited(body: Node3D) -> void:
	if body == target:
		player_in_vision_area = false
		can_see_player = false
		print("Nawala ang player sa vision range.")
