**Proyecto:** Salas de Estudio Colaborativas
**Rol de la IA:** Desarrollador Full-Stack Senior y Arquitecto de Software. Tu objetivo es generar código robusto, tipado y modular siguiendo estrictamente las especificaciones de este documento. No asumas ni inventes arquitecturas fuera de este marco.

#### 1. VISIÓN GENERAL

Aplicación móvil (Flutter) conectada a un servidor (Node.js/Express) mediante WebSockets (Socket.io) para sincronización en tiempo real. La app permite a estudiantes unirse a salas virtuales compartidas para chatear, gestionar tareas y coordinar tiempos de estudio (Pomodoro). La sincronización es de latencia ultrabaja.

**Despliegue:** Backend en Render (`https://studyhub-rl5b.onrender.com`), Frontend en Netlify.

#### 2. STACK TECNOLÓGICO ESTRICTO

- **Frontend:** Flutter (Dart).
- **Gestor de Estado:** Riverpod (Providers / StateNotifiers).
- **Navegación:** GoRouter.
- **Backend:** Node.js, Express, TypeScript.
- **Tiempo Real:** Socket.io (Cliente: `socket_io_client`, Servidor: `socket.io`).
- **Base de Datos:** MongoDB. ODM: Mongoose. (Desplegado vía Docker).

**Dependencias Flutter:**

| Paquete | Versión |
|---------|---------|
| `socket_io_client` | `^3.1.6` |
| `flutter_riverpod` | `^3.4.2` |
| `http` | `^1.6.0` |
| `lottie` | `^3.5.1` |
| `shared_preferences` | `^2.5.5` |
| `audioplayers` | `^6.8.1` |
| `qr_flutter` | `^4.1.0` |
| `mobile_scanner` | `^5.2.3` |

#### 3. ARQUITECTURA DE CARPETAS (NO MODIFICAR)

Debes respetar esta estructura exacta al proponer la creación de archivos.

**Frontend (Flutter - Layer-First):**

```
F_StudyHub/lib/
  main.dart
  core/
    constants.dart        # kApiBaseUrl, kSocketUrl (dart-define)
    theme.dart            # Design system completo: paleta de colores, tipografía, tokens
  logic/
    room_provider.dart    # RoomNotifier / RoomState
    chat_provider.dart    # ChatNotifier / ChatState
    task_provider.dart    # TaskNotifier / TaskState
    pomodoro_provider.dart# PomodoroNotifier / PomodoroState
    socket_provider.dart  # socketServiceProvider (Provider<WebSocketService>)
  data/
    models/
      user_model.dart     # User { id, name }
      room_model.dart     # Room { roomId, name, hostId }
      message_model.dart  # Message { id, roomId, senderId, senderName, text, timestamp }
      task_model.dart     # Task { taskId, title, stateCode, stateLabel, createdAt }
    services/
      api_service.dart    # REST API: createRoom, getRoom
      websocket_service.dart # Socket.IO client wrapper
      sound_service.dart  # Audio playback (pomodoro bell) + SoundProvider
  ui/
    screens/
      home_screen.dart         # Landing / Home
      create_room_screen.dart  # Formulario crear/unirse + Workspace (tabs Estudio/Chat)
    widgets/
      chat_box.dart            # ChatBox widget
      help_icon.dart           # HelpIcon widget reutilizable
      pomodoro_timer.dart      # PomodoroTimer widget
      qr_display.dart          # QrDisplaySheet (genera QR de la sala)
      qr_scanner.dart          # QrScannerScreen (escanea QR para unirse)
      task_list.dart           # TaskList widget con edit/delete
  assets/
    audio/pomodoro_bell.mp3    # Sonido Pomodoro
    fonts/CascadiaCode.ttf     # Fuente monoespaciada
    fonts/Recursive-VF.ttf     # Fuente principal (variable)
    Lottie/STUDENT.json        # Animación home
    Lottie/Loading.json        # Animación carga
    Lottie/claude.json         # Animación decorativa
    Lottie/404.json            # Animación error 404
```

