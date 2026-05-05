from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

# --- Estaciones ---
class EstacionBase(BaseModel):
    nombre: str
    ubicacion: str

class EstacionCreate(EstacionBase):
    pass

class Estacion(EstacionBase):
    id: int

    class Config:
        from_attributes = True

# --- Lecturas (AgroTech) ---
class LecturaBase(BaseModel):
    # SUSTITUIMOS 'valor' por los campos de AgroTech
    humedad: float
    temperatura: float
    ph: float
    estacion_id: int

class LecturaCreate(LecturaBase):
    fecha: Optional[datetime] = None

class Lectura(LecturaBase):
    id: int
    fecha: datetime

    class Config:
        from_attributes = True