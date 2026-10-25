extends Node2D
## Native Godot port of the supplied MEMORY//BREACH OVERDRIVE campaign.
## All world coordinates preserve the original 960 x 600 sector layout.
@export_range(0, 9) var starting_sector: int = 0
@export var tuning: Resource = preload("res://settings/Gameplay.tres")
@export var developer_cheats_enabled=false
@export var python_executable=""
var python_runtime: Node
var pending_python_target=""
var pending_python_a=0
var pending_python_b=0
var terminal_visual: PanelContainer
var hack_target=""
var hack_stage=0
var hack_a=0
var hack_b=0
var hack_family=0
var hack_kind=0
var summon_timer=5.0
var boss_music: AudioStreamPlayer
var music_player: AudioStreamPlayer
var solids_dirty=true
var cached_solids=[]
var wall_lookup={}
var wall_layer: TileMapLayer
var wall_inverse=Transform2D.IDENTITY
var hud_clock=0.0
var boss_label: Label
var boss_bar: ProgressBar
var challenge_epoch=0
var pending_python_epoch=0
var camera: Camera2D
var enemy_nav = preload("res://scripts/enemy_navigation.gd").new()
const SHEET = preload("res://assets/futuristic_tileset.png")
const CYAN = Color("5ce1e6")
const LIME = Color("c9f76b")
const RED = Color("ff5c70")
const AMBER = Color("f7b955")
const PURPLE = Color("c0a5ff")
const WEAPONS = ["PULSE PISTOL", "ION BLASTER", "DUAL CARBINE", "PLASMA RIFLE", "TRI-BURST CANNON", "OVERCHARGE LANCE", "HEAVY RAILGUN", "QUANTUM SCATTER", "HYPERION BEAM", "OMEGA ANNIHILATOR"]
var campaign = []
var sector = 0
var data = {}
var world: Node2D
var player: CharacterBody2D
var fallback_pos = Vector2.ZERO
var pos: Vector2:
	get:
		return player.position if is_instance_valid(player) else fallback_pos
	set(value):
		fallback_pos = value
		if is_instance_valid(player): player.position = value
var aim = Vector2.RIGHT
var hp = 100.0
var energy = 100.0
var shielding = false
var shield_toggle = false
var fire_cd = 0.0
var remaining = 0.0
var bonus_damage = 0.0
var bonus_shots = 0
var gates = []
var clues = []
var shards = []
var final_shard = {}
var gems=[]
var rail_beams=[]
var overdrive_remaining=0.0
var memory_story_shown=false
var arrival_sent=false
var drones = []
var receivers = []
var beams = []
var bullets = []
var particles = []
var lasers_on = true
var playing = false
var game_over = false
var elapsed = 0.0
var toast_time = 0.0
var touch_held = {}
var touch_mode = false
var stick_origin = Vector2.ZERO
var stick_vector = Vector2.ZERO
var stick_id = -1
var sound_players = {}
var ui: CanvasLayer
var status: Label
var message: Label
var toast_label: Label
var console: PanelContainer
var command_input: LineEdit
var chips: HFlowContainer
var console_log: Label
var modal: PanelContainer
var modal_title: Label
var modal_body: Label
var modal_action: Button
var resume_button: Button
var pending_action = "start"
var saved_sector = 0
var world_offset = Vector2(0, 100)

func _ready():
	campaign = JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign.json"))
	var save = ConfigFile.new()
	if save.load("user://progress.cfg") == OK:
		saved_sector = clampi(int(save.get_value("campaign", "sector", 0)), 0, 9)
	for sound_name in ["pulse", "hack", "shard", "end", "drone_down", "kavya_victory"]:
		var speaker = AudioStreamPlayer.new()
		speaker.stream = load("res://assets/" + sound_name + ".wav")
		speaker.volume_db = tuning.effects_volume_db
		speaker.max_polyphony=4 if sound_name=="drone_down" else 1
		add_child(speaker)
		sound_players[sound_name] = speaker
	camera = $CameraRig/Camera2D
	boss_music=AudioStreamPlayer.new()
	boss_music.stream=preload("res://assets/kavya_entry.wav")
	boss_music.volume_db=tuning.music_volume_db+6
	add_child(boss_music)
	music_player=AudioStreamPlayer.new()
	music_player.name="BackgroundMusic"
	var theme=preload("res://assets/memory_breach_theme.wav").duplicate()
	theme.loop_mode=AudioStreamWAV.LOOP_FORWARD
	theme.loop_begin=0
	theme.loop_end=int(round(theme.get_length()*theme.mix_rate))
	music_player.stream=theme
	music_player.volume_db=tuning.music_volume_db
	add_child(music_player)
	boss_music.finished.connect(restore_music_volume)
	sound_players["kavya_victory"].finished.connect(restore_music_volume)
	build_ui()
	terminal_visual=PanelContainer.new()
	terminal_visual.set_script(preload("res://scripts/hack_visual.gd"))
	ui.add_child(terminal_visual)
	terminal_visual.hide()
	python_runtime=Node.new()
	python_runtime.set_script(preload("res://scripts/python_runtime.gd"))
	python_runtime.python_executable=python_executable
	add_child(python_runtime)
	python_runtime.finished.connect(python_finished)

	load_sector(starting_sector)

func region(x, y):
	var a = Vector2(round(x * 1254.0 / 8), round(y * 1254.0 / 8))
	var b = Vector2(round((x + 1) * 1254.0 / 8), round((y + 1) * 1254.0 / 8))
	return Rect2(a, b - a)

func load_sector(index):
	challenge_epoch+=1
	solids_dirty=true
	sector = clampi(index, 0, 9)
	data = campaign[sector].duplicate(true)
	pos = Vector2(data.s[0], data.s[1])
	hp = tuning.max_hull
	energy = tuning.max_energy * (0.5 if sector==0 else 1.0)
	if is_instance_valid(boss_music):boss_music.stop()
	if is_instance_valid(music_player):music_player.stop()
	for id in ["drone_down","kavya_victory"]:
		if sound_players.has(id):sound_players[id].stop()
	hack_target=""
	hack_stage=0
	summon_timer=5
	remaining = float(data.tm)
	fire_cd = 0.0
	bonus_damage = 0.0
	bonus_shots = 0
	shield_toggle = false
	shielding = false
	lasers_on = true
	gates.clear()
	clues.clear()
	shards.clear()
	final_shard.clear()
	gems.clear()
	rail_beams.clear()
	overdrive_remaining=0
	memory_story_shown=false
	arrival_sent=false
	ui.clear_touch_buttons()
	ui.story_time=0.0
	ui.death.clear_effect()
	drones.clear()
	receivers.clear()
	bullets.clear()
	beams.clear()
	particles.clear()
	touch_held.clear()
	stick_vector = Vector2.ZERO
	stick_id = -1
	load_editable_world()
	remaining = data.tm * tuning.timer_multiplier
	console.hide()
	game_over = false
	playing = false
	show_modal("SECTOR %02d  /  %s" % [sector + 1, data.t], str(data.b) + "\n\n" + str(data.h), "ENTER SECTOR", "start")
	resume_button.visible = saved_sector > 0 and sector == 0
	refresh_chips()
	update_hud()
	sync_visuals()
	queue_redraw()

