extends CharacterBody3D


enum State {
	IDLE,
	WALKING
}


@export_category("Bewegung")
@export var walk_speed: float = 1.0
@export var roam_radius: float = 2.5
@export var arrive_distance: float = 0.1

@export_category("Idle-Zeit")
@export var idle_time_min: float = 1.0
@export var idle_time_max: float = 3.0


@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D


var state: State = State.IDLE
var home_position: Vector3
var target_position: Vector3
var idle_timer: float = 0.0

# Die Blickrichtung wird gespeichert, damit der NPC beim Stehen
# die passende Idle-Animation anzeigen kann.
var facing_direction: String = "down"


func _ready() -> void:
	home_position = global_position
	_start_idle()


func _physics_process(delta: float) -> void:
	# Gravitation
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0.0

	match state:
		State.IDLE:
			_process_idle(delta)

		State.WALKING:
			_process_walking()

	move_and_slide()


func _process_idle(delta: float) -> void:
	# Im Idle-Zustand horizontal vollständig stehen bleiben
	velocity.x = move_toward(velocity.x, 0.0, walk_speed * 8.0)
	velocity.z = move_toward(velocity.z, 0.0, walk_speed * 8.0)

	idle_timer -= delta

	if idle_timer <= 0.0:
		_choose_new_target()


func _process_walking() -> void:
	var difference := target_position - global_position
	difference.y = 0.0

	# Ziel erreicht
	if difference.length() <= arrive_distance:
		_start_idle()
		return

	var direction := difference.normalized()

	velocity.x = direction.x * walk_speed
	velocity.z = direction.z * walk_speed

	_update_walking_animation(direction)


func _choose_new_target() -> void:
	# Zufälliger Winkel und zufällige Entfernung innerhalb des Radius
	var angle := randf_range(0.0, TAU)
	var distance := randf_range(0.5, roam_radius)

	target_position = home_position + Vector3(
		cos(angle) * distance,
		0.0,
		sin(angle) * distance
	)

	state = State.WALKING


func _start_idle() -> void:
	state = State.IDLE
	idle_timer = randf_range(idle_time_min, idle_time_max)

	velocity.x = 0.0
	velocity.z = 0.0

	_play_idle_animation()


func _update_walking_animation(direction: Vector3) -> void:
	if abs(direction.x) > abs(direction.z):
		if direction.x > 0.0:
			facing_direction = "right"
			sprite.play("walking_right")
		else:
			facing_direction = "left"
			sprite.play("walking_left")
	else:
		if direction.z > 0.0:
			facing_direction = "down"
			sprite.play("walking_down")
		else:
			facing_direction = "up"
			sprite.play("walking_up")


func _play_idle_animation() -> void:
	match facing_direction:
		"down":
			sprite.play("down")

		"left":
			sprite.play("left")

		"right":
			sprite.play("right")

		"up":
			sprite.play("up")
