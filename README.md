# Backend - API REST con Node.js y Express 🔧

## Descripción

Backend API desarrollado en **JavaScript** con **Node.js** y **Express**. Proporciona endpoints RESTful para la gestión de usuarios con conexión a base de datos **MySQL**. Se ejecuta en un contenedor Docker desplegado en una instancia **EC2 privada** de AWS, junto con un contenedor MySQL con persistencia de datos mediante **volúmenes Docker**.

---

## Arquitectura de Contenedorización

```
┌───────────────────────────────────────────────────────┐
│              EC2 Privada (Backend)                     │
│                                                       │
│   ┌─────────────────────┐   ┌──────────────────────┐ │
│   │  Contenedor: API    │   │  Contenedor: MySQL   │ │
│   │  Node.js/Express    │──▶│  mysql:8.0           │ │
│   │  Puerto: 3000       │   │  Puerto: 3306        │ │
│   │  User: appuser      │   │                      │ │
│   └─────────────────────┘   └──────────┬───────────┘ │
│                                        │              │
│                              ┌─────────▼──────────┐  │
│                              │  Named Volume:      │  │
│                              │  mysql_data         │  │
│                              │  (persistencia)     │  │
│                              └────────────────────┘  │
│                                                       │
│   Red Docker: backend-network (bridge)                │
└───────────────────────────────────────────────────────┘
```

---

## Versiones y Herramientas Requeridas

| Herramienta | Versión |
|---|---|
| Node.js | 18.0.0+ |
| npm | 8.0.0+ |
| MySQL | 8.0 |
| Docker | 20.10+ |
| Docker Compose | 2.0+ |

### Dependencias Principales
- **express** `^4.18.2` - Framework web
- **cors** `^2.8.5` - Middleware CORS
- **mysql2** `^3.6.0` - Driver MySQL
- **dotenv** `^16.3.1` - Variables de entorno

---

## Estructura del Proyecto

```
Back_EVAL2/
├── .github/
│   └── workflows/
│       └── deploy.yml          # Pipeline CI/CD (GitHub Actions)
├── init-db/
│   └── 01_creacion_base_datos.sql  # Script SQL de inicialización
├── server.js                   # Servidor principal Express
├── package.json                # Configuración de dependencias
├── Dockerfile                  # Dockerfile multi-stage
├── docker-compose.yml          # Compose: Backend + MySQL + Volúmenes
├── .dockerignore               # Archivos excluidos del build
├── .env.example                # Ejemplo de variables de entorno
└── README.md                   # Documentación
```

---

## Dockerfile (Multi-Stage Build)

El Dockerfile utiliza **multi-stage build** con las siguientes buenas prácticas:

| Práctica | Implementación |
|---|---|
| **Multi-stage** | Etapa `builder` para instalar dependencias, etapa `production` para ejecutar |
| **Usuario no root** | Se crea `appuser` con `adduser -S`, ejecuta con mínimo privilegio |
| **Imagen Alpine** | Basada en `node:18-alpine` para reducir tamaño y superficie de ataque |
| **npm ci** | Instalación limpia y reproducible de dependencias |
| **Cache de capas** | Se copia `package*.json` antes del código fuente |
| **Limpieza** | Se eliminan archivos innecesarios y se limpia cache de npm |

### Construir la imagen manualmente:
```bash
docker build -t backend-api:latest .
```

---

## Docker Compose

El `docker-compose.yml` levanta dos servicios:

| Servicio | Imagen | Puerto | Descripción |
|---|---|---|---|
| `backend` | Build local | 3000 | API REST Node.js/Express |
| `mysql-db` | mysql:8.0 | 3306 | Base de datos MySQL |

### Persistencia de Datos (Volúmenes)

Se utiliza un **named volume** (`mysql_data`) en lugar de bind mount por las siguientes razones:

1. **Gestión por Docker**: Docker administra el ciclo de vida del volumen
2. **Rendimiento**: Mejor rendimiento de I/O que bind mounts
3. **Portabilidad**: No depende de rutas absolutas del host
4. **Persistencia**: Los datos sobreviven a reinicios y eliminación de contenedores

```yaml
volumes:
  mysql_data:
    driver: local
    name: innovatech_mysql_data
```

