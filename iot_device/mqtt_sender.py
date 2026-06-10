"""
AgroTech SMAT — MQTT Sender (Dispositivo de Campo)
====================================================
Simula un sensor agrícola (ESP32 / Raspberry Pi) que publica
lecturas de temperatura, humedad y pH cada 10 segundos vía MQTT.

Protocolo : MQTT
Broker    : broker.hivemq.com (público, sin cuenta)
Tópico    : agrotech/estaciones/<estacion_id>

Controles en tiempo real:
    P  →  Forzar escenario PELIGRO
    N  →  Volver a valores NORMAL
    Q  →  Salir

Requisitos:
    pip install paho-mqtt
"""

import paho.mqtt.client as mqtt
import json
import time
import random
import getpass
import threading
import sys

# ─── CONFIGURACIÓN ─────────────────────────────────────────────────────────────
BROKER   = "broker.hivemq.com"
PORT     = 1883
INTERVALO_NORMAL     = 10  # segundos
INTERVALO_EMERGENCIA = 2   # segundos en modo PELIGRO

# ─── ESTADO GLOBAL ─────────────────────────────────────────────────────────────
_modo_forzado = None   # None | "PELIGRO" | "NORMAL"
_salir        = False


# ─── SOLICITAR DATOS AL ARRANCAR ───────────────────────────────────────────────

def solicitar_configuracion() -> tuple:
    print("=" * 55)
    print("   AgroTech SMAT — MQTT Sender (Sensor de Campo)")
    print("=" * 55)
    print("   Configura el dispositivo antes de iniciar.\n")

    estacion_id = input("   ID Estación   : ").strip()
    while not estacion_id.isdigit():
        print("   ⚠️  El ID debe ser un número entero.")
        estacion_id = input("   ID Estación   : ").strip()

    print()
    return int(estacion_id)


# ─── SENSORES EMULADOS ─────────────────────────────────────────────────────────

def crear_estado_inicial() -> dict:
    """Valores iniciales dentro del rango NORMAL."""
    return {
        "temperatura": random.uniform(18.0, 28.0),
        "humedad":     random.uniform(50.0, 75.0),
        "ph":          random.uniform(5.5,  6.5),
    }

def leer_sensores(estado: dict) -> dict:
    """
    Variación gradual — simula sensor físico real.
    Si hay modo forzado, genera valores extremos.
    """
    global _modo_forzado

    if _modo_forzado == "PELIGRO":
        estado["temperatura"] = round(random.uniform(36.0, 42.0), 2)
        estado["humedad"]     = round(random.uniform(10.0, 25.0), 2)
        estado["ph"]          = round(random.uniform(3.0,  4.5),  2)
    elif _modo_forzado == "NORMAL":
        estado["temperatura"] = round(random.uniform(18.0, 28.0), 2)
        estado["humedad"]     = round(random.uniform(50.0, 75.0), 2)
        estado["ph"]          = round(random.uniform(5.5,  6.5),  2)
        _modo_forzado = None
    else:
        estado["temperatura"] = round(
            max(-10.0, min(50.0, estado["temperatura"] + random.uniform(-1.5, 1.5))), 2
        )
        estado["humedad"] = round(
            max(0.0, min(100.0, estado["humedad"] + random.uniform(-3.0, 3.0))), 2
        )
        estado["ph"] = round(
            max(0.0, min(14.0, estado["ph"] + random.uniform(-0.2, 0.2))), 2
        )
    return dict(estado)

def evaluar_nivel(lectura: dict) -> str:
    t, h, p = lectura["temperatura"], lectura["humedad"], lectura["ph"]
    if (t < 12.0 or t > 34.0) or (h < 30.0 or h > 85.0) or (p < 5.0 or p > 8.0):
        return "PELIGRO"
    if (t < 18.0 or t > 28.0) or (h < 50.0 or h > 75.0) or (p < 5.5 or p > 6.5):
        return "ALERTA"
    return "NORMAL"


# ─── HILO DE TECLADO (Windows compatible con msvcrt) ──────────────────────────

