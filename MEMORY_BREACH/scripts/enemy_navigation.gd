extends RefCounted
## A shared grid rebuilt when gates open or wall tiles change.
var grid=AStarGrid2D.new()
var revision=0
var rng=RandomNumberGenerator.new()
var allowed={}
var active_cells=[]
func _init():
	rng.randomize()
func cell_at(point):
	return Vector2i(floori(point.x/24.0),floori(point.y/24.0))
func rebuild(game):
	grid.region=Rect2i(0,0,40,25)
	grid.cell_size=Vector2(24,24)
	grid.offset=Vector2(12,12)
	grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	allowed.clear()
	active_cells.clear()
	var mask=game.world.get_node_or_null("EnemyPatrolTiles")
	if mask:
		for cell in mask.get_used_cells():allowed[cell]=true
	var floor_layer=game.world.get_node("FloorTiles")
	var blockers=game.solids()
	for y in range(25):
		for x in range(40):
			var cell=Vector2i(x,y)
			var p=Vector2(x*24+12,y*24+12)
			var blocked=(mask!=null and not allowed.has(cell)) or floor_layer.get_cell_source_id(cell)<0
			if not blocked:
				for rect in blockers:
					if p.distance_to(p.clamp(rect.position,rect.end))<14:
						blocked=true
						break
			grid.set_point_solid(cell,blocked)
			if not blocked:active_cells.append(cell)
	revision+=1
func nearest(point,bounds):
	var best=Vector2i(-1,-1)
	var distance=INF
	for cell in active_cells:
		var p=grid.get_point_position(cell)
		if not bounds.has_point(p):continue
		var d=p.distance_squared_to(point)
		if d<distance:
			distance=d
			best=cell
	return best
func random_path(point,bounds):
	var start=nearest(point,bounds)
	if start.x<0:return PackedVector2Array()
	var candidates=[]
	for cell in active_cells:
		if bounds.has_point(grid.get_point_position(cell)):candidates.append(cell)
	for attempt in range(18):
		if candidates.is_empty():break
		var target=candidates[rng.randi_range(0,candidates.size()-1)]
		var p=grid.get_point_position(target)
		if not bounds.has_point(p) or p.distance_to(point)<40:continue
		var path=grid.get_point_path(start,target)
		var valid=true
		for step in path:
			if not bounds.has_point(step):valid=false;break
		if valid and path.size()>1:return path
	return PackedVector2Array()
func target_path(point,target,bounds):
	var start=nearest(point,bounds)
	var end=nearest(target,bounds)
	if start.x<0 or end.x<0:return PackedVector2Array()
	var path=grid.get_point_path(start,end)
	for step in path:
		if not bounds.has_point(step):return PackedVector2Array()
	return path
func move(enemy,delta_pos,blockers):
	var before=enemy.pos
	var count=maxi(1,int(ceil(delta_pos.length()/4.0)))
	var step=delta_pos/count
	var radius=enemy.node.body_radius
	for i in range(count):
		for axis in range(2):
			var candidate=enemy.pos
			candidate[axis]+=step[axis]
			if not enemy.bounds.has_point(candidate):continue
			var cell=cell_at(candidate)
			if not grid.is_in_boundsv(cell) or grid.is_point_solid(cell):continue
			var blocked=false
			for rect in blockers:
				if candidate.distance_squared_to(candidate.clamp(rect.position,rect.end))<radius*radius:
					blocked=true
					break
			if not blocked:enemy.pos=candidate
	return enemy.pos-before
