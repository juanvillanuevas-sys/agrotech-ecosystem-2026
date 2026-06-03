"""
AgroTech SMAT - Emulador de Sensores IoT
=========================================
Simula un dispositivo de campo (ESP32 / Raspberry Pi) que mide
temperatura, humedad y pH del suelo cada ciertos segundos y envía
los datos automáticamente al backend de AgroTech.


Uso:
    python sensor_emitter.py

Controles
    P  →  Forzar escenario PELIGRO
    N  →  Volver a valores NORMAL
    Q  →  Salir

Requisitos:
    pip install requests
"""

import requests
import time
import random
import getpass
import threading
import sys

# ─── CONFIGURACIÓN 
API_URL              = "http://localhost:8000"
INTERVALO_NORMAL     = 10  # segundos
INTERVALO_EMERGENCIA = 2   # segundos en modo PELIGRO

# ─── Control de modo
# Desde teclado
_modo_forzado = None   # None | "PELIGRO" | "NORMAL"
_salir        = False


# ─── SOLICITAR DATOS AL ARRANCAR 

def solicitar_credenciales() -> tuple:
    print("=" * 55)
    print("   AgroTech SMAT — Emulador de Sensores IoT")
    print("=" * 55)
    print("   Ingresa tus credenciales para iniciar.\n")

    username    = input("   Usuario       : ").strip()
    password    = getpass.getpass("   Contraseña    : ")
    estacion_id = input("   ID Estación   : ").strip()

    while not estacion_id.isdigit():
        print("   ⚠️  El ID debe ser un número entero.")
        estacion_id = input("   ID Estación   : ").strip()

    print()
    return username, password, int(estacion_id)


# ─── AUTENTICACIÓN 

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
            print(f"[AUTH] ✅ Token obtenido. Rol: {rol}")
            return token
        else:
            print(f"[AUTH] ❌ Credenciales incorrectas.")
            exit(1)
    except Exception as e:
        print(f"[AUTH] ❌ No se pudo conectar con el servidor: {e}")
        exit(1)


# ─── CONTROLES DE TECLADO 

def escuchar_teclado():
    """
    Corre en un hilo separado escuchando comandos del usuario.
    P → forzar PELIGRO, N → volver a NORMAL, Q → salir.
    """
    global _modo_forzado, _salir
    print("[IoT] Controles: [P] Forzar PELIGRO  |  [N] Volver NORMAL  |  [Q] Salir")
    print("-" * 55)
    while not _salir:
        try:
            cmd = input().strip().upper()
            if cmd == "P":
                _modo_forzado = "PELIGRO"
                print("[CONTROL] 🔴 Modo PELIGRO forzado activado.")
            elif cmd == "N":
                _modo_forzado = "NORMAL"
                print("[CONTROL] 🟢 Volviendo a valores NORMAL.")
            elif cmd == "Q":
                _salir = True
                print("[IoT] Deteniendo emisor...")
                break
        except EOFError:
            break


# ─── SENSORES EMULADOS ─────────────────────────────────────────────────────────

def crear_estado_inicial() -> dict:
    return {
        "temperatura": random.uniform(18.0, 28.0),
        "humedad":     random.uniform(50.0, 75.0),
        "ph":          random.uniform(5.5, 6.5),
    }

def leer_sensores(estado: dict) -> dict:
    """Variación gradual — simula sensor físico real."""
    global _modo_forzado

    if _modo_forzado == "PELIGRO":
        # Forzar valores claramente fuera del rango crítico
        estado["temperatura"] = round(random.uniform(36.0, 42.0), 2)
        estado["humedad"]     = round(random.uniform(10.0, 25.0), 2)
        estado["ph"]          = round(random.uniform(3.0,  4.5),  2)
    elif _modo_forzado == "NORMAL":
        # Resetear a valores óptimos y quitar el forzado
        estado["temperatura"] = round(random.uniform(18.0, 28.0), 2)
        estado["humedad"]     = round(random.uniform(50.0, 75.0), 2)
        estado["ph"]          = round(random.uniform(5.5,  6.5),  2)
        _modo_forzado = None
    else:
        # Variación gradual normal
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
    t = lectura["temperatura"]
    h = lectura["humedad"]
    p = lectura["ph"]

    if (t < 12.0 or t > 34.0) or (h < 30.0 or h > 85.0) or (p < 5.0 or p > 8.0):
        return "PELIGRO"
    if (t < 18.0 or t > 28.0) or (h < 50.0 or h > 75.0) or (p < 5.5 or p > 6.5):
        return "ALERTA"
    return "NORMAL"


# ─── ENVÍO 

def enviar_lectura(lectura: dict, estacion_id: int, token: str) -> bool:
    payload = {
        "estacion_id": estacion_id,
        "temperatura": lectura["temperatura"],
        "humedad":     lectura["humedad"],
        "ph":          lectura["ph"],
        "valor": round(
            (lectura["temperatura"] + lectura["humedad"] + lectura["ph"]) / 3, 2
        ),
    }
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type":  "application/json",
    }
    try:
        response = requests.post(
            f"{API_URL}/lecturas/",
            json=payload,
            headers=headers,
            timeout=5,
        )
        return response.status_code in (200, 201)
    except Exception:
        return False


# ─── LOOP PRINCIPAL 

def iniciar_emisor():
    global _salir

    username, password, estacion_id = solicitar_credenciales()
    token  = obtener_token(username, password)

    print(f"[IoT] 🚀 Iniciando emisor para estación ID {estacion_id}...")
    print(f"[IoT]    Normal: {INTERVALO_NORMAL}s  |  Emergencia: {INTERVALO_EMERGENCIA}s")

    # Hilo de teclado en segundo plano
    hilo = threading.Thread(target=escuchar_teclado, daemon=True)
    hilo.start()

    estado = crear_estado_inicial()
    ciclo  = 0

    while not _salir:
        ciclo  += 1
        lectura = leer_sensores(estado)
        nivel   = evaluar_nivel(lectura)

        # Intervalo dinámico 
        intervalo = INTERVALO_EMERGENCIA if nivel == "PELIGRO" else INTERVALO_NORMAL

        ok = enviar_lectura(lectura, estacion_id, token)

        estado_envio = "✅ OK   " if ok else "❌ ERROR"
        emoji_nivel  = {"NORMAL": "🟢", "ALERTA": "🟡", "PELIGRO": "🔴"}.get(nivel, "⚪")

        print(
            f"[#{ciclo:04d}] {estado_envio} | {emoji_nivel} {nivel:<8} | "
            f"🌡  {lectura['temperatura']:5.1f}°C | "
            f"💧 {lectura['humedad']:5.1f}% | "
            f"🧪 pH {lectura['ph']:4.1f} | "
            f"⏱  {intervalo}s"
        )

        # Alerta en consola
        if nivel == "PELIGRO":
            print(
                f"         ⚠️  [ALERTA] Valores críticos — "
                f"Modo emergencia activado ({INTERVALO_EMERGENCIA}s)"
            )

        if not ok:
            print("[AUTH] 🔄 Renovando token...")
            token = obtener_token(username, password)

        # Espera en fragmentos para que Q responda rápido
        for _ in range(intervalo * 10):
            if _salir:
                break
            time.sleep(0.1)

    print("[IoT] Emisor detenido. ¡Hasta luego!")


if __name__ == "__main__":
    iniciar_emisor()