def escuchar_teclado():
    global _modo_forzado, _salir
    print("[IoT] Controles: [P] Forzar PELIGRO  |  [N] Volver NORMAL  |  [Q] Salir")
    print("-" * 55)

    if sys.platform == "win32":
        import msvcrt
        while not _salir:
            if msvcrt.kbhit():
                cmd = msvcrt.getwch().upper()
                if cmd == "P":
                    _modo_forzado = "PELIGRO"
                    print("\n[CONTROL] 🔴 Modo PELIGRO forzado activado.")
                elif cmd == "N":
                    _modo_forzado = "NORMAL"
                    print("\n[CONTROL] 🟢 Volviendo a valores NORMAL.")
                elif cmd == "Q":
                    _salir = True
                    print("\n[IoT] Deteniendo emisor...")
            time.sleep(0.1)
    else:
        # Linux / macOS
        import tty, termios
        fd = sys.stdin.fileno()
        old = termios.tcgetattr(fd)
        try:
            tty.setraw(fd)
            while not _salir:
                cmd = sys.stdin.read(1).upper()
                if cmd == "P":
                    _modo_forzado = "PELIGRO"
                    print("\n[CONTROL] 🔴 Modo PELIGRO forzado activado.")
                elif cmd == "N":
                    _modo_forzado = "NORMAL"
                    print("\n[CONTROL] 🟢 Volviendo a valores NORMAL.")
                elif cmd == "Q":
                    _salir = True
                    print("\n[IoT] Deteniendo emisor...")
        finally:
            termios.tcsetattr(fd, termios.TCSADRAIN, old)


# ─── LOOP PRINCIPAL ────────────────────────────────────────────────────────────

def iniciar_sender():
    global _salir

    estacion_id = solicitar_configuracion()
    topic       = f"agrotech/estaciones/{estacion_id}"

    # Conectar al broker MQTT
    print(f"[MQTT] Conectando a {BROKER}:{PORT}...")
    try:
        client = mqtt.Client(client_id=f"agrotech_sender_{estacion_id}")
        client.connect(BROKER, PORT, keepalive=60)
        client.loop_start()
        print(f"[MQTT] ✅ Conectado. Publicando en: {topic}")
    except Exception as e:
        print(f"[MQTT] ❌ No se pudo conectar al broker: {e}")
        print("[MQTT]    Verifica tu conexión a internet.")
        exit(1)

    print(f"[IoT]  Intervalo: {INTERVALO_NORMAL}s normal / {INTERVALO_EMERGENCIA}s emergencia")

    # Hilo de teclado
    hilo = threading.Thread(target=escuchar_teclado, daemon=True)
    hilo.start()

    estado = crear_estado_inicial()
    ciclo  = 0

    while not _salir:
        ciclo  += 1
        lectura = leer_sensores(estado)
        nivel   = evaluar_nivel(lectura)
        intervalo = INTERVALO_EMERGENCIA if nivel == "PELIGRO" else INTERVALO_NORMAL

        payload = {
            "estacion_id": estacion_id,
            "temperatura": lectura["temperatura"],
            "humedad":     lectura["humedad"],
            "ph":          lectura["ph"],
            "timestamp":   time.time(),
        }

        result = client.publish(topic, json.dumps(payload))
        ok     = result.rc == 0

        emoji_nivel  = {"NORMAL": "🟢", "ALERTA": "🟡", "PELIGRO": "🔴"}.get(nivel, "⚪")
        estado_envio = "✅ OK   " if ok else "❌ ERROR"

        print(
            f"[#{ciclo:04d}] {estado_envio} | {emoji_nivel} {nivel:<8} | "
            f"🌡  {lectura['temperatura']:5.1f}°C | "
            f"💧 {lectura['humedad']:5.1f}% | "
            f"🧪 pH {lectura['ph']:4.1f} | "
            f"⏱  {intervalo}s"
        )

        if nivel == "PELIGRO":
            print(
                f"         ⚠️  [ALERTA] Valores críticos — "
                f"Modo emergencia activado ({INTERVALO_EMERGENCIA}s)"
            )

        for _ in range(intervalo * 10):
            if _salir:
                break
            time.sleep(0.1)

    client.loop_stop()
    client.disconnect()
    print("[IoT] Sender detenido. ¡Hasta luego!")


if __name__ == "__main__":
    try:
        iniciar_sender()
    except KeyboardInterrupt:
        print("\n[IoT] Detenido con Ctrl+C.")
