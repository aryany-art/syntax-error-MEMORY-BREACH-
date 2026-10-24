@tool
extends "res://scripts/entity.gd"
## Optional collectible; required memory shards remain in the separate Shards group.
@export_enum("Repair", "Aegis", "Overdrive", "Chrono") var gem_type: int = 0:
	set(value):
		gem_type=value
		refresh()
@export var pickup_amount: float = 25.0
@export var buff_duration: float = 10.0
const GEM_ART=preload("res://assets/threats_and_gems.png")
var bob_time=0.0
func refresh():
	super.refresh()
	var sprite=get_node_or_null("Sprite2D")
	if not sprite:return
	var texture=AtlasTexture.new()
	texture.atlas=GEM_ART
	var a=Vector2(round(gem_type*1254.0/4),round(2*1254.0/4))
	var b=Vector2(round((gem_type+1)*1254.0/4),round(3*1254.0/4))
	texture.region=Rect2(a,b-a)
	sprite.texture=texture
	sprite.scale=Vector2(32,36)/texture.region.size
	collision_layer=0
	collision_mask=0
func _process(delta):
	if Engine.is_editor_hint():return
	bob_time+=delta
	var sprite=get_node_or_null("Sprite2D")
	if sprite:
		sprite.position.y=sin(bob_time*2.5)*2
		sprite.modulate=Color.WHITE*(0.9+sin(bob_time*3)*0.1)
