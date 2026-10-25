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
	g.modal_clicked()
	var runtime=g.python_runtime
	runtime.busy=true
	g.pending_python_epoch=12345
	g.run_command("print(a)")
	ck(g.pending_python_epoch==12345,"busy command cannot overwrite pending challenge")
	runtime.busy=false
	g.begin_hack("gate:0")
	g.pending_python_epoch=g.challenge_epoch
	g.pending_python_target=g.hack_target
	g.pending_python_a=g.hack_a
	g.pending_python_b=g.hack_b
	runtime.sequence=42
	runtime.busy=true
	runtime.web_loading=true
	runtime.web_received([JSON.stringify({"id":42,"phase":"ready","output":"Python runtime ready"})])
	ck(runtime.busy and not runtime.web_loading,"ready updates progress without finishing command")
	ck(not g.gates[0].open,"progress cannot authorize a breach")
	runtime.web_received([JSON.stringify({"id":41,"phase":"result","ok":true,"numeric":g.expected_answer(),"output":"old result"})])
	ck(runtime.busy and not g.gates[0].open,"stale request ID ignored")
	runtime.web_received([JSON.stringify({"id":42,"phase":"result","ok":true,"numeric":g.expected_answer(),"output":"accepted"})])
	ck(not runtime.busy and g.gates[0].open,"browser numeric result opens gate")
	g.load_sector(0)
	g.modal_clicked()
	runtime.busy=true
	runtime.web_loading=true
	var before=g.remaining
	g._physics_process(1.0)
	ck(g.remaining==before,"first runtime load does not consume sector time")
	runtime.busy=false
	runtime.web_loading=false
	g.boss_music.stop()
	g.music_player.stop()
	for speaker in g.sound_players.values():speaker.stop()
	await create_timer(0.2).timeout
	g.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("PASS" if failures==0 else "FAIL",": ",checks," web Python adapter checks")
	quit(0 if failures==0 else 1)
