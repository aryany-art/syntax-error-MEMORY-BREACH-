@tool
extends CharacterBody2D
## Tunable grounded movement and distance-driven 8-frame gait.
@export var movement_speed: float = 210.0
@export var shield_speed: float = 140.0
@export var acceleration: float = 1250.0
@export var braking: float = 1800.0
@export var turn_speed: float = 12.0
@export var stride_length: float = 92.0
@export var collision_radius: float = 15.0
var dead=false
var facing = Vector2.DOWN
var target_facing = Vector2.DOWN
var actual_speed = 0.0
var stride_phase = 0.0
var moving = false
var shielding = false
var hacking = false
var leaning = 0.0
var recoil = 0.0
var animation_direction = "down"
var gait_blend=0.0

func _ready():
	if not Engine.is_editor_hint():
		$AnimatedSprite2D.stop()

func drive(direction, dt, rectangles):
	var desired = direction.limit_length() * (shield_speed if shielding else movement_speed)
	if hacking:
		velocity = Vector2.ZERO
	else:
		velocity = velocity.move_toward(desired, (braking if direction.length() < 0.05 else acceleration) * dt)
	var before = position
	try_move(velocity * dt, rectangles)
	var displacement = position - before
	if dt > 0:
		var actual = displacement / dt
		if absf(actual.x) < 0.01: velocity.x = 0
		if absf(actual.y) < 0.01: velocity.y = 0
		actual_speed = actual.length()
	moving = actual_speed > 3.0
	# Walk cycle advances by actual distance, so feet do not animate against a wall.
	stride_phase = fmod(stride_phase + displacement.length() / maxf(1, stride_length), 1.0)
	if direction.length() > 0.1:
		target_facing = direction.normalized()

func try_move(delta_pos, rectangles):
	var count = maxi(1, int(ceil(delta_pos.length() / 5.0)))
	var step = delta_pos / count
	for i in range(count):
		for axis in range(2):
			var candidate = position
			candidate[axis] += step[axis]
			var blocked = false
			for rect in rectangles:
				var closest = candidate.clamp(rect.position, rect.end)
				if closest.distance_squared_to(candidate) < collision_radius * collision_radius:
					blocked = true
					break
			if not blocked: position = candidate

func present(aim, has_shield, has_laptop):
	shielding = has_shield
	hacking = has_laptop
	# Movement leads the body; aim controls the body while stationary or defending.
	if not moving or shielding or hacking or recoil > 0.05:
		target_facing = aim
	queue_redraw()

func kick():
	recoil = 1.0

func set_dead(value):
	dead=value
	if not value:$AnimatedSprite2D.modulate=Color.WHITE

func halt():
	velocity = Vector2.ZERO
	actual_speed = 0.0
	moving = false

func _process(delta):
	if Engine.is_editor_hint(): return
	if dead:
		$AnimatedSprite2D.modulate=Color(1,0.2,0.25)
		$AnimatedSprite2D.rotation=lerpf($AnimatedSprite2D.rotation,1.2,1-exp(-5*delta))
		return
	var weight = 1.0 - exp(-turn_speed * delta)
	if target_facing.length() > 0.1:
		facing = Vector2.from_angle(lerp_angle(facing.angle(),target_facing.angle(),weight))
	# Hysteresis avoids rapid left/down toggling near the diagonal boundary.
	var ratio = absf(facing.x) - absf(facing.y)
	if ratio > 0.15:
		animation_direction = "right" if facing.x > 0 else "left"
	elif ratio < -0.15:
		animation_direction = "down" if facing.y > 0 else "up"
	var sprite = $AnimatedSprite2D
	var animation = ("walk_" if moving else "idle_") + animation_direction
	# stop() resets the frame: pause first, then select the distance-driven pose.
	if sprite.animation!=animation:sprite.animation=animation
	sprite.pause()
	var frame_count=sprite.sprite_frames.get_frame_count(animation)
	var frame_position=stride_phase*frame_count
	sprite.set_frame_and_progress(mini(frame_count-1,int(frame_position)) if moving else 0, fmod(frame_position,1.0) if moving else 0.0)
	gait_blend=lerpf(gait_blend,clampf(actual_speed/maxf(1,movement_speed),0,1) if moving else 0.0,1-exp(-14*delta))
	leaning = lerpf(leaning,clampf(velocity.x / maxf(1,movement_speed),-1,1) * 0.035,weight)
	recoil = move_toward(recoil,0.0,delta*8)
	sprite.rotation = leaning+sin(stride_phase*TAU)*0.012*gait_blend
	var walk_bob=-absf(sin(stride_phase*TAU))*1.2*gait_blend
	var bob=walk_bob+sin(Time.get_ticks_msec()*0.0018)*0.3*(1-gait_blend)
	var sway=cos(stride_phase*TAU)*0.5*gait_blend
	sprite.position = Vector2(sway-target_facing.x*recoil*1.4,-8+bob-target_facing.y*recoil*1.4)
	queue_redraw()

func _draw():
	draw_circle(Vector2(0,12),16,Color(0,0,0,0.4))
	if shielding:
		draw_circle(Vector2.ZERO,33,Color(0.35,0.9,1,0.1))
		draw_arc(Vector2.ZERO,33,0,TAU,48,Color("5ce1e6"),2,true)
	if hacking:
		draw_rect(Rect2(9,-15,23,16),Color("122136"))
		draw_rect(Rect2(11,-13,19,10),Color("83d54f"))
