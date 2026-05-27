from sqlalchemy.orm import Session
from . import schemas, models
from .auth import hash_password


# ── Estaciones ─────────────────────────────────────────────────────────────────

def crear_estacion(db: Session, estacion: schemas.EstacionCreate, owner_id: int = None):
    nueva = models.EstacionDB(
        nombre=estacion.nombre,
        ubicacion=estacion.ubicacion,
        latitud=estacion.latitud,
        longitud=estacion.longitud,
        owner_id=owner_id,
    )
    db.add(nueva)
    db.commit()
    db.refresh(nueva)
    return nueva


# ── Lecturas ───────────────────────────────────────────────────────────────────

def guardar_lectura(db: Session, lectura: schemas.LecturaCreate):
    # Si no se envió 'valor', se calcula como promedio de los campos disponibles
    if lectura.valor is not None:
        valor = lectura.valor
    else:
        campos = [v for v in [lectura.temperatura, lectura.humedad, lectura.ph] if v is not None]
        valor = round(sum(campos) / len(campos), 2) if campos else None

    nueva = models.LecturaDB(
        estacion_id=lectura.estacion_id,
        temperatura=lectura.temperatura,
        humedad=lectura.humedad,
        ph=lectura.ph,
        valor=valor,
    )
    db.add(nueva)
    db.commit()
    db.refresh(nueva)
    return nueva

def listar_lecturas(db: Session, estacion_id: int):
    return (
        db.query(models.LecturaDB)
        .filter(models.LecturaDB.estacion_id == estacion_id)
        .order_by(models.LecturaDB.id.desc())
        .all()
    )


# ── Usuarios ───────────────────────────────────────────────────────────────────

def crear_usuario(db: Session, datos: schemas.UsuarioCreate, rol: str = "usuario"):
    nuevo = models.UsuarioDB(
        username=datos.username,
        email=datos.email,
        hashed_password=hash_password(datos.password),
        rol=rol,
    )
    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)
    return nuevo

def obtener_usuario_por_username(db: Session, username: str):
    return db.query(models.UsuarioDB).filter(
        models.UsuarioDB.username == username
    ).first()

def obtener_usuario_por_email(db: Session, email: str):
    return db.query(models.UsuarioDB).filter(
        models.UsuarioDB.email == email
    ).first()
