# AgroTech — Ecosistema Inteligente de Monitoreo Agrícola

**Curso:** Desarrollo Basado en Plataformas — UNMSM, FISI, E.P. Ciencias de la Computación

Ecosistema de monitoreo agrícola en tiempo real: sensores IoT → MQTT → Backend (FastAPI, Docker) → Móvil (Flutter) y Simulación 3D (Godot), con autenticación JWT y roles admin/usuario.

---

## 🚀 INICIO RÁPIDO — pasos exactos, en orden

### Paso 0 — Antes de empezar (una sola vez)

- [ ] **Docker Desktop** instalado y **abierto** (ballena estable en la barra de tareas)
- [ ] **Python 3.10+** instalado
- [ ] **Godot Engine 4.x** instalado
- [ ] **Flutter SDK** instalado

```bash
cd iot_device
pip install -r requirements.txt
cd ..
```

### Paso 1 — Configurar `docker-compose.yml` (una sola vez)

Abre `docker-compose.yml` en la raíz y reemplaza estos dos valores:

```yaml
backend:
  environment:
    - ADMIN_MASTER_KEY=agrotech-fisi-2026-admin    # ← puedes dejar este valor

mqtt_bridge:
  environment:
    - JWT_TOKEN=tu_token_jwt_aqui                   # ← lo generas en el Paso 3
```

### Paso 2 — Levantar Backend + Bridge

**Terminal 1:**
```bash
docker-compose up --build
```

**Espera a ver esta línea antes de continuar:**
```
Container agrotech-ecosystem-2026-backend-1  Healthy
```

### Paso 3 — Generar el token del Bridge

1. Abre `http://localhost:8000/docs`
2. `POST /token` → **Try it out** → Execute con cualquier usuario (si es la primera vez, créalo primero con `POST /register`, ver Paso 4)
3. Copia el `access_token` de la respuesta (**sin comillas**)
4. Pégalo en `docker-compose.yml` (Paso 1), reemplazando `tu_token_jwt_aqui`
5. Vuelve a correr en la Terminal 1:
   ```bash
   docker-compose up --build
   ```
   (repite hasta ver `Healthy` de nuevo)

> ⚠️ Este token expira en **30 minutos**. Si en algún momento el bridge empieza a fallar con `401`, repite este paso.

### Paso 4 — Crear el usuario administrador y uno normal

**4a. Admin** (usando la clave maestra del Paso 1):

```
POST /register
{
  "username": "admin",
  "email": "admin@agrotech.pe",
  "password": "admin123",
  "clave_maestra": "agrotech-fisi-2026-admin"
}
```

Confirma que la respuesta diga `"rol": "admin"`.

**4b. Usuario normal** (sin `clave_maestra`, para poder comparar roles):

```
POST /register
{
  "username": "usuario_demo",
  "email": "usuario@agrotech.pe",
  "password": "usuario123"
}
```

Confirma que la respuesta diga `"rol": "usuario"`.



### Paso 5.a — Alternativa: crear la estación desde el móvil (más simple)

Si prefieres no usar Swagger para este paso, puedes crear la estación directo desde la app:

1. Adelanta el **Paso 8** (`flutter pub get` + `flutter run -d web-server`) y haz login con `admin` / `admin123`
2. Toca el botón **"+"** (esquina inferior derecha)
3. Llena nombre, ubicación y coordenadas → Guardar
4. La estación aparece en la lista de la pantalla principal — toca sobre ella para ver su **ID** (se muestra debajo del nombre, ej. "ID: 1")
5. Anota ese ID y continúa con el Paso 6 normalmente

Con esta alternativa te saltas por completo la parte de Swagger de este paso — el resto de la guía (Pasos 6 y 7) sigue igual.

### Paso 5 B — Crear una estación de prueba (Desde el Swagger)

```
POST /token   →  usa "admin" / "admin123"  →  copia el access_token
```
Arriba a la derecha de Swagger → **Authorize** → pega el token → Authorize

```
POST /estaciones/
{
  "nombre": "Parcela Demo",
  "ubicacion": "Ica",
  "latitud": -14.07,
  "longitud": -75.73
}
```

**Anota el `id` que te devuelve** (normalmente `1`) — lo necesitas en los pasos 6 y 7.

### Paso 6 — Encender el sensor (simula el hardware)

**Terminal 2:**
```bash
cd iot_device
python mqtt_sender.py
```
Ingresa el mismo **ID de estación** del Paso 5.

### Paso 7 — Abrir la simulación 3D

1. Abre Godot 4.x → `Import` → `simulacion-godot/project.godot`
2. Si el ID de estación del Paso 5 **no fue `1`**, edita `api_manager.gd`:
   ```gdscript
   const ID_ESTACION_OBJETIVO = 1   # ← cámbialo por el ID real del Paso 5
   ```
3. Presiona **F5**

La parcela debería reaccionar en pocos segundos con los datos que publica el sensor (Terminal 2). Con `[P]` en esa terminal se fuerza escenario PELIGRO, `[N]` vuelve a NORMAL.

### Paso 8 — Abrir la app móvil

**Terminal 3:**
```bash
cd mobile
flutter pub get
flutter run -d web-server
```
Login con `admin` / `admin123`.

---

## ✅ Checklist de verificación rápida

