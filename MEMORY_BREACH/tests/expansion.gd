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
	for level in range(10):
		game.load_sector(level)
		var types={}
		for enemy in game.drones:types[enemy.node.enemy_type]=true
		check(types.size()==4,"four enemy types in every sector")
		check(game.gems.size()==4,"four optional gems in every sector")
		for i in range(4):check(game.gems[i].node.gem_type==i,"distinct gem type")
		check(not game.world.arrival_message.is_empty(),"arrival story exists")
		check(not game.world.memory_fragment.is_empty(),"memory revelation exists")
		check(not game.world.completion_text.is_empty(),"completion story exists")
		check(game.world.get_node("WallTiles") is TileMapLayer,"world remains tile editable")
		for gate in game.gates:
			if not gate.open:game.open_gate(gate)
		for gem in game.gems:
			var path=game.enemy_nav.target_path(game.pos,gem.node.position,Rect2(24,24,912,552))
			check(path.size()>0 and path[path.size()-1].distance_to(gem.node.position)<28,"optional gem is reachable with gates open")
	game.load_sector(0)
	for enemy in game.drones:enemy.sleep=true
	game.hp=40
	game.energy=10
	game.remaining=100
	game.collect_gem(game.gems[0])
	check(game.hp==65,"repair gem heals")
	game.collect_gem(game.gems[0])
	check(game.hp==65,"gem can only be collected once")
	check(not game.gems[0].node.visible,"collected gem disappears")
	game.collect_gem(game.gems[1])
	check(game.energy==45,"Aegis gem restores shield")
	var damage=game.weapon_damage()
	game.collect_gem(game.gems[2])
	check(game.overdrive_remaining==10 and game.weapon_damage()==damage+2,"overdrive gives temporary damage")
	game.fire_cd=0
	game.shoot()
	check(game.fire_cd<game.tuning.base_fire_interval,"overdrive accelerates firing")
	game.collect_gem(game.gems[3])
	check(game.remaining==120,"chrono gem adds time")
	game.modal_clicked()
	check(game.ui.story_history.back()==game.world.arrival_message,"sector start delivers story transmission")
	game.pos=Vector2(game.data.x[0],game.data.x[1])
	game._physics_process(0.016)
	check(game.playing and not game.game_over,"optional gems do not replace required memory shards")
	game.pos=Vector2(110,300)
	for i in range(101):game._physics_process(0.1)
	check(game.overdrive_remaining==0 and game.weapon_damage()==damage,"overdrive expires")
	game.pos=game.shards[0].pos
	game._physics_process(0.016)
	check(game.ui.story_history.back()==game.world.memory_fragment,"required memory shard reveals story")
	game.finish(true)
	check(game.modal_body.text.contains(game.world.completion_text),"completion modal includes story")
	game.hp=0
	game.playing=true
	game._physics_process(0.016)
	check(game.ui.death.dead and game.player.dead,"death activates red overlay and player pose")
	game.ui.death._process(0.5)
	check(game.ui.death.amount>0,"death tint fades in")
	check(game.ui.death.size==root.get_visible_rect().size,"death overlay covers the whole viewport")
	check(game.ui.death.material.get_shader_parameter("strength")>0,"red shader receives intensity")
	check(game.ui.death.mouse_filter==Control.MOUSE_FILTER_IGNORE,"death overlay does not block retry")
	check(game.ui.death.get_index()<game.modal.get_index(),"retry modal draws above death tint")
	game.load_sector(0)
	check(not game.ui.death.dead and game.ui.death.amount==0 and not game.player.dead,"retry clears death effect")
	var sentinel=game.drones.filter(func(e):return e.node.enemy_type==2)[0]
	sentinel.pos=Vector2(200,300)
	game.pos=Vector2(320,300)
	sentinel.state="roam"
	sentinel.cd=0
	var hull=game.hp
	game.update_sentinel(sentinel,0.016)
	check(sentinel.state=="rail_charge" and game.hp==hull,"rail sentinel warns before firing")
	game.pos=Vector2(320,360)
	game.update_sentinel(sentinel,1.0)
	check(game.hp==hull and sentinel.state=="rail_cool","committed rail aim can be dodged")
	check(game.rail_beams.size()>0,"rail beam visual created")
	game.pos=Vector2(320,300)
	sentinel.state="rail_charge"
	sentinel.state_timer=0
	sentinel.attack_dir=Vector2.RIGHT
	game.shielding=false
	game.update_sentinel(sentinel,0.016)
	check(game.hp<hull,"rail hit damages player")
	game.hp=100
	game.energy=100
	game.shielding=true
	sentinel.state="rail_charge"
	sentinel.state_timer=0
	game.update_sentinel(sentinel,0.016)
	check(game.hp==100 and game.energy==70,"shield blocks rail at energy cost")
	game.pos=Vector2(540,300)
	game.shielding=false
	game.fire_rail(sentinel)
	check(game.hp==100,"closed gate blocks rail")
	var wisp=game.drones.filter(func(e):return e.node.enemy_type==3)[0]
	wisp.pos=Vector2(200,300)
	wisp.cd=0
	game.pos=Vector2(320,300)
	game.bullets.clear()
	game.update_wisp(wisp,0.016)
	check(game.bullets.size()==3 and game.bullets[0].kind=="emp","wisp fires EMP spread")
	game.bullets.clear()
	game.hp=100
	game.energy=100
	game.projectile(game.pos,Vector2.RIGHT,false,6,50,"emp",25)
	game.update_bullets(0.001)
	check(game.hp==94 and game.energy==75,"EMP damages hull and drains shield energy")
	game.bullets.clear()
	game.shielding=true
	game.energy=100
	hull=game.hp
	game.projectile(game.pos+Vector2(28,0),Vector2.LEFT,false,6,50,"emp",25)
	game.update_bullets(0.001)
	check(game.hp==hull and game.energy==88 and game.bullets[0].friendly,"Aegis reflects EMP with smaller energy cost")
	game.gems[0].node.pickup_amount=55
	var packed=PackedScene.new()
	check(packed.pack(game.world)==OK,"expanded world packs")
	check(ResourceSaver.save(packed,"user://story_roundtrip.tscn")==OK,"expanded world saves")
	var restored=load("user://story_roundtrip.tscn").instantiate()
	check(restored.get_node("Gems/RepairGem").pickup_amount==55,"gem settings persist")
	check(not restored.memory_fragment.is_empty(),"story fields persist")
	restored.free()
	DirAccess.remove_absolute("user://story_roundtrip.tscn")
	game.load_sector(9)
	game.finish(true)
	check(game.modal_body.text.contains("Bot_404") and game.pending_action=="restart","final ending resolves Elena and campaign")
	for speaker in game.sound_players.values():speaker.stop()
	game.sound_players.clear()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("PASS: ",checks," enemy, gem, death-effect, story and editable-world assertions")
	quit()
