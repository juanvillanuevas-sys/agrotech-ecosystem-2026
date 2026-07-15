"""
AgroTech SMAT — MQTT Bridge
====================================================
Escucha el broker MQTT y persiste cada lectura en el
backend FastAPI (temperatura, humedad, pH).

Tópico suscrito : agrotech/estaciones/#
Endpoint destino: POST /lecturas/

Detección offline: si una estación no envía datos en
30 segundos, se registra una lectura de alerta en la BD.

Uso local (interactivo, pide usuario/contraseña):
    python mqtt_bridge.py

Uso en Docker (no interactivo, variables de entorno):
    API_URL=http://backend:8000  JWT_TOKEN=<token>  python mqtt_bridge.py

Requisitos:
    pip install paho-mqtt requests
"""

import json
import os
import threading
import time
import getpass

import paho.mqtt.client as mqtt
import requests

# ─── CONFIGURACIÓN ─────────────────────────────────────────────────────────────
BROKER          = "broker.hivemq.com"
TOPIC           = "agrotech/estaciones/#"

# En Docker, "localhost" apunta al propio contenedor del bridge, no al del backend.
# docker-compose.yml define API_URL=http://backend:8000 (nombre del servicio como dominio).
# Localmente (sin Docker) usamos localhost como siempre.
API_URL         = os.environ.get("API_URL", "http://localhost:8000")

# Si ya viene un token por variable de entorno (caso Docker), lo usamos directo
# y nos saltamos el login interactivo — un contenedor no tiene forma de escribir
# usuario/contraseña por teclado.
JWT_TOKEN_ENV   = os.environ.get("JWT_TOKEN")

TIMEOUT_OFFLINE = 30   # segundos sin datos → estación offline
CHECK_INTERVAL  = 10   # frecuencia del hilo de monitoreo

# ─── ESTADO GLOBAL ─────────────────────────────────────────────────────────────
last_seen: dict = {}   # estacion_id → timestamp última lectura
_token    = None
_username = None
_password = None


# ─── SOLICITAR CREDENCIALES AL ARRANCAR (solo modo local/interactivo) ──────────

def solicitar_credenciales() -> tuple:
    print("=" * 55)
    print("   AgroTech SMAT — MQTT Bridge")
    print("=" * 55)
    print("   Ingresa tus credenciales para iniciar.\n")

    username = input("   Usuario    : ").strip()
    password = getpass.getpass("   Contraseña : ")
    print()
    return username, password


# ─── AUTENTICACIÓN AUTOMÁTICA ──────────────────────────────────────────────────

def obtener_token(username: str, password: str) -> str:
    print(f"[AUTH] Autenticando como '{username}'...")
    try:
        response = requests.post(
            f"{API_URL}/token",
            data={"username": username, "password": password},
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            timeout=5,
        )
        if response.status_code == 200:
            token = response.json()["access_token"]
            rol   = response.json().get("rol", "usuario")
            print(f"[AUTH] ✅ Token obtenido. Rol: {rol}\n")
            return token
        else:
            print(f"[AUTH] ❌ Credenciales incorrectas.")
            exit(1)
    except Exception as e:
        print(f"[AUTH] ❌ No se pudo conectar con el servidor: {e}")
        exit(1)

def renovar_token():
    global _token
    if JWT_TOKEN_ENV:
        # En modo Docker/token-fijo no hay credenciales guardadas para renovar solo.
        # Se necesitaría generar un token nuevo y reiniciar el contenedor con él.
        print("[AUTH] ⚠️  Token expirado y no hay credenciales para renovar automáticamente")
        print("[AUTH]    (modo Docker con JWT_TOKEN fijo). Genera un token nuevo y reinicia el contenedor.")
        return
    print("[AUTH] 🔄 Renovando token...")
    _token = obtener_token(_username, _password)

def get_headers() -> dict:
    return {
        "Authorization": f"Bearer {_token}",
        "Content-Type":  "application/json",
    }


# ─── CALLBACKS MQTT ────────────────────────────────────────────────────────────

def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print(f"[MQTT] ✅ Conectado a {BROKER}")
        client.subscribe(TOPIC)
        print(f"[MQTT] 📡 Suscrito a: {TOPIC}\n")
    else:
        print(f"[MQTT] ❌ Error de conexión (código {rc})")


