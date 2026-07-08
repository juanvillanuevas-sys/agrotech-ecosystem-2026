extends Node3D

# ── Referencias a los nodos de la escena ───────────────────────
@onready var terreno: MeshInstance3D = $Terreno
@onready var cultivos: Node3D = $Cultivos
@onready var panel_datos: Label = $HUD/PanelDatos
@onready var api: Node = $ApiManager

# ── Colores según estado del suelo ─────────────────────────────
const COLOR_FERTIL   = Color(0.35, 0.25, 0.15)  # marrón oscuro húmedo
const COLOR_ALERTA   = Color(0.55, 0.45, 0.25)  # marrón amarillento
const COLOR_ARIDO    = Color(0.75, 0.65, 0.45)  # arena seca

const COLOR_PLANTA_SANA    = Color(0.30, 0.69, 0.31)  # verde
const COLOR_PLANTA_ESTRES  = Color(0.70, 0.65, 0.30)  # amarillento
const COLOR_PLANTA_SECA    = Color(0.55, 0.35, 0.20)  # café seco

# ── Materiales creados por código (garantizado que existen) ────
var mat_suelo: StandardMaterial3D
var materiales_plantas: Array = []

func _ready():
	# Conectar la señal del ApiManager a nuestra función
	api.datos_recibidos.connect(_actualizar_entorno)

	# ── Crear y asignar el material del suelo por código ────────
	terreno.material_override = null 
	mat_suelo = StandardMaterial3D.new()
	mat_suelo.albedo_color = COLOR_FERTIL
	terreno.set_surface_override_material(0, mat_suelo)

	# ── Crear y asignar un material propio para cada planta (la asignacion automatica nos da error)─────
	
	for planta in cultivos.get_children():
		if planta is MeshInstance3D:
			planta.material_override = null 
			var mat_planta = StandardMaterial3D.new()
			mat_planta.albedo_color = COLOR_PLANTA_SANA
			planta.set_surface_override_material(0, mat_planta)
			materiales_plantas.append({"nodo": planta, "material": mat_planta})

func _actualizar_entorno(nivel, temperatura, humedad, ph):
	# ── Actualizar el HUD ──────────────────────────────────────
	panel_datos.text = "Estado: %s\nTemp: %.1f °C\nHumedad: %.1f %%\npH: %.1f" % [nivel, temperatura, humedad, ph]

	# ── Elegir colores según el nivel ──────────────────────────
	var color_suelo: Color
	var color_planta: Color
	var escala_planta: float

	match nivel:
		"NORMAL":
			color_suelo   = COLOR_FERTIL
			color_planta  = COLOR_PLANTA_SANA
			escala_planta = 1.0
		"ALERTA":
			color_suelo   = COLOR_ALERTA
			color_planta  = COLOR_PLANTA_ESTRES
			escala_planta = 0.8
		"PELIGRO":
			color_suelo   = COLOR_ARIDO
			color_planta  = COLOR_PLANTA_SECA
			escala_planta = 0.5
		_:
			color_suelo   = COLOR_ARIDO
			color_planta  = COLOR_PLANTA_SECA
			escala_planta = 0.6

	# ── Aplicar al terreno (con transición suave) ───────────────
	var tween_suelo = create_tween()
	tween_suelo.tween_property(mat_suelo, "albedo_color", color_suelo, 1.5)

	# ── Aplicar a cada planta ────────────────────────────────────
	for entrada in materiales_plantas:
		var planta: MeshInstance3D = entrada["nodo"]
		var mat: StandardMaterial3D = entrada["material"]

		var tween_color = create_tween()
		tween_color.tween_property(mat, "albedo_color", color_planta, 1.5)

		var tween_escala = create_tween()
		tween_escala.tween_property(planta, "scale", Vector3.ONE * escala_planta, 1.5)
