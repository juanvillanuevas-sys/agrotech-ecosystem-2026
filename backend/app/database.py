from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

URL_BASE_DE_DATOS = "sqlite:///./agrotech.db"

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
