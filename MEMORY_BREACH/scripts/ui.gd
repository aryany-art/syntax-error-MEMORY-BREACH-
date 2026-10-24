extends CanvasLayer
## UI layout lives in GameUI.tscn; this script forwards user actions to game.gd.
signal command_requested(command)
signal console_close_requested
signal modal_action_requested
signal resume_requested
signal touch_action(action, pressed)
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
	$TouchControls.visible = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	for button in $TouchControls.get_children():
		var id = str(button.get_meta("action"))
		button.button_down.connect(func(): touch_action.emit(id,true))
		button.button_up.connect(func(): touch_action.emit(id,false))

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
	story_time=maxf(0,story_time-delta)
	%StoryPanel.visible=story_time>0 and not modal.visible and not console.visible