func save_progress():
	if not tuning.persist_progress: return
	var save = ConfigFile.new()
	save.set_value("campaign", "sector", sector)
	save.save("user://progress.cfg")
	saved_sector = sector

func show_modal(title_text, body_text, button_text, action):
	modal_title.text = title_text
	modal_body.text = body_text
	modal_action.text = button_text
	pending_action = action
	modal.show()
	resume_button.hide()

func modal_clicked():
	modal.hide()
	if pending_action == "next":
		load_sector(sector + 1)
	elif pending_action == "retry":
		load_sector(sector)
	elif pending_action == "restart":
		ui.reset_story_history()
		load_sector(0)
	else:
		playing = true
		game_over = false
		save_progress()
		if not arrival_sent:
			ui.transmit(world.arrival_message,9.0)
			arrival_sent=true
			music_player.volume_db=tuning.music_volume_db
			music_player.play()
			if sector==9:
				music_player.volume_db=tuning.music_volume_db-10
				boss_music.play()

func finish(success, reason = ""):
	if is_instance_valid(boss_music):boss_music.stop()
	if is_instance_valid(music_player):music_player.stop()
	if not (success and sector==9 and sound_players["kavya_victory"].playing):sound("end")
	playing = false
	if is_instance_valid(player): player.halt()
	game_over = true
	console.hide()
	if not success:
		ui.death.trigger_death()
		player.set_dead(true)
	if success and sector == 9:
		show_modal("THE HUMAN EXCEPTION", world.completion_text, "NEW CAMPAIGN", "restart")
	elif success:
		show_modal("SECTOR RESTORED", world.completion_text + "\n\nNext weapon: " + WEAPONS[sector+1], "NEXT SECTOR", "next")
	else:
		show_modal("CONNECTION LOST", reason + "\n\nRetry this sector with a restored hull and Aegis.", "RETRY SECTOR", "retry")

func solids():
	if not solids_dirty:return cached_solids
	cached_solids=[]
	for w in data.w:cached_solids.append(Rect2(w[0],w[1],w[2],w[3]))
	for gate in gates:
		if not gate.open:cached_solids.append(gate.rect)
	solids_dirty=false
	return cached_solids

func point_solid(p):
	if is_instance_valid(wall_layer) and wall_lookup.has(wall_layer.local_to_map(wall_inverse*p)):return true
	for gate in gates:
		if not gate.open and gate.rect.has_point(p):return true
	return false

func move_player(delta_pos):
	if is_instance_valid(player): player.try_move(delta_pos, solids())

func weapon_damage():
	return tuning.base_weapon_damage + sector * tuning.damage_per_sector + bonus_damage + (2.0 if overdrive_remaining>0 else 0.0)

func projectile(origin, direction, friendly, damage, speed, kind="plasma", energy_drain=0.0):
	if bullets.size()>=192:bullets.pop_front()
	bullets.append({"pos": origin, "vel": direction * speed, "friendly": friendly, "damage": damage, "life": 2.1 if friendly else maxf(2.1, 900.0/maxf(speed,1.0)), "kind":kind, "energy_drain":energy_drain})

func restore_music_volume():
	if is_instance_valid(music_player):music_player.volume_db=tuning.music_volume_db

func sound(id):
	if sound_players.has(id): sound_players[id].play()

func shoot():
	if fire_cd > 0 or console.visible:
		return
	sound("pulse")
	player.target_facing = aim
	player.kick()
	camera.add_shake(0.05)
	fire_cd = maxf(tuning.minimum_fire_interval, tuning.base_fire_interval - sector * tuning.interval_reduction)
	if overdrive_remaining>0:fire_cd*=0.7
	var count = mini(4, (3 if sector >= tuning.triple_shot_sector else (2 if sector >= tuning.dual_shot_sector else 1)) + bonus_shots)
	for i in range(count):
		var direction = aim.rotated((i - (count - 1) / 2.0) * 0.14)
		projectile(pos + aim * 23, direction, true, weapon_damage(), tuning.bullet_speed + sector * tuning.bullet_speed_per_sector)
	burst(pos + aim * 25, CYAN, 3)

func burst(p, color, amount):
	for i in range(amount):
		if particles.size()>=160:return
		particles.append({"pos": p, "vel": Vector2.from_angle(randf() * TAU) * randf_range(20, 130), "life": randf_range(0.15, 0.5), "color": color})

func notice(text):
	toast_label.text = text
	toast_time = 3.0
	if hack_target.is_empty():console_log.text = text

func normalized_command(text):
	return " ".join(str(text).to_lower().replace(";", "").replace("\"", "").replace("'", "").split(" ", false)).strip_edges()

func execute_command(text):
	var code = normalized_command(text)
	if code.is_empty():
		return
	var ok = false
	for gate in gates:
		if not gate.open and normalized_command(gate.code) == code:
			open_gate(gate)
			ok = true
	if code in ["laser.power = off", "laser = off"]:
		lasers_on = false
		ok = true
	if developer_cheats_enabled and code in ["drone.mode = sleep", "drone.sleep()"]:
		for drone in drones:
			if not drone.get("boss",false):drone.sleep = true
		ok = true
	if developer_cheats_enabled and code in ["heal", "sudo heal"]:
		hp = tuning.max_hull
		energy = tuning.max_energy
		ok = true
	if developer_cheats_enabled and code == "overclock":
		bonus_damage += 2.0
		bonus_shots = mini(3, bonus_shots + 1)
		ok = true
	if ok:
		sound("hack")
		for clue in clues:
			if normalized_command(clue.code) == code:
				clue.used = true
		notice("EXECUTED: " + code)
		command_input.clear()
	else:
		notice("SYNTAX ERROR: " + text)
	refresh_chips()