**Backend (Node.js/TypeScript):**

```
B_StudyHub/src/
  index.ts              # Entry point: express + http.listen + registerSocketHandlers
  config/
    db.ts               # Mongoose connect
    env.ts              # Variables de entorno
  controllers/          # Lógica REST
  routes/               # Definición de endpoints HTTP Express
  models/
    Room.ts             # RoomModel + TaskSubSchema + generateRoomCode()
    Message.ts          # MessageModel
    CatalogTaskState.ts # CatalogTaskStateModel + seedCatalogTaskStates()
  sockets/
    index.ts            # registerSocketHandlers (master)
    roomHandler.ts      # join_room, leave_room, kick_user, disconnect
    chatHandler.ts      # send_message, get_chat_history, join_room
    taskHandler.ts      # add_task, update_task_status, delete_task, edit_task, join_room
    pomodoroHandler.ts  # pomodoro_action, join_room
```

#### 4. DISEÑO DE BASE DE DATOS (MONGODB)

**Regla Estricta de Diseño:** Para asegurar la escalabilidad, **está estrictamente prohibido usar ENUMs directos** en los modelos para definir estados (ej. estado de tarea, roles, categorías). Se deben utilizar **Colecciones de Catálogo** y referenciarlas.

- **Colección `Catalog_TaskStates`:** `{ _id, code: "PENDING" | "IN_PROGRESS" | "COMPLETED", label: string }`
  - Seed data: `PENDING` -> `'Pendiente'`, `IN_PROGRESS` -> `'En progreso'`, `COMPLETED` -> `'Completada'`
  - Exporta constantes: `CATALOG_TASK_STATES` y tipo `CatalogTaskStateCode`

- **Colección `Rooms` (Salas):**
    - Documento principal que contiene metadatos y un array de subdocumentos para las tareas.
    - Esquema: `{ roomId: string (unique, required), name: string (required), hostId: string (required), tasks: [TaskSubDoc], createdAt, updatedAt }`
    - **TaskSubDoc** (`_id: false`): `{ taskId: string, title: string, stateRef: ObjectId(Catalog_TaskStates), createdAt: Date }`
    - Helper: `generateRoomCode(length = 6)` con alfabeto `'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'`

- **Colección `Messages` (Chat):**
    - Separada de las salas para evitar sobrepasar el límite de 16MB por documento de MongoDB.
    - Esquema: `{ roomId: string (indexed), senderId: string, senderName: string, text: string, timestamp: Date, createdAt, updatedAt }`

#### 5. DICCIONARIO DE EVENTOS WEBSOCKET (SOCKET.IO)

Todos los eventos deben estar tipados mediante Interfaces en TypeScript en el backend y Clases en Dart.

##### Dominio: Salas (Rooms)

- *(REST HTTP)* `POST /api/rooms` -> Crea sala, retorna `roomId` único (alfabeto sin caracteres ambiguos I/0/O).
- *(Emite Cliente)* `join_room`: `{ roomId, user: { id, name } }` -> El backend notifica a los 4 handlers: roomHandler (users), chatHandler (history), taskHandler (task_sync), pomodoroHandler (timer state).
- *(Emite Cliente)* `leave_room`: `{ roomId, userId }`.
- *(Emite Cliente)* `kick_user`: `{ roomId, hostId, userId }` -> Verifica que `hostId` coincide con el host en DB. Si es válido: emite `kicked` al usuario expulsado y `user_kicked` a todos.
- *(Emite Servidor)* `room_users_update`: `Array<{ id: string, name: string }>` -> Broadcast a sala completa.
- *(Emite Servidor)* `kicked`: `{ roomId: string }` -> Solo al usuario expulsado.
- *(Emite Servidor)* `user_kicked`: `{ userId: string, userName: string }` -> Broadcast a sala completa.
- *(Manejo disconnect)* En `disconnect`: el socket se remueve automáticamente de todas las salas.

##### Dominio: Chat

