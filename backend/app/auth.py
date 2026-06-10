from jose import jwt, JWTError
from datetime import datetime, timedelta
from fastapi import HTTPException, status, Depends
from fastapi.security import OAuth2PasswordBearer
from passlib.context import CryptContext

CLAVE_SECRETA  = "UNMSM_FISI_SMAT_SECRET_2026"
ALGORITMO      = "HS256"
MINUTOS_EXPIRACION = 30

esquema_oauth2 = OAuth2PasswordBearer(tokenUrl="token")

# Cifrado de contraseñas con bcrypt
contexto_cifrado = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hashear_clave(clave: str) -> str:
    return contexto_cifrado.hash(clave)

def verificar_clave(texto_plano: str, hash: str) -> bool:
    return contexto_cifrado.verify(texto_plano, hash)

def crear_token_acceso(datos: dict) -> str:
    para_encriptar = datos.copy()
    expiracion = datetime.utcnow() + timedelta(minutes=MINUTOS_EXPIRACION)
    para_encriptar.update({"exp": expiracion})
    return jwt.encode(para_encriptar, CLAVE_SECRETA, algorithm=ALGORITMO)

async def obtener_identidad_actual(token: str = Depends(esquema_oauth2)) -> str:
    excepcion_credenciales = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="No se pudo validar el token de acceso",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        carga = jwt.decode(token, CLAVE_SECRETA, algorithms=[ALGORITMO])
        nombre_usuario: str = carga.get("sub")
        if nombre_usuario is None:
            raise excepcion_credenciales
        return nombre_usuario
    except JWTError:
        raise excepcion_credenciales
