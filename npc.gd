extends CharacterBody3D


enum State {
	IDLE,
	WALKING
}


@export_category("NPC-Identität")
@export var npc_name: String = "Dorfbewohner"

@export_multiline var dialogue_text: String = """Hallo, Trainer!
Willkommen in unserem Dorf.
Ich wünsche dir eine gute Reise!"""


@export_category("Bewegung")
@export var walk_speed: float = 1.0
@export var roam_radius: float = 2.5
@export var arrive_distance: float = 0.1
@export var can_roam: bool = true


@export_category("Idle-Zeit")
@export var idle_time_min: float = 1.0
@export var idle_time_max: float = 3.0


@export_category("Kollision")
@export var collision_pause_time: float = 0.75


@export_category("Interaktion")
@export var interaction_enabled: bool = true


@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D


var state: State = State.IDLE

var home_position: Vector3
var target_position: Vector3

var idle_timer: float = 0.0
var collision_pause_timer: float = 0.0

var facing_direction: String = "down"
var is_talking: bool = false


func _ready() -> void:
	randomize()

	home_position = global_position

	_start_idle()


func _physics_process(delta: float) -> void:
	# Während eines Dialogs darf der NPC nicht laufen.
	if is_talking:
		_stop_horizontal_movement()
		_play_idle_animation()

		# Gravitation weiterhin anwenden.
		if not is_on_floor():
			velocity += get_gravity() * delta
		else:
			velocity.y = 0.0

		move_and_slide()
		return


	# Gravitation
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0.0


	# Nach einer Kollision kurz stehen bleiben
	if collision_pause_timer > 0.0:
		collision_pause_timer -= delta

		_stop_horizontal_movement()
		_play_idle_animation()

		move_and_slide()
		return


	# Wenn Bewegung deaktiviert wurde, bleibt der NPC stehen.
	if not can_roam:
		_start_idle()
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


	# Kollisionen prüfen
	if state == State.WALKING and get_slide_collision_count() > 0:
		_check_for_collision()


# --------------------------------------------------
# IDLE UND BEWEGUNG
# --------------------------------------------------

func _process_idle(delta: float) -> void:
	# Horizontal abbremsen
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

	# Neues Ziel auswählen
	if idle_timer <= 0.0 and collision_pause_timer <= 0.0:
		_choose_new_target()


func _process_walking() -> void:
	var difference: Vector3 = target_position - global_position

	# Nur auf der X-/Z-Ebene bewegen
	difference.y = 0.0


	# Ziel erreicht
	if difference.length() <= arrive_distance:
		_start_idle()
		return


	# Richtung zum Ziel berechnen
	var direction: Vector3 = difference.normalized()

	velocity.x = direction.x * walk_speed
	velocity.z = direction.z * walk_speed

	_update_walking_animation(direction)


func _choose_new_target() -> void:
	if not can_roam:
		_start_idle()
		return


	# Zufälligen Winkel auswählen
	var angle: float = randf_range(0.0, TAU)

	# Zufällige Entfernung innerhalb des Radius
	var distance: float = randf_range(0.5, roam_radius)


	# Neues Ziel rund um die Heimatposition setzen
	target_position = home_position + Vector3(
		cos(angle) * distance,
		0.0,
		sin(angle) * distance
	)

	state = State.WALKING


func _start_idle() -> void:
	state = State.IDLE

	idle_timer = randf_range(
		idle_time_min,
		idle_time_max
	)

	_stop_horizontal_movement()
	_play_idle_animation()


func _stop_after_collision() -> void:
	state = State.IDLE

	collision_pause_timer = collision_pause_time

	_stop_horizontal_movement()

	# Verhindert, dass der NPC direkt wieder losläuft.
	idle_timer = collision_pause_time

	_play_idle_animation()


func _stop_horizontal_movement() -> void:
	velocity.x = 0.0
	velocity.z = 0.0


func _check_for_collision() -> void:
	for index in range(get_slide_collision_count()):
		var collision: KinematicCollision3D = get_slide_collision(index)
		var collider: Object = collision.get_collider()

		if collider == null:
			continue

		# Nur auf Spieler oder andere bewegliche Körper reagieren.
		if collider is CharacterBody3D:
			_stop_after_collision()
			return


# --------------------------------------------------
# ANIMATIONEN
# --------------------------------------------------

func _update_walking_animation(direction: Vector3) -> void:
	# Bewegung hauptsächlich links/rechts
	if abs(direction.x) > abs(direction.z):
		if direction.x > 0.0:
			facing_direction = "right"
			sprite.play("walking_right")
		else:
			facing_direction = "left"
			sprite.play("walking_left")

	# Bewegung hauptsächlich oben/unten
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


# --------------------------------------------------
# INTERAKTION
# --------------------------------------------------

func interact(player: Node3D) -> void:
	# Interaktion verhindern, wenn sie deaktiviert ist.
	if not interaction_enabled:
		return

	# Verhindert, dass der Dialog mehrfach gleichzeitig geöffnet wird.
	if is_talking:
		return

	if player == null:
		return


	# NPC anhalten
	is_talking = true
	state = State.IDLE
	_stop_horizontal_movement()

	# NPC zum Spieler drehen
	_face_player(player)


	# Dialog-UI suchen
	var dialogue_ui: Node = get_tree().get_first_node_in_group("dialogue_ui")

	if dialogue_ui == null:
		push_warning(
			"Keine DialogueUI gefunden. " +
			"Füge deine DialogueUI zur Gruppe 'dialogue_ui' hinzu."
		)

		is_talking = false
		return


	# Text in einzelne Seiten aufteilen.
	var dialogue_lines: Array[String] = _get_dialogue_lines()


	# Prüfen, ob die UI die erwartete Funktion besitzt.
	if dialogue_ui.has_method("show_dialogue"):
		dialogue_ui.show_dialogue(
			npc_name,
			dialogue_lines
		)
	else:
		push_warning(
			"Die DialogueUI besitzt keine Funktion " +
			"'show_dialogue(npc_name, dialogue_lines)'."
		)

		is_talking = false
		return


	# Wenn die DialogueUI ein Signal dialogue_closed besitzt,
	# wird der NPC nach dem Dialog automatisch freigegeben.
	if dialogue_ui.has_signal("dialogue_closed"):
		if not dialogue_ui.dialogue_closed.is_connected(_on_dialogue_closed):
			dialogue_ui.dialogue_closed.connect(
				_on_dialogue_closed,
				CONNECT_ONE_SHOT
			)


func _get_dialogue_lines() -> Array[String]:
	var lines: Array[String] = []

	# Jede nichtleere Zeile wird zu einer eigenen Textseite.
	for line in dialogue_text.split("\n"):
		var clean_line: String = line.strip_edges()

		if not clean_line.is_empty():
			lines.append(clean_line)

	# Falls kein Text eingetragen wurde.
	if lines.is_empty():
		lines.append("...")


	return lines


func _on_dialogue_closed() -> void:
	is_talking = false

	# NPC bleibt nach dem Gespräch kurz stehen.
	state = State.IDLE
	idle_timer = collision_pause_time

	_stop_horizontal_movement()
	_play_idle_animation()


func _face_player(player: Node3D) -> void:
	var difference: Vector3 = player.global_position - global_position

	# Höhe ignorieren
	difference.y = 0.0


	# Falls Spieler exakt auf derselben Position steht
	if difference.length_squared() <= 0.001:
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


	_play_idle_animation()
