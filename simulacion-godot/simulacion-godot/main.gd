extends Node3D

# ── Referencias a los nodos de la escena ───────────────────────
@onready var terreno: MeshInstance3D = $Terreno
@onready var cultivos: Node3D = $Cultivos
@onready var panel_datos: Label = $HUD/PanelContainer/PanelDatos
@onready var api: Node = $ApiManager


# ── Colores según estado del suelo ─────────────────────────────
const COLOR_FERTIL   = Color(0.218, 0.302, 0.166, 1.0)  # marrón oscuro húmedo
const COLOR_ALERTA   = Color(0.609, 0.419, 0.217, 1.0)  # marrón amarillento
const COLOR_ARIDO    = Color(0.75, 0.65, 0.45)  # arena seca

const COLOR_PLANTA_SANA    = Color(0.30, 0.69, 0.31)  # verde
const COLOR_PLANTA_ESTRES  = Color(0.70, 0.65, 0.30)  # amarillento
const COLOR_PLANTA_SECA    = Color(0.55, 0.35, 0.20)  # café seco

# ── Terreno procedural ───────────────────────────────────────────
const TERRENO_TAMANO = 10.0
const SUBDIVISIONES  = 40
const ALTURA_RELIEVE = 0.25

# ── Generación de plantas ───────────────────────────────────────
const NUM_PLANTAS = 200
const AREA_TERRENO = 7

# ── Modelos de plantas (variedad) ──────────────────────────────
# Ajusta las rutas exactas según donde hayas guardado los .glb
const MODELOS_PLANTAS = [
	preload("res://assets/plantas/crops_cornStageD.glb"),
	preload("res://assets/plantas/crops_wheatStageB.glb"),
	preload("res://assets/plantas/crop_pumpkin.glb"),
]
const OFFSETS_VERTICALES = [
	0.0,   # CornStageD
	0.0,   # WheatStageB
	0.0,   # Pumpkin
]

# ── Materiales creados por código ────
var mat_suelo: StandardMaterial3D
var materiales_plantas: Array = []
var ruido_terreno: FastNoiseLite
var sky_material: ProceduralSkyMaterial


func _ready():
	api.datos_recibidos.connect(_actualizar_entorno)

	_generar_terreno()
	_generar_plantas()

	sky_material = $WorldEnvironment.environment.sky.sky_material


func _generar_terreno():
	ruido_terreno = FastNoiseLite.new()
	ruido_terreno.seed = randi()
	ruido_terreno.frequency = 0.15
	ruido_terreno.fractal_octaves = 3

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var paso = TERRENO_TAMANO / float(SUBDIVISIONES)
	var mitad = TERRENO_TAMANO / 2.0

	for x in range(SUBDIVISIONES + 1):
		for z in range(SUBDIVISIONES + 1):
			var px = -mitad + x * paso
			var pz = -mitad + z * paso
			var py = ruido_terreno.get_noise_2d(px, pz) * ALTURA_RELIEVE
			st.set_uv(Vector2(x / float(SUBDIVISIONES), z / float(SUBDIVISIONES)))
			st.add_vertex(Vector3(px, py, pz))

	for x in range(SUBDIVISIONES):
		for z in range(SUBDIVISIONES):
			var i0 = x * (SUBDIVISIONES + 1) + z
			var i1 = i0 + 1
			var i2 = i0 + (SUBDIVISIONES + 1)
			var i3 = i2 + 1
			st.add_index(i0)
			st.add_index(i2)
			st.add_index(i1)
			st.add_index(i1)
			st.add_index(i2)
			st.add_index(i3)

	st.generate_normals()
	terreno.mesh = st.commit()

	terreno.material_override = null
	mat_suelo = StandardMaterial3D.new()
	mat_suelo.albedo_color = COLOR_FERTIL
	mat_suelo.roughness = 0.9
	mat_suelo.metallic = 0.0
	terreno.set_surface_override_material(0, mat_suelo)


func _altura_en(x: float, z: float) -> float:
	return ruido_terreno.get_noise_2d(x, z) * ALTURA_RELIEVE


