extends SceneTree
var checks=0
func ck(value,label):
	checks+=1
	assert(value,label)
func _initialize():call_deferred("run")
func run():
	for number in [7,10]:
		var wrapper=load("res://Play_Sector_%02d.tscn"%number)
		ck(wrapper!=null,"direct sector launcher loads")
		var g=wrapper.instantiate()
		root.add_child(g)
		g.set_physics_process(false)
		ck(g.sector==number-1 and is_instance_valid(g.player),"sector opens with player")
		g.modal_clicked()
		for enemy in g.drones:enemy.sleep=true
		for i in range(g.gates.size()):
			var gate=g.gates[i]
			g.pos=gate.rect.get_center()+Vector2(-70,0)
			g.run_command(gate.code)
			ck(g.hack_target=="gate:"+str(i),"legacy code selects correct gate challenge")
			var hint=g.console_log.text
			g.notice("unrelated event")
			ck(g.console_log.text==hint,"game notices preserve puzzle hint")
			g.run_command(str(g.expected_answer()))
			ck(gate.open,"one numeric protocol opens gate")
			ck(not g.point_solid(gate.rect.get_center()),"opened gate no longer blocks queries")
		for j in range(1000):
			var point=Vector2(j%960,(j*7)%600)
			var reference=false
			for rect in g.solids():
				if rect.has_point(point):reference=true;break
			ck(g.point_solid(point)==reference,"fast lookup matches collision rectangles")
		var start=Time.get_ticks_usec()
		for j in range(30000):g.point_solid(Vector2(j%960,(j*7)%600))
		print("COLLISION_QUERY_MS ",number," ",(Time.get_ticks_usec()-start)/1000.0)
		if number==10:
			var boss=g.drones.filter(func(e):return e.get("boss",false))[0]
			ck(boss.max_hp==(g.drones[0].max_hp/1.25)*20,"boss health ratio retained")
			g.update_hud()
			ck(g.boss_label.text.contains("KAVYA"),"visible boss status")
			g.release_final_shard_if_defeated()
			for shard in g.shards:shard.got=true
			g.pos=Vector2(g.data.x[0],g.data.x[1])
			g._physics_process(0.016)
			ck(g.game_over and g.pending_action=="restart","boss disabled and memories permit final completion")
		else:
			for shard in g.shards:shard.got=true
			g.pos=Vector2(g.data.x[0],g.data.x[1])
			g._physics_process(0.016)
			ck(g.pending_action=="next","sector 7 can complete")
		for j in range(250):g.projectile(Vector2(100,100),Vector2.RIGHT,false,1,100)
		ck(g.bullets.size()<=192,"projectile population bounded")
		g.burst(Vector2.ZERO,Color.RED,1000)
		ck(g.particles.size()<=160,"effect population bounded")
		g.boss_music.stop()
		for speaker in g.sound_players.values():speaker.stop()
		await create_timer(0.15).timeout
		g.queue_free()
		await process_frame
	await create_timer(0.1).timeout
	print("PASS: ",checks," sector opening, hacking, collision parity, completion and performance-bound checks")
	quit()