- *(Emite Cliente)* `send_message`: `{ roomId, senderId, text }`. -> El backend guarda en DB y emite `new_message` a la sala.
- *(Emite Cliente)* `get_chat_history`: `{ roomId }`.
- *(Emite Servidor)* `chat_history`: `ChatMessage[]` -> Solo al socket que lo solicitó.
- *(Emite Servidor)* `new_message`: `{ id, roomId, senderId, senderName, text, timestamp }` -> Broadcast a sala.

##### Dominio: Tareas (Tasks)

- *(Emite Cliente)* `add_task`: `{ roomId, title }`.
- *(Emite Cliente)* `update_task_status`: `{ roomId, taskId, newStateRef }`.
- *(Emite Cliente)* `delete_task`: `{ roomId, taskId }`.
- *(Emite Cliente)* `edit_task`: `{ roomId, taskId, title }`.
- *(Emite Servidor)* `task_sync`: Retorna el array completo de tareas con `stateCode` y `stateLabel` resueltos. Broadcast a sala.

**Detección de nuevas tareas (frontend):** El provider compara IDs de la lista anterior vs la nueva en `task_sync`. Si hay IDs nuevos y no es una acción local (`_pendingLocalAdd`), incrementa `newTaskCount` y muestra notificación.

##### Dominio: Pomodoro (Regla: El Servidor es la Fuente Única de Verdad)

- *(Emite Cliente)* `pomodoro_action`: `{ roomId, action: 'START' | 'PAUSE' | 'RESET', duration?: number }`.
- *(Backend Logic)* El servidor gestiona un mapa en memoria `Map<roomId, NodeJS.Timeout>`. Maneja el `setInterval` de 1000ms. `duration` es opcional (default 30 min = 1800s).
- *(Emite Servidor)* `timer_tick`: `{ roomId, timeRemaining: number, totalSeconds: number, status: string }`. Flutter **solo** dibuja este `timeRemaining`.
- *(Emite Servidor)* `pomodoro_finished`: `{ roomId, totalSeconds: number }` -> Emite cuando el timer llega a 0.

##### Matriz Completa de Eventos

| Evento | Cliente -> Servidor | Servidor -> Cliente |
|--------|:---:|:---:|
| `join_room` | EMIT | HANDLED (4 handlers) |
| `leave_room` | EMIT | HANDLED (roomHandler) |
| `kick_user` | EMIT | HANDLED (roomHandler) |
| `disconnect` | auto | HANDLED (roomHandler + index) |
| `room_users_update` | -- | EMIT (broadcast sala) |
| `kicked` | -- | EMIT (solo expulsado) |
| `user_kicked` | -- | EMIT (broadcast sala) |
| `send_message` | EMIT | HANDLED (chatHandler) |
| `get_chat_history` | EMIT | HANDLED (chatHandler) |
| `chat_history` | -- | EMIT (solo requestor) |
| `new_message` | -- | EMIT (broadcast sala) |
| `add_task` | EMIT | HANDLED (taskHandler) |
| `update_task_status` | EMIT | HANDLED (taskHandler) |
| `delete_task` | EMIT | HANDLED (taskHandler) |
| `edit_task` | EMIT | HANDLED (taskHandler) |
| `task_sync` | -- | EMIT (broadcast sala) |
| `pomodoro_action` | EMIT | HANDLED (pomodoroHandler) |
| `timer_tick` | -- | EMIT (broadcast sala) |
| `pomodoro_finished` | -- | EMIT (broadcast sala) |

#### 6. PROVIDERS Y ESTADO (RIVERPod)

