extends SceneTree
var checks=0
func check(condition,label):
	checks+=1
	if not condition:
		push_error("FAILED: "+label)
		assert(condition,label)
func _initialize():
	call_deferred("run")
func run():
	var game=load("res://Main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	var c=game.camera
	check(c is Camera2D,"native Camera2D is exposed")
	check(c.target==game.player,"camera binds to player")
	check(c.zoom==Vector2(1.5,1.5),"initial framing")
	check(game.ui.scene_file_path=="res://scenes/ui/GameUI.tscn","HUD is an editable scene")
	check(game.world.get_script().resource_path=="res://scripts/world_settings.gd","world mission fields exposed")
	check(game.drones[0].node.get_script().resource_path=="res://scripts/enemy.gd","enemy tuning has separate script")
	c.use_world_limits=false
	c.position_smoothing_enabled=false
	c.look_ahead=0
	c.set_mode(0)
	game.player.position=Vector2(240,300)
	c._process(1.0)
	c.force_update_scroll()
	await process_frame
	check(c.global_position.distance_to(game.player.global_position)<0.1,"follow tracks target")
	var center=root.get_visible_rect().size/2
	var projected=game.player.get_global_transform_with_canvas().origin
	check(projected.distance_to(center)<1,"player projects to viewport center")
	c.set_zoom_level(2)
	c._process(2)
	c.force_update_scroll()
	await process_frame
	check(absf(c.zoom.x-2)<0.01,"zoom changes smoothly to target")
	var projected2=game.player.get_global_transform_with_canvas()*Vector2(10,0)
	check(absf(projected2.distance_to(game.player.get_global_transform_with_canvas().origin)-20)<0.1,"zoom transforms world view")
	c.set_zoom_level(999)
	check(c.zoom_target==c.zoom_max,"maximum zoom clamp")
	c.set_zoom_level(0)
	check(c.zoom_target==c.zoom_min,"minimum zoom clamp")
	c.set_mode(1)
	c._process(0.1)
	check(c.global_position==c.fixed_position,"fixed camera framing")
	c.set_mode(2)
	c.global_position=Vector2(800,600)
	game.player.position=Vector2(100,300)
	c._process(0.1)
	check(c.global_position==Vector2(800,600),"free mode is independent of player")
	check(c.limit_left==-1000000,"free camera releases limits")
	c.add_shake(1)
	c._process(0.01)
	check(c.offset.length()>0,"screen shake reacts")
	c.shake_enabled=false
	c._process(0.01)
	check(c.offset==Vector2.ZERO,"shake can be disabled")
	c.use_world_limits=true
	c.set_mode(0)
	game.load_sector(1)
	check(c.target==game.player,"camera rebinds after sector change")
	check(c.limit_left==0 and c.limit_right==960 and c.limit_bottom==720,"world camera limits applied")
	game.load_sector(0)
	game.command_input.text="access = true"
	game.ui.get_node("Console/ConsoleContent/CommandRow/RunButton").pressed.emit()
	check(game.gates[0].open,"scene RUN button executes command")
	game.modal_action.pressed.emit()
	check(game.playing,"scene ENTER button starts play")
	game.ui.console_close_requested.emit()
	check(game.console.visible,"scene console signal connects")
	game.ui.console_close_requested.emit()
	check(not game.console.visible,"console signal closes laptop")
	var original=game.tuning
	game.tuning=original.duplicate(true)
	game.tuning.base_weapon_damage=10
	check(game.weapon_damage()==10,"weapon resource changes damage")
	game.tuning.max_hull=150
	game.tuning.max_energy=120
	game.tuning.timer_multiplier=2
	game.load_sector(0)
	check(game.hp==150 and game.energy==120,"vitals use tuning resource")
	check(game.remaining==300,"timer uses tuning resource")
	game.tuning=original
	var rig=load("res://scenes/CameraRig.tscn").instantiate()
	rig.get_node("Camera2D").zoom=Vector2(1.8,1.8)
	rig.get_node("Camera2D").camera_mode=1
	var packed=PackedScene.new()
	check(packed.pack(rig)==OK,"camera rig can be packed")
	check(ResourceSaver.save(packed,"user://camera_roundtrip.tscn")==OK,"camera configuration saves")
	var loaded=load("user://camera_roundtrip.tscn").instantiate()
	check(loaded.get_node("Camera2D").zoom==Vector2(1.8,1.8),"saved camera zoom persists")
	check(loaded.get_node("Camera2D").camera_mode==1,"saved camera mode persists")
	rig.free()
	loaded.free()
	DirAccess.remove_absolute("user://camera_roundtrip.tscn")
	for speaker in game.sound_players.values():speaker.stop()
	game.sound_players.clear()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("PASS: ",checks," camera, UI and configuration assertions")
	quit()