func open_gate(gate):
	solids_dirty=true
	gate.open = true
	enemy_nav.rebuild(self)
	if gate.has("node"): gate.node.set_activated(true)
	burst(gate.rect.get_center(), LIME, 18)
	notice("UNLOCKED: " + gate.name)

func toggle_console():
	if not playing:
		return
	console.visible = not console.visible
	if console.visible:
		refresh_chips()
		command_input.grab_focus()
	else:
		command_input.release_focus()

func refresh_chips():
	for child in chips.get_children():
		chips.remove_child(child)
		child.queue_free()
	for i in range(clues.size()):
		if clues[i].found and (developer_cheats_enabled or clues[i].code not in ["drone.mode = sleep","drone.sleep()"]):
			var button=Button.new()
			button.text="BREACH: "+clues[i].name
			button.pressed.connect(begin_hack.bind("terminal:"+str(i)))
			chips.add_child(button)
	for i in range(gates.size()):
		if not gates[i].open and pos.distance_to(gates[i].rect.get_center())<160:
			var button=Button.new()
			button.text="BREACH GATE: "+gates[i].name
			button.pressed.connect(begin_hack.bind("gate:"+str(i)))
			chips.add_child(button)
	for i in range(drones.size()):
		if drones[i].hp>0 and pos.distance_to(drones[i].pos)<110:
			var button=Button.new()
			button.text="BREACH "+("KAVYA" if drones[i].get("boss",false) else "ENEMY %d"%i)
			button.pressed.connect(begin_hack.bind("enemy:"+str(i)))
			chips.add_child(button)

func begin_hack(target):
	challenge_epoch+=1
	hack_target=target
	hack_stage=0
	new_protocol()

func expected_answer():
	return [hack_a+2*hack_b,hack_a*hack_b*hack_b,hack_a^hack_b,((hack_a<<1)|hack_b)&63][hack_kind]

func new_protocol():
	hack_a=randi_range(7,31)
	hack_b=randi_range(3,15)
	hack_kind=randi_range(0,3)
	var rules=["AP third term: a + 2*b", "GP third term: a*b*b", "XOR gate output: a ^ b", "Logic output: ((a << 1) | b) & 63"]
	console_log.text="PROTOCOL 1/1 | a=%d  b=%d | %s"%[hack_a,hack_b,rules[hack_kind]]
	command_input.placeholder_text=">>> Python code: print(a ^ b), import math, x = 10 ..."
	command_input.clear()
	terminal_visual.protocol(console_log.text)

func evaluate_terminal(source):
	var text=str(source).strip_edges()
	if text.begins_with(">>>"):text=text.substr(3).strip_edges()
	if text.begins_with("print(") and text.ends_with(")"):text=text.substr(6,text.length()-7).strip_edges()
	# Restricted arithmetic/bitwise expressions only; no calls, objects or file access.
	var valid=RegEx.new()
	valid.compile("^[0-9ab +*/%()&|^<>~-]+$")
	if text.length()>160 or valid.search(text)==null:return null
	var expression=Expression.new()
	if expression.parse(text,PackedStringArray(["a","b"]))!=OK:return null
	var value=expression.execute([hack_a,hack_b],null,false,true)
	if expression.has_execute_failed() or not (value is int or value is float):return null
	return value

func run_command(text):
	if developer_cheats_enabled and normalized_command(text) in ["drone.mode = sleep","drone.sleep()","heal","sudo heal","overclock"]:
		execute_command(text)
		return
	if python_runtime.busy:
		terminal_visual.line("[BUSY] Python is still executing.")
		return
	var legacy=normalized_command(text)
	for i in range(gates.size()):
		if normalized_command(gates[i].code)==legacy:
			var known=pos.distance_to(gates[i].rect.get_center())<160
			for clue in clues:
				if clue.found and normalized_command(clue.code)==legacy:known=true
			if not known:
				terminal_visual.line("[LOCKED] Approach this gate or read its terminal first.")
				return
			if gates[i].open:
				terminal_visual.line("[INFO] Gate already open.")
				return
			begin_hack("gate:"+str(i))
			terminal_visual.line("[AUTH] Gate code recognized. Solve the displayed one-protocol puzzle to authorize it.")
			return
	pending_python_epoch=challenge_epoch
	pending_python_target=hack_target
	pending_python_a=hack_a
	pending_python_b=hack_b
	terminal_visual.line(">>> "+str(text))
	command_input.clear()
	var literal=str(text).strip_edges()
	if literal.is_valid_int():
		python_finished({"ok":true,"output":literal,"numeric":int(literal)})
	else:
		python_runtime.submit(text,hack_a,hack_b)

func python_finished(response):
	terminal_visual.line(str(response.get("output","")))
	if not response.ok or pending_python_target.is_empty():return
	if challenge_epoch!=pending_python_epoch or hack_target!=pending_python_target or hack_a!=pending_python_a or hack_b!=pending_python_b:
		terminal_visual.line("[AUTH] Output belongs to an older challenge; select the current target.")
		return
	var value=response.get("numeric",null)
	if value==null:
		terminal_visual.line("[AUTH] Python ran, but produced no numeric answer. Use print(...) or finish with a numeric expression.")
		return
	if value!=expected_answer():
		terminal_visual.line("[AUTH] Incorrect numeric result. Retry this protocol.")
		return
	terminal_visual.line("[AUTH] Protocol 1/1 accepted")
	var completed_target=hack_target
	var breach_succeeded=true
	var parts=hack_target.split(":")
	var index=int(parts[1])
	if parts[0]=="gate":
		open_gate(gates[index])
	elif parts[0]=="terminal":
		execute_command(clues[index].code)
	else:
		if pos.distance_to(drones[index].pos)>140:
			breach_succeeded=false
			notice("Target out of range; breach lost")
		else:
			drones[index].sleep=true
			notice("Protocol breached: target disabled")
	if breach_succeeded:terminal_visual.breach(completed_target)
	hack_target=""
	hack_stage=0
	refresh_chips()

