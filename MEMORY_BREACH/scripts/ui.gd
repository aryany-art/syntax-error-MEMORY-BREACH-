extends CanvasLayer
## UI layout lives in GameUI.tscn; this script forwards user actions to game.gd.
signal command_requested(command)
signal console_close_requested
signal modal_action_requested
signal resume_requested
signal touch_action(action, pressed)
signal touch_controls_enabled
var touch_buttons={}
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
func _ready():
	%RunButton.pressed.connect(func(): command_requested.emit(command_input.text))
	%CloseConsole.pressed.connect(func(): console_close_requested.emit())
	command_input.text_submitted.connect(func(text): command_requested.emit(text))
	modal_action.pressed.connect(func(): modal_action_requested.emit())
	resume_button.pressed.connect(func(): resume_requested.emit())
	$TouchControls.visible = false
	var browser_touch=false
	if OS.has_feature("web"):
		browser_touch=bool(JavaScriptBridge.eval("navigator.maxTouchPoints > 0"))
	if DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") or browser_touch:
		enable_touch_controls()
	for button in $TouchControls.get_children():
		var id = str(button.get_meta("action"))
		button.button_down.connect(func(): touch_action.emit(id,true))
		button.button_up.connect(func(): touch_action.emit(id,false))

func enable_touch_controls():
	if $TouchControls.visible:return
	$TouchControls.show()
	for button in $TouchControls.get_children():button.mouse_filter=Control.MOUSE_FILTER_IGNORE
	touch_controls_enabled.emit()

func release_touch_button(index):
	if not touch_buttons.has(index):return
	var action=touch_buttons[index]
	touch_buttons.erase(index)
	if not touch_buttons.values().has(action):touch_action.emit(action,false)

func clear_touch_buttons():
	for index in touch_buttons.keys():release_touch_button(index)

func _input(event):
	if event is InputEventScreenTouch:
		enable_touch_controls()
		if not event.pressed:
			if touch_buttons.has(event.index):
				release_touch_button(event.index)
				get_viewport().set_input_as_handled()
			return
	if not (event is InputEventScreenTouch or event is InputEventScreenDrag):return
	if modal.visible or console.visible:return
	var action=""
	for button in $TouchControls.get_children():
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
	if not action.is_empty() or not previous.is_empty():get_viewport().set_input_as_handled()

@onready var death = %DeathOverlay
var story_time=0.0
var story_history: Array[String] = []
func reset_story_history():
	story_history.clear()
	story_time=0.0
	%StoryText.text=""
func transmit(text, duration=8.0):
	var message=str(text).strip_edges()
	if message.is_empty():return
	# Ignore repeated triggers, including whitespace/case differences.
	var key=" ".join(message.split(" ",false)).replace("\n"," ").replace("\t"," ").to_lower()
	while key.contains("  "):key=key.replace("  "," ")
	if story_history.has(key):return
	story_history.append(key)
	%StoryText.text=message
	story_time=duration
func _process(delta):
	if modal.visible or console.visible:clear_touch_buttons()
	story_time=maxf(0,story_time-delta)
	%StoryPanel.visible=story_time>0 and not modal.visible and not console.visible
