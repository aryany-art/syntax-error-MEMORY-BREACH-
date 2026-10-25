extends CanvasLayer
## Responsive UI in logical viewport coordinates; no non-uniform scaling.
signal command_requested(command)
signal console_close_requested
signal modal_action_requested
signal resume_requested
signal touch_action(action, pressed)
signal touch_controls_enabled
signal joystick_changed(direction)
var touch_buttons={}
var portrait_mode=false
var keyboard_height=0.0
var keyboard_clock=0.0
var layout_size=Vector2(1280,720)
var layout_queued=false
@onready var status = %Status
@onready var objective = %Objective
@onready var toast = %Toast
@onready var console = %Console
@onready var command_input = %CommandInput
@onready var chips = %CommandChips
@onready var console_log = %ConsoleLog
@onready var modal = %Modal
@onready var modal_title = %ModalTitle
@onready var modal_body = %ModalBody
@onready var modal_action = %ModalAction
@onready var resume_button = %ResumeCampaign
@onready var joystick=$TouchControls/Joystick
@onready var death = %DeathOverlay

func _ready():
	%RunButton.pressed.connect(func(): command_requested.emit(command_input.text))
	%CloseConsole.pressed.connect(func(): console_close_requested.emit())
	command_input.text_submitted.connect(func(text): command_requested.emit(text))
	modal_action.pressed.connect(func(): modal_action_requested.emit())
	resume_button.pressed.connect(func(): resume_requested.emit())
	$Fullscreen.pressed.connect(_on_fullscreen_pressed)
	joystick.movement_changed.connect(func(value):joystick_changed.emit(value))
	$TouchControls.hide()
	style_actions()
	status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size",20)
	objective.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	objective.add_theme_font_size_override("font_size",16)
	for panel in [$HUD,modal,console]:
		panel.minimum_size_changed.connect(queue_layout)
	var browser_touch=false
	if OS.has_feature("web"):
		browser_touch=bool(JavaScriptBridge.eval("navigator.maxTouchPoints > 0"))
	if DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") or browser_touch:
		enable_touch_controls()
	for button in action_buttons():
		var id=str(button.get_meta("action"))
		button.button_down.connect(func():touch_action.emit(id,true))
		button.button_up.connect(func():touch_action.emit(id,false))
	get_viewport().size_changed.connect(viewport_changed)
	update_layout()
	call_deferred("update_layout")

func action_buttons():
	return [$TouchControls/Fire,$TouchControls/Shield,$TouchControls/Hack]

func style_actions():
	for button in action_buttons():
		var color=Color("ff657e") if button.name=="Fire" else (Color("7be8ff") if button.name=="Shield" else Color("f4d16b"))
		var style=StyleBoxFlat.new()
		style.bg_color=Color(0.025,0.06,0.1,0.9)
		style.border_color=color
		style.set_border_width_all(2)
		style.set_corner_radius_all(64)
		style.content_margin_left=8
		style.content_margin_right=8
		button.add_theme_stylebox_override("normal",style)
		button.add_theme_stylebox_override("hover",style)
		button.add_theme_stylebox_override("pressed",style)
		button.add_theme_color_override("font_color",color)
		button.add_theme_font_size_override("font_size",20)

func enable_touch_controls():
	if $TouchControls.visible:return
	$TouchControls.show()
	for button in action_buttons():button.mouse_filter=Control.MOUSE_FILTER_IGNORE
	touch_controls_enabled.emit()
	if is_node_ready():update_layout()

func release_touch_button(index):
	if not touch_buttons.has(index):return
	var action=touch_buttons[index]
	touch_buttons.erase(index)
	if not touch_buttons.values().has(action):touch_action.emit(action,false)
	update_action_visuals()

func clear_touch_buttons():
	for index in touch_buttons.keys():release_touch_button(index)
	if is_instance_valid(joystick):joystick.reset()

func update_action_visuals():
	for button in action_buttons():
		button.modulate=Color(1.5,1.5,1.5,1) if touch_buttons.values().has(str(button.get_meta("action"))) else Color.WHITE

func _input(event):
	if event is InputEventScreenTouch:
		enable_touch_controls()
		if not event.pressed:
			if joystick.feed(event):
				get_viewport().set_input_as_handled()
			elif touch_buttons.has(event.index):
				release_touch_button(event.index)
				get_viewport().set_input_as_handled()
			return
	if not (event is InputEventScreenTouch or event is InputEventScreenDrag):return
	if modal.visible or console.visible or portrait_mode:return
	if joystick.feed(event):
		get_viewport().set_input_as_handled()
		return
	var action=""
	for button in action_buttons():
		if button.get_global_rect().has_point(event.position):
			action=str(button.get_meta("action"))
			break
	var previous=touch_buttons.get(event.index,"")
	if previous!=action:
		release_touch_button(event.index)
		if not action.is_empty():
			var already_held=touch_buttons.values().has(action)
			touch_buttons[event.index]=action
			if not already_held:touch_action.emit(action,true)
	update_action_visuals()
	if not action.is_empty() or not previous.is_empty():get_viewport().set_input_as_handled()

func queue_layout():
	layout_queued=true

func viewport_changed():
	clear_touch_buttons()
	update_layout()

