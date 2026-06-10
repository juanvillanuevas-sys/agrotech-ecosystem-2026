from fastapi import FastAPI, Depends, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from typing import Optional, List

from . import crud, models, schemas
from .database import motor, obtener_sesion
from .auth import (
    crear_token_acceso,
    obtener_identidad_actual,
    verificar_clave,
)

models.Base.metadata.create_all(bind=motor)

app = FastAPI(
    title="SMAT - Sistema de Monitoreo de Alerta Temprana",
    description="""
API para la gestión y monitoreo agrícola tecnificado.
Permite la telemetría de sensores en tiempo real y el cálculo de niveles de riesgo.

**Entidades principales:**
* **Estaciones:** Puntos de monitoreo físico.
* **Lecturas:** Datos capturados por sensores (temperatura, humedad, pH).
* **Riesgos:** Análisis de criticidad basado en umbrales FAO.
* **Usuarios:** Registro y autenticación con roles (admin / usuario).
""",
    version="2.0.0",
    contact={
        "name": "Soporte Técnico SMAT - FISI",
        "url": "http://fisi.unmsm.edu.pe",
        "email": "desarrollo.smat@unmsm.edu.pe",
    },
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Seguridad ──────────────────────────────────────────────────────────────────

@app.post(
    "/register",
    response_model=schemas.UsuarioSalida,
    tags=["Seguridad"],
    summary="Registrar nuevo usuario",
    description="Crea una cuenta nueva con rol 'usuario'.",
)
def registrar_usuario(datos: schemas.UsuarioCrear, sesion: Session = Depends(obtener_sesion)):
    if crud.obtener_usuario_por_nombre(sesion, datos.username):
        raise HTTPException(status_code=400, detail="El nombre de usuario ya existe")
    if crud.obtener_usuario_por_email(sesion, datos.email):
        raise HTTPException(status_code=400, detail="El email ya está registrado")
    return crud.crear_usuario(sesion, datos, rol="usuario")


@app.post(
    "/token",
    tags=["Seguridad"],
    summary="Obtener token de acceso",
    description="Genera un JWT válido por 30 minutos.",
)
async def iniciar_sesion(
    formulario: OAuth2PasswordRequestForm = Depends(),
    sesion: Session = Depends(obtener_sesion),
):
    usuario = crud.obtener_usuario_por_nombre(sesion, formulario.username)
    if not usuario or not verificar_clave(formulario.password, usuario.clave_hash):
        raise HTTPException(
            status_code=401,
            detail="Credenciales incorrectas",
            headers={"WWW-Authenticate": "Bearer"},
        )
    token = crear_token_acceso({"sub": usuario.username, "rol": usuario.rol})
    return {
        "access_token": token,
        "token_type": "bearer",
        "rol": usuario.rol,
    }


# ── Gestión de Infraestructura ────────────────────────────────────────────────

@app.post(
    "/estaciones/",
    response_model=schemas.EstacionSalida,
    status_code=201,
    tags=["Gestión de Infraestructura"],
    summary="Registrar una nueva estación de monitoreo",
)
def crear_estacion(
    estacion: schemas.EstacionCrear,
    sesion: Session = Depends(obtener_sesion),
    usuario: str = Depends(obtener_identidad_actual),
):
    usuario_db = crud.obtener_usuario_por_nombre(sesion, usuario)
    propietario_id = usuario_db.id if usuario_db else None
    return crud.crear_estacion(sesion=sesion, estacion=estacion, propietario_id=propietario_id)


@app.get(
    "/estaciones/",
    response_model=List[schemas.EstacionSalida],
    tags=["Gestión de Infraestructura"],
    summary="Listar estaciones",
    description="El admin ve todas. El usuario solo ve las suyas.",
)
def listar_estaciones(
    sesion: Session = Depends(obtener_sesion),
    usuario: str = Depends(obtener_identidad_actual),
):
    usuario_db = crud.obtener_usuario_por_nombre(sesion, usuario)
    if usuario_db and usuario_db.rol == "admin":
        return sesion.query(models.EstacionDB).all()
    if usuario_db:
        return sesion.query(models.EstacionDB).filter(
            models.EstacionDB.propietario_id == usuario_db.id
        ).all()
    return []


@app.put(
    "/estaciones/{id}",
    response_model=schemas.EstacionSalida,
    tags=["Gestión de Infraestructura"],
    summary="Editar una estación",
)
def editar_estacion(
    id: int,
    estacion: schemas.EstacionCrear,
    sesion: Session = Depends(obtener_sesion),
    usuario: str = Depends(obtener_identidad_actual),
):
    est = sesion.query(models.EstacionDB).filter(models.EstacionDB.id == id).first()
    if not est:
        raise HTTPException(status_code=404, detail="Estación no encontrada")
    est.nombre    = estacion.nombre
    est.ubicacion = estacion.ubicacion
    est.latitud   = estacion.latitud
    est.longitud  = estacion.longitud
    sesion.commit()
    sesion.refresh(est)
    return est


@app.delete(
    "/estaciones/{id}",
    tags=["Gestión de Infraestructura"],
    summary="Eliminar una estación",
)
def eliminar_estacion(
    id: int,
    sesion: Session = Depends(obtener_sesion),
    usuario: str = Depends(obtener_identidad_actual),
):
    est = sesion.query(models.EstacionDB).filter(models.EstacionDB.id == id).first()
    if not est:
        raise HTTPException(status_code=404, detail="Estación no encontrada")
    sesion.delete(est)
    sesion.commit()
    return {"detalle": "Estación eliminada"}


# ── Telemetría de Sensores ────────────────────────────────────────────────────

@app.post(
    "/lecturas/",
    response_model=schemas.LecturaSalida,
    status_code=201,
    tags=["Telemetría de Sensores"],
    summary="Recibir datos de telemetría",
    description="Recibe temperatura, humedad y pH del sensor y los vincula a una estación.",
)
def registrar_lectura(
    lectura: schemas.LecturaCrear,
    sesion: Session = Depends(obtener_sesion),
    usuario: str = Depends(obtener_identidad_actual),
):
    estacion_db = sesion.query(models.EstacionDB).filter(
        models.EstacionDB.id == lectura.estacion_id
    ).first()
    if not estacion_db:
        raise HTTPException(
            status_code=404,
            detail="Error de Integridad: La estación no existe en la base de datos.",
        )
    return crud.guardar_lectura(sesion=sesion, lectura=lectura)


@app.get(
    "/estaciones/{id}/lecturas",
    response_model=List[schemas.LecturaSalida],
    tags=["Telemetría de Sensores"],
    summary="Obtener lecturas de una estación",
)
def obtener_lecturas(
    id: int,
    sesion: Session = Depends(obtener_sesion),
    usuario: str = Depends(obtener_identidad_actual),
):
    est = sesion.query(models.EstacionDB).filter(models.EstacionDB.id == id).first()
    if not est:
        raise HTTPException(status_code=404, detail="Estación no encontrada")
    return crud.listar_lecturas(sesion, id)


# ── Reportes Históricos ───────────────────────────────────────────────────────

@app.get(
    "/estaciones/{id}/historial",
    tags=["Reportes Históricos"],
    summary="Consultar historial estadístico de una estación",
)
def obtener_historial(id: int, sesion: Session = Depends(obtener_sesion)):
    estacion = sesion.query(models.EstacionDB).filter(
        models.EstacionDB.id == id
    ).first()
    if not estacion:
        raise HTTPException(status_code=404, detail="Estación no encontrada")
    lecturas = sesion.query(models.LecturaDB).filter(
        models.LecturaDB.estacion_id == id
    ).all()
    valores = [l.valor for l in lecturas if l.valor is not None]
    promedio = round(sum(valores) / len(valores), 2) if valores else 0.0
    return {
        "estacion_id": id,
        "conteo": len(lecturas),
        "promedio_valor": promedio,
    }


# ── Análisis de Riesgo ────────────────────────────────────────────────────────

@app.get(
    "/estaciones/{id}/riesgo",
    tags=["Análisis de Riesgo"],
    summary="Evaluar nivel de peligro actual",
)
def obtener_riesgo(id: int, sesion: Session = Depends(obtener_sesion)):
    estacion = sesion.query(models.EstacionDB).filter(
        models.EstacionDB.id == id
    ).first()
    if not estacion:
        raise HTTPException(status_code=404, detail="Estación no encontrada")
    ultima = sesion.query(models.LecturaDB).filter(
        models.LecturaDB.estacion_id == id
    ).order_by(models.LecturaDB.id.desc()).first()
    if not ultima:
        return {"id": id, "nivel": "SIN DATOS"}

    # Evaluación basada en temperatura, humedad y pH
    nivel = "NORMAL"
    if ultima.temperatura is not None:
        if ultima.temperatura < 12.0 or ultima.temperatura > 34.0:
            nivel = "PELIGRO"
        elif ultima.temperatura < 18.0 or ultima.temperatura > 28.0:
            nivel = "ALERTA"
    if ultima.humedad is not None and nivel != "PELIGRO":
        if ultima.humedad < 30.0 or ultima.humedad > 85.0:
            nivel = "PELIGRO"
        elif ultima.humedad < 50.0 or ultima.humedad > 75.0:
            nivel = "ALERTA"
    if ultima.ph is not None and nivel != "PELIGRO":
        if ultima.ph < 5.0 or ultima.ph > 8.0:
            nivel = "PELIGRO"
        elif ultima.ph < 5.5 or ultima.ph > 6.5:
            nivel = "ALERTA"

    return {
        "id": id,
        "nivel": nivel,
        "temperatura": ultima.temperatura,
        "humedad": ultima.humedad,
        "ph": ultima.ph,
    }


# ── Auditoría ─────────────────────────────────────────────────────────────────

@app.get(
    "/reportes/criticos",
    tags=["Auditoría"],
    summary="Listar lecturas críticas",
)
def reportes_criticos(
    umbral: Optional[float] = Query(
        default=75.0,
        description="Valor mínimo para considerar una lectura como crítica",
    ),
    sesion: Session = Depends(obtener_sesion),
):
    lecturas = sesion.query(models.LecturaDB).filter(
        models.LecturaDB.valor > umbral
    ).all()
    return {
        "umbral_aplicado": umbral,
        "total_criticas": len(lecturas),
        "lecturas": [
            {"id": l.id, "estacion_id": l.estacion_id, "valor": l.valor}
            for l in lecturas
        ],
    }


@app.get(
    "/estaciones/stats",
    tags=["Auditoría"],
    summary="Resumen ejecutivo del sistema SMAT",
)
def estadisticas_globales(sesion: Session = Depends(obtener_sesion)):
    total_estaciones   = sesion.query(models.EstacionDB).count()
    todas_las_lecturas = sesion.query(models.LecturaDB).all()
    total_lecturas     = len(todas_las_lecturas)
    valores = [l.valor for l in todas_las_lecturas if l.valor is not None]
    promedio_global = round(sum(valores) / len(valores), 2) if valores else 0.0
    lectura_max = (
        max(todas_las_lecturas, key=lambda l: l.valor or 0)
        if todas_las_lecturas else None
    )
    return {
        "total_estaciones": total_estaciones,
        "total_lecturas":   total_lecturas,
        "promedio_global":  promedio_global,
        "lectura_maxima": {
            "valor":       lectura_max.valor,
            "estacion_id": lectura_max.estacion_id,
        } if lectura_max else None,
    }


# ── Admin ─────────────────────────────────────────────────────────────────────

@app.get(
    "/admin/usuarios",
    tags=["Admin"],
    summary="Listar todos los usuarios (solo admin)",
)
def listar_usuarios(
    sesion: Session = Depends(obtener_sesion),
    usuario: str = Depends(obtener_identidad_actual),
):
    usuario_db = crud.obtener_usuario_por_nombre(sesion, usuario)
    if not usuario_db or usuario_db.rol != "admin":
        raise HTTPException(status_code=403, detail="Se requiere rol de administrador")
    return sesion.query(models.UsuarioDB).all()


@app.patch(
    "/admin/usuarios/{id}/rol",
    tags=["Admin"],
    summary="Cambiar rol de un usuario (solo admin)",
)
def cambiar_rol(
    id: int,
    nuevo_rol: str,
    sesion: Session = Depends(obtener_sesion),
    usuario: str = Depends(obtener_identidad_actual),
):
    usuario_db = crud.obtener_usuario_por_nombre(sesion, usuario)
    if not usuario_db or usuario_db.rol != "admin":
        raise HTTPException(status_code=403, detail="Se requiere rol de administrador")
    if nuevo_rol not in ("admin", "usuario"):
        raise HTTPException(status_code=400, detail="Rol inválido. Usa 'admin' o 'usuario'")
    objetivo = sesion.query(models.UsuarioDB).filter(models.UsuarioDB.id == id).first()
    if not objetivo:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    objetivo.rol = nuevo_rol
    sesion.commit()
    return {"detalle": f"Rol actualizado a '{nuevo_rol}'"}
