extends SceneTree
var game
var stage=0
func report(message):
	JavaScriptBridge.eval("document.getElementById('result').textContent += "+JSON.stringify(str(message)+"\n"),true)
func _initialize():call_deferred("run")
func run():
	game=load("res://Main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.modal_clicked()
	game.python_runtime.progress.connect(report)
	game.python_runtime.finished.connect(result)
	report("Actual Godot game loaded. Running print(2+3)...")
	game.run_command("print(2+3)")
func result(response):
	report(JSON.stringify(response))
	if stage==0:
		if not response.get("ok",false) or response.get("numeric",null)!=5:
			report("FAIL: game terminal integration")
			return
		report("PASS: Godot -> browser worker -> Python -> Godot -> game terminal")
		stage=1
		game.begin_hack("gate:0")
		var formula=["a+2*b","a*b*b","a^b","((a<<1)|b)&63"][game.hack_kind]
		report("Testing actual gate breach with print("+formula+")...")
		game.run_command("print("+formula+")")
	elif stage==1:
		report("PASS: Python result opened the actual game gate" if game.gates[0].open else "FAIL: gate did not open")
		stage=2
