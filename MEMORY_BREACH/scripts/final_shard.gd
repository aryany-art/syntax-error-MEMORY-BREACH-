extends "res://scripts/entity.gd"
## Distinct final-memory effect around the existing editable Shard artwork.
var phase=0.0
func _process(delta):
	if activated or not visible:return
	phase+=delta
	var sprite=get_node_or_null("Sprite2D")
	if sprite:
		sprite.position=Vector2(0,-5+sin(phase*3)*4)
		sprite.rotation=sin(phase*1.5)*0.12
	queue_redraw()
func _draw():
	if activated:return
	draw_arc(Vector2(0,-5),25+sin(phase*3)*2,0,TAU,40,Color("c0a5ff"),2,true)
	draw_circle(Vector2(0,-5),32,Color(0.65,0.3,1,0.10))
