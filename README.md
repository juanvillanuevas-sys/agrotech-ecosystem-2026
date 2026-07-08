# AgroTech — Ecosistema Inteligente de Monitoreo Agrícola

**Curso:** Desarrollo Basado en Plataformas
**Facultad de Ingeniería de Sistemas e Informática — E.P. Ciencias de la Computación**
**Universidad Nacional Mayor de San Marcos**

Proyecto integral (Fase I a IV) que automatiza la captura de datos de suelo y agua en cultivos de exportación, y entrega herramientas de decisión en tiempo real mediante 4 plataformas conectadas entre sí.

---

## 1. Descripción del problema

Los agricultores de cultivos de exportación enfrentan pérdidas significativas por el uso ineficiente del agua y la falta de datos sobre los nutrientes del suelo. Este proyecto automatiza la captura de esos datos y entrega herramientas de decisión en tiempo real, garantizando la seguridad de la información mediante autenticación JWT.

---

## 2. Arquitectura general

```
sensor (iot_device)
    │  REST / MQTT
    ▼
Backend (FastAPI + SQLite)  ◄────────────┐
    │  REST                              │  REST
    ▼                                    ▼
Mobile (Flutter)                 Godot (Gemelo Digital 3D)
```

Los sensores IoT publican telemetría (temperatura, humedad, pH) hacia el backend, ya sea directo por REST o vía MQTT con un bridge intermedio. El backend calcula el nivel de riesgo (`NORMAL` / `ALERTA` / `PELIGRO`) y lo expone por API. La app móvil y la simulación en Godot consumen esa misma API para mostrar el estado en tiempo real, cada una a su manera.

---

## 3. Componentes (las 4 plataformas)

| Componente | Carpeta | Tecnología | Función |
|---|---|---|---|
| **Backend / Cloud** | `backend/` | Python + FastAPI + SQLAlchemy | "Cerebro" del sistema: gestiona parcelas, procesa telemetría, calcula riesgo, persiste en SQLite, seguridad JWT con roles (admin/usuario). |
| **Móvil** | `mobile/` | Flutter | App de campo para el agricultor: login, listado de estaciones, gráficos de lecturas (fl_chart), mapa de estaciones (flutter_map), alertas visuales de Estrés Hídrico. |
| **IoT Industrial** | `iot_device/` | Python | Simulación de sensores de humedad, pH y temperatura del suelo. Envía telemetría por REST (`sensor_emitter.py`) o por MQTT (`mqtt_sender.py` + `mqtt_bridge.py`). |
| **Simulación 3D** | `simulation_godot/` | Godot Engine 4.x | Gemelo digital de la parcela: consulta el endpoint de riesgo cada pocos segundos y anima en 3D el color del suelo y el estado de los cultivos según el nivel detectado. |

---

## 4. Cómo levantar el proyecto completo

Se necesitan **hasta 4 terminales** corriendo en paralelo, en este orden:

### 4.1 Backend (siempre primero)

```bash
cd backend
python -m venv venv
venv\Scripts\activate          # Windows
# source venv/bin/activate     # Linux/Mac
pip install -r requirements.txt
uvicorn app.main:app --reload
```

- API disponible en `http://localhost:8000`
- Documentación interactiva (Swagger) en `http://localhost:8000/docs`
- La base de datos SQLite (`agrotech.db`) se genera automáticamente al primer arranque. **No se sube al repositorio** (ver `.gitignore`).

### 4.2 IoT — emisor de datos

Elige una de las dos opciones:

**Opción REST:**
```bash
cd iot_device
python sensor_emitter.py
```

**Opción MQTT** (requiere el bridge corriendo en otra terminal):
```bash
cd iot_device
python mqtt_sender.py
```
```bash
cd iot_device
python mqtt_bridge.py
```
El bridge pide login (usuario/contraseña) para obtener su propio token JWT y poder hacer `POST /lecturas/` autorizado.

Controles del simulador: `[P]` fuerza estado PELIGRO, `[N]` vuelve a NORMAL, `[Q]` para salir.

### 4.3 Móvil

```bash
cd mobile
flutter pub get
flutter run -d web-server        # o -d chrome, o un emulador conectado
```

> **Nota Windows:** si sale el error *"Please enable Developer Mode"*, correr `start ms-settings:developers` y activar el Modo de programador antes de compilar.

### 4.4 Simulación Godot

1. Abrir Godot Engine 4.x → "Import" → seleccionar `simulation_godot/project.godot`.
2. Presionar **F5** para correr la escena principal (`main.tscn`).
3. Con el backend y el emisor IoT corriendo, la parcela 3D debería reaccionar cada pocos segundos a los datos reales.

---

## 5. Seguridad

- Autenticación mediante **JWT**.
- Roles diferenciados: `admin` (ve y gestiona todas las estaciones) y `usuario` (solo las suyas).
- Los scripts IoT autentican cada envío de telemetría con un token autorizado.

---

## 6. Estructura del repositorio

```
agrotech-ecosystem-2026/
├── .gitignore
├── README.md
├── backend/            # API REST (FastAPI, SQLAlchemy, JWT)
│   ├── app/            # Código modular (routers, models, schemas, tests)
│   └── requirements.txt
├── mobile/             # App móvil (Flutter)
│   └── lib/
├── iot_device/         # Scripts de sensores (Python) — REST y MQTT
└── simulation_godot/   # Gemelo digital 3D (Godot Engine 4.x)
```

---

## 7. Roles y responsabilidades del equipo

| Rol | Integrante | Responsable de... |
|---|---|---|
| **Backend Lead** | _(completar)_ | Lógica de negocio, base de datos relacional y seguridad JWT. |
| **Mobile Dev** | _(completar)_ | UI/UX de la app y consumo de servicios protegidos. |
| **IoT Engineer** | _(completar)_ | Telemetría de sensores y protocolos de comunicación (REST/MQTT). |
| **Sim Manager** | _(completar)_ | Entorno 3D en Godot y lógica de respuesta visual. |

---

## 8. Cronograma de hitos

- **Hito 1 — Examen Parcial (Semana 8):** Backend con JWT funcional, base de datos con relaciones 1:N y Swagger documentado. App móvil con login funcional y lista de parcelas en tiempo real.
- **Hito 2 — Examen Final (Semana 16):** Scripts IoT enviando telemetría continua mediante tokens autorizados. Escena en Godot que consume la API y modifica visualmente el entorno 3D.

---

## 9. Criterios de aceptación

- ✅ El profesor (`vbustamanteo`) tiene acceso al repositorio y visibilidad de la actividad de todos los miembros.
- ✅ Uso estricto de JWT para endpoints críticos.
- ✅ Los datos fluyen de punta a punta: script IoT → backend → simulación en Godot (y móvil).

---

## 10. Notas de mantenimiento

- El "contrato" de la API (rutas, formatos de request/response) debe mantenerse actualizado para que Mobile, IoT y Godot sigan funcionando sin romperse entre sí. Ante cualquier cambio de endpoint, avisar al equipo.
- No subir `agrotech.db`, `venv/`, `__pycache__/`, `.dart_tool/`, ni `.godot/` — ya están excluidos en el `.gitignore` de la raíz.