| Qué revisar | Cómo confirmarlo |
|---|---|
| Backend responde | `http://localhost:8000/docs` carga Swagger |
| Bridge conectado | Terminal 1 muestra `[MQTT] ✅ Conectado a broker.hivemq.com` |
| Sensor publicando | Terminal 2 muestra `✅ OK` en cada ciclo |
| Datos llegando al backend | Terminal 1 muestra `POST /lecturas/ ... 201 Created` |
| Godot reacciona | La parcela cambia de color/escala unos segundos después de encender el sensor |
| Móvil funciona | Login exitoso, se ve la estación creada en el Paso 5 |
| Admin funciona | Ícono de escudo 🛡️ visible en el AppBar del móvil |

---

## 🔑 Probar la diferenciación de roles

Las cuentas `admin` / `usuario_demo` que se crearon en el **Paso 4** ya te permiten probar el sistema de roles completo, no se necesita nada adicional, ya que cada quien las crea en su propia base de datos local.

| Usuario | Contraseña | Rol | Qué deberías ver |
|---|---|---|---|
| `admin` | `admin123` | admin | Ve **todas** las estaciones, ícono de escudo 🛡️ en el AppBar, puede cambiar roles de otros usuarios |
| `usuario_demo` | `usuario123` | usuario | Solo ve **sus propias** estaciones, sin ícono de escudo |

**Prueba en vivo sugerida (móvil, Paso 8):**
1. Inicia sesión como `usuario_demo` → confirma que **no** hay ícono de escudo
2. Cierra sesión → entra como `admin` → toca el escudo → verás a `usuario_demo` en la lista con rol "Usuario"
3. Cambia su rol a "Admin" desde el dropdown → confirma
4. Cierra sesión → vuelve a entrar como `usuario_demo` → ahora sí tiene acceso admin

Esto demuestra de punta a punta: registro con clave maestra (Paso 4), autorización por rol en el backend, y gestión de roles desde la app — sin tocar código ni Swagger más allá de la creación inicial de cuentas.

---

## 🏗️ Arquitectura (referencia)

```
                          ┌────────────────────────┐
                          │   Broker MQTT público   │
                          │   (broker.hivemq.com)   │
                          └───────────┬────────────┘
                                      │
            ┌─────────────────────────┼─────────────────────────┐
   publica  │                escucha  │                escucha  │
┌───────────▼───────────┐   ┌─────────▼──────────┐   ┌──────────▼───────────┐
│  Sensor IoT (Python)   │   │   MQTT Bridge       │   │  Godot (Gemelo       │
│  mqtt_sender.py        │   │   (Docker)          │   │  Digital 3D)         │
│  NO dockerizado        │   │   MQTT → REST       │   │  se suscribe DIRECTO │
└────────────────────────┘   └─────────┬───────────┘   │  al broker           │
                                        │ POST           └───────────────────────┘
                                        ▼
                          ┌──────────────────────────┐
                          │  Backend FastAPI (Docker) │
                          │  + SQLite · JWT · Roles   │
                          └─────────────┬─────────────┘
                                        │ REST
                                        ▼
                          ┌──────────────────────────┐
                          │   App Móvil (Flutter)     │
                          └──────────────────────────┘
```

Godot **no depende del backend** — se conecta directo al broker MQTT y calcula el riesgo localmente. El móvil sí depende del backend vía REST.

---

## 🔐 Seguridad y Roles

- **JWT**, expira a los 60 min.
- **`usuario`**: ve/edita/elimina solo sus propias estaciones.
- **`admin`**: ve/edita/elimina todas las estaciones, y gestiona roles de otros usuarios desde el móvil (`GET/PATCH /admin/usuarios`).
- `PUT`/`DELETE /estaciones/{id}` verifican propietario o admin (403 si no corresponde).
- `GET /estaciones/{id}/riesgo` y `/historial` son públicos a propósito (Godot los ignora de todas formas, ya no consulta el backend).

---

## 📁 Estructura del repositorio

```
agrotech-ecosystem-2026/
├── docker-compose.yml
├── README.md
├── backend/              # FastAPI + SQLAlchemy + JWT — Docker
├── mobile/                # Flutter
├── iot_device/            # mqtt_sender.py (local) + mqtt_bridge.py (Docker)
└── simulacion-godot/       # Godot 4.x — cliente MQTT nativo
```

---

## 👥 Roles del equipo

| Rol | Integrante | Responsable de |
|---|---|---|
| Backend Lead | _(completar)_ | API, JWT, roles, Docker |
| Mobile Dev | _(completar)_ | UI/UX, panel de admin |
| IoT Engineer | _(completar)_ | Sensores, MQTT, bridge |
| Sim Manager | _(completar)_ | Godot, cliente MQTT, visuales |

---

## ⚠️ Problemas conocidos

- **Token del bridge expira en 60 min** → repetir Paso 3 si aparece `401` en los logs de Docker.
- **`ADMIN_MASTER_KEY` en texto plano** en `docker-compose.yml` — aceptable para entorno académico, no para producción.
- **Notificaciones de "Estrés Hídrico" en móvil son visuales** (color/ícono), no push/locales del sistema.
- **El sensor no se dockeriza a propósito** — simula hardware físico en campo, fuera de la infraestructura de servidor.
