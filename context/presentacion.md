# StudyHub

## Ingeniería en Sistemas | Sistemas Propietarios III

# PLATAFORMA DE SALAS DE ESTUDIO COLABORATIVAS EN TIEMPO REAL

## StudyHub

---

### Puntos clave de tecnología / arquitectura

- 🎨 Figma mockups de la aplicación (UI/UX): pantallas de inicio, crear/unirse a sala y workspace con pestañas Chat/Estudio, con paleta índigo "Enfoque Índigo".

- ⚙️ Arquitectura de Backend en Node.js, Express y TypeScript, con WebSockets (Socket.io) para sincronización en tiempo real y arquitectura modular por handlers (`Backend`).

- 🗄️ Base de datos con MongoDB y Mongoose: colecciones de catálogo en lugar de ENUMs, salas con tareas anidadas y chat en colección separada para escalabilidad (`Base de datos`).

- ☁️ DevOps en contenedores Docker y despliegue en la nube: MongoDB en Docker, backend en Render y frontend Flutter web en Netlify (`DevOps / Cloud`).

---

### Ciclo de vida del software

#### CICLO DE VIDA DE SOFTWARE EN STUDYHUB

1. **REQUERIMIENTOS:** Análisis de roles (host y participantes) y mapa de historias de usuario para salas colaborativas, chat, tareas y pomodoro.

2. **DISEÑO:** Diseño de interfaces UI/UX desde Figma y modelo de datos en MongoDB (colecciones de catálogo, salas y mensajes).

3. **IMPLEMENTACIÓN:** Frontend Flutter + Riverpod y API REST + WebSockets Node.js/Express con TypeScript y Socket.io.

4. **PRUEBAS:** Testing unitario e integración (`flutter analyze`, `tsc --noEmit`) y control de versiones con Git.

5. **MANTENIMIENTO:** Estrategia de migración de datos, respaldos, monitoreo de conexiones, limpieza de salas vacías y traspaso de host.

---

### Aprendizajes

- Frontend modular con Flutter y Riverpod, estado reactivo, consumo de APIs y WebSockets dinámicos, y diseño maquetado desde Figma.

- API RESTful y eventos Socket.io, arquitectura por handlers, control de accesos por roles (host/kick) e integridad en tiempo real.

- Esquema en MongoDB con colecciones de catálogo, integridad referencial, colecciones separadas para escalar y migración de datos.

- Entorno de desarrollo homogéneo con Docker y despliegue en la nube (Render y Netlify).

---

### Pie de página

> **Lema / Frase:** "Estudia y concéntrate en equipo"

**Integrantes del equipo:**

- Erick Barbosa