from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from . import models, schemas, auth, database

# Creación de tablas al iniciar
models.Base.metadata.create_all(bind=database.engine)

app = FastAPI(
    title="AgroTech API - UNMSM 2026",
    description="""
### 📊 Especificaciones Técnicas y Soporte Bibliográfico
Umbrales configurados para la mitigación de riesgos bióticos y abióticos en cultivos tecnificados.

| Parámetro | NORMAL ✅ | ALERTA ⚠️ | PELIGRO 🚨 | Sustento Técnico |
| :--- | :--- | :--- | :--- | :--- |
| **Humedad** | 50% - 75% | 30%-49% / 76%-85% | < 30% o > 85% | **FAO 66 (Pág. 22):** Estrés por agotamiento MAD. |
| **pH** | 5.5 - 6.5 | 5.0-5.4 / 6.6-8.0 | < 5.0 o > 8.0 | **BioEdafología (Pág. 1):** Toxicidad por Al y Mn. |
| **Temperatura** | 18°C - 28°C | 12°C-17°C / 29°C-34°C | < 12°C o > 34°C | **BPA i2056s (Pág. 14):** Rango metabólico óptimo. |

---
### 📖 Enlaces de Corroboración (Descarga Directa)
* **pH:** [BioEdafología - pH y Nutrientes](https://www.bioedafologia.com/sites/default/files/documentos/pdf/pH-del-suelo-y-nutrientes.pdf)
* **Humedad:** [FAO 66 - Rendimiento de cultivos al agua](https://openknowledge.fao.org/server/api/core/bitstreams/82bd842b-862d-4e51-8794-d80156ddab2e/content)
* **Temperatura:** [Manual BPA i2056s - FAO](https://www.fao.org/3/i2056s/i2056s.pdf)
    """,
    version="1.3.1"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- MOTOR DE REGLAS (Lógica de Negocio) ---
def evaluar_cultivo(lectura: schemas.LecturaCreate):
    # 1. PELIGRO: Rangos vitales críticos (Basado en Pág. 1 BioEdafología y Pág. 22 FAO 66)
    # pH < 5.0 (Toxicidad Aluminio) | Humedad < 30% (Punto Marchitez) | Temp > 34 (Estrés térmico)
    if (lectura.ph < 5.0 or lectura.ph > 8.0) or \
       (lectura.humedad < 30.0 or lectura.humedad > 85.0) or \
       (lectura.temperatura < 12.0 or lectura.temperatura > 34.0):
        return "PELIGRO", "Riesgo crítico: Valores fuera de rango vital. Revisar de inmediato."

    # 2. ALERTA: Fuera de rango óptimo pero no crítico (Basado en Pág. 14 Manual BPA)
    # pH 5.0-5.4 o 6.6-8.0 | Humedad 30-49% o 76-85% | Temp 12-17 o 29-34
    if (5.0 <= lectura.ph < 5.5 or 6.5 < lectura.ph <= 8.0) or \
       (30.0 <= lectura.humedad < 50.0 or 75.0 < lectura.humedad <= 85.0) or \
       (12.0 <= lectura.temperatura < 18.0 or 28.0 < lectura.temperatura <= 34.0):
        return "ALERTA", "Precaución: El cultivo está fuera del rango óptimo."

    # 3. NORMAL: Zona de confort agrícola
    return "NORMAL", "Condiciones óptimas para el cultivo."

# --- ENDPOINTS ---

@app.post("/token", tags=["Seguridad"])
def login(form_data: OAuth2PasswordRequestForm = Depends()):
    token = auth.autenticar_usuario(form_data.username, form_data.password)
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Credenciales incorrectas"
        )
    return {"access_token": token, "token_type": "bearer"}

@app.get("/estaciones/", response_model=list[schemas.Estacion], tags=["SMAT"])
def listar_estaciones(db: Session = Depends(database.get_db)):
    return db.query(models.EstacionDB).all()

@app.post("/estaciones/", response_model=schemas.Estacion, tags=["SMAT"])
def crear_estacion(estacion: schemas.EstacionCreate, db: Session = Depends(database.get_db), user=Depends(auth.validar_token)):
    # Verificamos si el ID manual ya existe
    existe = db.query(models.EstacionDB).filter(models.EstacionDB.id == estacion.id).first()
    if existe:
        raise HTTPException(status_code=400, detail="El ID de estación ya existe. Use otro.")
    
    nueva = models.EstacionDB(
        id=estacion.id, 
        nombre=estacion.nombre, 
        ubicacion=estacion.ubicacion
    )
    db.add(nueva)
    db.commit() # <--- Guarda físicamente en el archivo .db
    db.refresh(nueva)
    return nueva

@app.post("/lecturas/", tags=["Telemetría"])
def registrar_lectura(lectura: schemas.LecturaCreate, db: Session = Depends(database.get_db), user=Depends(auth.validar_token)):
    # Validación de existencia de estación
    estacion = db.query(models.EstacionDB).filter(models.EstacionDB.id == lectura.estacion_id).first()
    if not estacion:
        raise HTTPException(status_code=404, detail="La estación indicada no existe.")
    
    # Aplicar Motor de Reglas
    nivel, mensaje = evaluar_cultivo(lectura)
    
    # Guardar en base de datos
    nueva_lectura = models.LecturaDB(**lectura.model_dump())
    db.add(nueva_lectura)
    db.commit() # <--- Guarda físicamente en el archivo .db
    
    return {
        "status": "Lectura registrada con éxito",
        "evaluacion": {
            "nivel": nivel,
            "mensaje": mensaje,
            "estacion": estacion.nombre,
            "usuario": user
        }
    }