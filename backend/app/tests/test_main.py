from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_flujo_completo_agrotech():
    # 1. Login
    login_res = client.post("/token", data={"username": "admin_smat", "password": "password123"})
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Crear Estación (ID Manual para evitar 422)
    id_test = 500
    # Intentamos borrar el registro si existiera para que el test sea limpio (opcional)
    est_res = client.post("/estaciones/", 
                         json={"id": id_test, "nombre": "Campo Test", "ubicacion": "Ica"}, 
                         headers=headers)
    
    # Aceptamos 200 (creado) o 400 (ya existe de un test previo)
    assert est_res.status_code in [200, 400]

    # 3. Registrar Lectura Crítica (PELIGRO)
    lec_res = client.post("/lecturas/", 
                         json={
                             "humedad": 10.0, 
                             "temperatura": 40.0, 
                             "ph": 2.0, 
                             "estacion_id": id_test
                         }, 
                         headers=headers)
    
    assert lec_res.status_code == 200
    assert lec_res.json()["evaluacion"]["nivel"] == "PELIGRO"

def test_estacion_no_encontrada():
    login_res = client.post("/token", data={"username": "admin_smat", "password": "password123"})
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    response = client.post("/lecturas/", 
                         json={"humedad": 50, "temperatura": 25, "ph": 6, "estacion_id": 9999}, 
                         headers=headers)
    assert response.status_code == 404