| Provider | StateNotifier | State Fields | Archivo |
|----------|---------------|-------------|---------|
| `roomProvider` | `RoomNotifier` | `room: Room?`, `localUser: User?`, `users: List<User>`, `isCreating: bool`, `isRestoring: bool`, `error: String?` | `room_provider.dart` |
| `chatProvider` | `ChatNotifier` | `messages: List<Message>`, `isLoadingHistory: bool`, `error: String?`, `unreadCount: int` | `chat_provider.dart` |
| `taskProvider` | `TaskNotifier` | `tasks: List<Task>`, `error: String?`, `newTaskCount: int`, `lastAddedTaskTitle: String?` | `task_provider.dart` |
| `pomodoroProvider` | `PomodoroNotifier` | `timeRemaining: int` (1800), `totalSeconds: int` (1800), `status: String` ('PAUSED'), `isFinished: bool` | `pomodoro_provider.dart` |
| `socketServiceProvider` | -- (Provider) | `WebSocketService` | `socket_provider.dart` |
| `soundProvider` | `SoundNotifier` | `isEnabled: bool` (true) | `sound_service.dart` |

**Regla:** Ningún widget de UI debe hacer llamadas directas a Socket.io. Todo pasa por providers.

**Chat State extra:** `_isChatVisible` (bool, privado en Notifier) + `setChatVisible(bool)` + `clearUnread()`. El `unreadCount` se incrementa cuando llega `new_message` y el chat no es visible.

**Task State extra:** `_pendingLocalAdd` (bool, privado en Notifier) + `consumeNewTask()`. Permite distinguir tareas agregadas por el usuario local vs remotas, para no mostrar notificación en tareas propias.

**Room State extra:** `leaveRoom()` emite `leave_room` y limpia sesión local. `kickUser(userId)` emite `kick_user` con verificación de host.

#### 7. MODELOS DE DATOS (DART)

| Modelo | Campos | Notas |
|--------|--------|-------|
| `User` | `id: String`, `name: String` | Factory `generateLocal(name)` genera ID con timestamp + random |
| `Room` | `roomId: String`, `name: String`, `hostId: String` | |
| `Message` | `id: String`, `roomId: String`, `senderId: String`, `senderName: String`, `text: String`, `timestamp: DateTime` | `.toLocal()` en factory. `isOwn(userId)` helper |
| `Task` | `taskId: String`, `title: String`, `stateCode: String`, `stateLabel: String`, `createdAt: DateTime?` | |

#### 8. DISEÑO VISUAL (THEME)

**Paleta:** "Organic Minimal" definida en `core/theme.dart`. Los tokens de colores se usan como `kColorInk`, `kColorPaper`, `kColorSage`, `kColorDeepSage`, `kColorSageSoft`, `kColorGold`, `kColorGoldSoft`, `kColorCard`, `kColorTintedShadow`, `kColorTextSecondary`, `kColorError`, `kColorErrorBorder`.

**Tokens de tamaño de fuente (`AppType`):**
- `sizeCaption`: 12
- `sizeBodyMedium`: 14
- `sizeBody`: 16
- `sizeTitle`: 20
- `sizeHero`: 40
- `sizeGiant`: 48
- `sizeTimerCompact`: 38
- `sizeTimerDisplay`: 44
- `sizeTimerLarge`: 56

**Weights:** `weightRegular` (400), `weightMedium` (500), `weightSemiBold` (600), `weightBold` (700).

**Métodos de estilo:**
- `AppType.secondaryItalic({size, color})` - Texto secundario cursiva
- `AppType.monoTimer({fontSize, color})` - Fuente monoespaciada para timers (acepta `fontSize` opcional)

**Fuentes:** `Recursive` (variable, 100-900) como fuente principal, `Cascadia Code` como monoespaciada.

#### 9. PLATAFORMA Y PERMISOS

- **iOS** (`Info.plist`): `NSCameraUsageDescription` = "StudyHub necesita acceso a la camara para escanear codigos QR de salas."
- **Android** (`AndroidManifest.xml`): `android.permission.CAMERA`
- **iOS Audio:** `audioplayers` requiere `AudioContext(iOS: AudioContextIOS(category: AVAudioSessionCategory.playback))` para reproducir audio en modo silencio. Esto se configura en `sound_service.dart` constructor, `unlock()`, y antes de `playPomodoroFinishedSound()`.
- **`mobile_scanner` v5.2.3:** Usa `MobileScannerErrorCode` enum (`permissionDenied`, `controllerAlreadyInitialized`, `controllerDisposed`, `controllerUninitialized`, `genericError`, `unsupported`). NO tiene `hasCameraPermission` en state.

