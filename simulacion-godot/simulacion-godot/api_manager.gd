extends Node

# ── Configuración ──────────────────────────────────────────────
const URL_BASE = "http://localhost:8000"
const ID_ESTACION = 1          # la estación que vamos a monitorear
const INTERVALO_SEGUNDOS = 5.0 # cada cuánto consultar el backend

# ── Señal que emitimos cuando llegan datos nuevos ──────────────
signal datos_recibidos(nivel, temperatura, humedad, ph)

var http: HTTPRequest
var timer: Timer

func _ready():
	# Crear el nodo HTTP para hacer peticiones
	http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_al_recibir_respuesta)

	# Crear el timer que consulta periódicamente
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = INTERVALO_SEGUNDOS
	timer.timeout.connect(_consultar_riesgo)
	timer.start()

	# Primera consulta inmediata
	_consultar_riesgo()

func _consultar_riesgo():
	var url = URL_BASE + "/estaciones/" + str(ID_ESTACION) + "/riesgo"
	var error = http.request(url)
	if error != OK:
		print("Error al lanzar la petición: ", error)

func _al_recibir_respuesta(result, response_code, headers, body):
	if response_code != 200:
		print("El backend respondió con código: ", response_code)
		return

	# Parsear el JSON (body llega como bytes)
	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	if parse_result != OK:
		print("Error al parsear JSON")
		return

	var datos = json.data
	var nivel = datos.get("nivel", "SIN DATOS")
	var temperatura = datos.get("temperatura", 0.0)
	var humedad = datos.get("humedad", 0.0)
	var ph = datos.get("ph", 0.0)

	print("Nivel: ", nivel, " | Temp: ", temperatura, " | Hum: ", humedad)

	# Emitir la señal para que la escena reaccione
	datos_recibidos.emit(nivel, temperatura, humedad, ph)