func web_insets():
	if not OS.has_feature("web"):return Vector4.ZERO
	var raw=JavaScriptBridge.eval("window.memoryBreachInsets ? window.memoryBreachInsets("+str(get_viewport().get_visible_rect().size.x)+") : '0,0,0,0'")
	var parts=str(raw).split(",")
	if parts.size()!=4:return Vector4.ZERO
	return Vector4(parts[0].to_float(),parts[1].to_float(),parts[2].to_float(),parts[3].to_float())

func update_layout():
	layout_for_size(get_viewport().get_visible_rect().size,web_insets())

func place(node,rect):
	if node.position!=rect.position:node.position=rect.position
	if node.size!=rect.size:node.size=rect.size

func layout_for_size(viewport_size,insets=Vector4.ZERO):
	layout_size=viewport_size
	var w=viewport_size.x
	var h=viewport_size.y
	var left=maxf(20,insets.x+16)
	var top=maxf(16,insets.y+12)
	var right=maxf(20,insets.z+16)
	var bottom=maxf(20,insets.w+16)
	portrait_mode=$TouchControls.visible and h>w
	place($HUD,Rect2(left,top,w-left-right-155,94))
	place($TouchControls,Rect2(Vector2.ZERO,viewport_size))
	place(joystick,Rect2(Vector2(left+10,h-bottom-220),Vector2(196,196)))
	joystick.queue_redraw()
	place($TouchControls/Fire,Rect2(w-right-130,h-bottom-152,112,112))
	place($TouchControls/Shield,Rect2(w-right-260,h-bottom-112,88,88))
	place($TouchControls/Hack,Rect2(w-right-132,h-bottom-282,88,88))
	$TouchControls/Shield.text="SHIELD"
	var story_width=minf(820,w-left-right-360)
	place(%StoryPanel,Rect2((w-story_width)/2,top+175 if $TouchControls.visible else h-bottom-135,story_width,112))
	toast.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	toast.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	place(toast,Rect2(left+80,top+140,w-left-right-160,48))
	var modal_width=minf(760,w-left-right-40)
	modal_body.custom_minimum_size=Vector2(modal_width-50,130)
	modal_body.size.x=modal_width-50
	modal_title.size.x=modal_width-50
	place(modal,Rect2((w-modal_width)/2,maxf(top+80,(h-400)/2),modal_width,400))
	place($ControlHints,Rect2(left,h-bottom-6,w-left-right-160,24))
	$ControlHints.visible=not $TouchControls.visible
	var console_width=minf(960,w-left-right-40)
	chips.visible=keyboard_height<1
	var available=h-bottom-keyboard_height
	var console_height=minf(300,maxf(210,available-top-16))
	place(console,Rect2((w-console_width)/2,maxf(top,available-console_height),console_width,console_height))
	var boss=get_node_or_null("BossStatus")
	if boss:
		place(boss,Rect2((w-600)/2,top+98,600,44))
		for child in boss.get_children():
			if child is ProgressBar:child.custom_minimum_size.x=600
		boss.modulate.a=0.0 if keyboard_height>0 else 1.0
	var terminal=get_node_or_null("TerminalVisual")
	if terminal:
		terminal.log_view.custom_minimum_size=Vector2(0,0)
		terminal.log_view.size_flags_vertical=Control.SIZE_EXPAND_FILL
		place(terminal,Rect2((w-console_width)/2,top+180,console_width,maxf(80,h-console_height-top-bottom-200)))
	$HUD.visible=keyboard_height<1
	place($OrientationNotice,Rect2(Vector2.ZERO,viewport_size))
	$OrientationNotice.visible=portrait_mode
	place($Fullscreen,Rect2(w-right-144,top,144,46))
	$Fullscreen.visible=not OS.has_feature("web")

func _on_fullscreen_pressed():
	if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _notification(what):
	if what==MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready():
		clear_touch_buttons()

var story_time=0.0
var story_history: Array[String] = []
func reset_story_history():
	story_history.clear()
	story_time=0.0
	%StoryText.text=""
func transmit(text, duration=8.0):
	var message=str(text).strip_edges()
	if message.is_empty():return
	var key=" ".join(message.split(" ",false)).replace("\n"," ").replace("\t"," ").to_lower()
	while key.contains("  "):key=key.replace("  "," ")
	if story_history.has(key):return
	story_history.append(key)
	%StoryText.text=message
	story_time=duration
func _process(delta):
	if layout_queued:
		layout_queued=false
		update_layout()
	if modal.visible or console.visible or portrait_mode:clear_touch_buttons()
	if not portrait_mode:story_time=maxf(0,story_time-delta)
	%StoryPanel.visible=story_time>0 and not modal.visible and not console.visible and not portrait_mode
	$TouchControls.modulate.a=0.0 if modal.visible or console.visible or portrait_mode else 1.0
	keyboard_clock+=delta
	if OS.has_feature("web") and keyboard_clock>0.1:
		keyboard_clock=0
		var next=float(JavaScriptBridge.eval("window.memoryBreachKeyboard ? window.memoryBreachKeyboard("+str(get_viewport().get_visible_rect().size.y)+") : 0")) if console.visible else 0.0
		if absf(next-keyboard_height)>2:
			keyboard_height=next
			update_layout()
	var terminal=get_node_or_null("TerminalVisual")
	if terminal and keyboard_height>0:terminal.hide()
