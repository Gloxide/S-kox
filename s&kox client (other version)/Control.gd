extends Control

var modulated = Color(0.3686, 0.3686, 0.3686, 1)

var current = Color(000000)
var rotater = true
var counter = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if self.visible == true:
		counter = counter + 1
		if counter == 150:
			counter = 0
			rotater = !rotater
			if rotater == true:
				$SubViewport/TextureRect.rotation = $SubViewport/TextureRect.rotation + deg_to_rad(45)
		if rotater == true:
			current = modulated
		if rotater == false:
			current = Color(0, 0, 0, 1)
		$SubViewport/TextureRect.modulate = $SubViewport/TextureRect.modulate.lerp(current, delta)