def on_message(client, userdata, msg):
    global _token
    try:
        payload     = json.loads(msg.payload.decode())
        estacion_id = int(msg.topic.split("/")[-1])

        # Actualizar timestamp de última actividad
        last_seen[str(estacion_id)] = time.time()

        temperatura = payload.get("temperatura")
        humedad     = payload.get("humedad")
        ph          = payload.get("ph")

        if temperatura is None or humedad is None:
            print(f"⚠️  Payload incompleto, se omite: {payload}")
            return

        emoji_nivel = _emoji_nivel(temperatura, humedad, ph)
        print(
            f"[MQTT] 📩 Estación {estacion_id} | "
            f"{emoji_nivel} | "
            f"🌡  {temperatura}°C | "
            f"💧 {humedad}% | "
            f"🧪 pH {ph}"
        )

        data = {
            "estacion_id": estacion_id,
            "temperatura": temperatura,
            "humedad":     humedad,
            "ph":          ph,
            "valor": round((temperatura + humedad + (ph or 0)) / 3, 2),
        }

        response = requests.post(
            f"{API_URL}/lecturas/",
            json=data,
            headers=get_headers(),
            timeout=5,
        )

        if response.status_code in (200, 201):
            print(f"         ✅ Guardado en BD")
        elif response.status_code == 401:
            print("         🔒 Token expirado — renovando...")
            renovar_token()
            # Reintentar con nuevo token
            requests.post(
                f"{API_URL}/lecturas/",
                json=data,
                headers=get_headers(),
                timeout=5,
            )
        else:
            print(f"         ⚠️  API respondió {response.status_code}: {response.text}")

    except json.JSONDecodeError:
        print(f"[MQTT] ❌ Mensaje no es JSON válido: {msg.payload}")
    except ValueError:
        print(f"[MQTT] ❌ ID de estación inválido en tópico: {msg.topic}")
    except Exception as e:
        print(f"[MQTT] ❌ Error procesando mensaje: {e}")


def _emoji_nivel(t, h, p) -> str:
    """Evalúa nivel localmente para el log — misma lógica que el backend."""
    if p is None:
        p = 6.0
    if (t < 12 or t > 34) or (h < 30 or h > 85) or (p < 5.0 or p > 8.0):
        return "🔴 PELIGRO"
    if (t < 18 or t > 28) or (h < 50 or h > 75) or (p < 5.5 or p > 6.5):
        return "🟡 ALERTA"
    return "🟢 NORMAL"


# ─── HILO: DETECCIÓN OFFLINE ───────────────────────────────────────────────────

def monitor_offline():
    """
    Cada CHECK_INTERVAL segundos revisa si alguna estación
    lleva más de TIMEOUT_OFFLINE segundos sin enviar datos.
    """
    while True:
        ahora = time.time()
        for eid, ultimo in list(last_seen.items()):
            if ahora - ultimo > TIMEOUT_OFFLINE:
                print(f"\n[OFFLINE] 🚨 Estación {eid} sin datos "
                      f"por más de {TIMEOUT_OFFLINE}s")
                try:
                    requests.post(
                        f"{API_URL}/lecturas/",
                        json={
                            "estacion_id": int(eid),
                            "temperatura": -1.0,
                            "humedad":     -1.0,
                            "valor":       -1.0,
                        },
                        headers=get_headers(),
                        timeout=5,
                    )
                except Exception as e:
                    print(f"[OFFLINE] ❌ No se pudo notificar: {e}")
        time.sleep(CHECK_INTERVAL)


# ─── ARRANQUE ──────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    if JWT_TOKEN_ENV:
        # Modo Docker / no interactivo: token ya viene listo por variable de entorno.
        print("=" * 55)
        print("   AgroTech SMAT — MQTT Bridge (modo Docker)")
        print("=" * 55)
        print("   Usando JWT_TOKEN de variable de entorno.\n")
        _token = JWT_TOKEN_ENV
    else:
        # Modo local: credenciales interactivas, igual que siempre.
        _username, _password = solicitar_credenciales()
        _token = obtener_token(_username, _password)

    print(f"[Bridge] Broker  : {BROKER}:1883")
    print(f"[Bridge] Tópico  : {TOPIC}")
    print(f"[Bridge] API     : {API_URL}")
    print(f"[Bridge] Offline : >{TIMEOUT_OFFLINE}s sin datos\n")

    # Hilo de monitoreo offline
    # NOTA: comentado — estaba generando problemas con la chart, revisar luego.
    # threading.Thread(target=monitor_offline, daemon=True).start()

    # Cliente MQTT
    client = mqtt.Client(client_id="agrotech_bridge")
    client.on_connect = on_connect
    client.on_message = on_message

    try:
        client.connect(BROKER, 1883)
        print("[MQTT] Conectando al broker...")
        client.loop_forever()
    except KeyboardInterrupt:
        print("\n[Bridge] Detenido manualmente. ¡Hasta luego!")
    except Exception as e:
        print(f"[MQTT] ❌ Error de conexión: {e}")
        print("[MQTT]    Verifica tu conexión a internet.")
