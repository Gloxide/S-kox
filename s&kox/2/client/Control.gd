extends Control

var CONTROL_1 = preload("res://control1.tres")
var CONTROL = preload("res://control.tres")

func _process(delta):
	CONTROL_1.noise.fractal_ping_pong_strength += 0.5 * delta
	CONTROL.noise.offset += Vector3(5 * delta, 5 * delta, 0)
