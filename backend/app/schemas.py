from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

# --- Estaciones ---
class EstacionBase(BaseModel):
    nombre: str
    ubicacion: str

class EstacionCreate(EstacionBase):
    nombre: str = Field(..., min_length=1, max_length=100, description="Nombre de la estación")
    ubicacion: str = Field(..., min_length=1, max_length=200, description="Ubicación geográfica")

class Estacion(EstacionBase):
    id: int

    class Config:
        from_attributes = True

# --- Lecturas (AgroTech) ---
class LecturaBase(BaseModel):
    humedad: float = Field(..., ge=0, le=100, description="Humedad relativa (%) - Rango 0-100")
    temperatura: float = Field(..., ge=-10, le=50, description="Temperatura en grados Celsius - Rango -10 a 50")
    ph: float = Field(..., ge=0, le=14, description="Nivel de pH - Rango 0 a 14")
    estacion_id: int = Field(..., gt=0, description="ID de la estación (debe existir)")

class LecturaCreate(LecturaBase):
    fecha: Optional[datetime] = None

class Lectura(LecturaBase):
    id: int
    fecha: datetime

    class Config:
        from_attributes = True