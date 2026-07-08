extends Camera3D

var angulo_camara = 0.0

func _process(delta):
	angulo_camara += delta * 0.05   # velocidad lenta
	var radio = 12.0
	position = Vector3(sin(angulo_camara) * radio, 8, cos(angulo_camara) * radio)
	look_at(Vector3.ZERO, Vector3.UP)
