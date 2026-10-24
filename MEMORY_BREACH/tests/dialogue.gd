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
	var story_seen={}
	var sentence_seen={}
	var sentence_split=RegEx.new()
	sentence_split.compile("[^.!?]+[.!?]?")
	for i in range(10):
		g.load_sector(i)
		var w=g.world
		ck(not w.briefing.contains(w.hint),"hint absent from briefing")
		ck(not w.briefing.contains(w.arrival_message),"arrival absent from briefing")
		var body=g.modal_body.text
		ck(body.count(w.hint)==1,"hint appears exactly once in intro")
		for text in [w.arrival_message,w.memory_fragment,w.completion_text]:
			var key=text.strip_edges().to_lower()
			ck(not story_seen.has(key),"story block unique across campaign")
			story_seen[key]=true
			for m in sentence_split.search_all(text):
				var sentence=m.get_string().strip_edges().to_lower()
				if sentence.length()<15:continue
				ck(not sentence_seen.has(sentence),"narrative sentence unique: "+sentence)
				sentence_seen[sentence]=true
	g.ui.reset_story_history()
	g.load_sector(0)
	g.modal_clicked()
	ck(g.ui.story_history.size()==1,"arrival plays once")
	g.ui.story_time=0
	g.modal_clicked()
	ck(g.ui.story_history.size()==1 and g.ui.story_time==0,"repeated start does not replay")
	g.load_sector(0)
	g.modal_clicked()
	ck(g.ui.story_history.size()==1 and g.ui.story_time==0,"retry does not replay dialogue")
	g.ui.transmit("  "+g.world.arrival_message.to_upper().replace(" ","  ")+"  ")
	ck(g.ui.story_history.size()==1,"case and whitespace cannot duplicate dialogue")
	g.ui.transmit(g.world.memory_fragment)
	ck(g.ui.story_history.size()==2,"new memory still plays")
	g.ui.transmit(g.world.memory_fragment)
	ck(g.ui.story_history.size()==2,"same memory cannot play twice")
	g.pending_action="restart"
	g.modal_clicked()
	ck(g.ui.story_history.is_empty(),"new campaign resets story history")
	g.modal_clicked()
	ck(g.ui.story_history.size()==1,"new campaign can show opening dialogue again")
	g.boss_music.stop()
	for speaker in g.sound_players.values():speaker.stop()
	await create_timer(0.2).timeout
	g.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("PASS" if failures==0 else "FAIL",": ",checks," dialogue checks")
	quit(0 if failures==0 else 1)
