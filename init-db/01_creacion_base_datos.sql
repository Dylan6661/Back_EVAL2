-- =====================================================
-- SCRIPT DE CREACIÓN DE BASE DE DATOS
-- Proyecto: Sistema de Gestión de Usuarios
-- Motor: MySQL 8.0+
-- =====================================================

CREATE DATABASE IF NOT EXISTS proyecto_db 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE proyecto_db;

CREATE TABLE IF NOT EXISTS usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL COMMENT 'Nombre completo del usuario',
    email VARCHAR(150) NOT NULL UNIQUE COMMENT 'Correo electrónico único del usuario',
    edad INT NULL COMMENT 'Edad del usuario (opcional)',
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha y hora de creación del registro',
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Fecha y hora de última actualización',
    estado ENUM('activo', 'inactivo') DEFAULT 'activo' COMMENT 'Estado actual del usuario'
) ENGINE=InnoDB COMMENT 'Tabla principal de usuarios del sistema';

CREATE INDEX idx_usuarios_nombre ON usuarios(nombre);
CREATE INDEX idx_usuarios_estado ON usuarios(estado);
CREATE INDEX idx_usuarios_fecha_creacion ON usuarios(fecha_creacion);
CREATE INDEX idx_usuarios_nombre_estado ON usuarios(nombre, estado);

INSERT INTO usuarios (nombre, email, edad, estado) VALUES
('Juan Pérez García', 'juan.perez@ejemplo.com', 28, 'activo'),
('María Rodríguez López', 'maria.rodriguez@ejemplo.com', 34, 'activo'),
('Carlos Martínez Sánchez', 'carlos.martinez@ejemplo.com', 45, 'activo'),
('Ana González Fernández', 'ana.gonzalez@ejemplo.com', 22, 'activo'),
('Luis Hernández Torres', 'luis.hernandez@ejemplo.com', 39, 'inactivo'),
('Sofía Díaz Ramírez', 'sofia.diaz@ejemplo.com', 31, 'activo'),
('Pedro Jiménez Castro', 'pedro.jimenez@ejemplo.com', 27, 'activo'),
('Laura Moreno Vargas', 'laura.moreno@ejemplo.com', 29, 'activo')
ON DUPLICATE KEY UPDATE 
    nombre = VALUES(nombre),
    edad = VALUES(edad),
    estado = VALUES(estado);
