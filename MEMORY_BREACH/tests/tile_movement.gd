extends SceneTree
var checks = 0
func check(condition, label):
	checks += 1
	if not condition:
		push_error("FAILED: " + label)
		assert(condition, label)
func _initialize():
	call_deferred("run")
func run():
	var game=load("res://Main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	for i in range(10):
		game.load_sector(i)
		check(game.world.get_node("FloorTiles").get_used_cells().size()==1000,"complete floor grid")
		check(game.world.get_node("WallTiles").get_used_cells().size()>0,"wall grid exists")
		check(game.world.get_node("DecorationTiles") is TileMapLayer,"decoration grid exists")
		var frames=game.player.get_node("AnimatedSprite2D").sprite_frames
		for direction in ["down","left","right","up"]:
			check(frames.get_frame_count("walk_"+direction)==8,"8-frame walking animation")
	game.load_sector(0)
	var wall=game.world.get_node("WallTiles")
	var floor=game.world.get_node("FloorTiles")
	var cell=Vector2i(4,12)
	var center=wall.transform * wall.map_to_local(cell)
	check(not game.point_solid(center),"test location initially clear")
	wall.set_cell(cell,0,Vector2i(3,1))
	game.rebuild_wall_collision()
	check(game.point_solid(center),"painting wall blocks gameplay")
	await physics_frame
	await physics_frame
	var query=PhysicsPointQueryParameters2D.new()
	query.position=game.world.to_global(center)
	query.collision_mask=1
	check(root.world_2d.direct_space_state.intersect_point(query).size()>0,"painted tile native collision exists")
	floor.set_cell(cell,0,Vector2i(1,1))
	var packed=PackedScene.new()
	check(packed.pack(game.world)==OK,"edited world can be packed")
	check(ResourceSaver.save(packed,"user://tile_roundtrip.tscn")==OK,"edited world saves")
	var restored=load("user://tile_roundtrip.tscn").instantiate()
	check(restored.get_node("FloorTiles").get_cell_atlas_coords(cell)==Vector2i(1,1),"floor edit survives save/reload")
	check(restored.get_node("WallTiles").get_cell_source_id(cell)==0,"wall edit survives save/reload")
	restored.free()
	DirAccess.remove_absolute("user://tile_roundtrip.tscn")
	wall.erase_cell(cell)
	game.rebuild_wall_collision()
	check(not game.point_solid(center),"erasing wall removes gameplay obstruction")
	await physics_frame
	await physics_frame
	check(root.world_2d.direct_space_state.intersect_point(query).is_empty(),"erasing wall removes native collision")
	var p=game.player
	p.position=Vector2(110,300)
	p.halt()
	var initial=p.position
	p.drive(Vector2.RIGHT,1.0/60,game.solids())
	check(p.velocity.length()>0 and p.velocity.length()<p.movement_speed,"smooth acceleration")
	for i in range(20):p.drive(Vector2.RIGHT,1.0/60,game.solids())
	check(p.velocity.length()<=p.movement_speed+0.01,"speed capped")
	check(p.stride_phase>0,"gait advances with actual travel")
	var speed=p.velocity.length()
	p.drive(Vector2.ZERO,1.0/60,game.solids())
	check(p.velocity.length()<speed and p.velocity.length()>0,"controlled braking")
	for i in range(30):p.drive(Vector2.ZERO,1.0/60,game.solids())
	check(p.velocity.is_zero_approx() and not p.moving,"comes to rest")
	p.position=Vector2(39.2,300)
	p.velocity=Vector2(-p.movement_speed,0)
	var phase=p.stride_phase
	p.drive(Vector2.LEFT,1.0/60,game.solids())
	check(not p.moving and is_equal_approx(phase,p.stride_phase),"no walking cycle when blocked by wall")
	p.hacking=true
	p.drive(Vector2.RIGHT,1.0/60,game.solids())
	check(p.velocity.is_zero_approx(),"opening laptop stops player")
	p.hacking=false
	for speaker in game.sound_players.values():speaker.stop()
	game.sound_players.clear()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("PASS: ",checks," tile editing, persistence, collision and movement assertions")
	quit()
