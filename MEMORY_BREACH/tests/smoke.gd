extends SceneTree
var checks = 0
func check(condition, description):
	checks += 1
	if not condition:
		push_error("FAILED: " + description)
		quit(1)
		assert(condition, description)
func _initialize():
	call_deferred("run")
func run():
	var game = load("res://Main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	check(game.campaign.size() == 10, "campaign has all 10 sectors")
	for i in range(10):
		game.load_sector(i)
		check(game.sector == i and game.gates.size() > 0, "sector loads with gates")
		check(not game.point_solid(game.pos), "player spawns outside solids")
		check(game.shards.size() == game.data.sh.size(), "shards preserved")
		check(game.world.get_node("Drones").get_child_count() == game.data.dr.size(), "drones preserved")
		for gate in game.gates:
			game.run_command(gate.code.to_upper() + ";")
			check(gate.open, "reference gate command executes")
		game.run_command("laser.power = off")
		check(not game.lasers_on, "laser disable command")
		game.run_command("drone.mode = sleep")
		for drone in game.drones:
			check(drone.sleep, "sleep command disables drones")
		game.hp = 1
		game.run_command("heal")
		check(game.hp == 100, "heal command")
	game.load_sector(0)
	check(game.world.get_node("FloorTiles") is TileMapLayer, "world uses editable TileMapLayer")
	check(game.player.get_node("AnimatedSprite2D").sprite_frames.get_animation_names().size() == 8, "character has 8 idle/walk animations")
	check(game.player.get_script().resource_path == "res://scripts/player.gd", "player has separate script")
	check(game.world.get_node("WallTiles") is TileMapLayer, "walls are paintable tiles")
	check(game.gates[0].node.get_node("CollisionShape2D").shape != null, "gates have collision shapes")
	game.modal_clicked()
	game.pos = Vector2(50,300)
	game.move_player(Vector2(-100,0))
	check(game.pos.x >= 39, "movement respects outer wall")
	game.pos = Vector2(440,300)
	game.move_player(Vector2(100,0))
	check(game.pos.x <= 445.1, "locked gate blocks player")
	game.run_command("access = true")
	game.move_player(Vector2(100,0))
	check(game.pos.x > 496, "open gate is passable")
	check(not game.gates[0].node.visible, "unlocked gate sprite disappears")
	check(game.gates[0].node.get_node("CollisionShape2D").disabled, "unlocked gate native collision disabled")
	game.pos = game.clues[0].pos
	game._physics_process(0.016)
	check(game.clues[0].found, "nearby terminal reveals command")
	game.pos = game.shards[0].pos
	game._physics_process(0.016)
	check(game.shards[0].got, "nearby shard is collected")
	check(not game.shards[0].node.visible, "collected shard sprite disappears")
	game.pos = Vector2(600,300)
	game.aim = Vector2.RIGHT
	game.shielding = true
	game.bullets.clear()
	game.projectile(game.pos+Vector2(29,0), Vector2.LEFT, false, 18, 290)
	game.update_bullets(0.016)
	check(game.bullets.size() == 1 and game.bullets[0].friendly, "Aegis reflects enemy bolt")
	game.shielding = false
	game.bullets.clear()
	var before = game.hp
	game.projectile(game.pos,Vector2.LEFT,false,18,290)
	game.update_bullets(0.016)
	check(game.hp < before, "enemy bolt damages hull")
	game.bullets.clear()
	var drone = game.drones[0]
	before = drone.hp
	game.projectile(drone.pos,Vector2.RIGHT,true,1,530)
	game.update_bullets(0.001)
	check(drone.hp < before, "player bolt damages drone")
	game.load_sector(1)
	game.bullets.clear()
	var receiver = game.receivers[0]
	game.projectile(receiver.pos,Vector2.RIGHT,true,1,530)
	game.update_bullets(0.001)
	check(receiver.lit, "shooting receiver activates it")
	game.modal_clicked()
	game._physics_process(0.001)
	check(game.gates[0].open, "receiver opens linked gate")
	game.pos = Vector2(328,150)
	game.shielding = false
	before = game.hp
	game.update_lasers(0.1)
	check(game.hp < before, "laser damages unshielded player")
	game.shielding = true
	before = game.hp
	game.update_lasers(0.1)
	check(game.hp == before, "Aegis blocks laser damage")
	game.remaining = 0
	game._physics_process(0.016)
	check(game.game_over and game.pending_action == "retry", "timeout creates retry state")
	game.load_sector(0)
	game.modal_clicked()
	for shard in game.shards: shard.got = true
	game.pos = Vector2(game.data.x[0],game.data.x[1])
	game._physics_process(0.016)
	check(game.game_over and game.pending_action == "next", "exit advances after collecting shards")
	game.modal_clicked()
	check(game.sector == 1, "next sector loads")
	game.load_sector(9)
	game.finish(true)
	check(game.pending_action == "restart", "final sector produces campaign ending")
	for speaker in game.sound_players.values():
		speaker.stop()
	game.sound_players.clear()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("PASS: ",checks," native Godot assertions across 10 sectors")
	quit(0)
