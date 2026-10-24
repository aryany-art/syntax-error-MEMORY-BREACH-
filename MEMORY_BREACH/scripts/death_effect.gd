extends ColorRect
## Screen-space red damage/death effect. Editor settings allow reducing intensity.
@export_range(0,1) var maximum_opacity: float = 0.8
@export var fade_speed: float = 3.0
var dead=false
var amount=0.0
func _ready():
	material=material.duplicate()
	mouse_filter=Control.MOUSE_FILTER_IGNORE
func trigger_death():
	dead=true
func flash_damage():
	if not dead:amount=maxf(amount,0.25)
func clear_effect():
	dead=false
	amount=0
	if material:material.set_shader_parameter("strength",0.0)
func _process(delta):
	amount=move_toward(amount,1.0 if dead else 0.0,delta*fade_speed)
	material.set_shader_parameter("strength",amount*maximum_opacity)
