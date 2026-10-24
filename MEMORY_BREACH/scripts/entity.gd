@tool
extends StaticBody2D
## Editable world object. Exported properties configure both its art and gameplay.
@export_enum("Wall", "Gate", "Terminal", "Shard", "Receiver", "Laser", "Exit", "Drone") var kind: String = "Wall":
	set(value):
		kind = value
		refresh()
@export var dimensions = Vector2(48, 48):
	set(value):
		dimensions = value
		refresh()
@export var command: String = ""
@export var sensor: String = ""
@export var label: String = ""
@export var patrol_velocity = Vector2.ZERO
@export var patrol_bounds = Rect2(60, 60, 840, 480)
@export var base_health: float = 3.0
@export var laser_direction = Vector2.DOWN
@export var tile = Vector2i(0, 0):
	set(value):
		tile = value
		refresh()
const ART = preload("res://assets/futuristic_tileset.png")
var activated = false

func _ready():
	refresh()

func refresh():
	if not is_inside_tree(): return
	var sprite = get_node_or_null("Sprite2D")
	var collision = get_node_or_null("CollisionShape2D")
	if sprite:
		var texture = AtlasTexture.new()
		texture.atlas = ART
		var a = Vector2(round(tile.x * 1254.0 / 8), round(tile.y * 1254.0 / 8))
		var b = Vector2(round((tile.x + 1) * 1254.0 / 8), round((tile.y + 1) * 1254.0 / 8))
		texture.region = Rect2(a, b - a)
		sprite.texture = texture
		sprite.scale = dimensions / texture.region.size
		sprite.position = dimensions / 2 if kind in ["Wall", "Gate"] else Vector2.ZERO
	if collision:
		var shape = RectangleShape2D.new()
		shape.size = dimensions
		collision.shape = shape
		collision.position = dimensions / 2
		collision.disabled = kind not in ["Wall", "Gate"] or activated
	collision_layer = 1 if kind in ["Wall", "Gate"] else 0
	collision_mask = 0

func set_activated(value):
	if activated == value: return
	activated = value
	if kind == "Gate":
		visible = not value
	elif kind == "Shard":
		visible = not value
	elif kind == "Terminal":
		modulate = Color("c9f76b") if value else Color.WHITE
	elif kind == "Receiver":
		tile = Vector2i(3 if value else 2, 7)
	elif kind == "Drone":
		modulate = Color("768aa0") if value else Color.WHITE
	refresh()
