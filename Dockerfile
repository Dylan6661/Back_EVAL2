# =====================================================
# DOCKERFILE - Backend Node.js/Express (Multi-Stage Build)
# Proyecto: Sistema de Gestión de Usuarios
# =====================================================

# ---------- Etapa 1: Dependencias ----------
FROM node:18-alpine AS builder

WORKDIR /app

# Copiar archivos de dependencias para aprovechar cache de capas
COPY package*.json ./

# Instalar solo dependencias de producción
RUN npm ci --only=production && npm cache clean --force

# ---------- Etapa 2: Producción ----------
FROM node:18-alpine AS production

# Metadata del contenedor
LABEL maintainer="Innovatech Chile"
LABEL description="Backend API Express - Sistema de Gestión de Usuarios"

# Crear usuario no root por seguridad (mínimo privilegio)
RUN addgroup -S appuser && adduser -S appuser -G appuser

WORKDIR /app

# Copiar node_modules desde la etapa builder
COPY --from=builder /app/node_modules ./node_modules

# Copiar código fuente de la aplicación
COPY --chown=appuser:appuser . .

# Eliminar archivos innecesarios en producción
RUN rm -f .env .env.example Dockerfile .dockerignore docker-compose.yml 2>/dev/null || true

# Variables de entorno por defecto
ENV PORT=3000
ENV NODE_ENV=production

# Exponer el puerto del backend
EXPOSE 3000

# Cambiar a usuario no root
USER appuser

# Comando de inicio
CMD ["node", "server.js"]
