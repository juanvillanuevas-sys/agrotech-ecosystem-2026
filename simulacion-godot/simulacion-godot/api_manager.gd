extends Node

# Configuración MQTT 
# Mismo broker público que usa tu mqtt_sender.py (HiveMQ), pero por WebSocket
# en vez de TCP crudo, para máxima compatibilidad (editor, escritorio y web).
const BROKER_URL = "ws://broker.hivemq.com:8000/mqtt"

# Mismo esquema de tópico que publica mqtt_sender.py: "agrotech/estaciones/<id>"
# El '+' es un comodín MQTT: nos suscribimos a TODAS las estaciones a la vez,
# y filtramos en código cuál nos interesa mostrar en la parcela 3D.
const TOPIC_SUSCRIPCION = "agrotech/estaciones/+"

# Qué estación queremos visualizar en el gemelo digital
const ID_ESTACION_OBJETIVO = 2

# Señal que emitimos cuando llegan datos nuevos 
# (misma firma que antes — main.gd no necesita ningún cambio)
signal datos_recibidos(nivel, temperatura, humedad, ph)

@onready var mqtt = $MQTT


func _ready():
	# Conectamos las señales del nodo MQTT por código (más robusto que hacerlo
	# a mano desde el editor — evita errores de tipeo en los nombres de nodo).
	mqtt.broker_connected.connect(_on_mqtt_broker_connected)
	mqtt.received_message.connect(_on_mqtt_received_message)
	mqtt.broker_disconnected.connect(_on_mqtt_broker_disconnected)
	mqtt.broker_connection_failed.connect(_on_mqtt_broker_connection_failed)

	print("[MQTT] Conectando a: ", BROKER_URL)
	var exito = mqtt.connect_to_broker(BROKER_URL)
	if not exito:
		print("[MQTT] Error al iniciar la conexión.")


func _on_mqtt_broker_connected():
	print("[MQTT] ✅ Conectado. Suscribiendo a: ", TOPIC_SUSCRIPCION)
	mqtt.subscribe(TOPIC_SUSCRIPCION)


func _on_mqtt_received_message(topic, message):
	var datos = JSON.parse_string(message)
	if datos == null:
		print("[MQTT] Mensaje no es JSON válido: ", message)
		return

	var estacion_id = datos.get("estacion_id", -1)
	if estacion_id != ID_ESTACION_OBJETIVO:
		return   # ignoramos lecturas de otras estaciones, solo nos interesa la nuestra

	var temperatura = datos.get("temperatura", 0.0)
	var humedad     = datos.get("humedad", 0.0)
	var ph          = datos.get("ph", 0.0)
	var nivel       = _evaluar_nivel(temperatura, humedad, ph)

	print("[MQTT] Estación ", estacion_id, " → ", nivel,
		" | Temp: ", temperatura, " | Hum: ", humedad, " | pH: ", ph)

	datos_recibidos.emit(nivel, temperatura, humedad, ph)


func _evaluar_nivel(temperatura: float, humedad: float, ph: float) -> String:
	# Mismos umbrales que usa el backend (obtener_riesgo) y el sender (evaluar_nivel),
	# para que Godot, el móvil y el backend estén de acuerdo en qué es "PELIGRO".
	var nivel = "NORMAL"

	if temperatura < 12.0 or temperatura > 34.0:
		nivel = "PELIGRO"
	elif temperatura < 18.0 or temperatura > 28.0:
		nivel = "ALERTA"

	if nivel != "PELIGRO":
		if humedad < 30.0 or humedad > 85.0:
			nivel = "PELIGRO"
		elif humedad < 50.0 or humedad > 75.0:
			nivel = "ALERTA"

	if nivel != "PELIGRO":
		if ph < 5.0 or ph > 8.0:
			nivel = "PELIGRO"
		elif ph < 5.5 or ph > 6.5:
			nivel = "ALERTA"

	return nivel


func _on_mqtt_broker_disconnected():
	print("[MQTT] Desconectado del broker.")


func _on_mqtt_broker_connection_failed():
	print("[MQTT] ❌ Falló la conexión al broker.")
