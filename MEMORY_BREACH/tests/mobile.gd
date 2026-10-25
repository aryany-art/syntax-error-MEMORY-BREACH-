extends SceneTree
var checks=0
var failures=0
func ck(ok,label):
	checks+=1
	if not ok:
		failures+=1
		push_error(label)
func touch(ui,index,point,pressed):
	var event=InputEventScreenTouch.new()
	event.index=index
	event.pressed=pressed
	event.position=point
	ui._input(event)
func drag(ui,index,point):
	var event=InputEventScreenDrag.new()
	event.index=index
	event.position=point
	ui._input(event)
func _initialize():call_deferred("run")
func run():
	var g=load("res://Main.tscn").instantiate()
	root.add_child(g)
	g.set_physics_process(false)
	g.modal_clicked()
	var ui=g.ui
	ui.set_process(false)
	ui.enable_touch_controls()
	ui.layout_for_size(Vector2(1280,720))
	var joy=ui.joystick
	var center=joy.get_global_rect().get_center()
	touch(ui,0,center,true)
	ck(g.touch_mode and joy.finger_id==0,"joystick claims movement finger")
	ck(g.stick_vector==Vector2.ZERO,"center is neutral")
	drag(ui,0,center+Vector2(3,0))
	ck(g.stick_vector==Vector2.ZERO,"deadzone removes thumb jitter")
	drag(ui,0,center+Vector2(joy.radius/2,0))
	ck(g.stick_vector.x>0 and g.stick_vector.x<0.5,"analog movement has intermediate speed")
	drag(ui,0,center+Vector2(400,400))
	ck(is_equal_approx(g.stick_vector.length(),1),"joystick clamps diagonal speed")
	touch(ui,1,ui.get_node("TouchControls/Fire").get_global_rect().get_center(),true)
	touch(ui,2,ui.get_node("TouchControls/Shield").get_global_rect().get_center(),true)
	ck(g.touch_held.get("fire",false) and g.touch_held.get("shield",false),"move fire shield work together")
	touch(ui,3,center,true)
	ck(joy.finger_id==0,"another finger cannot steal joystick")
	touch(ui,1,Vector2.ZERO,false)
	ck(not g.touch_held.get("fire",false) and g.stick_vector.length()>0,"fire release preserves movement")
	touch(ui,0,Vector2.ZERO,false)
	ck(g.stick_vector==Vector2.ZERO and joy.finger_id==-1,"release outside joystick resets movement")
	touch(ui,0,center,true)
	drag(ui,0,center+Vector2(80,0))
	touch(ui,4,ui.get_node("TouchControls/Hack").get_global_rect().get_center(),true)
	ui._process(0.016)
	ck(g.console.visible and g.stick_vector==Vector2.ZERO,"hacking opens console and releases joystick")
	ck(not g.touch_held.get("shield",false),"console releases shield")
	g.console.hide()
	for viewport_size in [Vector2(1280,720),Vector2(1600,720),Vector2(1920,720),Vector2(1280,800),Vector2(1280,960)]:
		ui.layout_for_size(viewport_size)
		await process_frame
		ui.layout_for_size(viewport_size)
		await process_frame
		ui.layout_for_size(viewport_size)
		var screen=Rect2(Vector2.ZERO,viewport_size)
		var nodes=ui.action_buttons()+[ui.joystick,ui.get_node("HUD"),ui.modal,ui.console]
		for node in nodes:
			var rect=node.get_global_rect()
			if not screen.encloses(rect):print("OVERFLOW ",node.name," rect=",rect," min=",node.get_combined_minimum_size())
			ck(screen.encloses(rect),"UI fits aspect "+str(viewport_size)+" "+str(node.name))
		for a in range(3):
			for b in range(a+1,3):
				ck(not ui.action_buttons()[a].get_global_rect().intersects(ui.action_buttons()[b].get_global_rect()),"action buttons separated")
		ck(ui.joystick.size.x==ui.joystick.size.y,"joystick keeps circular proportions")
	ui.layout_for_size(Vector2(1600,720),Vector4(72,30,72,20))
	ck(ui.get_node("HUD").position.x>=88,"notch safe-area inset applied")
	ck(ui.get_node("TouchControls/Fire").get_rect().end.x<=1600-72,"fire stays clear of notch")
	ui.keyboard_height=400
	ui.layout_for_size(Vector2(1600,720))
	ck(ui.console.get_rect().end.y<=320,"console stays above keyboard")
	ck(not ui.chips.visible,"keyboard hides target chips while typing")
	ui.keyboard_height=0
	ui.layout_for_size(Vector2(1280,2200))
	var timer=g.remaining
	g._physics_process(0.5)
	ck(ui.portrait_mode and ui.get_node("OrientationNotice").visible,"portrait requests landscape")
	ck(g.remaining==timer,"rotation does not consume sector time")
	ui.layout_for_size(Vector2(1280,720))
	ck(not ui.portrait_mode,"landscape restores game")
	var c=g.camera
	c._process(0.2)
	ck(c.zoom.x==c.zoom.y,"camera never stretches world")
	g.boss_music.stop()
	g.music_player.stop()
	for speaker in g.sound_players.values():speaker.stop()
	await create_timer(0.2).timeout
	g.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("PASS" if failures==0 else "FAIL",": ",checks," joystick and responsive layout checks")
	quit(0 if failures==0 else 1)
