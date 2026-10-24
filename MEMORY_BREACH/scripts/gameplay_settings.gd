extends Resource
## Editable balancing resource. Shared by Main and all standalone sector wrappers.
@export_group("Hull and Aegis")
@export var max_hull: float = 200.0
@export var max_energy: float = 100.0
@export var shield_drain: float = 19.0
@export var shield_recharge: float = 6.0
@export var shield_laser_drain: float = 18.0
@export_group("Weapons")
@export var base_weapon_damage: float = 1.0
@export var damage_per_sector: float = 0.65
@export var base_fire_interval: float = 0.23
@export var interval_reduction: float = 0.013
@export var minimum_fire_interval: float = 0.10
@export var bullet_speed: float = 530.0
@export var bullet_speed_per_sector: float = 28.0
@export var dual_shot_sector: int = 3
@export var triple_shot_sector: int = 7
@export_group("Enemies and Hazards")
@export var enemy_damage_multiplier: float = 1.0
@export var laser_damage_per_second: float = 75.0
@export var drone_detection_range: float = 360.0
@export_group("Campaign")
@export var timer_multiplier: float = 1.0
@export var persist_progress: bool = true

@export_group("Audio")
@export_range(-60,0,1) var music_volume_db: float = -20.0
@export_range(-60,0,1) var effects_volume_db: float = -12.0
