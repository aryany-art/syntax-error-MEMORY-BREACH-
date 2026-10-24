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
	var g=load("res://Main.tscn").instantiate()
	root.add_child(g)
	g.set_physics_process(false)
	ck(ProjectSettings.get_setting("application/config/name")=="MEMORY//BREACH","application title renamed")
	ck(g.music_player.stream.loop_mode==AudioStreamWAV.LOOP_FORWARD,"theme loops")
	ck(g.music_player.stream.get_length()>30,"background theme duration")
	ck(not g.music_player.playing,"music waits for entry")
	g.modal_clicked()
	ck(g.music_player.playing,"music starts with sector")
	ck(g.music_player.volume_db==g.tuning.music_volume_db,"music default volume")
	var drone=g.drones[0]
	g.receivers.clear()
	g.bullets.clear()
	g.projectile(drone.pos,Vector2.ZERO,true,1,0)
	g.update_bullets(0.016)
	ck(not g.sound_players["drone_down"].playing,"nonlethal hit does not play destruction")
	g.projectile(drone.pos,Vector2.ZERO,true,drone.hp+1,0)
	g.update_bullets(0.016)
	ck(drone.hp<=0 and g.sound_players["drone_down"].playing,"lethal drone hit plays crash")
	g.finish(false,"test")
	ck(not g.music_player.playing,"death stops music")
	g.load_sector(9)
	ck(not g.sound_players["drone_down"].playing,"sector transition clears old effects")
	g.modal_clicked()
	ck(g.boss_music.playing and g.music_player.playing,"boss entrance retains theme")
	ck(g.music_player.volume_db==g.tuning.music_volume_db-10,"boss entrance ducks theme")
	g.boss_music.finished.emit()
	ck(g.music_player.volume_db==g.tuning.music_volume_db,"entrance completion restores theme")
	var boss=g.drones.filter(func(e):return e.get("boss",false))[0]
	boss.hp=0
	g.release_final_shard_if_defeated()
	ck(g.sound_players["kavya_victory"].playing,"KAVYA defeat plays victory")
	ck(not g.boss_music.playing,"victory stops boss entrance")
	ck(g.final_shard.released,"victory keeps final shard drop")
	ck(g.music_player.volume_db==g.tuning.music_volume_db-10,"victory ducks theme")
	g.sound_players["kavya_victory"].finished.emit()
	ck(g.music_player.volume_db==g.tuning.music_volume_db,"victory completion restores music")
	g.load_sector(9)
	ck(not g.sound_players["kavya_victory"].playing,"retry clears victory")
	g.boss_music.stop()
	g.music_player.stop()
	for speaker in g.sound_players.values():speaker.stop()
	await create_timer(0.2).timeout
	g.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("PASS" if failures==0 else "FAIL",": ",checks," audio checks")
	quit(0 if failures==0 else 1)
