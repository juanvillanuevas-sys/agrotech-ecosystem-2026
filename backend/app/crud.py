from sqlalchemy.orm import Session
from . import schemas, models
from .auth import hashear_clave


# ── Estaciones ─────────────────────────────────────────────────────────────────

def crear_estacion(sesion: Session, estacion: schemas.EstacionCrear, propietario_id: int = None):
    nueva = models.EstacionDB(
        nombre=estacion.nombre,
        ubicacion=estacion.ubicacion,
        latitud=estacion.latitud,
        longitud=estacion.longitud,
        propietario_id=propietario_id,
    )
    sesion.add(nueva)
    sesion.commit()
    sesion.refresh(nueva)
    return nueva


# ── Lecturas ───────────────────────────────────────────────────────────────────

def guardar_lectura(sesion: Session, lectura: schemas.LecturaCrear):
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
    sesion.add(nueva)
    sesion.commit()
    sesion.refresh(nueva)
    return nueva

def listar_lecturas(sesion: Session, estacion_id: int):
    return (
        sesion.query(models.LecturaDB)
        .filter(models.LecturaDB.estacion_id == estacion_id)
        .order_by(models.LecturaDB.id.desc())
        .all()
    )


# ── Usuarios ───────────────────────────────────────────────────────────────────

def crear_usuario(sesion: Session, datos: schemas.UsuarioCrear, rol: str = "usuario"):
    nuevo = models.UsuarioDB(
        username=datos.username,
        email=datos.email,
        clave_hash=hashear_clave(datos.password),
        rol=rol,
    )
    sesion.add(nuevo)
    sesion.commit()
    sesion.refresh(nuevo)
    return nuevo

def obtener_usuario_por_nombre(sesion: Session, nombre_usuario: str):
    return sesion.query(models.UsuarioDB).filter(
        models.UsuarioDB.username == nombre_usuario
    ).first()

def obtener_usuario_por_email(sesion: Session, email: str):
    return sesion.query(models.UsuarioDB).filter(
        models.UsuarioDB.email == email
    ).first()