func _generar_plantas():
	for hijo in cultivos.get_children():
		hijo.queue_free()

	materiales_plantas.clear()

	for i in range(NUM_PLANTAS):
		var indice_modelo = randi() % MODELOS_PLANTAS.size()
		var planta = MODELOS_PLANTAS[indice_modelo].instantiate()

		var x = randf_range(-AREA_TERRENO, AREA_TERRENO)
		var z = randf_range(-AREA_TERRENO, AREA_TERRENO)
		var y_suelo = _altura_en(x, z)
		var offset = OFFSETS_VERTICALES[indice_modelo]

		# Posiciónamiento de plantitas
		planta.position = Vector3(x, y_suelo + offset, z)
		planta.rotation.y = randf_range(0, TAU)

		var escala_base = randf_range(0.8, 1.2)
		planta.scale = Vector3.ONE * escala_base

		cultivos.add_child(planta)

		var mesh_instance = _buscar_mesh_instance(planta)
		if mesh_instance:
			var mat_planta = StandardMaterial3D.new()
			mat_planta.albedo_color = COLOR_PLANTA_SANA
			mesh_instance.material_override = null
			mesh_instance.set_surface_override_material(0, mat_planta)
			materiales_plantas.append({
				"nodo": mesh_instance,
				"material": mat_planta,
				"raiz": planta,
				"escala_base": escala_base,
			})


func _buscar_mesh_instance(nodo: Node) -> MeshInstance3D:
	if nodo is MeshInstance3D:
		return nodo
	for hijo in nodo.get_children():
		var encontrado = _buscar_mesh_instance(hijo)
		if encontrado:
			return encontrado
	return null


func _actualizar_entorno(nivel, temperatura, humedad, ph):
	panel_datos.text = "Estado: %s\nTemp: %.1f °C\nHumedad: %.1f %%\npH: %.1f" % [nivel, temperatura, humedad, ph]

	var color_suelo: Color
	var color_planta: Color
	var color_texto: Color
	var color_horizonte_segun_nivel: Color
	var factor_escala: float
	var color_ground_horizon_segun_nivel: Color   

	match nivel:
		"NORMAL":
			color_suelo   = COLOR_FERTIL
			color_planta  = COLOR_PLANTA_SANA
			color_texto   = Color(0.4, 1.0, 0.4)
			color_horizonte_segun_nivel = Color(0.28, 0.895, 0.382, 1.0)
			color_ground_horizon_segun_nivel = Color(0.513, 0.732, 0.287, 1.0)   
			factor_escala = 1.0
		"ALERTA":
			color_suelo   = COLOR_ALERTA
			color_planta  = COLOR_PLANTA_ESTRES
			color_texto   = Color(1.0, 0.85, 0.3)
			color_horizonte_segun_nivel = Color(0.85, 0.78, 0.6)
			color_ground_horizon_segun_nivel = Color(0.78, 0.68, 0.5)
			factor_escala = 0.8
		"PELIGRO":
			color_suelo   = COLOR_ARIDO
			color_planta  = COLOR_PLANTA_SECA
			color_texto   = Color(1.0, 0.35, 0.35)
			color_horizonte_segun_nivel = Color(0.75, 0.6, 0.45)
			color_ground_horizon_segun_nivel = Color(0.85, 0.72, 0.55)
			factor_escala = 0.5
		_:
			color_suelo   = COLOR_ARIDO
			color_planta  = COLOR_PLANTA_SECA
			color_texto   = Color.WHITE
			color_horizonte_segun_nivel = Color(0.75, 0.6, 0.45)
			color_ground_horizon_segun_nivel = Color(0.85, 0.72, 0.55)
			factor_escala = 0.6

	$PolvoAmbiente.emitting = (nivel == "PELIGRO")
	$LluviaAmbiente.emitting = (nivel == "NORMAL")
	panel_datos.add_theme_color_override("font_color", color_texto)

	var tween_suelo = create_tween()
	tween_suelo.tween_property(mat_suelo, "albedo_color", color_suelo, 1.5)

	if sky_material:
		var tween_cielo = create_tween()
		tween_cielo.tween_property(sky_material, "sky_horizon_color", color_horizonte_segun_nivel, 2.0)
		var tween_ground_horizon = create_tween()   # ← AGREGA ESTAS DOS LÍNEAS
		tween_ground_horizon.tween_property(sky_material, "ground_horizon_color", color_ground_horizon_segun_nivel, 2.0)

	for entrada in materiales_plantas:
		var mat: StandardMaterial3D = entrada["material"]
		var raiz: Node3D = entrada["raiz"]
		var escala_base: float = entrada["escala_base"]

		var tween_color = create_tween()
		tween_color.tween_property(mat, "albedo_color", color_planta, 1.5)

		var tween_escala = create_tween()
		tween_escala.tween_property(raiz, "scale", Vector3.ONE * escala_base * factor_escala, 1.5)
