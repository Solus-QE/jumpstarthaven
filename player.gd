extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const MIN_BOOST_VELOCITY = -600.0
const MAX_BOOST_VELOCITY = -1600.0
const MAX_HOLD_TIME = 1.0
const DIVING_SPEED = 600.0

var actions = ["left", "right", "jump", "hold"]
var current_mappings = {
	"left": "left",
	"right": "right",
	"jump": "jump",
	"hold": "hold"
}

var can_hold_boost: bool = false
var is_charging_dive: bool = false
var is_diving: bool = false
var is_boosting: bool = false
var hold_timer: float = 0.0

@onready var collision_shape = $CollisionShape2D

func _physics_process(delta: float) -> void:
	_check_and_shuffle_inputs()

	if not is_on_floor() and not is_diving:
		velocity += get_gravity() * delta

	if is_charging_dive:
		if _is_action_pressed("hold"):
			hold_timer = min(hold_timer + delta, MAX_HOLD_TIME)
			rotation += 25.0 * delta
		else:
			is_charging_dive = false
			is_diving = true
			collision_shape.disabled = true

	if is_diving:
		rotation += 35.0 * delta
		velocity.y = DIVING_SPEED
		
		if position.y > get_viewport_rect().size.y + 100.0:
			is_diving = false
			is_boosting = true
			collision_shape.disabled = false
			
			var charge_ratio = hold_timer / MAX_HOLD_TIME
			velocity.y = lerp(MIN_BOOST_VELOCITY, MAX_BOOST_VELOCITY, charge_ratio)
			hold_timer = 0.0

	elif is_boosting:
		rotation += 20.0 * delta
		if velocity.y >= 0:
			is_boosting = false
			rotation = 0.0

	if is_on_floor():
		can_hold_boost = false
		rotation = 0.0

	if _is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		can_hold_boost = true

	if _is_action_just_pressed("hold") and can_hold_boost and not is_charging_dive and not is_diving:
		is_charging_dive = true
		can_hold_boost = false
		hold_timer = 0.0

	var direction := 0.0
	if _is_action_pressed("left"):
		direction -= 1.0
	if _is_action_pressed("right"):
		direction += 1.0

	if direction != 0.0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func _check_and_shuffle_inputs() -> void:
	for action in actions:
		if Input.is_action_just_pressed(action):
			_shuffle_controls()
			break

func _shuffle_controls() -> void:
	var shuffled = actions.duplicate()
	shuffled.shuffle()
	for i in range(actions.size()):
		current_mappings[actions[i]] = shuffled[i]

func _is_action_pressed(action_name: String) -> bool:
	var mapped_action = current_mappings[action_name]
	return Input.is_action_pressed(mapped_action)

func _is_action_just_pressed(action_name: String) -> bool:
	var mapped_action = current_mappings[action_name]
	return Input.is_action_just_pressed(mapped_action)
