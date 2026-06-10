from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime
from .database import Base


# ── Usuarios ───────────────────────────────────────────────────────────────────

class UsuarioDB(Base):
    __tablename__ = "usuarios"

    id           = Column(Integer, primary_key=True, index=True)
    username     = Column(String, unique=True, index=True, nullable=False)
    email        = Column(String, unique=True, index=True, nullable=False)
    clave_hash   = Column(String, nullable=False)
    rol          = Column(String, default="usuario")  # "admin" | "usuario"

    estaciones = relationship("EstacionDB", back_populates="propietario")


# ── Estaciones ─────────────────────────────────────────────────────────────────

class EstacionDB(Base):
    __tablename__ = "estaciones"

    id            = Column(Integer, primary_key=True, index=True)
    nombre        = Column(String, nullable=False)
    ubicacion     = Column(String, nullable=False)
    latitud       = Column(Float, nullable=True)
    longitud      = Column(Float, nullable=True)
    propietario_id = Column(Integer, ForeignKey("usuarios.id"), nullable=True)

    propietario = relationship("UsuarioDB", back_populates="estaciones")
    lecturas    = relationship("LecturaDB", back_populates="estacion", cascade="all, delete")


# ── Lecturas ───────────────────────────────────────────────────────────────────

class LecturaDB(Base):
    __tablename__ = "lecturas"

    id          = Column(Integer, primary_key=True, index=True)
    valor       = Column(Float, nullable=True)       # calculado internamente
    temperatura = Column(Float, nullable=True)
    humedad     = Column(Float, nullable=True)
    ph          = Column(Float, nullable=True)
    timestamp   = Column(DateTime, default=datetime.utcnow)
    estacion_id = Column(Integer, ForeignKey("estaciones.id"))

    estacion = relationship("EstacionDB", back_populates="lecturas")
