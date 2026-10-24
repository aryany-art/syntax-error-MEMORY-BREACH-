extends SceneTree
func _initialize():call_deferred("run")
func run():
	var g=load("res://Main.tscn").instantiate()
	root.add_child(g)
	g.set_physics_process(false)
	g.modal_clicked()
	g.console.show()
	g.clues[0].found=true
	g.begin_hack("terminal:0")
	g.hack_a=12
	g.hack_b=5
	g.hack_kind=2
	g.run_command("import math; x=math.sqrt(81); print(x)")
	var result=await g.python_runtime.finished
	assert(result.ok and result.numeric==9)
	assert(g.gates[0].open)
	g.run_command("print(x + 1)")
	result=await g.python_runtime.finished
	assert(result.numeric==10)
	g.run_command("print('Hello from real Python')")
	result=await g.python_runtime.finished
	assert(result.output.contains("Hello from real Python"))
	g.run_command("1/0")
	result=await g.python_runtime.finished
	assert(not result.ok and result.output.contains("ZeroDivisionError"))
	g.boss_music.stop()
	for speaker in g.sound_players.values():speaker.stop()
	await create_timer(0.2).timeout
	g.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("PASS: actual Python imports, persistent variables, stdout, exceptions and one-protocol gate breach")
	quit()
