from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime


# ── Estaciones ─────────────────────────────────────────────────────────────────

class EstacionCrear(BaseModel):
    nombre:    str
    ubicacion: str
    latitud:   Optional[float] = None
    longitud:  Optional[float] = None

class EstacionSalida(BaseModel):
    id:             int
    nombre:         str
    ubicacion:      str
    latitud:        Optional[float]
    longitud:       Optional[float]
    propietario_id: Optional[int]

    class Config:
        from_attributes = True


# ── Lecturas ───────────────────────────────────────────────────────────────────

class LecturaCrear(BaseModel):
    estacion_id: int
    temperatura: Optional[float] = None
    humedad:     Optional[float] = None
    ph:          Optional[float] = None
    valor:       Optional[float] = None   # calculado internamente si no se envía

class LecturaSalida(BaseModel):
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

class UsuarioCrear(BaseModel):
    username: str
    email:    EmailStr
    password: str
    # Opcional: si coincide con ADMIN_MASTER_KEY del servidor, el usuario nace como admin.
    # Pensado solo para crear el primer admin del sistema; para promover a otros
    # usuarios después, se usa PATCH /admin/usuarios/{id}/rol (requiere ser admin).
    clave_maestra: Optional[str] = None

class UsuarioSalida(BaseModel):
    id:       int
    username: str
    email:    str
    rol:      str

    class Config:
        from_attributes = True
