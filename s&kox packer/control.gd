extends Control

@onready var packname = $Panel/MarginContainer/VBoxContainer/LineEdit
var path

var packfiles = Array()

func _on_select_pressed():
	$FileDialog.show()


func _on_pack_pressed():
	packfiles = Array()
	var packer = PCKPacker.new()
	packer.pck_start(packname.text + ".pck")
	var dir = DirAccess.get_files_at(path)
	var x = 0
	while x < dir.size():
		$Panel/MarginContainer/VBoxContainer/RichTextLabel.append_text("added file:" + dir[x] + "\n")
		packfiles.append(dir[x])
		packer.add_file("res://" + dir[x], path + "/" + dir[x])
		x = x + 1
	var file = FileAccess.open("res://temp.info", FileAccess.WRITE)
	file.store_var(packfiles)
	print(file.get_as_text())
	file.close
	packer.add_file("res://" + packname.text + ".info", "res://temp.info")
	packer.flush()
	$Panel/MarginContainer/VBoxContainer/RichTextLabel.append_text("packing done")


func _on_file_dialog_dir_selected(dir):
	$Panel/MarginContainer/VBoxContainer/select.text = dir
	path = dir
