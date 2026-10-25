extends SceneTree
var checks=0
var failures=0
func ck(ok,label):
	checks+=1
	if not ok:
		failures+=1
		push_error(label)
func _initialize():call_deferred("run")
func run():
	var g=load("res://Play_Sector_10.tscn").instantiate()
	root.add_child(g)
	g.set_physics_process(false)
	var nav=g.enemy_nav
	# Compare the O(1) nearest-cell path to the previous exhaustive lookup.
	for i in range(300):
		var point=Vector2((i*73)%960,(i*37)%600)
		var bounds=Rect2(48,48,864,504)
		var result=nav.nearest(point,bounds)
		var distance=INF
		for cell in nav.active_cells:
			var candidate=nav.grid.get_point_position(cell)
			if bounds.has_point(candidate):distance=minf(distance,candidate.distance_squared_to(point))
		if result.x>=0:ck(is_equal_approx(nav.grid.get_point_position(result).distance_squared_to(point),distance),"nearest cell retains exact distance")
	var e=g.drones[0].duplicate(false)
	e.bounds=Rect2(-100,-100,1,1)
	e.path=PackedVector2Array()
	e.path_index=0
	e.path_timer=0
	e.nav_revision=-1
	var before=nav.path_queries
	for frame in range(60):g.enemy_patrol_step(e,1.0/60)
	ck(nav.path_queries-before<=2,"empty patrol path respects retry timer")
	ck(e.vel==Vector2.ZERO,"enemy without route stays still")
	nav.random_path(g.drones[0].pos,g.drones[0].bounds)
	ck(not nav.bounds_cells.is_empty(),"patrol candidates cached")
	nav.rebuild(g)
	ck(nav.bounds_cells.is_empty(),"navigation rebuild invalidates cache")
	g.boss_music.stop()
	g.music_player.stop()
	for player in g.sound_players.values():player.stop()
	await create_timer(0.2).timeout
	g.queue_free()
	await process_frame
	print("PASS" if failures==0 else "FAIL",": ",checks," navigation performance checks")
	quit(0 if failures==0 else 1)
