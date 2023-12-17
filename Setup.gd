extends Control
class_name OverlaySetupWnd

var overlay_instance : OverlayWindow
@onready var hv_path_ef := $MarginContainer/VBoxContainer/frame_pp/LineEdit
@onready var context_path_ef := $MarginContainer/VBoxContainer/context_pp/LineEdit
@onready var ovrl_state_lbl := $MarginContainer/VBoxContainer/boot_controls/TargetState
var owpd_thread : Thread

func start_overlay():
	if not overlay_instance:
		var o = OverlayWindow.new(hv_path_ef.text)#,context_path_ef.text)
		o.cfg_wnd = self
		add_child(o)
		overlay_instance = o

func stop_overlay():
	if overlay_instance:
		overlay_instance.queue_free()
		overlay_instance = null


# Called when the node enters the scene tree for the first time.
func _ready():
	#print(ProjectSettings.get_global_class_list())
	#print("./a".get_base_dir())
	#get_tree().get_root().size = Vector2i(480,640)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if overlay_instance:
		ovrl_state_lbl.text = "Running"
	else:
		ovrl_state_lbl.text = ""


func _on_button_pressed():
	start_overlay()


func _on_button_2_pressed():
	stop_overlay()

func _exit_tree():
	owpd_thread.wait_to_finish()
