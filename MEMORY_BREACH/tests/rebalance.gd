extends SceneTree
var count=0
func ck(value,label):count+=1;assert(value,label)
func _initialize():call_deferred("run")
func run():
	var g=load("res://Main.tscn").instantiate()
	root.add_child(g)
	g.set_physics_process(false)
	ck(g.hp==200,"player health doubled")
	for i in range(10):
		g.load_sector(i)
		for e in g.drones:
			if not e.get("boss",false):ck(e.hp==g.enemy_health(e.node),"enemy hull halved")
		ck(g.gems.size()==3,"three remaining gem types")
		for gem in g.world.get_node("Gems").get_children():ck(gem.gem_type!=1,"shield crystals removed from saved worlds")
	g.load_sector(0)
	g.modal_clicked()
	for e in g.drones:e.sleep=true
	g.energy=20
	g._physics_process(0.5)
	ck(is_equal_approx(g.energy,23),"slow shield recovery")
	g.load_sector(1)
	var first=g.weapon_damage()
	g.load_sector(8)
	ck(g.weapon_damage()>first,"weapon upgrades enabled past old cap")
	g.load_sector(9)
	var boss=g.drones.filter(func(e):return e.get("boss",false))[0]
	ck(boss.hp==(g.drones[0].max_hp/1.25)*20,"boss ratio retained with halved baseline")
	g.run_command("drone.mode = sleep")
	ck(not g.drones[0].sleep,"developer command off by default")
	var event=InputEventKey.new()
	event.physical_keycode=KEY_F12
	event.pressed=true
	event.ctrl_pressed=true
	event.shift_pressed=true
	g._unhandled_input(event)
	ck(g.developer_cheats_enabled,"secret developer shortcut")
	g.run_command("drone.mode = sleep")
	ck(not boss.sleep,"KAVYA is immune to global sleep cheat")
	for e in g.drones:
		if not e.get("boss",false):ck(e.sleep,"nonboss bots sleep")
	g.boss_music.stop()
	for speaker in g.sound_players.values():speaker.stop()
	await create_timer(0.2).timeout
	g.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("PASS: ",count," rebalance checks")
	quit()
