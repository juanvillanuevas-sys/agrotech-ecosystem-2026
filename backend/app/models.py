from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime
from .database import Base

class EstacionDB(Base):
    __tablename__ = "estaciones"

    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String, unique=True, nullable=False)
    ubicacion = Column(String, nullable=False)
    
    # Relación con las lecturas
    lecturas = relationship("LecturaDB", back_populates="estacion", cascade="all, delete-orphan")


class LecturaDB(Base):
    __tablename__ = "lecturas"

    id = Column(Integer, primary_key=True, index=True)
    # Cambiamos 'valor' por los campos específicos requeridos por AgroTech
    humedad = Column(Float, nullable=False)
    temperatura = Column(Float, nullable=False)
    ph = Column(Float, nullable=False)
    
    # Mantenemos la fecha para tener un registro histórico
    fecha = Column(DateTime, default=datetime.utcnow)
    
    # Relación con la estación
    estacion_id = Column(Integer, ForeignKey("estaciones.id"))
    estacion = relationship("EstacionDB", back_populates="lecturas")