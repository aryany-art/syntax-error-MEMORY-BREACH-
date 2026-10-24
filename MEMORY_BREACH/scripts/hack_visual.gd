extends PanelContainer
@export var reduced_motion=false
var log_view: RichTextLabel
var progress: ProgressBar
var banner: Label
var clock=0.0
var step=0
var running=false
var entries=0
func _ready():
	var style=StyleBoxFlat.new()
	style.bg_color=Color("030b07")
	style.border_color=Color("2bea68")
	style.set_border_width_all(1)
	style.content_margin_left=12
	style.content_margin_top=10
	add_theme_stylebox_override("panel",style)
	position=Vector2(36,142)
	size=Vector2(888,320)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	var box=VBoxContainer.new()
	add_child(box)
	banner=Label.new()
	banner.add_theme_color_override("font_color",Color("74ff95"))
	box.add_child(banner)
	log_view=RichTextLabel.new()
	log_view.custom_minimum_size=Vector2(850,245)
	log_view.scroll_following=true
	log_view.mouse_filter=Control.MOUSE_FILTER_IGNORE
	log_view.add_theme_color_override("default_color",Color("39ff75"))
	var font=SystemFont.new()
	font.font_names=PackedStringArray(["Consolas","DejaVu Sans Mono","Menlo"])
	log_view.add_theme_font_override("normal_font",font)
	log_view.add_theme_font_size_override("normal_font_size",13)
	box.add_child(log_view)
	progress=ProgressBar.new()
	progress.max_value=50
	box.add_child(progress)
	log_view.add_text("PATCH // PYTHON INTERPRETER + VISUAL BREACH LOG\nSelect a target and solve one protocol.\n")
func line(text):
	log_view.add_text(text+"\n")
	entries+=1
	if entries>100:
		log_view.clear()
		entries=0
func protocol(text):
	running=false
	step=0
	progress.value=0
	banner.text="PYTHON 3 TERMINAL // PROTOCOL 1/1"
	line("[AUTH] "+text)
func breach(target):
	running=true
	step=0
	clock=0
	banner.text="ACCESS GRANTED // "+target+" // cosmetic verification"
	line("[SUCCESS] Gameplay authorization confirmed. Starting visual lock audit...")
func _process(delta):
	if not visible:return
	clock+=delta
	if running:
		if clock<0.055:return
		clock=0
		step+=1
		progress.value=step
		line("[UNLOCK] virtual lock %02d / 50 :: signature=%08x :: VERIFIED"%[step,randi()])
		if not reduced_motion:
			line("    0x%08x  decode(packet.a ^ packet.b) -> memory.commit() :: %08x"%[randi(),randi()])
		if step>=50:
			running=false
			banner.text="BREACH COMPLETE // 50/50 virtual locks verified"
			line("[DONE] Target action has already been applied. These 50 locks are visual effects.")
	elif clock>0.5 and not reduced_motion:
		clock=0
		line("[TRACE] %08x %08x %08x :: await valid protocol response"%[randi(),randi(),randi()])
