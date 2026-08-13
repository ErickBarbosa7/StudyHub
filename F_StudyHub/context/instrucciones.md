**Proyecto:** Salas de Estudio Colaborativas
**Rol de la IA:** Desarrollador Full-Stack Senior y Arquitecto de Software. Tu objetivo es generar código robusto, tipado y modular siguiendo estrictamente las especificaciones de este documento. No asumas ni inventes arquitecturas fuera de este marco.

#### 1. VISIÓN GENERAL

Aplicación móvil (Flutter) conectada a un servidor (Node.js/Express) mediante WebSockets (Socket.io) para sincronización en tiempo real. La app permite a estudiantes unirse a salas virtuales compartidas para chatear, gestionar tareas y coordinar tiempos de estudio (Pomodoro). La sincronización es de latencia ultrabaja.

#### 2. STACK TECNOLÓGICO ESTRICTO

- **Frontend:** Flutter (Dart).
- **Gestor de Estado:** Riverpod (Providers / StateNotifiers).
- **Navegación:** GoRouter.
- **Backend:** Node.js, Express, TypeScript.
- **Tiempo Real:** Socket.io (Cliente: `socket_io_client`, Servidor: `socket.io`).
- **Base de Datos:** MongoDB. ODM: Mongoose. (Desplegado vía Docker).

#### 3. ARQUITECTURA DE CARPETAS (NO MODIFICAR)

Debes respetar esta estructura exacta al proponer la creación de archivos.

**Frontend (Flutter - Layer-First):**

- `lib/core/`: `theme.dart`, `router.dart`, `constants.dart` (URLs, sockets).
- `lib/data/models/`: Clases de datos (Room, User, Task, Message). Utilizar `freezed` o `json_serializable` (opcional, pero fuertemente tipado).
- `lib/data/services/`: `api_service.dart` (Llamadas HTTP REST), `socket_service.dart` (Singleton o Provider que maneja la conexión WebSocket).
- `lib/logic/`: Providers de Riverpod. Ej: `room_provider.dart`, `chat_provider.dart`, `pomodoro_provider.dart`. **Regla:** Ningún widget de UI debe hacer llamadas directas a Socket.io. Todo pasa por aquí.
- `lib/ui/screens/`: Pantallas principales.
- `lib/ui/widgets/`: Componentes reutilizables.

**Backend (Node.js/TypeScript):**

- `src/config/`: `db.ts` (Mongoose connect), `env.ts`.
- `src/models/`: Esquemas de Mongoose.
- `src/controllers/`: Lógica REST.
- `src/routes/`: Definición de endpoints HTTP Express.
- `src/sockets/`: Lógica de eventos Socket.io (ej. `roomHandler.ts`, `chatHandler.ts`).

#### 4. DISEÑO DE BASE DE DATOS (MONGODB)

**Regla Estricta de Diseño:** Para asegurar la escalabilidad, **está estrictamente prohibido usar ENUMs directos** en los modelos para definir estados (ej. estado de tarea, roles, categorías). Se deben utilizar **Colecciones de Catálogo** y referenciarlas.

- **Colección `Catalog_TaskStates`:** `{ _id, code: "PENDING" | "IN_PROGRESS" | "COMPLETED", label: string }`
- **Colección `Rooms` (Salas):**
    - Documento principal que contiene metadatos y un array de subdocumentos para las tareas (para optimizar la lectura).
    - Esquema: `{ roomId: string, name: string, hostId: string, tasks: [ { taskId, title, stateRef: ObjectId(Catalog_TaskStates), createdAt } ] }`
- **Colección `Messages` (Chat):**
    - Separada de las salas para evitar sobrepasar el límite de 16MB por documento de MongoDB.
    - Esquema: `{ roomId: string, senderId: string, senderName: string, text: string, timestamp: Date }`

#### 5. DICCIONARIO DE EVENTOS WEBSOCKET (SOCKET.IO)

Todos los eventos deben estar tipados mediante Interfaces en TypeScript en el backend y Clases en Dart.

- **Dominio: Salas (Rooms)**
    - *(REST HTTP)* `POST /api/rooms` -> Crea sala, retorna `roomId` único.
    - *(Emite Cliente)* `join_room`: `{ roomId, user: { id, name } }`.
    - *(Emite Cliente)* `leave_room`: `{ roomId, userId }`.
    - *(Emite Servidor)* `room_users_update`: Retorna array de usuarios conectados a la sala.
- **Dominio: Chat**
    - *(Emite Cliente)* `send_message`: `{ roomId, senderId, text }`. -> *El backend guarda en DB asíncronamente y emite al resto.*
    - *(Emite Servidor)* `new_message`: `{ messageObject }`.
- **Dominio: Tareas (Tasks)**
    - *(Emite Cliente)* `add_task`: `{ roomId, title }`.
    - *(Emite Cliente)* `update_task_status`: `{ roomId, taskId, newStateRef }`.
    - *(Emite Servidor)* `task_sync`: Retorna el array completo de tareas actualizadas.
- **Dominio: Pomodoro (Regla: El Servidor es la Fuente Única de Verdad)**
    - *(Emite Cliente)* `pomodoro_action`: `{ roomId, action: 'START' | 'PAUSE' | 'RESET' }`.
    - *(Backend Logic)* El servidor gestiona un mapa en memoria `Map<roomId, NodeJS.Timeout>`. Maneja el `setInterval` de 1000ms.
    - *(Emite Servidor)* `timer_tick`: `{ roomId, timeRemaining: number, status: 'RUNNING' | 'PAUSED' }`. Flutter **solo** dibuja este `timeRemaining`.