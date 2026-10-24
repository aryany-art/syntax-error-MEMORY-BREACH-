extends SceneTree
var checks=0
var failed=false
func ck(ok,label):
	checks+=1
	if not ok:
		failed=true
		push_error(label)
func _initialize():call_deferred("run")
func run():
	var g=load("res://Play_Sector_10.tscn").instantiate()
	root.add_child(g)
	g.set_physics_process(false)
	g.modal_clicked()
	g.lasers_on=false
	g.summon_timer=999
	var boss=g.drones.filter(func(e):return e.get("boss",false))[0]
	for e in g.drones:
		if not e.get("boss",false):e.sleep=true
	var final=g.final_shard
	ck(not final.released and not final.node.visible,"final shard initially hidden and locked")
	g.pos=final.pos
	g._physics_process(0.016)
	ck(not final.got,"cannot collect locked shard")
	for gate in g.gates:g.open_gate(gate)
	for shard in g.shards:
		if not shard.get("final",false):shard.got=true
	g.pos=Vector2(g.data.x[0],g.data.x[1])
	g._physics_process(0.016)
	ck(not g.game_over,"no ending before boss defeat")
	var drop_pos=boss.pos
	boss.hp=0
	g.release_final_shard_if_defeated()
	ck(final.released and final.node.visible,"defeat releases visible shard")
	ck(final.pos==drop_pos and final.node.position==drop_pos,"drop at current boss position")
	ck(final.node.kind=="Shard","drop uses pickup artwork and collision behavior")
	var total=g.shards.size()
	for i in range(5):g.release_final_shard_if_defeated()
	ck(g.shards.size()==total,"drop happens only once")
	g._physics_process(0.016)
	ck(not g.game_over,"no finale until final shard collected")
	g.pos=drop_pos
	g._physics_process(0.016)
	ck(final.got and not final.node.visible,"final shard picked up normally")
	ck(not g.game_over,"pickup directs player to extraction")
	g.pos=Vector2(g.data.x[0],g.data.x[1])
	g._physics_process(0.016)
	ck(g.game_over and g.pending_action=="restart","finale follows collection and extraction")
	g.load_sector(9)
	ck(not g.final_shard.released and not g.final_shard.got,"restart resets final shard")
	boss=g.drones.filter(func(e):return e.get("boss",false))[0]
	g.developer_cheats_enabled=true
	g.run_command("drone.mode = sleep")
	g.release_final_shard_if_defeated()
	ck(not g.final_shard.released,"developer sleep does not unlock boss shard")
	# The normal one-protocol route also releases the shard.
	g.pos=boss.pos
	g.hack_target="enemy:"+str(g.drones.find(boss))
	g.hack_a=12
	g.hack_b=7
	g.hack_kind=2
	g.run_command(str(g.expected_answer()))
	g.release_final_shard_if_defeated()
	ck(boss.sleep and g.final_shard.released,"legitimate protocol defeat releases shard")
	var p=g.player
	p.set_process(false)
	p.position=Vector2(100,100)
	p.halt()
	p.hacking=false
	p.shielding=false
	var frames={}
	for i in range(50):
		p.drive(Vector2.RIGHT,0.016,[])
		p._process(0.016)
		frames[p.get_node("AnimatedSprite2D").frame]=true
	ck(frames.size()==8,"all eight walking frames survive presentation")
	p.halt()
	p.velocity=Vector2.ZERO
	p.position=Vector2(100,100)
	p.drive(Vector2.RIGHT,0.016,[Rect2(115,0,20,200)])
	var phase=p.stride_phase
	for i in range(20):
		p.drive(Vector2.RIGHT,0.016,[Rect2(115,0,20,200)])
		p._process(0.016)
	ck(is_equal_approx(phase,p.stride_phase),"blocked feet do not cycle")
	ck(not p.moving and p.get_node("AnimatedSprite2D").frame==0,"idle pose when blocked")
	var resting=absf(p.leaning)
	for i in range(60):
		p.drive(Vector2.ZERO,0.016,[])
		p._process(0.016)
	ck(p.gait_blend<0.01 and absf(p.leaning)<=resting,"gait settles after stopping")
	g.boss_music.stop()
	for speaker in g.sound_players.values():speaker.stop()
	await create_timer(0.2).timeout
	g.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("PASS" if not failed else "FAIL",": ",checks," final shard and walking checks")
	quit(1 if failed else 0)
