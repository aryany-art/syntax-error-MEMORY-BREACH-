extends SceneTree
var count=0
var failures=0
func ck(ok,label):
	count+=1
	if not ok:
		failures+=1
		push_error(label)
func touch(ui,index,action,pressed):
	var event=InputEventScreenTouch.new()
	event.index=index
	event.pressed=pressed
	event.position=ui.get_node("TouchControls/"+action).get_global_rect().get_center()
	ui._input(event)
func _initialize():call_deferred("run")
func run():
	var g=load("res://Main.tscn").instantiate()
	root.add_child(g)
	g.set_physics_process(false)
	g.modal_clicked()
	var ui=g.ui
	touch(ui,0,"Left",true)
	touch(ui,1,"Fire",true)
	ck(g.touch_mode and ui.get_node("TouchControls").visible,"touch enables mobile controls and autoaim")
	ck(g.touch_held.get("left",false) and g.touch_held.get("fire",false),"movement and fire support separate fingers")
	touch(ui,2,"Shield",true)
	ck(g.touch_held.get("shield",false),"third finger raises shield")
	touch(ui,0,"Left",false)
	ck(not g.touch_held.get("left",false) and g.touch_held.get("fire",false),"releasing move preserves fire")
	touch(ui,3,"Fire",true)
	touch(ui,1,"Fire",false)
	ck(g.touch_held.get("fire",false),"shared action held until final finger releases")
	touch(ui,3,"Fire",false)
	ck(not g.touch_held.get("fire",false),"fire releases correctly")
	touch(ui,4,"Hack",true)
	ui._process(0.016)
	ck(g.console.visible,"touch hacking opens terminal")
	ck(not g.touch_held.get("shield",false) and ui.touch_buttons.is_empty(),"console clears held actions")
	g.console.hide()
	touch(ui,5,"Right",true)
	var event=InputEventScreenDrag.new()
	event.index=5
	event.position=Vector2(400,300)
	ui._input(event)
	ck(not g.touch_held.get("right",false),"dragging off a button releases it")
	g.boss_music.stop()
	g.music_player.stop()
	for speaker in g.sound_players.values():speaker.stop()
	await create_timer(0.2).timeout
	g.queue_free()
	await process_frame
	print("PASS" if failures==0 else "FAIL",": ",count," mobile checks")
	quit(0 if failures==0 else 1)
