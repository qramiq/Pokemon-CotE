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


@export_category("Kollision")
@export var collision_pause_time: float = 0.75


@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D


var state: State = State.IDLE

var home_position: Vector3
var target_position: Vector3
var idle_timer: float = 0.0
var collision_pause_timer: float = 0.0

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


	# Nach einer Kollision kurz stehen bleiben
	if collision_pause_timer > 0.0:
		collision_pause_timer -= delta

		velocity.x = 0.0
		velocity.z = 0.0

		_play_idle_animation()

		move_and_slide()
		return


	# Aktuellen Zustand verarbeiten
	match state:
		State.IDLE:
			_process_idle(delta)

		State.WALKING:
			_process_walking()


	# NPC bewegen
	move_and_slide()


	# Kollision nach der Bewegung prüfen
	if state == State.WALKING and get_slide_collision_count() > 0:
		for index in range(get_slide_collision_count()):
			var collision := get_slide_collision(index)
			var collider := collision.get_collider()

			# Nur auf andere CharacterBody3D reagieren,
			# zum Beispiel auf den Spieler
			if collider is CharacterBody3D:
				_stop_after_collision()
				break


func _process_idle(delta: float) -> void:
	# Horizontale Bewegung abbremsen
	velocity.x = move_toward(
		velocity.x,
		0.0,
		walk_speed * 8.0 * delta
	)

	velocity.z = move_toward(
		velocity.z,
		0.0,
		walk_speed * 8.0 * delta
	)


	# Idle-Zeit herunterzählen
	idle_timer -= delta


	# Nach der Pause ein neues Ziel wählen
	if idle_timer <= 0.0 and collision_pause_timer <= 0.0:
		_choose_new_target()


func _process_walking() -> void:
	var difference := target_position - global_position

	# Nur auf der X-/Z-Ebene bewegen
	difference.y = 0.0


	# Ziel erreicht
	if difference.length() <= arrive_distance:
		_start_idle()
		return


	# Richtung zum Ziel berechnen
	var direction := difference.normalized()

	velocity.x = direction.x * walk_speed
	velocity.z = direction.z * walk_speed

	# Passende Laufanimation abspielen
	_update_walking_animation(direction)


func _choose_new_target() -> void:
	# Zufälligen Winkel auswählen
	var angle := randf_range(0.0, TAU)

	# Zufällige Entfernung innerhalb des Radius
	var distance := randf_range(0.5, roam_radius)

	# Neues Ziel rund um die Startposition setzen
	target_position = home_position + Vector3(
		cos(angle) * distance,
		0.0,
		sin(angle) * distance
	)

	state = State.WALKING


func _start_idle() -> void:
	state = State.IDLE

	# Zufällige Wartezeit setzen
	idle_timer = randf_range(
		idle_time_min,
		idle_time_max
	)

	# Bewegung stoppen
	velocity.x = 0.0
	velocity.z = 0.0

	# Idle-Animation abspielen
	_play_idle_animation()


func _stop_after_collision() -> void:
	state = State.IDLE

	# Kollisionspause starten
	collision_pause_timer = collision_pause_time

	# NPC sofort stoppen
	velocity.x = 0.0
	velocity.z = 0.0

	# Nach der Kollisionspause nicht direkt wieder loslaufen
	idle_timer = collision_pause_time

	# Idle-Animation abspielen
	_play_idle_animation()


func _update_walking_animation(direction: Vector3) -> void:
	# Bewegung hauptsächlich nach links oder rechts
	if abs(direction.x) > abs(direction.z):
		if direction.x > 0.0:
			facing_direction = "right"
			sprite.play("walking_right")
		else:
			facing_direction = "left"
			sprite.play("walking_left")


	# Bewegung hauptsächlich nach oben oder unten
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


func interact(player: CharacterBody3D) -> void:
	# NPC anhalten
	state = State.IDLE
	velocity.x = 0.0
	velocity.z = 0.0

	# NPC zum Spieler drehen
	_face_player(player)

	# Vorläufige Testausgabe
	print("NPC wurde angesprochen!")


func _face_player(player: CharacterBody3D) -> void:
	var difference := player.global_position - global_position

	# Höhe ignorieren
	difference.y = 0.0


	# Falls Spieler exakt auf derselben Position steht
	if difference.length() == 0.0:
		return


	# Prüfen, ob Spieler eher links/rechts oder oben/unten steht
	if abs(difference.x) > abs(difference.z):
		if difference.x > 0.0:
			facing_direction = "right"
		else:
			facing_direction = "left"
	else:
		if difference.z > 0.0:
			facing_direction = "down"
		else:
			facing_direction = "up"


	# Passende Idle-Animation abspielen
	_play_idle_animation()
