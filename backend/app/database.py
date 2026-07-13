import os

from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# En Docker, docker-compose.yml define DATABASE_URL apuntando al volumen persistente.
# Localmente (sin Docker), usamos el archivo agrotech.db de siempre, en la carpeta actual.
URL_BASE_DE_DATOS = os.environ.get("DATABASE_URL", "sqlite:///./agrotech.db")

motor = create_engine(
    URL_BASE_DE_DATOS,
    connect_args={"check_same_thread": False}
)

SesionLocal = sessionmaker(autocommit=False, autoflush=False, bind=motor)

Base = declarative_base()

def obtener_sesion():
    sesion = SesionLocal()
    try:
        yield sesion
    finally:
        sesion.close()
