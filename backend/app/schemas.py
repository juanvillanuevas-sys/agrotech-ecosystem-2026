from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

# --- Estaciones ---
class EstacionBase(BaseModel):
    nombre: str = Field(..., min_length=1, max_length=100, description="Nombre de la estación")
    ubicacion: str = Field(..., min_length=1, max_length=200, description="Ubicación geográfica")

class EstacionCreate(EstacionBase):
    id: int = Field(..., gt=0, description="ID manual para la estación (ej: 100)")
    nombre: str = Field(..., min_length=1, max_length=100)
    ubicacion: str = Field(..., min_length=1, max_length=200)

class Estacion(EstacionBase):
    id: int
    class Config:
        from_attributes = True


# --- Lecturas (AgroTech) ---
class LecturaBase(BaseModel):
    humedad: float = Field(..., ge=0, le=100, description="Humedad relativa (%) - Rango 0-100")
    temperatura: float = Field(..., ge=-10, le=50, description="Temperatura en grados Celsius")
    ph: float = Field(..., ge=0, le=14, description="Nivel de pH - Rango 0 a 14")
    estacion_id: int = Field(..., gt=0, description="ID de la estación (debe existir)")

class LecturaCreate(LecturaBase):
    pass

class Lectura(LecturaBase):
    id: int
    fecha: datetime
    class Config:
        from_attributes = True


# ─── NUEVO SCHEMA ──────────────────────────────────────────────────────────────
class LecturaResumen(BaseModel):
    """
    Respuesta del endpoint GET /estaciones/{id}/lecturas/
    Incluye el nivel de alerta actual y el historial de las últimas 10 lecturas.
    """
    estacion_id: int
    estacion_nombre: str
    nivel: str              # "NORMAL" | "ALERTA" | "PELIGRO" | "SIN_DATOS"
    mensaje: str
    lecturas: List[Lectura]

    class Config:
        from_attributes = True
