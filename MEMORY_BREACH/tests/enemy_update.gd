extends SceneTree
var checks=0
func ck(ok,label):
	checks+=1
	if not ok:
		push_error(label)
		quit(1)
		assert(ok,label)
func _initialize():call_deferred("run")
func run():
	var g=load("res://Main.tscn").instantiate()
	root.add_child(g)
	g.set_physics_process(false)
	for sector in range(10):
		g.load_sector(sector)
		for e in g.drones:
			if e.get("boss",false):continue
			var old_hp=round((e.node.base_health+sector*2.4)*4)*0.5
			ck(is_equal_approx(e.hp,old_hp*(1.25 if e.node.enemy_type in [0,1] else 1.0)),"HP multiplier per enemy type")
			var old_range=300.0 if e.node.enemy_type==2 else (260.0 if e.node.enemy_type==3 else 360.0)
			ck(is_equal_approx(e.node.detection_range,old_range*1.25),"detection increased on saved enemies")
			ck(e.node.rail_range==600,"rail range increased")
	var boss=g.drones.filter(func(e):return e.get("boss",false))[0]
	ck(boss.hp==round((g.drones[0].node.base_health+9*2.4)*4)*0.5*20,"boss HP preserved")
	for e in g.drones:
		if not e.get("boss",false):e.sleep=true
	var spawn_position=boss.pos
	for frame in range(120):g.update_drones(1.0/60)
	ck(boss.pos.distance_to(spawn_position)>2,"boss moves while gates remain locked")
	for gate in g.gates:g.open_gate(gate)
	g.enemy_nav.rebuild(g)
	var start=boss.pos
	# Pursue a reachable point outside the former base, through real navigation.
	var path=PackedVector2Array()
	for cell in g.enemy_nav.active_cells:
		var target=g.enemy_nav.grid.get_point_position(cell)
		if Rect2(610,170,120,250).has_point(target):continue
		var candidate=g.enemy_nav.target_path(start,target,boss.bounds)
		if candidate.size()>1 and candidate[-1].distance_to(start)>80:
			path=candidate
			break
	ck(path.size()>1,"reachable arena pursuit path")
	g.pos=path[-1]
	for frame in range(600):g.update_drones(1.0/60)
	ck(boss.pos.distance_to(start)>50,"boss moves from spawn")
	ck(not Rect2(610,170,120,250).has_point(boss.pos),"boss leaves former base bounds")
	ck(not g.point_solid(boss.pos),"boss respects walls")
	boss.node.present(Vector2(115,0),"chase")
	var art=boss.node.get_node("BossArt")
	boss.node.animate_boss(0.1)
	ck(art.rotation>0 and absf(art.position.y)>0,"movement animation changes bank and hover")
	boss.node.flash_attack(Vector2.RIGHT)
	boss.node.animate_boss(0.1)
	ck(art.modulate.g<1,"firing animation")
	var frozen=art.transform
	boss.node.set_activated(true)
	boss.node.animate_boss(0.1)
	ck(art.transform==frozen,"hacked boss animation freezes")
	g.boss_music.stop()
	g.queue_free()
	await process_frame
	print("PASS: ",checks," enemy update checks")
	quit()
