extends SceneTree
var checks=0
func check(condition,label):
	checks+=1
	if not condition:
		push_error("FAILED: "+label)
		assert(condition,label)
func _initialize():call_deferred("run")
func run():
	var game=load("res://Main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.enemy_nav.rng.seed=42019
	for index in range(10):
		game.load_sector(index)
		var drone_count=0
		var stalker_count=0
		for enemy in game.drones:
			if enemy.node.enemy_type==0:drone_count+=1
			else:stalker_count+=1
			check(enemy.node.get_node("EnemySprite").sprite_frames!=null,"animated enemy has sprite frames")
		check(drone_count>0 and stalker_count>0,"both enemy types in each sector")
		check(not game.world.get_node("EnemyPatrolTiles").visible,"patrol overlay hidden in gameplay")
		var started=[]
		var positions=[]
		for enemy in game.drones:
			started.append(enemy.pos)
			positions.append({})
		for frame in range(360):
			game.update_drones(1.0/60)
			for j in range(game.drones.size()):
				var enemy=game.drones[j]
				positions[j][game.enemy_nav.cell_at(enemy.pos)]=true
				var clear=true
				for rect in game.solids():
					if enemy.pos.distance_to(enemy.pos.clamp(rect.position,rect.end))<enemy.node.body_radius-0.1:clear=false
				if not clear:
					check(false,"enemy never crosses wall or closed gate")
				var cell=game.enemy_nav.cell_at(enemy.pos)
				if not game.enemy_nav.allowed.has(cell):check(false,"enemy stays on allowed patrol tiles")
		for j in range(game.drones.size()):
			if game.drones[j].node.enemy_type==2:
				check(game.drones[j].pos==started[j],"rail sentinel remains stationary")
			else:
				check(positions[j].size()>1,"mobile enemy moves across multiple tiles")
		check(true,"all simulated movement avoids walls and gates")
		game.bullets.clear()
	game.load_sector(0)
	var nav=game.enemy_nav
	var drone=game.drones[0]
	var goals={}
	for i in range(24):
		var path=nav.random_path(drone.pos,drone.bounds)
		if not path.is_empty():goals[path[path.size()-1]]=true
	check(goals.size()>1,"random patrol chooses different destinations")
	var before=drone.pos
	drone.sleep=true
	game.update_drones(0.5)
	check(drone.pos==before,"sleep freezes random patrol")
	drone.sleep=false
	var mask=game.world.get_node("EnemyPatrolTiles")
	var snapshot={}
	for cell in mask.get_used_cells():snapshot[cell]=mask.get_cell_atlas_coords(cell)
	mask.clear()
	nav.rebuild(game)
	check(nav.active_cells.is_empty(),"empty mask disallows all patrol cells")
	drone.path=PackedVector2Array()
	before=drone.pos
	game.update_drones(0.1)
	check(drone.pos==before,"enemies freeze when no patrol area remains")
	for cell in snapshot:mask.set_cell(cell,0,snapshot[cell])
	nav.rebuild(game)
	var rev=nav.revision
	game.run_command("access = true")
	check(nav.revision>rev,"opening a gate rebuilds navigation")
	check(not game.clear_enemy_sight(Vector2(100,100),Vector2(940,100)),"walls block line of sight")
	# Controlled melee attack in an open room.
	var stalker=game.drones.filter(func(e):return e.node.enemy_type==1)[0]
	stalker.pos=Vector2(300,300)
	stalker.bounds=Rect2(48,48,864,504)
	game.pos=Vector2(350,300)
	stalker.state="roam"
	stalker.attack_cd=0
	var hull=game.hp
	game.update_stalker(stalker,0.016)
	check(stalker.state=="windup" and game.hp==hull,"stalker telegraphs attack before damage")
	game.update_stalker(stalker,0.5)
	check(stalker.state=="lunge","stalker transitions from warning to lunge")
	game.shielding=false
	for i in range(14):game.update_stalker(stalker,0.016)
	check(game.hp<hull,"stalker lunge damages player")
	check(stalker.state=="recover","stalker has recovery window")
	# Shield blocks the same melee strike.
	stalker.pos=Vector2(300,300)
	game.pos=Vector2(350,300)
	stalker.state="lunge"
	stalker.state_timer=0.22
	stalker.attack_dir=Vector2.RIGHT
	stalker.hit_player=false
	game.shielding=true
	game.energy=100
	hull=game.hp
	for i in range(14):game.update_stalker(stalker,0.016)
	check(game.hp==hull and game.energy<100,"Aegis blocks stalker strike and consumes energy")
	game.run_command("drone.mode = sleep")
	check(stalker.sleep,"sleep command disables stalkers too")
	for speaker in game.sound_players.values():speaker.stop()
	game.sound_players.clear()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("PASS: ",checks," enemy graphics, random movement, collision, patrol-mask and melee assertions")
	quit()
