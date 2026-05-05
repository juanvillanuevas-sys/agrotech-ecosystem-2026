from jose import jwt
from datetime import datetime, timedelta
from fastapi import HTTPException, Depends
from fastapi.security import OAuth2PasswordBearer

SECRET_KEY = "UNMSM_FISI_SMAT_2026"
ALGORITHM = "HS256"

#El tokenUrl="token" le indica a la documentación de Swagger 
#a qué endpoint debe enviar el usuario y contraseña para iniciar sesión.

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

#BASE DE DATOS SIMULADA (Diccionario temporal)

USUARIOS_DB = {
    "admin_smat": {
        "username": "admin_smat",
        "password": "password123",
        "rol": "administrador"
    },
    "operador": {
        "username": "operador",
        "password": "smat_user2026",
        "rol": "lectura"
    }
}


#FUNCIONES BASE DEL TOKEN

def crear_token(data: dict):
    # El token durará 60 minutos antes de vencer
    expiracion = datetime.utcnow() + timedelta(minutes=60)
    data.update({"exp": expiracion})
    return jwt.encode(data, SECRET_KEY, algorithm=ALGORITHM)

def validar_token(token: str = Depends(oauth2_scheme)):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload.get("sub")
    except:
        raise HTTPException(status_code=401, detail="Token inválido o expirado")


#LÓGICA DE AUTENTICACIÓN

def autenticar_usuario(username: str, password: str):
    """
    Recibe credenciales, las verifica en el diccionario y devuelve un token JWT.
    """
    #Buscar al usuario en el diccionario
    usuario = USUARIOS_DB.get(username)
    
    #Validar que el usuario exista y que la contraseña coincida exactamente
    if not usuario or usuario["password"] != password:
        # Credenciales incorrectas
        return None 
        
    #Si todo es válido,la información se empaqueta
    datos_token = {
        "sub": usuario["username"], 
        "rol": usuario["rol"]
    }
    
    #Generamos y devolvemos el token
    return crear_token(datos_token)