@tool
extends Node2D
## Select the World root to edit this sector's briefing, timer and camera bounds.
@export_group("Mission")
@export var mission_title: String = "Sector"
@export_multiline var briefing: String = ""
@export_multiline var hint: String = ""
@export var time_limit: float = 180.0
@export_group("Camera")
@export var camera_bounds = Rect2(0,-100,960,720)

@export_group("Story")
@export_multiline var arrival_message: String = ""
@export_multiline var memory_fragment: String = ""
@export_multiline var completion_text: String = ""
