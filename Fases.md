#### PLAN DE EJECUCIÓN POR FASES (INSTRUCCIONES DE DESARROLLO ESTRICTAS)

El desarrollo se hará paso a paso. Cuando te pida "Iniciar Fase [X]", tu única tarea es generar EXACTAMENTE los archivos listados en esa fase, con su código completo y sin omitir importaciones. No debes escribir código de fases posteriores.

**Fase 1: Infraestructura y Conexión Base**

*Objetivo:* Levantar servidores y asegurar el handshake de WebSockets sin crear UI compleja.
*Entregables Backend:*

- `docker-compose.yml` (MongoDB).
- `src/config/db.ts` (Conexión Mongoose).
- `src/index.ts` (Inicialización Express, HTTP Server y Socket.io).
*Entregables Frontend (Flutter):*
- `lib/core/constants.dart` (URLs del servidor local).
- `lib/data/services/socket_service.dart` (Clase o Provider que inicializa `socket_io_client` y hace el `connect()`).
- `lib/main.dart` (Configuración inicial, inicialización de Riverpod y llamada básica al Socket para verificar conexión por consola).

**Fase 2: Gestión de Salas y Catálogos en Base de Datos**

*Objetivo:* Crear salas vía REST, conectarse vía Sockets y mostrar quién está conectado.
*Regla de BD:* Debes crear obligatoriamente el catálogo relacional para los estados, no uses ENUMs.
*Entregables Backend:*

- `src/models/CatalogTaskState.ts` (Catálogo para PENDING, IN_PROGRESS, COMPLETED).
- `src/models/Room.ts` (Esquema de sala).
- `src/controllers/roomController.ts` y `src/routes/roomRoutes.ts` (Endpoint POST para generar sala).
- `src/sockets/roomHandler.ts` (Eventos: `join_room`, `leave_room`, `room_users_update`).
*Entregables Frontend:*
- `lib/data/models/room_model.dart` y `lib/data/models/user_model.dart`.
- `lib/data/services/api_service.dart` (Llamada HTTP para crear sala).
- `lib/logic/room_provider.dart` (Riverpod StateNotifier para almacenar los usuarios conectados de la sala actual).
- `lib/ui/screens/create_room_screen.dart` (Formulario básico).

**Fase 3: Tareas (CRUD Colaborativo)**

*Objetivo:* Sincronizar una lista de tareas usando el catálogo de base de datos.
*Entregables Backend:*

- Actualización de `src/models/Room.ts` (Agregar el array de tareas referenciando a `CatalogTaskState`).
- `src/sockets/taskHandler.ts` (Lógica para `add_task` y `update_task_status`, actualizando Mongo y emitiendo `task_sync`).
*Entregables Frontend:*
- `lib/data/models/task_model.dart`.
- `lib/logic/task_provider.dart` (Escucha `task_sync` del WebSocket).
- `lib/ui/widgets/task_list.dart` (Renderiza la lista reactiva).

**Fase 4: Chat Grupal Persistente**

*Objetivo:* Mensajería rápida guardada en su propia colección.
*Entregables Backend:*

- `src/models/Message.ts` (Colección independiente, NO anidada en la sala).
- `src/sockets/chatHandler.ts` (Evento `send_message`, guardado asíncrono en DB y emisión `new_message`).
*Entregables Frontend:*
- `lib/data/models/message_model.dart`.
- `lib/logic/chat_provider.dart` (Manejo de la lista de mensajes).
- `lib/ui/widgets/chat_box.dart` (ListView.builder con `ScrollController` para forzar auto-scroll hacia abajo).

**Fase 5: Temporizador Pomodoro Centralizado**

*Objetivo:* El reloj de la sala. El servidor manda, el cliente obedece.
*Regla Estricta:* Prohibido usar `Timer.periodic` en Flutter para contar el tiempo.
*Entregables Backend:*

- `src/sockets/pomodoroHandler.ts`. (Debe gestionar un objeto o mapa `Map<string, NodeJS.Timeout>` para llevar el control por sala, y emitir `timer_tick` cada 1000ms).
*Entregables Frontend:*
- `lib/logic/pomodoro_provider.dart` (Solo actualiza el estado al recibir `timer_tick`).
- `lib/ui/widgets/pomodoro_timer.dart` (Muestra los minutos/segundos y botones para emitir `start_timer` o `pause_timer`).