### Inicialización de la Base de Datos

El directorio `init-db/` contiene scripts SQL que se ejecutan automáticamente al crear el contenedor MySQL por primera vez (montados en `/docker-entrypoint-initdb.d`).

### Comandos útiles:
```bash
# Levantar todo el stack (backend + mysql)
docker compose up -d

# Ver logs de los servicios
docker compose logs -f

# Ver solo logs del backend
docker compose logs -f backend

# Detener servicios (los datos se mantienen en el volumen)
docker compose down

# Detener y eliminar volúmenes (⚠️ ELIMINA DATOS)
docker compose down -v
```

---

## Variables de Entorno

| Variable | Descripción | Valor por defecto |
|---|---|---|
| `PORT` | Puerto del servidor Express | `3000` |
| `DB_HOST` | Host de MySQL | `mysql-db` (nombre del servicio) |
| `DB_USER` | Usuario de MySQL | `root` |
| `DB_PASSWORD` | Contraseña de MySQL | (requerida) |
| `DB_NAME` | Nombre de la base de datos | `proyecto_db` |
| `DB_PORT` | Puerto de MySQL | `3306` |
| `NODE_ENV` | Entorno de ejecución | `production` |

---

## Endpoints de la API

| Método | Ruta | Descripción |
|---|---|---|
| `GET` | `/api/usuarios` | Obtener todos los usuarios |
| `POST` | `/api/usuarios` | Crear un nuevo usuario |
| `PUT` | `/api/usuarios/:id` | Actualizar un usuario |
| `DELETE` | `/api/usuarios/:id` | Eliminar un usuario |

### Ejemplo de uso:
```bash
# Obtener todos los usuarios
curl http://localhost:3000/api/usuarios

# Crear un nuevo usuario
curl -X POST http://localhost:3000/api/usuarios \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Juan Pérez","email":"juan@example.com","edad":25}'
```

---

## Pipeline CI/CD (GitHub Actions)

El pipeline se activa con un **push a la rama `deploy`** y ejecuta:

```
Push a rama 'deploy'
       │
       ▼
┌──────────────────┐
│  1. Build Image  │  Construye imagen Docker multi-stage
└────────┬─────────┘
         ▼
┌──────────────────┐
│  2. Push Image   │  Publica en Docker Hub con tags :latest y :sha
└────────┬─────────┘
         ▼
┌──────────────────┐
│  3. Copy Files   │  Copia docker-compose.yml e init-db/ a EC2
└────────┬─────────┘
         ▼
┌──────────────────┐
│  4. Deploy EC2   │  SSH → pull → stop → run nuevo contenedor
└──────────────────┘
```

### Secrets requeridos en GitHub:

| Secret | Descripción |
|---|---|
| `DOCKER_HUB_USERNAME` | Usuario de Docker Hub |
| `DOCKER_HUB_TOKEN` | Token de acceso de Docker Hub |
| `EC2_BACKEND_HOST` | IP de la instancia EC2 del backend |
| `EC2_USER` | Usuario SSH de EC2 (ej: `ec2-user`, `ubuntu`) |
| `EC2_SSH_KEY` | Clave privada SSH para conexión a EC2 |
| `DB_USER` | Usuario de la base de datos MySQL |
| `DB_PASSWORD` | Contraseña de MySQL |
| `DB_NAME` | Nombre de la base de datos |

### Cómo desplegar:
```bash
# Crear y cambiar a la rama deploy
git checkout -b deploy

# Hacer push para activar el pipeline
git push origin deploy
```

---

## Puertos Requeridos

| Puerto | Servicio | Dirección |
|---|---|---|
| `3000` | Express (Backend API) | Entrante desde frontend |
| `3306` | MySQL (Base de datos) | Interno entre contenedores |

---

## Notas Importantes

- MySQL debe estar corriendo antes de iniciar el backend (`depends_on` + healthcheck en compose)
- La base de datos `proyecto_db` se crea automáticamente con el script de init
- Los datos persisten en el named volume `innovatech_mysql_data`
- El backend **NO es accesible desde Internet**, solo desde la EC2 del frontend
- La comunicación se realiza por la **subred privada de AWS**
- Los Security Groups deben permitir tráfico en puerto 3000 desde el frontend
