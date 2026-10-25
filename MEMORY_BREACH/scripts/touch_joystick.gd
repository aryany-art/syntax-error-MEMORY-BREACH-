@tool
extends Control
## Fixed left-thumb joystick. Input is routed by GameUI before action buttons.
signal movement_changed(direction)
@export var radius: float = 78.0
@export_range(0.0,0.5) var deadzone: float = 0.14
var finger_id=-1
var direction=Vector2.ZERO

func feed(event):
	if event is InputEventScreenTouch:
		if not event.pressed:
			if event.index!=finger_id:return false
			reset()
			return true
		if finger_id!=-1:return false
		if event.position.distance_to(get_global_rect().get_center())>radius*1.4:return false
		finger_id=event.index
		update_direction(event.position)
		return true
	if event is InputEventScreenDrag and event.index==finger_id:
		update_direction(event.position)
		return true
	return false

func update_direction(point):
	var offset=point-get_global_rect().get_center()
	var strength=clampf(offset.length()/radius,0,1)
	var next=Vector2.ZERO
	if strength>deadzone:
		next=offset.normalized()*(strength-deadzone)/(1-deadzone)
	if not direction.is_equal_approx(next):
		direction=next
		movement_changed.emit(direction)
	queue_redraw()

func reset():
	finger_id=-1
	if direction!=Vector2.ZERO:
		direction=Vector2.ZERO
		movement_changed.emit(direction)
	queue_redraw()

func _draw():
	var center=size/2
	var active=finger_id>=0
	draw_circle(center,radius+15,Color(0.015,0.04,0.075,0.65))
	draw_circle(center,radius,Color(0.15,0.65,0.78,0.10))
	draw_arc(center,radius,0,TAU,64,Color(0.35,0.9,1,0.8 if active else 0.45),2,true)
	for axis in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		draw_line(center+axis*(radius-12),center+axis*(radius-3),Color(0.45,0.8,0.9,0.55),2,true)
	draw_circle(center+direction*radius,32,Color(0.15,0.6,0.7,0.8 if active else 0.5))
	draw_arc(center+direction*radius,32,0,TAU,40,Color("83efff"),2,true)
	draw_circle(center+direction*radius,5,Color("c8faff"))
