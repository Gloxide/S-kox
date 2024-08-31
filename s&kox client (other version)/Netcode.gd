extends Node

var start_client = false

var file
var received_bytes = 0
var total_file_size = 0
var current_file_path = ""
var files_gotten = 0
var Aaddons = Array()

@onready var ip = $"../Control/Panel2/MarginContainer/VBoxContainer/IP"
@onready var port = str_to_var($"../Control/Panel2/MarginContainer/VBoxContainer/Port".text)
@onready var username = $"../Control/Panel2/MarginContainer/VBoxContainer/Username"
@onready var _3d = $"../3D"

var e_type = Array()
var e_names = Array()
var e_script = Array()
var e_pos = Array()
var e_rot = Array()
var e_ext = Array()

var peers = Array()
var peer_names = Array()

var map = "res://map/crossyroads.tscn"
var mp_peer = ENetMultiplayerPeer.new()

var polling_rate = 2 #how often the inputs are polled
var polling_timing = 0

var mouse_sensitivity = 0.002
var mouse

var can_pole = false
var fake_delta

var client_id

var addons = 0


func _ready():
	_3d.set_physics_process(false)

func _process(delta):
	if can_pole == false:
		return
	polling_timing += 1
	if polling_timing == polling_rate:
		polling_timing = 0
		if e_type.size() != 0:
			if multiplayer.get_unique_id() != null:
				client_polling.rpc(multiplayer.get_unique_id(), Input.get_vector("left", "right", "up", "down"), $"../3D".get_node(var_to_str(client_id)).rotation, Input.is_action_pressed("ui_accept"))

func get_all_pcks_in_folder(folderPath:String)->Array[String]:  
	var files:Array[String]
	files.assign(DirAccess.get_files_at(folderPath))
	print(files)
	return files.filter( func(fileName:String): return fileName.get_extension() == "pck")  

func load_all_pcks_in_folder(folder:String):  
	for pck in get_all_pcks_in_folder(folder):  
		ProjectSettings.load_resource_pack("res://addons/" + pck)

@rpc("any_peer", "unreliable")
func client_polling(id, dir, rot, pos):
	pass

@rpc("authority", "reliable")
func receive_chunk(chunk, sent_bytes, file_size, file_path, id, fileamount):
	if multiplayer.get_unique_id() != id:
		return
	if current_file_path != file_path:
		if file:
			file.close()
		current_file_path = file_path
		received_bytes = 0
		total_file_size = file_size
		print(file_path)
		file = FileAccess.open(file_path, FileAccess.WRITE)
	$"../Control/Panel/MarginContainer/VBoxContainer/Label".text = var_to_str(files_gotten + 1) + "/" + var_to_str(fileamount) + " " + file_path
	
	var uncompressed = chunk.decompress(2048, 3)
	file.store_buffer(uncompressed)
	received_bytes += uncompressed.size()
	var percentage = float(received_bytes) / float(total_file_size) * 100.0
	$"../Control/Panel/MarginContainer/VBoxContainer/ProgressBar".value = percentage
	if received_bytes >= total_file_size:
		file.close()
		files_gotten += 1
		print("Download completed: %s" % file_path)

@rpc("authority", "reliable")
func all_files_sent(id):
	if id == multiplayer.get_unique_id():
		client_done_downloading.rpc(id, username.text)

@rpc("any_peer", "reliable")
func client_done_downloading(id, name):
	pass

@rpc("authority", "reliable")
func setup_client(id, map):
	if id == multiplayer.get_unique_id():
		load_all_pcks_in_folder("res://addons")
		#load_all_from_pck()
		create_map(map)
		client_id = multiplayer.get_unique_id()
		start_client = true
		$"../Control".visible = false

func save(content, sfile):
	var file = FileAccess.open("res://addons/" + sfile,FileAccess.WRITE)
	file.store_buffer(content)
	file = null


@rpc("authority", "reliable")
func send_snapshot(ee_types, ee_name, ee_pos, ee_rot, ee_ext, fdelta):
	if start_client == false:
		return
	e_type = ee_types
	e_names = ee_name
	e_pos = ee_pos
	e_rot = ee_rot
	e_ext = ee_ext
	fake_delta = fdelta
	print(e_names.size())
	update()

func load_all_from_pck():
	var x = 0
	while x < Aaddons.size():
		if Aaddons[x] == 1:
			var a = Aaddons[x]
			a = a.erase(a.length() - 4, 4)
			var file = FileAccess.open("res://" + a + ".info", FileAccess.READ)
			var addonfiles = file.get_var()
			var y = 0
			while y < addonfiles.size():
				load(addonfiles[y])
				print(addonfiles[y])
				y = y + 1
		x = x + 1

func update():
	var x = 0
	while x < e_names.size():
		if $"../3D".get_node_or_null(NodePath(e_names[x])) == null:
			var new_entity = load("res://" + e_type[x]).instantiate()
			new_entity.name = e_names[x]
			new_entity.position = e_pos[x]
			new_entity.rotation = e_rot[x]
			if e_type[x] == "player.tscn":
				new_entity.get_node("Label3D").text = e_ext[x]
			$"../3D".add_child(new_entity)
			if new_entity.get_script() != null:
				$"../3D".get_node_or_null(e_names[x]).client = 1
			if e_names[x] == var_to_str(multiplayer.get_unique_id()):
				can_pole = true
				$"../3D".get_node_or_null(e_names[x]).client = 1
				$"../3D".get_node_or_null(NodePath(e_names[x])).get_node("Camera3D").current = true
				$"../3D".get_node_or_null(NodePath(e_names[x])).get_node("berry").visible = false
			return
		var tweener = get_tree().create_tween()
		tweener.tween_property($"../3D".get_node_or_null(NodePath(e_names[x])), "position", e_pos[x], 0.1)
		tweener.kill
		if e_names[x] != var_to_str(multiplayer.get_unique_id()):
			$"../3D".get_node_or_null(NodePath(e_names[x])).rotation = e_rot[x]
		x = x + 1

func create_map(mapname):
	var map = load("res://" + mapname).instantiate()
	_3d.add_child(map)

func _on_connect_pressed():
	$"../Control/Panel2".hide()
	mp_peer.create_client(ip.text, port)
	multiplayer.multiplayer_peer = mp_peer
