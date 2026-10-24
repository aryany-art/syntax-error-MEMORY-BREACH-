@tool
extends Camera2D
## Select this Camera2D in Main.tscn to tune framing and native camera settings.
@export_enum("Follow", "Fixed", "Free") var camera_mode: int = 0
@export var target_path: NodePath = NodePath("../../World/Player")
@export_group("Framing")
@export var look_ahead: float = 48.0
@export var look_smoothing: float = 6.0
@export var fixed_position = Vector2(480,360)
@export var use_world_limits: bool = true
@export var world_bounds = Rect2(0,0,960,720)
@export_group("Developer Controls")
@export var allow_debug_controls: bool = true
@export var free_pan_speed: float = 450.0
@export var zoom_min: float = 0.75
@export var zoom_max: float = 3.0
@export var zoom_smoothing: float = 10.0
@export_group("Screen Shake")
@export var shake_enabled: bool = true
@export var shake_strength: float = 5.0
@export var shake_decay: float = 3.5
var target: Node2D
var zoom_target: float = 1.5
var look_offset = Vector2.ZERO
var trauma: float = 0.0
var input_blocked: bool = false
var screen_aim = Vector2.RIGHT
var initial_zoom = 1.5
var free_dragging = false

func _ready():
	if Engine.is_editor_hint(): return
	initial_zoom = zoom.x
	zoom_target = zoom.x
	apply_limits()
	make_current()

func bind_target(node, bounds):
	target = node
	world_bounds = bounds
	apply_limits()
	look_offset = Vector2.ZERO
	if camera_mode == 0 and is_instance_valid(target):
		global_position = target.global_position
	reset_smoothing()
	force_update_scroll()

func apply_limits():
	if use_world_limits and camera_mode != 2:
		limit_left = int(world_bounds.position.x)
		limit_top = int(world_bounds.position.y)
		limit_right = int(world_bounds.end.x)
		limit_bottom = int(world_bounds.end.y)
	else:
		limit_left = -1000000
		limit_top = -1000000
		limit_right = 1000000
		limit_bottom = 1000000

func set_mode(value):
	camera_mode = clampi(value,0,2)
	apply_limits()
	reset_smoothing()

func set_zoom_level(value):
	zoom_target = clampf(value,zoom_min,zoom_max)

func add_shake(amount):
	if shake_enabled: trauma = minf(1.0,trauma+amount)

func _process(delta):
	if Engine.is_editor_hint(): return
	if not is_instance_valid(target): target = get_node_or_null(target_path)
	zoom = Vector2.ONE * lerpf(zoom.x,zoom_target,1.0-exp(-zoom_smoothing*delta))
	if camera_mode == 0 and is_instance_valid(target):
		look_offset = look_offset.lerp(screen_aim*look_ahead,1.0-exp(-look_smoothing*delta))
		global_position = target.global_position+look_offset
	elif camera_mode == 1:
		global_position = fixed_position
	elif camera_mode == 2 and allow_debug_controls and not input_blocked:
		var direction = Vector2(float(Input.is_physical_key_pressed(KEY_L))-float(Input.is_physical_key_pressed(KEY_J)),float(Input.is_physical_key_pressed(KEY_K))-float(Input.is_physical_key_pressed(KEY_I)))
		global_position += direction.limit_length()*free_pan_speed*delta/zoom.x
	trauma = maxf(0,trauma-shake_decay*delta)
	offset = Vector2(sin(Time.get_ticks_msec()*0.09),cos(Time.get_ticks_msec()*0.075))*trauma*trauma*shake_strength if shake_enabled else Vector2.ZERO

func _unhandled_input(event):
	if Engine.is_editor_hint() or input_blocked or not allow_debug_controls: return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_F1: set_mode(2)
			KEY_F2: set_mode(1); set_zoom_level(1.0)
			KEY_F3: set_mode(0); set_zoom_level(initial_zoom)
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP: set_zoom_level(zoom_target*1.1)
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN: set_zoom_level(zoom_target/1.1)
		if event.button_index == MOUSE_BUTTON_MIDDLE: free_dragging = event.pressed
	if event is InputEventMouseMotion and camera_mode == 2 and free_dragging:
		global_position -= event.relative / zoom.x
