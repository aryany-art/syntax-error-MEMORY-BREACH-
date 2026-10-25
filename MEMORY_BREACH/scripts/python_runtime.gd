extends Node
signal finished(response)
signal progress(message)
var web_loading=false
@export var python_executable=""
var process_id=-1
var folder=""
var sequence=0
var busy=false
var elapsed=0.0
var prefix=PackedStringArray()
var executable=""
func _ready():
	if OS.has_feature("web"):return
	folder=OS.get_user_data_dir()+"/python_session_"+str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(folder)
func start():
	if process_id>0 and OS.is_process_running(process_id):return true
	# Resolve executables from PATH instead of blocking the game with --version probes.
	var windows=OS.get_name()=="Windows"
	var names=["py.exe","python.exe","python3.exe"] if windows else ["python3","python"]
	var options=[]
	if not python_executable.is_empty():
		options.append(python_executable)
	else:
		for name in names:
			for directory in OS.get_environment("PATH").split(";" if windows else ":",false):
				var candidate=directory.strip_edges().trim_prefix("\"").trim_suffix("\"").path_join(name)
				if FileAccess.file_exists(candidate):options.append(candidate)
	for option in options:
		executable=option
		prefix=PackedStringArray(["-3"]) if option.get_file().to_lower() in ["py","py.exe"] else PackedStringArray()
		var command=prefix.duplicate()
		command.append(ProjectSettings.globalize_path("res://python_runtime/worker.py"))
		command.append(folder)
		process_id=OS.create_process(executable,command,false)
		if process_id>0:return true
	return false
func submit(code,a,b):
	if busy:return false
	sequence+=1
	if OS.has_feature("web"):return submit_web(code,a,b)
	if not start():
		finished.emit({"id":sequence,"ok":false,"numeric":null,"output":"Python 3 was not found. Install Python 3 or set Python Executable on the game root. No separate terminal window is required."})
		return false
	var file=FileAccess.open(folder+"/request.tmp",FileAccess.WRITE)
	file.store_string(JSON.stringify({"id":sequence,"code":code,"a":a,"b":b}))
	file.close()
	DirAccess.rename_absolute(folder+"/request.tmp",folder+"/request.json")
	busy=true
	elapsed=0
	return true
func submit_web(code,a,b):
	if not bool(JavaScriptBridge.eval("typeof window.memoryBreachPythonSubmit === 'function'",true)):
		finished.emit({"ok":false,"numeric":null,"output":"Python bridge is missing. Open the latest published game link."})
		return false
	busy=true
	web_loading=true
	elapsed=0.0
	var request=JSON.stringify({"id":sequence,"code":str(code),"a":a,"b":b})
	var accepted=JavaScriptBridge.eval("window.memoryBreachPythonSubmit("+request+")",true)
	if not accepted:
		busy=false
		finished.emit({"ok":false,"numeric":null,"output":"Python is already processing a command. Wait and retry."})
	return bool(accepted)

func web_received(args):
	if args.is_empty():return
	var response=JSON.parse_string(str(args[0]))
	if not response is Dictionary or int(response.get("id",-1))!=sequence:return
	if not busy:return
	if response.get("phase","result")!="result":
		if response.get("phase","")=="ready":
			web_loading=false
			elapsed=0.0
		progress.emit(str(response.get("output","")))
		return
	busy=false
	finished.emit(response)

func _process(delta):
	if not busy:return
	elapsed+=delta
	if OS.has_feature("web"):
		for _index in range(8):
			var message=JavaScriptBridge.eval("window.memoryBreachPythonPoll ? window.memoryBreachPythonPoll() : ''",true)
			if message==null or str(message).is_empty():break
			web_received([str(message)])
		if not busy:return
		if elapsed>(125.0 if web_loading else 10.0):
			JavaScriptBridge.eval("window.memoryBreachPythonCancel && window.memoryBreachPythonCancel()",true)
			busy=false
			finished.emit({"ok":false,"numeric":null,"output":"Python timed out. Retry the command; session variables have been cleared."})
		return
	var path=folder+"/response.json"
	if FileAccess.file_exists(path):
		var result=JSON.parse_string(FileAccess.get_file_as_string(path))
		DirAccess.remove_absolute(path)
		if result is Dictionary and result.id==sequence:
			busy=false
			finished.emit(result)
	elif elapsed>5:
		if process_id>0:OS.kill(process_id)
		process_id=-1
		busy=false
		for name in ["request.json","response.json"]:DirAccess.remove_absolute(folder+"/"+name)
		finished.emit({"id":sequence,"ok":false,"numeric":null,"output":"Execution exceeded 5 seconds. Python session stopped; variables reset on next command."})
func _exit_tree():
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.memoryBreachPythonCancel && window.memoryBreachPythonCancel()",true)
	if process_id>0 and OS.is_process_running(process_id):OS.kill(process_id)