#### 10. PATRONES DE ERROR Y NOTIFICACIONES

**Patrón de error en providers:** Cada state tiene campo `error: String?`. Los widgets usan `ref.listen<XState>` para mostrar errores:
```dart
ref.listen<XState>(provider, (previous, next) {
  if (next.error != null && next.error != previous?.error) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.error!)));
      ref.read(provider.notifier).clearError();
    });
  }
});
```

**Traducción de errores:** `_translateError(String raw)` en `RoomState` convierte mensajes del servidor a mensajes amigables en español.

**Handler global de errores** (`main.dart`):
1. `FlutterError.onError` - catches Flutter framework errors
2. `runZonedGuarded` - catches Dart async errors
3. `ErrorWidget.builder` override en `MaterialApp.builder` - UI de error con "Volver al inicio"

**Notificación de tareas nuevas:** Banner animado (`AnimatedSize`) en `_buildWorkspace`, debajo del header de usuarios. Muestra "Nueva tarea: [nombre]" con fondo `kColorSageSoft`. Auto-dismiss después de 3 segundos.

**Badge de chat no leído:** `_ChatTabBadge` widget en la tab de Chat. Incrementa `unreadCount` cuando llega `new_message` y el chat no es visible.

#### 11. FEATURES IMPLEMENTADAS

| Feature | Archivos Principales | Descripción |
|---------|---------------------|-------------|
| **Sistema de errores** | `room_provider.dart`, `task_provider.dart`, `chat_provider.dart` | `error` en State + `_translateError()` español |
| **Estados de carga** | `home_screen.dart` | `isRestoring` spinner, chat loading, crear/unirse spinner |
| **HelpIcon** | `help_icon.dart` | Bottom sheet reutilizable con título + descripción |
| **Tooltips de ayuda** | `pomodoro_timer.dart`, `task_list.dart` | Icono `?` con información contextual |
| **Error global** | `main.dart` | `runZonedGuarded` + `ErrorWidget.builder` custom |
| **Confirmación al salir** | `create_room_screen.dart` | AlertDialog con `_leaveRoom()` |
| **QR generación** | `qr_display.dart` | Bottom sheet con QR, código, botón copiar |
| **QR escaneo** | `qr_scanner.dart` | `MobileScannerErrorCode` manejo, botón reintentar, permisos |
| **QR integración** | `create_room_screen.dart` | Icono QR en pill de código (host), botón "Escanear QR" (join) |
| **Timezone fix** | `message_model.dart`, `task_model.dart` | `.toLocal()` en factories |
| **Tareas edit/delete** | `task_handler.ts`, `task_provider.dart`, `task_list.dart` | Backend + frontend completo |
| **Default Pomodoro 30min** | `pomodoro_provider.dart` | `kDefaultPomodoroSeconds = 30 * 60` |
| **Input código 6 cajas** | `create_room_screen.dart` | Auto-advance, auto-backspace, paste, validación inline |
| **Fix iOS audio** | `sound_service.dart` | `AVAudioSessionCategory.playback` via `AudioContext` |
| **Tokens de tema** | `theme.dart` + screens | `sizeHero`, `sizeGiant`, `sizeTimerCompact`, `sizeTimerLarge` + `monoTimer(fontSize:)` |
| **Input código responsive** | `create_room_screen.dart` | `compact = screenWidth < 400`, boxWidth 38/46, gap 8/10, fontSize 16/20 |
| **Permisos cámara** | `Info.plist`, `AndroidManifest.xml`, `qr_scanner.dart` | NSCameraUsageDescription, CAMERA permission, manejo específico |
| **Badge chat no leído** | `chat_provider.dart`, `create_room_screen.dart` | `unreadCount`, `_isChatVisible`, `_ChatTabBadge` widget |
| **Error "Código no válido"** | `room_provider.dart`, `create_room_screen.dart` | Mensaje específico en español |
| **Animación 404** | `pubspec.yaml`, `create_room_screen.dart` | `404.json` Lottie, bottom sheet con retry |
| **Kick participantes** | `roomHandler.ts`, `room_provider.dart`, `create_room_screen.dart` | Backend verificación host, frontend long press + corona + dialogo |
| **PopScope back button** | `create_room_screen.dart` | Bloquea retroceso cuando estás en sala, muestra confirmación |
| **Botón "Volver a la sala"** | `home_screen.dart` | Aparece cuando `roomState.room != null` |
| **Notificación tarea nueva** | `task_provider.dart`, `create_room_screen.dart` | Banner animado top workspace, solo para tareas de otros |
| **Fix teclado chat** | `chat_box.dart` | Eliminado `FocusScope.unfocus()` del botón enviar |
| **Banner conexión/errores** | `connection_banner.dart`, `websocket_service.dart`, `socket_provider.dart` | `SocketConnectionStatus` + `ValueNotifier`, `SocketState`, `ensureConnected`, banner "Conectando…"/error con Reintentar |
| **Límites de caracteres** | `chat_box.dart`, `roomHandler.ts`, `chatHandler.ts`, `taskHandler.ts`, `roomController.ts` | Chat 1000, feedback 100, tarea 100, sala 20, usuario 15 |
| **Sound unlock iOS (edit)** | `sound_service.dart`, `pomodoro_timer.dart` | `unlock()` reproduce clip mudo dentro del gesto para activar sesión de audio |
| **Pomodoro bottom sheet (edit)** | `pomodoro_timer.dart` | `_promptCustomDuration` en `showModalBottomSheet` con `AnimatedPadding` (sigue al teclado), sin `SingleChildScrollView`, input numérico (`digitsOnly`, max 3). Fix salto iOS al abrir |
| **Traspaso de dueño** | `roomHandler.ts`, `room_provider.dart`, `room_model.dart` | Al irse el dueño y quedar 1+ usuario, el 1ro que se queda pasa a ser dueño (Mongo + evento `host_transferred`) |
| **Eliminar sala vacía** | `roomHandler.ts` | Al quedar 0 usuarios conectados se borra `Room` + `Message` del chat |

