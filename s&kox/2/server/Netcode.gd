extends Node

var settings = {
	"map": "ball_land",
	"port": "7878",
	"tickrate": 66,
	"sim_rate": 2,
	"upd_rate": 3,
}

@onready var addon_container = $"../Control/Panel/MarginContainer/HBoxContainer/Panel/MarginContainer/VBoxContainer/Panel2/MarginContainer/ScrollContainer/VBoxContainer"
@onready var console = $"../Control/Panel/MarginContainer/HBoxContainer/Panel2/MarginContainer/VBoxContainer/Panel/MarginContainer/RichTextLabel"
const ADDON_BUTTON = preload("res://addon_panel.tscn")
@onready var _3d = $"../3D"

var server_started = false
var mp_peer = ENetMultiplayerPeer.new()

var simtime = 0
var updtime = 0
var fakedelta = 0

var addons_all = Array()
var addons = Array()
var addon_hash = Array()

var path

var chunk_size = 1024
var clients = Array()
var file_index = Array()

#server:
var entities = Array()
var entity_type = Array()
var entity_pos = Array()
var entity_rot = Array()


func _ready():
	path = "res://"
	if path == "":
		# Exported, will return the folder where the executable is located.
		path = OS.get_executable_path().get_base_dir()
	else:
		# Editor, will return one level above the project folder
		pass
	get_all_addons()

func _process(delta):
	if server_started:
		fakedelta = fakedelta + delta
		simtime += 1
		updtime += 1
		if simtime == settings.sim_rate:
			simulate(fakedelta)
			simtime = 0
			fakedelta = 0
		if updtime == settings.upd_rate:
			updtime = 0


func simulate(delta):
	var x = 0
	if entities.size() != 0:
		while x < entities.size():
			if $"../3D".get_node_or_null(NodePath(entities[x])).get_script() != null:
				$"../3D".get_node_or_null(NodePath(entities[x])).simulate(delta)
			entity_pos[x] = $"../3D".get_node_or_null(NodePath(entities[x])).position
			entity_rot[x] = $"../3D".get_node_or_null(NodePath(entities[x])).rotation
			x += 1


func get_all_addons():
	var dir = DirAccess.get_files_at(path + "/addons")
	addons_all = dir
	var x = 0
	while x < addons_all.size():
		var addon_button = ADDON_BUTTON.instantiate()
		addon_button.get_node("MarginContainer/Label").text = addons_all[x]
		addon_button.get_node("MarginContainer/CheckBox").button_pressed = true
		addon_container.add_child(addon_button)
		x = x + 1

func activate_addons():
	var x = 0
	while x < addons_all.size():
		if addon_container.get_child(x).get_node("MarginContainer/CheckBox").button_pressed:
			ProjectSettings.load_resource_pack(path + "addons/" + addons_all[x])
			console.append_text('Using addon: "' + addons_all[x] + '"\n')
			addons.append(addons_all[x])
		x = x + 1

func start_server():
	mp_peer.create_server(str_to_var(settings.port))
	multiplayer.multiplayer_peer = mp_peer
	server_started = true

func _on_start_pressed():
	activate_addons()
	start_server()
	console.append_text("started server on port: 7878")
	$"../Control/Panel/MarginContainer/HBoxContainer/Panel/MarginContainer/VBoxContainer/Panel/MarginContainer/HBoxContainer/start".disabled = true
	$"../Control/Panel/MarginContainer/HBoxContainer/Panel/MarginContainer/VBoxContainer/Panel/MarginContainer/HBoxContainer/stop".disabled = false


@rpc("any_peer", "unreliable")
func client_polling_data(id, dir, jump, rot):
	if entities.find(id) != -1:
		var player = _3d.get_node(NodePath(var_to_str(id)))
		player.input_dir = dir
		player.rotate = rot
		player.jump = jump

@rpc("authority", "unreliable")
func send_server_data(entities, type, dir, rot):
	pass

func send_client_chunk(id):
	while file_index[clients.find(id)] < addons.size():
		var path = "res://addons/" + addons[file_index[clients.find(id)]]
		var file = FileAccess.open(path, FileAccess.READ)
		var file_size = file.get_length()
		var sent_bytes = 0
		while sent_bytes < file_size:
			var chunk = file.get_buffer(chunk_size)
			sent_bytes += chunk.size()
			chunk = chunk.compress(3)
			receive_chunk.rpc(chunk, sent_bytes, file_size, path, id, addons.size())
		file.close()
		file_index[clients.find(id)] += 1
	all_files_sent.rpc(id)

@rpc("authority", "reliable")
func receive_chunk(chunk, sent_bytes, file_size, file_path, id, fileamount):
	pass
@rpc("authority", "reliable")
func all_files_sent(id):
	pass

func create_entity(type, ename, pos, rot):
	var instance = load("res://" + type + ".tscn").instantiate()
	instance.name = ename
	instance.position = pos
	instance.rotation = rot
	entities.append(ename)
	entity_pos.append(pos)
	entity_rot.append(rot)
	entity_type.append(type)
	_3d.add_child(instance)

func _on_line_edit_text_submitted(new_text):
	create_entity("ball", var_to_str(entities.size()), Vector3(0, 4, 4), Vector3.ZERO)
