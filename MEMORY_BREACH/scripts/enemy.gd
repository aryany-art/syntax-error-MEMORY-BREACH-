@tool
extends "res://scripts/entity.gd"
## Per-enemy visual, random patrol and combat settings.
@export_enum("Hover Drone", "Cyber Stalker", "Rail Sentinel", "EMP Wisp") var enemy_type: int = 0
@export_group("Enemy Patrol")
@export var patrol_speed: float = 95.0
@export var speed_gain_per_sector: float = 3.0
@export var retarget_min: float = 1.2
@export var retarget_max: float = 3.0
@export var body_radius: float = 13.0
@export_group("Enemy Combat")
@export var detection_range: float = 450.0
@export var shot_damage: float = 18.0
@export var damage_per_sector: float = 4.5
@export var fire_interval: float = 1.45
@export var interval_reduction: float = 0.075
@export var minimum_interval: float = 0.65
@export var projectile_speed: float = 290.0
@export var speed_per_sector: float = 22.0
@export var stun_duration: float = 0.28
@export_group("Stalker Melee")
@export var chase_speed: float = 145.0
@export var attack_range: float = 107.5
@export var windup_time: float = 0.45
@export var lunge_speed: float = 330.0
@export var lunge_duration: float = 0.275
@export var recovery_time: float = 0.85
@export var melee_damage: float = 20.0
@export_group("Rail Sentinel")
@export var rail_charge_time: float = 0.9
@export var rail_damage: float = 24.0
@export var rail_range: float = 600.0
@export var rail_cooldown: float = 2.7
@export_group("EMP Wisp")
@export var emp_damage: float = 6.0
@export var emp_energy_drain: float = 25.0
@export var emp_cooldown: float = 2.1
@export_group("Enemy Appearance")
@export var use_tile_art: bool = false:
	set(value):
		use_tile_art=value
		refresh()
var boss_animation_time=0.0
var velocity_hint=Vector2.RIGHT
var look_direction=Vector2.RIGHT
var visual_state="roam"
var attack_visual_time=0.0
var windup_progress=0.0
func refresh():
	super.refresh()
	var sprite=get_node_or_null("Sprite2D")
	if sprite: sprite.visible=use_tile_art
	var animated=get_node_or_null("EnemySprite")
	if animated: animated.visible=not use_tile_art
	queue_redraw()
func _ready():
	super._ready()
	if not Engine.is_editor_hint() and get_node_or_null("EnemySprite"):
		$EnemySprite.play(["drone_hover","stalker_walk","sentinel_idle","wisp_hover"][enemy_type])
func present(velocity, state, progress=0.0):
	velocity_hint=velocity
	visual_state=state
	windup_progress=progress
func flash_attack(direction):
	look_direction=direction
	attack_visual_time=0.35
func _process(delta):
	if Engine.is_editor_hint(): return
	if has_meta("kavya"):
		$EnemySprite.hide()
		animate_boss(delta)
		return
	var animated=get_node_or_null("EnemySprite")
	if not animated: return
	attack_visual_time=maxf(0,attack_visual_time-delta)
	if velocity_hint.length()>1 and attack_visual_time<=0 and visual_state not in ["windup","lunge","rail_charge"]:
		look_direction=velocity_hint.normalized()
	animated.rotation=lerp_angle(animated.rotation,look_direction.angle(),1-exp(-12*delta))
	var attacking=attack_visual_time>0 or visual_state in ["windup","lunge"]
	var animation=("drone_fire" if attacking else "drone_hover") if enemy_type==0 else ("stalker_attack" if attacking else "stalker_walk")
	if enemy_type==2:
		animation="sentinel_charge" if visual_state=="rail_charge" else ("sentinel_fire" if attack_visual_time>0 else ("sentinel_cool" if visual_state=="rail_cool" else "sentinel_idle"))
	elif enemy_type==3:
		animation="wisp_pulse" if attack_visual_time>0 else "wisp_hover"
	if animated.animation!=animation:animated.play(animation)
	if activated:
		animated.pause()
	elif enemy_type==1 and velocity_hint.length()<1 and not attacking:
		animated.pause()
	else:
		if not animated.is_playing():animated.play()
		animated.speed_scale=1.0 if enemy_type==0 or attacking else clampf(velocity_hint.length()/95.0,0.35,2.0)
	animated.position.y=sin(Time.get_ticks_msec()*0.005)*1.5 if enemy_type==0 and not activated else 0
	queue_redraw()
func animate_boss(delta):
	var art=get_node_or_null("BossArt")
	if not art:return
	attack_visual_time=maxf(0,attack_visual_time-delta)
	if activated:return
	boss_animation_time+=delta
	var moving=velocity_hint.length()>1
	var bank=clampf(velocity_hint.x/115.0,-1,1)*0.10
	art.rotation=lerp_angle(art.rotation,bank,1-exp(-8*delta))
	art.position=Vector2(-look_direction.x*attack_visual_time*8,sin(boss_animation_time*4.5)*(3.0 if moving else 1.5))
	var pulse=sin(boss_animation_time*6)*0.015
	art.scale=Vector2(0.09,0.09)*(1.0+pulse+attack_visual_time*0.06)
	art.modulate=Color(1.0,1.0-attack_visual_time*0.7,1.0)
	queue_redraw()

func _draw():
	draw_circle(Vector2(0,13),20,Color(0,0,0,0.4))
	if has_meta("kavya") and not activated:
		var flicker=sin(boss_animation_time*19)*3
		for x in [-22,22]:
			draw_line(Vector2(x,22),Vector2(x,34+flicker+minf(velocity_hint.length()/12,10)),Color("4efcff"),5,true)
			draw_circle(Vector2(x,22),5,Color("ff4edb"))
	if visual_state in ["windup","rail_charge"]:
		draw_arc(Vector2.ZERO,27+windup_progress*8,0,TAU,32,Color("ff4edb"),2,true)
		draw_line(Vector2.ZERO,look_direction*42,Color("ff4edb"),2,true)
