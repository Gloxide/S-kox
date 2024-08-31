extends Node


var entities = Array()
var entity_type = Array()
var entity_pos = Array()
var entity_rot = Array()



@rpc("any_peer", "unreliable")
func client_polling_data(id, dir, jump, rot):
	pass

@rpc("authority", "unreliable")
func send_server_data(sentities, stype, sdir, srot):
	entities = sentities
	entity_type = stype
	entity_pos = sdir
	entity_pos = srot

@rpc("authority", "reliable")
func receive_chunk(chunk, sent_bytes, file_size, file_path, id, fileamount):
	pass

@rpc("authority", "reliable")
func all_files_sent(id):
	pass
