extends Window
class_name OverlayWindow

var cfg_wnd : OverlaySetupWnd
var test_scene := preload("res://OverlayTest.tscn")
var frame_version :int= 0
var context_version :int= 0
var loaded_classes := {}
var hv_path := "R:/Gover/"
var context_path := hv_path+"context.json"
var owpd_control_filename := "owpdc.bin"
var trgt_name := "noname"
var ovrl_name := "Overlay fragment"
var owpd_wpath := OS.get_executable_path().get_base_dir()+"/owpd.py"
const ver_name := "v.json"
const frame_names := ["fbo0.json","fbo1.json"]
const read_retry := 8

func load_json(path : String):
	var file = FileAccess.open(path, FileAccess.READ)
	var content
	if !file:
		push_warning(path ,":unable to open - ",FileAccess.get_open_error())
		return
	
	var json = JSON.new()
	
	content = file.get_as_text()
	var error = json.parse(content)
	
	var tries = read_retry
	while (error != OK) || (tries > 0):
		content = file.get_as_text()
		error = json.parse(content)
		tries -= 1
	file.close()

	if error == OK:
		#print(data)
		return json.data
	else:
		push_warning("Failed to parse JSON: ", json.get_error_message())

func update_context():
	var new_context = load_json(context_path)
	if not new_context:
		return
	
	trgt_name = new_context.v # update window name to hook on
	
	if new_context.resources is Dictionary:
		for r in new_context.resources.keys():
			if context_version < new_context.resources[r]:
				loaded_classes[r] = load(r)
	
	for nps : String in new_context.scene.keys():
		var nn = new_context.scene[nps]
		if context_version >= nn.vadd:
			continue
		if nn.exist: #add node
			var n : Node
			if loaded_classes.has(nn.class):
				n = loaded_classes[nn.class].new(self)
			else:
				if ClassDB.class_exists(nn.class):
					n = ClassDB.instantiate(nn.class)
			n.name = nps.get_file() #if there will be errors, there's much stable code above
			get_node(("./"+nps).get_base_dir()).add_child(n)
		else: #remove node 
			var nr = get_node(nps)
			if nr:
				if nr is Node:
					nr.queue_free()

func update_scene():
	var changes = load_json(hv_path+frame_names[frame_version % len(frame_names)])
	if not changes:
		return
	for np in changes.keys():
		var n = get_node_or_null(np)
		if not n:
			push_warning("cant find node:"+np)
			continue
		for v in changes[np].keys():
			var expr := Expression.new()
			var data = changes[np][v]
			var nval 
			match typeof(data):
				TYPE_STRING:
					if expr.parse(changes[np][v]) == OK:
						nval = expr.execute([],n)
				TYPE_FLOAT:
					nval = data
			#expr.execute([],n)
			n.set_indexed(v, nval)
		n._vars_changed()

func overlay_update():
	var vfn := hv_path+ver_name
	var versions = load_json(vfn)
	if not versions:
		return
	
	if context_version > versions.context:
		var qfd := 0
		for c in get_children():
			c.name = "queued"+str(qfd)
			c.queue_free()
			qfd += 1
		context_version = 0
	
	if context_version != versions.context:
		update_context()
		context_version = versions.context
	
	if frame_version != versions.frame:
		#if frame_version > versions.frame:
		#	frame_version = 0
		update_scene()
		frame_version = versions.frame

func load_proj_classes():
	for p in ProjectSettings.get_global_class_list():
		loaded_classes[p.path] = load(p.path)

func _init(hpath : String):#, cpath : String):
	load_proj_classes()
	hv_path = hpath
	#context_path = cpath
	name = "Overlay"
	title = ovrl_name
	size = Vector2i(256,256)
	initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	always_on_top = true
	borderless = true
	mouse_passthrough = true
	transparent = true
	transparent_bg = true

func boot_owpd():
	#print(OS.get_executable_path().get_base_dir())
	var output = []
	if !FileAccess.file_exists(owpd_wpath):
		var source_file = FileAccess.open("res://owpd.py", FileAccess.READ)
		var dest_file = FileAccess.open(owpd_wpath, FileAccess.WRITE)
		dest_file.store_string(source_file.get_as_text())
		source_file.close()
		dest_file.close()
	OS.execute("python", [owpd_wpath,trgt_name,ovrl_name], output)
	print(output[0])
	#while owpd_run:
	#	OS.execute("", ["c"])
	#OS.execute("", ["exit"])
	#print(trgt_name)
	cfg_wnd.stop_overlay()

func start_owpd():
	cfg_wnd.owpd_thread = Thread.new()
	cfg_wnd.owpd_thread.start(boot_owpd.bind())

# Called when the node enters the scene tree for the first time.
func _ready():
	overlay_update()
	#add_child(test_scene.instantiate())
	start_owpd()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	overlay_update()