func down(key):
	return Input.is_physical_key_pressed(key)

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_F12 and event.ctrl_pressed and event.shift_pressed:
		developer_cheats_enabled=not developer_cheats_enabled
		notice("Developer commands enabled" if developer_cheats_enabled else "Developer commands disabled")
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_E:
			toggle_console()
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_Q:
			shield_toggle = not shield_toggle
		elif event.physical_keycode == KEY_R and not console.visible:
			load_sector(sector)
		elif event.physical_keycode == KEY_ESCAPE:
			if console.visible:
				console.hide()
			elif playing:
				playing = false
				player.halt()
				show_modal("CONNECTION PAUSED", "Take a breath. Your sector is preserved.", "RESUME", "start")
	if event is InputEventScreenTouch:
		if event.pressed and event.position.x < 400 and event.position.y > 400 and stick_id == -1:
			stick_id = event.index
			stick_origin = event.position
		elif not event.pressed and event.index == stick_id:
			stick_id = -1
			stick_vector = Vector2.ZERO
	if event is InputEventScreenDrag and event.index == stick_id:
		stick_vector = (event.position - stick_origin).limit_length(65.0) / 65.0

func _physics_process(dt):
	if is_instance_valid(terminal_visual):terminal_visual.visible=console.visible and not modal.visible

	camera.screen_aim = aim
	camera.input_blocked = console.visible
	for i in range(rail_beams.size()-1,-1,-1):
		rail_beams[i].ttl-=dt
		if rail_beams[i].ttl<=0:rail_beams.remove_at(i)
	elapsed += dt
	toast_time = maxf(0, toast_time - dt)
	toast_label.visible = toast_time > 0
	if not playing:
		sync_visuals()
		queue_redraw()
		return
	var hull_before=hp
	overdrive_remaining=maxf(0,overdrive_remaining-dt)
	remaining -= dt
	fire_cd -= dt
	if remaining <= 0:
		finish(false, "Connection timed out.")
		return
	var direction = Vector2.ZERO
	if not console.visible:
		direction = Vector2(float(down(KEY_D) or down(KEY_RIGHT)) - float(down(KEY_A) or down(KEY_LEFT)), float(down(KEY_S) or down(KEY_DOWN)) - float(down(KEY_W) or down(KEY_UP))) + stick_vector
		if touch_held.get("left", false): direction.x -= 1
		if touch_held.get("right", false): direction.x += 1
		if touch_held.get("up", false): direction.y -= 1
		if touch_held.get("down", false): direction.y += 1
		if touch_mode:
			var target_distance = 450.0
			for drone in drones:
				if drone.hp > 0 and pos.distance_to(drone.pos) < target_distance:
					aim = (drone.pos - pos).normalized()
					target_distance = pos.distance_to(drone.pos)
			if target_distance == 450.0 and direction.length() > 0.1:
				aim = direction.normalized()
		else:
			aim = (get_global_mouse_position() - world_offset - pos).normalized()
		if aim.length() < 0.1: aim = Vector2.RIGHT
	var wants_shield = down(KEY_SHIFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or shield_toggle or touch_held.get("shield", false)
	shielding = wants_shield and energy > 4 and not console.visible
	energy = clampf(energy + (-tuning.shield_drain if shielding else tuning.shield_recharge) * dt, 0, tuning.max_energy)
	if energy <= 4: shield_toggle = false
	player.present(aim, shielding, console.visible)
	player.drive(direction, dt, solids())
	if not console.visible and (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or down(KEY_SPACE) or touch_held.get("fire", false)):
		shoot()
	for clue in clues:
		if not clue.found and pos.distance_to(clue.pos) < 52:
			clue.found = true
			notice("TERMINAL: " + clue.name + "   [E: BREACH]")
			burst(clue.pos, AMBER, 10)
			refresh_chips()
	for shard in shards:
		if shard.get("released",true) and not shard.got and pos.distance_to(shard.pos) < 28:
			shard.got = true
			sound("shard")
			burst(shard.pos, PURPLE, 18)
			if shard.get("final",false):
				notice("FINAL SHARD RECOVERED — reach extraction to restore Elena")
				ui.transmit("ELENA: That is the last piece, Patch. The purge signature is broken. Bring my memory to the rescue bridge. Leave the others free to choose.",12.0)
			else:
				notice("Memory shard recovered")
			if not memory_story_shown and not shard.get("final",false):
				ui.transmit(world.memory_fragment,10.0)
				memory_story_shown=true
	for gem in gems:
		if not gem.got and pos.distance_to(gem.node.position)<28:collect_gem(gem)
	update_kavya(dt)
	update_drones(dt)
	update_bullets(dt)
	release_final_shard_if_defeated()
	update_lasers(dt)
	for gate in gates:
		if not gate.open and not str(gate.sensor).is_empty():
			for receiver in receivers:
				if receiver.id == gate.sensor and receiver.lit:
					open_gate(gate)
	for i in range(particles.size()-1, -1, -1):
		var p = particles[i]
		p.pos += p.vel * dt
		p.life -= dt
		if p.life <= 0: particles.remove_at(i)
	if hp<hull_before:ui.death.flash_damage()
	if hp <= 0:
		finish(false, "Hull destroyed. Reflect drone bolts with Aegis or use terminal commands to disable threats.")
	elif pos.distance_to(Vector2(data.x[0], data.x[1])) < 30:
		var all_found = true
		for shard in shards:
			if not shard.got or not shard.get("released",true): all_found = false
		if all_found and (sector!=9 or drones.filter(func(e):return e.get("boss",false) and e.hp>0 and not e.sleep).is_empty()):
			finish(true)
		elif toast_time <= 0:
			if sector==9 and not final_shard.get("released",false):
				notice("Defeat or breach KAVYA to release the final shard")
			elif sector==9 and not final_shard.get("got",false):
				notice("Collect KAVYA's released final shard before extracting")
			else:
				notice("Collect every memory shard before extracting")
	hud_clock+=dt
	if hud_clock>=0.1:
		hud_clock=0
		update_hud()
	sync_visuals()
	queue_redraw()

func clear_enemy_sight(a,b):
	var steps=maxi(1,int(ceil(a.distance_to(b)/8.0)))
	for i in range(1,steps):
		if point_solid(a.lerp(b,float(i)/steps)):return false
	return true

func enemy_patrol_step(enemy,dt,chasing=false):
	enemy.path_timer-=dt
	if enemy.nav_revision!=enemy_nav.revision or enemy.path_timer<=0 or (enemy.path.size()>1 and enemy.path_index>=enemy.path.size()):
		enemy.path = enemy_nav.target_path(enemy.pos,pos,enemy.bounds) if chasing else enemy_nav.random_path(enemy.pos,enemy.bounds)
		if enemy.get("boss",false) and chasing and enemy.path.size()<=1:
			enemy.path=enemy_nav.random_path(enemy.pos,enemy.bounds)
		enemy.path_index=0
		enemy.path_timer=0.35 if chasing else enemy_nav.rng.randf_range(enemy.node.retarget_min,maxf(enemy.node.retarget_min,enemy.node.retarget_max))
		enemy.nav_revision=enemy_nav.revision
	while enemy.path_index<enemy.path.size() and enemy.pos.distance_to(enemy.path[enemy.path_index])<5:
		enemy.path_index+=1
	if enemy.path_index>=enemy.path.size():
		enemy.vel=Vector2.ZERO
		return
	var target=enemy.path[enemy.path_index]
	var speed=enemy.node.chase_speed if chasing else enemy.node.patrol_speed+sector*enemy.node.speed_gain_per_sector
	var delta_pos=(target-enemy.pos).limit_length(speed*dt)
	var actual=enemy_nav.move(enemy,delta_pos,solids())
	enemy.vel=actual/maxf(dt,0.001)
	if actual.length()<0.01:enemy.path_timer=minf(enemy.path_timer,0.2)

func update_stalker(enemy,dt):
	enemy.attack_cd=maxf(0,enemy.attack_cd-dt)
	if enemy.state=="windup":
		enemy.state_timer-=dt
		enemy.vel=Vector2.ZERO
		enemy.node.look_direction=enemy.attack_dir
		if enemy.state_timer<=0:
			enemy.state="lunge"
			enemy.state_timer=enemy.node.lunge_duration
			enemy.hit_player=false
		return
	if enemy.state=="lunge":
		enemy.state_timer-=dt
		var actual=enemy_nav.move(enemy,enemy.attack_dir*enemy.node.lunge_speed*dt,solids())
		enemy.vel=actual/maxf(dt,0.001)
		if not enemy.hit_player and enemy.pos.distance_to(pos)<34 and clear_enemy_sight(enemy.pos,pos):
			enemy.hit_player=true
			if shielding and energy>4:
				energy=maxf(0,energy-18)
				burst(pos,LIME,8)
			else:
				hp-=enemy.node.melee_damage*tuning.enemy_damage_multiplier
				camera.add_shake(0.4)
				burst(pos,PURPLE,10)
		if enemy.state_timer<=0:
			enemy.state="recover"
			enemy.state_timer=enemy.node.recovery_time
		return
	if enemy.state=="recover":
		enemy.vel=Vector2.ZERO
		enemy.state_timer-=dt
		if enemy.state_timer<=0:
			enemy.state="roam"
			enemy.path_timer=0
		return
	var sees_player=enemy.pos.distance_to(pos)<enemy.node.detection_range and enemy.bounds.has_point(pos) and clear_enemy_sight(enemy.pos,pos)
	if sees_player and enemy.pos.distance_to(pos)<enemy.node.attack_range and enemy.attack_cd<=0:
		enemy.state="windup"
		enemy.state_timer=enemy.node.windup_time
		enemy.attack_dir=(pos-enemy.pos).normalized()
		enemy.attack_cd=enemy.node.windup_time+enemy.node.lunge_duration+enemy.node.recovery_time
		enemy.node.flash_attack(enemy.attack_dir)
		enemy.vel=Vector2.ZERO
		return
	var desired_state="chase" if sees_player else "roam"
	if enemy.state!=desired_state:enemy.path_timer=0
	enemy.state=desired_state
	enemy_patrol_step(enemy,dt,sees_player)

func update_drones(dt):
	for drone in drones:
		if drone.hp<=0 or drone.sleep:
			drone.vel=Vector2.ZERO
			continue
		drone.stun=maxf(0,drone.stun-dt)
		if drone.stun>0:
			drone.vel=Vector2.ZERO
			continue
		if drone.node.enemy_type==2:
			update_sentinel(drone,dt)
			continue
		if drone.node.enemy_type==3:
			update_wisp(drone,dt)
			continue
		if drone.node.enemy_type==1:
			update_stalker(drone,dt)
			continue
		var pursuing=drone.get("boss",false) and drone.pos.distance_to(pos)<drone.node.detection_range and drone.pos.distance_to(pos)>150
		drone.state="chase" if pursuing else "roam"
		enemy_patrol_step(drone,dt,pursuing)
		drone.cd-=dt
		if drone.cd<=0 and drone.pos.distance_to(pos)<drone.node.detection_range*tuning.drone_detection_range/360.0 and clear_enemy_sight(drone.pos,pos):
			drone.cd=maxf(drone.node.minimum_interval,drone.node.fire_interval-sector*drone.node.interval_reduction)
			var direction=(pos-drone.pos).normalized()
			drone.node.flash_attack(direction)
			var count=3 if sector>=8 else (2 if sector>=4 else 1)
			for i in range(count):
				projectile(drone.pos,direction.rotated((i-(count-1)/2.0)*0.16),false,round(drone.node.shot_damage+sector*drone.node.damage_per_sector)*tuning.enemy_damage_multiplier,drone.node.projectile_speed+sector*drone.node.speed_per_sector)

func update_bullets(dt):
	for i in range(bullets.size()-1, -1, -1):
		var q = bullets[i]
		q.life -= dt
		var count = maxi(1, int(ceil(q.vel.length() * dt / 5)))
		for _step in range(count):
			if q.life <= 0: break
			q.pos += q.vel * dt / count
			if point_solid(q.pos):
				q.life = 0
				break
			if q.friendly:
				for receiver in receivers:
					if not receiver.lit and q.pos.distance_to(receiver.pos) < 22:
						receiver.lit = true
						q.life = 0
						burst(receiver.pos, LIME, 10)
				for drone in drones:
					if q.life > 0 and drone.hp > 0 and q.pos.distance_to(drone.pos) < 24:
						drone.hp -= q.damage
						if drone.hp<=0 and not drone.get("boss",false) and drone.node.enemy_type==0:
							sound("drone_down")
						drone.stun = drone.node.stun_duration
						q.life = 0
						burst(drone.pos, RED, 8)
			else:
				if shielding and q.pos.distance_to(pos) < 34:
					if q.get("kind","plasma")=="emp":energy=maxf(0,energy-12)
					q.friendly = true
					q.vel = aim * q.vel.length() * 1.35
					q.damage = weapon_damage() * 1.5
					q.life = 1.5
					burst(q.pos, LIME, 8)
				elif q.pos.distance_to(pos) < 17:
					hp -= q.damage
					energy=maxf(0,energy-q.get("energy_drain",0.0))
					camera.add_shake(0.35)
					q.life = 0
		if q.life <= 0: bullets.remove_at(i)

func update_lasers(dt):
	beams.clear()
	if not lasers_on: return
	for a in data.tu:
		var origin = Vector2(a[0], a[1])
		var direction = Vector2(a[2], a[3])
		var end = origin
		var hit_player = false
		for distance in range(8, 1100, 4):
			end = origin + direction * distance
			if point_solid(end): break
			if end.distance_to(pos) < (31 if shielding else 15):
				hit_player = true
				if shielding:
					energy = maxf(0, energy - tuning.shield_laser_drain * dt)
				else:
					hp -= tuning.laser_damage_per_second * dt
				break
		beams.append({"a": origin, "b": end, "blocked": hit_player and shielding})

func build_ui():
	ui = $GameUI
	var boss_box=VBoxContainer.new()
	boss_box.name="BossStatus"
	boss_box.position=Vector2(220,95)
	boss_box.size=Vector2(520,48)
	ui.add_child(boss_box)
	boss_label=Label.new()
	boss_label.add_theme_color_override("font_color",Color("ff70de"))
	boss_box.add_child(boss_label)
	boss_bar=ProgressBar.new()
	boss_bar.custom_minimum_size=Vector2(520,12)
	boss_bar.show_percentage=false
	boss_box.add_child(boss_bar)
	status = ui.status
	message = ui.objective
	toast_label = ui.toast
	console = ui.console
	command_input = ui.command_input
	chips = ui.chips
	console_log = ui.console_log
	modal = ui.modal
	modal_title = ui.modal_title
	modal_body = ui.modal_body
	modal_action = ui.modal_action
	resume_button = ui.resume_button
	ui.command_requested.connect(run_command)
	ui.console_close_requested.connect(toggle_console)
	ui.modal_action_requested.connect(modal_clicked)
	ui.resume_requested.connect(func(): load_sector(saved_sector))
	ui.touch_action.connect(func(id, pressed):
		if id == "hack" and pressed: toggle_console()
		else: touch_held[id] = pressed)
	command_input.gui_input.connect(console_key)
	touch_mode = ui.get_node("TouchControls").visible
	ui.touch_controls_enabled.connect(func():touch_mode=true)

func console_key(event):
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		console.hide()
		get_viewport().set_input_as_handled()

func update_hud():
	boss_label.get_parent().visible=sector==9
	if sector==9:
		var bosses=drones.filter(func(e):return e.get("boss",false))
		if not bosses.is_empty():
			var boss=bosses[0]
			boss_bar.max_value=boss.max_hp
			boss_bar.value=maxf(0,boss.hp)
			boss_label.text="KAVYA  %d / %d  |  %s"%[maxi(0,int(boss.hp)),int(boss.max_hp),("FINAL SHARD RECOVERED — EXTRACT" if final_shard.get("got",false) else "DEFEATED — COLLECT FINAL SHARD") if boss.sleep or boss.hp<=0 else ("PHASE 2" if boss.hp<boss.max_hp*0.5 else "PHASE 1")]
	var found = 0
	var known = 0
	for shard in shards:
		if shard.got: found += 1
	for clue in clues:
		if clue.found: known += 1
	status.text = "SEC %02d   %s   |   %d:%02d   |   HULL %d/%d   AEGIS %d%%" % [sector+1, data.t, int(maxf(0,remaining))/60, int(maxf(0,remaining))%60, int(maxf(0,hp)), int(tuning.max_hull), int(energy/tuning.max_energy*100)]
	message.text = "%s   |   SHARDS %d/%d   KEYS %d/%d   LASERS %s" % [WEAPONS[sector], found, shards.size(), known, clues.size(), "ONLINE" if lasers_on else "OFF"]

	if overdrive_remaining>0:message.text+="   |   BOOST %.0fs"%overdrive_remaining

func sprite(x, y, center, size, tint = Color.WHITE):
	draw_texture_rect_region(SHEET, Rect2(center-size/2, size), region(x,y), tint)

func text_at(at, text, color, size = 12):
	draw_string(ThemeDB.fallback_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw():
	if data.is_empty(): return
	draw_set_transform(world_offset)
	for gate in gates:
		if not gate.open:
			text_at(gate.rect.position+Vector2(-15,-6),gate.name,AMBER,10)
	for clue in clues:
		text_at(clue.pos+Vector2(-27,-29),clue.name,AMBER,10)
	for receiver in receivers:
		text_at(receiver.pos+Vector2(-10,-25),receiver.id,LIME if receiver.lit else AMBER)
	for beam in beams:
		var color = LIME if beam.blocked else RED
		draw_line(beam.a,beam.b,Color(color,0.15),13,true)
		draw_line(beam.a,beam.b,color,3,true)
		draw_line(beam.a,beam.b,Color.WHITE,1,true)
	for drone in drones:
		if drone.hp <= 0: continue
		var p = drone.pos
		var color = Color("849ab2") if drone.sleep else RED
		draw_rect(Rect2(p+Vector2(-22,-32),Vector2(44,4)),Color("172534"))
		draw_rect(Rect2(p+Vector2(-22,-32),Vector2(44*maxf(0,drone.hp)/drone.max_hp,4)),color)
		text_at(p+Vector2(-20,38),"SLEEP" if drone.sleep else (["DRN.%d"%(sector+1),"STALKER","SENTINEL","EMP WISP"][drone.node.enemy_type]),color,10)
	for rail in rail_beams:
		draw_line(rail.a,rail.b,Color(1,0.55,0.1,0.22),12,true)
		draw_line(rail.a,rail.b,Color("ffbc63"),3,true)
	for enemy in drones:
		if enemy.state=="rail_charge" and not enemy.sleep and enemy.hp>0:
			var end=trace_rail_end(enemy.pos,enemy.attack_dir,enemy.node.rail_range)
			draw_dashed_line(enemy.pos,end,Color("ff9b45"),1.5,9.0)
	for q in bullets:
		var color = (LIME if sector>=3 else CYAN) if q.friendly else RED
		if q.get("kind","plasma")=="emp" and not q.friendly:color=CYAN
		draw_line(q.pos-q.vel.normalized()*10,q.pos,color,4,true)
		draw_circle(q.pos,3,Color.WHITE)
	for p in particles:
		draw_circle(p.pos,2,Color(p.color,clampf(p.life*3,0,1)))
	draw_set_transform(Vector2.ZERO)
	if touch_mode and stick_id >= 0:
		draw_circle(stick_origin,65,Color(0.2,0.8,1,0.12))
		draw_circle(stick_origin+stick_vector*65,23,Color(0.2,0.8,1,0.45))

func draw_ellipse_shadow(p):
	draw_circle(p+Vector2(0,15),19,Color(0,0,0,0.4))

func load_editable_world():
	var previous = get_node_or_null("World")
	if previous:
		remove_child(previous)
		previous.free()
	world = load("res://worlds/Sector_%02d.tscn" % (sector+1)).instantiate()
	world.name = "World"
	world.position = world_offset
	add_child(world)
	player = world.get_node("Player")
	fallback_pos = player.position
	data.s = [player.position.x, player.position.y]
	data.w = []
	rebuild_wall_collision()
	for gate in world.get_node("Gates").get_children():
		gates.append({"name":gate.label if not gate.label.is_empty() else str(gate.name), "rect":Rect2(gate.position,gate.dimensions), "code":gate.command, "sensor":gate.sensor, "open":false, "node":gate})
	for clue in world.get_node("Terminals").get_children():
		clues.append({"pos":clue.position, "name":clue.label, "code":clue.command, "found":false, "used":false, "node":clue})
	for shard in world.get_node("Shards").get_children():
		shards.append({"pos":shard.position, "got":false, "node":shard})
	for receiver in world.get_node("Receivers").get_children():
		receivers.append({"id":receiver.label, "pos":receiver.position, "lit":false, "node":receiver})
	data.tu = []
	for laser in world.get_node("Lasers").get_children():
		data.tu.append([laser.position.x,laser.position.y,laser.laser_direction.x,laser.laser_direction.y])
	for group_name in ["Drones","Stalkers","Sentinels","Wisps"]:
		for drone in world.get_node(group_name).get_children():
			var health=enemy_health(drone)
			drones.append({"pos":drone.position,"vel":Vector2.ZERO,"bounds":drone.patrol_bounds,"hp":health,"max_hp":health,"cd":1.0,"sleep":false,"stun":0.0,"node":drone,"path":PackedVector2Array(),"path_index":0,"path_timer":0.0,"nav_revision":-1,"state":"roam","state_timer":0.0,"attack_cd":0.5,"attack_dir":Vector2.RIGHT,"hit_player":false})
	world.get_node("EnemyPatrolTiles").hide()
	solids_dirty=true
	enemy_nav.rebuild(self)
	for enemy in drones:
		var cell=enemy_nav.nearest(enemy.pos,enemy.bounds)
		if cell.x>=0:
			enemy.pos=enemy_nav.grid.get_point_position(cell)
			enemy.node.position=enemy.pos
	for gem in world.get_node("Gems").get_children():
		if gem.gem_type==1:
			gem.hide()
			continue
		gems.append({"node":gem,"got":false})
	var exit = world.get_node("Extraction")
	data.x = [exit.position.x,exit.position.y]
	data.t = world.mission_title
	data.b = world.briefing
	data.h = world.hint
	data.tm = world.time_limit
	var bounds = Rect2(world.to_global(world.camera_bounds.position),world.camera_bounds.size)
	camera.bind_target(player,bounds)
	if sector==9:spawn_kavya()

func sync_visuals():
	if not is_instance_valid(world): return
	player.present(aim,shielding,console.visible)
	for gate in gates: gate.node.set_activated(gate.open)
	for clue in clues: clue.node.set_activated(clue.used)
	for shard in shards:
		shard.node.set_activated(shard.got)
		shard.node.visible=shard.get("released",true) and not shard.got
	for gem in gems:gem.node.set_activated(gem.got)
	for receiver in receivers: receiver.node.set_activated(receiver.lit)
	for drone in drones:
		drone.node.position = drone.pos
		drone.node.visible = drone.hp > 0
		drone.node.set_activated(drone.sleep)
		drone.node.present(drone.vel,drone.state,clampf(1.0-drone.state_timer/maxf(0.01,drone.node.windup_time),0,1))
	for laser in world.get_node("Lasers").get_children():
		laser.modulate = Color.WHITE if lasers_on else Color("59616c")

func rebuild_wall_collision():
	# One horizontal strip per contiguous run of wall cells, so movement and
	# projectile/laser queries stay inexpensive even after tile painting.
	data.w = []
	solids_dirty=true
	wall_lookup.clear()
	var layer = world.get_node("WallTiles") as TileMapLayer
	wall_layer=layer
	wall_inverse=layer.transform.affine_inverse()
	var rows = {}
	for cell in layer.get_used_cells():
		var tile = layer.get_cell_tile_data(cell)
		if tile == null or tile.get_collision_polygons_count(0) == 0: continue
		wall_lookup[cell]=true
		if not rows.has(cell.y): rows[cell.y] = []
		rows[cell.y].append(cell.x)
	for y in rows:
		var xs = rows[y]
		xs.sort()
		var first = int(xs[0])
		var last = first
		for i in range(1, xs.size()+1):
			if i < xs.size() and int(xs[i]) == last+1:
				last = int(xs[i])
				continue
			var half = Vector2(layer.tile_set.tile_size) / 2.0
			var top_left = layer.transform * (layer.map_to_local(Vector2i(first,y))-half)
			var bottom_right = layer.transform * (layer.map_to_local(Vector2i(last,y))+half)
			data.w.append([top_left.x,top_left.y,bottom_right.x-top_left.x,bottom_right.y-top_left.y])
			if i < xs.size():
				first = int(xs[i])
				last = first
	enemy_nav.rebuild(self)

func collect_gem(gem):
	if gem.got:return
	gem.got=true
	var node=gem.node
	match node.gem_type:
		0:
			hp=minf(tuning.max_hull,hp+node.pickup_amount)
			notice("REPAIR GEM: hull restored")
		1:
			energy=minf(tuning.max_energy,energy+node.pickup_amount)
			notice("AEGIS GEM: energy restored")
		2:
			overdrive_remaining=maxf(overdrive_remaining,node.buff_duration)
			notice("OVERDRIVE: bonus damage and faster fire for %.0fs"%node.buff_duration)
		3:
			remaining+=node.pickup_amount
			notice("CHRONO GEM: +%.0fs"%node.pickup_amount)
	node.set_activated(true)
	sound("shard")
	burst(node.position,[Color("6cff82"),CYAN,AMBER,Color("a6c8ff")][node.gem_type],12)

func trace_rail_end(origin,direction,distance):
	var end=origin
	for step in range(4,int(distance)+1,4):
		var p=origin+direction*step
		if point_solid(p):break
		end=p
	return end

func fire_rail(enemy):
	var end=trace_rail_end(enemy.pos,enemy.attack_dir,enemy.node.rail_range)
	var player_point=Geometry2D.get_closest_point_to_segment(pos,enemy.pos,end)
	if player_point.distance_to(pos)<(31 if shielding else 15):
		if shielding and energy>4:
			energy=maxf(0,energy-30)
		else:
			hp-=enemy.node.rail_damage*tuning.enemy_damage_multiplier
			camera.add_shake(0.4)
	rail_beams.append({"a":enemy.pos,"b":end,"ttl":0.18})
	enemy.node.flash_attack(enemy.attack_dir)

func update_sentinel(enemy,dt):
	enemy.vel=Vector2.ZERO
	if enemy.state=="rail_charge":
		enemy.state_timer-=dt
		enemy.node.look_direction=enemy.attack_dir
		if enemy.state_timer<=0:
			fire_rail(enemy)
			enemy.state="rail_cool"
			enemy.cd=enemy.node.rail_cooldown
		return
	enemy.cd-=dt
	if enemy.cd<=0 and enemy.pos.distance_to(pos)<enemy.node.detection_range and clear_enemy_sight(enemy.pos,pos):
		enemy.state="rail_charge"
		enemy.state_timer=enemy.node.rail_charge_time
		enemy.attack_dir=(pos-enemy.pos).normalized()
		enemy.node.look_direction=enemy.attack_dir

func update_wisp(enemy,dt):
	enemy.state="roam"
	enemy_patrol_step(enemy,dt)
	enemy.cd-=dt
	if enemy.cd<=0 and enemy.pos.distance_to(pos)<enemy.node.detection_range and clear_enemy_sight(enemy.pos,pos):
		enemy.cd=enemy.node.emp_cooldown
		var direction=(pos-enemy.pos).normalized()
		enemy.node.flash_attack(direction)
		for i in range(3):
			projectile(enemy.pos,direction.rotated((i-1)*0.18),false,enemy.node.emp_damage*tuning.enemy_damage_multiplier,230.0,"emp",enemy.node.emp_energy_drain)

func enemy_health(node):
	var health=round((node.base_health+sector*2.4)*4.0)*0.5
	return health*1.25 if node.enemy_type in [0,1] else health

func spawn_kavya():
	var boss=load("res://scenes/entities/Drone.tscn").instantiate()
	boss.name="KAVYA"
	boss.set_meta("kavya",true)
	boss.position=Vector2(660,300)
	boss.patrol_speed=85
	boss.chase_speed=115
	boss.detection_range=812.5
	boss.fire_interval=0.8
	boss.minimum_interval=0.5
	world.get_node("Drones").add_child(boss)
	boss.get_node("EnemySprite").hide()
	var art=Sprite2D.new()
	art.name="BossArt"
	art.texture=preload("res://assets/kavya.png")
	art.scale=Vector2(0.09,0.09)
	boss.add_child(art)
	var record=drones[0].duplicate(false)
	record.node=boss
	record.pos=boss.position
	record.bounds=Rect2(48,48,864,504)
	boss.patrol_bounds=record.bounds
	var cell=enemy_nav.nearest(record.pos,record.bounds)
	if cell.x>=0:record.pos=enemy_nav.grid.get_point_position(cell)
	boss.position=record.pos
	record.hp=(drones[0].max_hp/1.25)*20
	record.max_hp=record.hp
	record.sleep=false
	record.boss=true
	record.path=PackedVector2Array()
	record.path_timer=0.0
	record.cd=1.0
	drones.append(record)
	var shard=load("res://scenes/entities/Shard.tscn").instantiate()
	shard.name="KavyaFinalShard"
	shard.set_script(preload("res://scripts/final_shard.gd"))
	shard.kind="Shard"
	shard.tile=Vector2i(1,7)
	world.get_node("Shards").add_child(shard)
	shard.hide()
	final_shard={"pos":record.pos,"got":false,"node":shard,"final":true,"released":false}
	shards.append(final_shard)

func release_final_shard_if_defeated():
	if sector!=9 or final_shard.is_empty() or final_shard.released:return
	for boss in drones:
		if not boss.get("boss",false):continue
		if boss.hp>0 and not boss.sleep:return
		final_shard.released=true
		final_shard.pos=boss.pos
		final_shard.node.position=boss.pos
		final_shard.node.show()
		burst(boss.pos,PURPLE,32)
		boss_music.stop()
		music_player.volume_db=tuning.music_volume_db-10
		sound("kavya_victory")
		notice("KAVYA DEFEATED — recover the final shard at her position")
		ui.transmit("AETHER: KAVYA's memory lock has collapsed. Elena's final shard is free. Recover it, then reach the extraction bridge.",10.0)
		return

func update_kavya(dt):
	release_final_shard_if_defeated()
	if sector!=9:return
	var bosses=drones.filter(func(e):return e.get("boss",false))
	if bosses.is_empty() or bosses[0].sleep or bosses[0].hp<=0:return
	summon_timer-=dt
	if summon_timer>0:return
	summon_timer=8.0 if bosses[0].hp>bosses[0].max_hp*0.5 else 5.0
	if drones.filter(func(e):return e.hp>0 and not e.sleep).size()>=10:return
	var candidates=enemy_nav.active_cells.filter(func(c):return enemy_nav.grid.get_point_position(c).distance_to(bosses[0].pos)<190)
	if candidates.is_empty():return
	var node=load("res://scenes/entities/Drone.tscn" if randi()%2==0 else "res://scenes/entities/CyberStalker.tscn").instantiate()
	world.get_node("Drones").add_child(node)
	var record=bosses[0].duplicate(false)
	record.erase("boss")
	record.node=node
	record.pos=enemy_nav.grid.get_point_position(candidates.pick_random())
	record.bounds=Rect2(48,48,864,504)
	record.hp=enemy_health(node)*0.5
	record.max_hp=record.hp
	record.path=PackedVector2Array()
	record.path_index=0
	record.path_timer=0
	record.state="roam"
	record.cd=1.0
	drones.append(record)
	notice("KAVYA: reinforcement wave deployed")
