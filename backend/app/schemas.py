from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime


# ── Estaciones ─────────────────────────────────────────────────────────────────

class EstacionCreate(BaseModel):
    nombre:    str
    ubicacion: str
    latitud:   Optional[float] = None
    longitud:  Optional[float] = None

class EstacionOut(BaseModel):
    id:        int
    nombre:    str
    ubicacion: str
    latitud:   Optional[float]
    longitud:  Optional[float]
    owner_id:  Optional[int]

    class Config:
        from_attributes = True


# ── Lecturas ───────────────────────────────────────────────────────────────────

class LecturaCreate(BaseModel):
    estacion_id: int
    temperatura: Optional[float] = None
    humedad:     Optional[float] = None
    ph:          Optional[float] = None
    # valor es calculado internamente — opcional para compatibilidad
    valor:       Optional[float] = None

class LecturaOut(BaseModel):
    id:          int
    estacion_id: int
    temperatura: Optional[float]
    humedad:     Optional[float]
    ph:          Optional[float]
    valor:       Optional[float]
    timestamp:   datetime

    class Config:
        from_attributes = True


# ── Usuarios ───────────────────────────────────────────────────────────────────

class UsuarioCreate(BaseModel):
    username: str
    email:    EmailStr
    password: str

class UsuarioOut(BaseModel):
    id:       int
    username: str
    email:    str
    rol:      str

    class Config:
        from_attributes = True
