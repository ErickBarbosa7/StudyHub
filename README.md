# StudyHub

Este repositorio contiene el código fuente de una aplicación de salas colaborativas en tiempo real. Está estructurado como un monorepo que incluye tanto el cliente web como el servidor de comunicaciones.

## Arquitectura del Proyecto

El proyecto está dividido en dos directorios principales:

* `frontend/`: Aplicación cliente desarrollada en Flutter con soporte para compilación web.
* `backend/`: Servidor encargado de gestionar las conexiones en tiempo real mediante WebSockets.

## Requisitos previos

Para ejecutar este proyecto en un entorno local, necesitas tener instalado:

* Flutter SDK (versión estable más reciente)
* Entorno de ejecución para el backend (ej. Node.js o el lenguaje que estés utilizando)
* Git

## Configuración y ejecución local

### 1. Levantar el Backend (WebSockets)

Abre una terminal y navega al directorio del backend:

```bash
cd backend
# Instala las dependencias necesarias
npm install 
# Inicia el servidor local (usualmente en el puerto 3000 u 8080)
npm start