#### 12. REGLAS DE CODIFICACIÓN

- **Flutter:** `flutter analyze` debe pasar con 0 errores siempre.
- **Backend:** `tsc --noEmit` debe pasar con 0 errores siempre.
- **Sin comentarios** en el código a menos que el usuario lo pida explícitamente.
- **Sin emojis** en archivos a menos que el usuario lo pida.
- **Naming:** `snake_case` para archivos, `camelCase` para variables/métodos, `PascalCase` para clases.
- **Variables privadas:** Prefijo `_` (e.g. `_socketService`, `_pendingLocalAdd`).
- **Constants:** Prefijo `k` (e.g. `kColorPaper`, `kDefaultPomodoroSeconds`).
- **IDs de usuario local:** Se generan con `User.generateLocal(name)` usando timestamp + random.
- **Código de sala:** 6 caracteres de `'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'` (sin I/0/O).
- **Room host:** `hostId` se guarda en MongoDB Room model y se usa para permisos de kick. Si el dueño sale y quedan usuarios, el cargo se transfiere al 1ro que se queda (`host_transferred`).
- **Sala vacía:** Si quedan 0 usuarios conectados (`usersByRoom`), la sala y sus mensajes se eliminan de Mongo automáticamente (`handleRoomAfterLeave`).
- **Users in-memory:** Se trackean en `usersByRoom` Map (keyed by socket `id`), no persistidos.
- **Audio iOS:** Requiere `AudioContext` con `AVAudioSessionCategory.playback` para funcionar en silencio.
- **PopScope:** Usado en `create_room_screen.dart` para interceptar back button cuando hay sala activa.
- **`addPostFrameCallback`:** Siempre usar antes de `showSnackBar` o `setState` en `ref.listen` para evitar errores de build phase.
- **`AnimatedSize`:** Usado para banners de notificación con transiciones suaves.
