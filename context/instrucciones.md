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
| `dicebear_core` | `^10.7.0` |
| `dicebear_styles` | `^10.6.0` |
| `flutter_svg` | `^2.3.0` |
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
    avatars.dart          # avatarSvg(seed): avatares DiceBear "Sprouts" generados en el dispositivo (con caché) + kAvatarSeeds (espejo de AVATAR_SEEDS) + warmUpAvatars()
    theme.dart            # Design system: AppColors (ThemeExtension claro/oscuro), AppType, buildTheme(brightness)
  logic/
    room_provider.dart    # RoomNotifier / RoomState
    chat_provider.dart    # ChatNotifier / ChatState
    task_provider.dart    # TaskNotifier / TaskState
    pomodoro_provider.dart# PomodoroNotifier / PomodoroState
    socket_provider.dart  # socketServiceProvider (Provider<WebSocketService>)
    theme_provider.dart   # themeProvider (ThemeNotifier sobre ThemeMode) + loadSavedThemeMode()
  data/
    models/
      user_model.dart     # User { id, name, avatarSeed? }
      room_model.dart     # Room { roomId, name, hostId }
      message_model.dart  # Message { id, roomId, senderId, senderName, text, timestamp, reactions } + kReactionEmojis
      task_model.dart     # Task { taskId, title, stateCode, stateLabel, createdAt }
    services/
      api_service.dart    # REST API: createRoom, getRoom
      websocket_service.dart # Socket.IO client wrapper
      sound_service.dart  # Audio (campanas de fin de fase, aviso de tarea) + SoundProvider
  ui/
    screens/
      home_screen.dart         # Landing / Home
      create_room_screen.dart  # Formulario crear/unirse + Workspace (tabs Estudio/Chat)
    widgets/
      avatar_picker.dart       # showAvatarPicker: rejilla de macetas libres para cambiar el avatar
      chat_box.dart            # ChatBox: burbujas con avatar agrupado, reacciones rápidas, indicador "escribiendo"
      help_icon.dart           # HelpIcon widget reutilizable
      pomodoro_timer.dart      # PomodoroTimer widget
      qr_display.dart          # QrDisplaySheet (genera QR de la sala)
      qr_scanner.dart          # QrScannerScreen (escanea QR para unirse)
      task_list.dart           # TaskList: edit/delete, reordenar y arrastrar a la papelera
      theme_toggle.dart        # Botón de modo claro/oscuro (ThemeToggleIconButton / PillButton / Row)
      mascot/pomodoro_mascot.dart # Mascota del dial: reacciona a la fase del ciclo (MascotMood)
  assets/
    audio/focus_end.mp3        # Fin de estudio (3 notas que bajan)
    audio/break_end.mp3        # Fin de descanso (2 notas que suben)
    audio/task_notification.mp3 # Aviso de tarea nueva
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
    avatarSeeds.ts      # AVATAR_SEEDS (23 seeds curadas de Sprouts) + pickAvatarSeed() + isValidAvatarSeed()
    env.ts              # Variables de entorno
  controllers/          # Lógica REST
  routes/               # Definición de endpoints HTTP Express
  models/
    Room.ts             # RoomModel + TaskSubSchema + generateRoomCode()
    Message.ts          # MessageModel (incluye reactions: [{ emoji, userIds }])
    CatalogTaskState.ts # CatalogTaskStateModel + seedCatalogTaskStates()
    sockets/
    index.ts            # registerSocketHandlers (master)
    roomHandler.ts      # join_room, leave_room, kick_user, set_avatar, disconnect

    chatHandler.ts      # send_message, get_chat_history, toggle_reaction, typing, join_room
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
    - Esquema: `{ roomId: string (indexed), senderId: string, senderName: string, text: string, timestamp: Date, reactions: [{ emoji: string, userIds: string[] }] (_id: false, default []), createdAt, updatedAt }`
    - Las reacciones viven en el propio mensaje (se borran con él). Los emojis permitidos son una lista de validación (`ALLOWED_REACTIONS` en `chatHandler.ts`, espejo de `kReactionEmojis` en Dart), no un estado de negocio, por eso no lleva catálogo.
    - **Un usuario, un emoji por mensaje:** nunca hay dos entradas con el mismo `userId`. Elegir un emoji distinto sustituye al anterior; elegir el que ya tiene lo quita.

#### 5. DICCIONARIO DE EVENTOS WEBSOCKET (SOCKET.IO)

Todos los eventos deben estar tipados mediante Interfaces en TypeScript en el backend y Clases en Dart.

##### Dominio: Salas (Rooms)

- *(REST HTTP)* `POST /api/rooms` -> Crea sala, retorna `roomId` único (alfabeto sin caracteres ambiguos I/0/O).
- *(Emite Cliente)* `join_room`: `{ roomId, user: { id, name, avatarSeed? } }` -> El backend notifica a los 4 handlers: roomHandler (users), chatHandler (history), taskHandler (task_sync), pomodoroHandler (timer state).
- *(Emite Cliente)* `leave_room`: `{ roomId, userId }`.
- *(Emite Cliente)* `kick_user`: `{ roomId, hostId, userId }` -> Verifica que `hostId` coincide con el host en DB. Si es válido: emite `kicked` al usuario expulsado y `user_kicked` a todos.
- *(Emite Servidor)* `room_users_update`: `Array<{ id: string, name: string, avatarSeed: string }>` -> Broadcast a sala completa. También es la respuesta a `set_avatar` (el cliente reemplaza su `localUser` con la entrada de la lista que coincida con su id).
- *(Emite Cliente)* `set_avatar`: `{ roomId, userId, avatarSeed }` -> Elige la maceta a mano. El servidor valida que el usuario esté en la sala y que la seed sea de `AVATAR_SEEDS` y **no la tenga otra persona**; si está ocupada re-emite `room_users_update` para que el cliente se resincronice.

**Avatares por defecto:** al hacer `join_room` el servidor asigna a cada usuario un `avatarSeed` de `AVATAR_SEEDS` que nadie más de esa sala esté usando (al azar entre las libres; si se agotan las 23, usa el `userId`, que es único). Prioridad al entrar: **1)** la `avatarSeed` que manda el cliente, si es válida y está libre, **2)** la que ya tenía en `usersByRoom` (F5, reconexión dentro del periodo de gracia), **3)** una libre al azar. Al salir del mapa su seed queda libre. Sigue sin guardarse en Mongo: la elección vive en el dispositivo (pref `avatar_seed`) y viaja con el `join_room`, así que el servidor solo la valida. El cliente dibuja el avatar en el dispositivo con `avatarSvg(seed)` (estilo Sprouts de DiceBear, CC0, sin peticiones de red).
- *(Pendiente)* Con las 23 macetas consumidas no queda nada libre: no hay límite de personas por sala, así que en salas muy grandes el selector se queda sin opciones. Valorar un tope de participantes más adelante.
- *(Emite Servidor)* `kicked`: `{ roomId: string }` -> Solo al usuario expulsado.
- *(Emite Servidor)* `user_kicked`: `{ userId: string, userName: string }` -> Broadcast a sala completa.
- *(Manejo disconnect)* En `disconnect`: el socket se remueve automáticamente de todas las salas.

##### Dominio: Chat

- *(Emite Cliente)* `send_message`: `{ roomId, senderId, text }`. -> El backend guarda en DB y emite `new_message` a la sala.
- *(Emite Cliente)* `get_chat_history`: `{ roomId }`.
- *(Emite Servidor)* `chat_history`: `ChatMessage[]` -> Solo al socket que lo solicitó.
- *(Emite Servidor)* `new_message`: `{ id, roomId, senderId, senderName, text, timestamp, reactions }` -> Broadcast a sala.
- *(Emite Cliente)* `toggle_reaction`: `{ roomId, messageId, userId, emoji }`. -> Solo acepta emojis de `ALLOWED_REACTIONS` (🚀 🔥 🍅), un `messageId` válido de esa sala y un `userId` que esté en ella. Alterna la reacción del usuario con operaciones atómicas de Mongo (`$pull` / `$addToSet` / `$push`) y limpia los emojis que quedan sin usuarios. Como solo se admite una reacción por usuario y mensaje, al añadir primero lo saca de los otros emojis del mensaje: elegir uno nuevo **mueve** el anterior en vez de acumularlo. Tocar el emoji que ya tiene lo quita. El `$` posicional de `$pull` solo toca el primer elemento, así que esa limpieza se repite en bucle (con tope `ALLOWED_REACTIONS.length`) hasta que no queden; de paso, los mensajes guardados con duplicados de antes se van corrigiendo solos.
- *(Emite Servidor)* `message_reactions`: `{ roomId, messageId, reactions: [{ emoji, userIds }] }` -> Broadcast a sala con el estado completo de ese mensaje (el cliente reemplaza, no suma).
- *(Emite Cliente)* `typing`: `{ roomId, userId, isTyping: boolean }`. -> Efímero: no se guarda.
- *(Emite Servidor)* `user_typing`: `{ roomId, userId, userName, isTyping }` -> A la sala **excepto** a quien escribe (`socket.to(roomId)`).

**Indicador "escribiendo" (frontend):** `ChatNotifier.notifyTyping(bool)` emite `typing` al empezar, se reenvía cada 3 s mientras se sigue tecleando (`typingResend`) y emite `false` al vaciar el campo, al enviar o al cerrar el chat. Quien recibe guarda `typingUsers` (id -> nombre) y lo caduca a los 5 s sin renovación (`typingExpiry`), por si el otro se desconecta sin avisar. Un `new_message` de esa persona también lo quita.

##### Dominio: Tareas (Tasks)

- *(Emite Cliente)* `add_task`: `{ roomId, title }`.
- *(Emite Cliente)* `update_task_status`: `{ roomId, taskId, newStateRef }`.
- *(Emite Cliente)* `delete_task`: `{ roomId, taskId }`.
- *(Emite Cliente)* `edit_task`: `{ roomId, taskId, title }`.
- *(Emite Servidor)* `task_sync`: Retorna el array completo de tareas con `stateCode` y `stateLabel` resueltos. Broadcast a sala.

**Detección de nuevas tareas (frontend):** El provider compara IDs de la lista anterior vs la nueva en `task_sync`. Si hay IDs nuevos y no es una acción local (`_pendingLocalAdd`), incrementa `newTaskCount` y muestra notificación.

##### Dominio: Pomodoro (Regla: El Servidor es la Fuente Única de Verdad)

- *(Emite Cliente)* `pomodoro_action`: `{ roomId, action: 'START' | 'PAUSE' | 'RESET' | 'SKIP' | 'SET_MODE', duration?: number, mode?: 'FOCUS' | 'SHORT_BREAK' | 'LONG_BREAK' }`.
- *(Backend Logic)* El servidor gestiona un mapa en memoria `Map<roomId, PomodoroSession>`. Maneja el `setInterval` de 1000ms. `duration` es opcional (default 30 min = 1800s) y solo aplica en modo `FOCUS`; los descansos son fijos (corto 5 min, largo 15 min).
- *(Modos / Descansos)* Al terminar una fase el servidor prepara la siguiente **en pausa**: estudio -> descanso corto (cada 4 rondas, descanso largo); descanso -> estudio. `SKIP` (flecha ⏭) adelanta a la siguiente fase y, si el reloj corría, la inicia de inmediato. `SET_MODE` cambia de modo manualmente (pausa el reloj).
- *(Emite Servidor)* `timer_tick`: `{ roomId, timeRemaining: number, totalSeconds: number, status: string, mode: string, completedFocus: number }`. Flutter **solo** dibuja este `timeRemaining`.
- *(Emite Servidor)* `pomodoro_finished`: `{ roomId, totalSeconds: number, mode: string }` -> Emite cuando el timer llega a 0 (`mode` = fase que terminó).

##### Matriz Completa de Eventos

| Evento | Cliente -> Servidor | Servidor -> Cliente |
|--------|:---:|:---:|
| `join_room` | EMIT | HANDLED (4 handlers) |
| `leave_room` | EMIT | HANDLED (roomHandler) |
| `kick_user` | EMIT | HANDLED (roomHandler) |
| `set_avatar` | EMIT | HANDLED (roomHandler) |
| `disconnect` | auto | HANDLED (roomHandler + index) |
| `room_users_update` | -- | EMIT (broadcast sala) |
| `kicked` | -- | EMIT (solo expulsado) |
| `user_kicked` | -- | EMIT (broadcast sala) |
| `send_message` | EMIT | HANDLED (chatHandler) |
| `get_chat_history` | EMIT | HANDLED (chatHandler) |
| `chat_history` | -- | EMIT (solo requestor) |
| `new_message` | -- | EMIT (broadcast sala) |
| `toggle_reaction` | EMIT | HANDLED (chatHandler) |
| `message_reactions` | -- | EMIT (broadcast sala) |
| `typing` | EMIT | HANDLED (chatHandler) |
| `user_typing` | -- | EMIT (sala, sin el emisor) |
| `add_task` | EMIT | HANDLED (taskHandler) |
| `update_task_status` | EMIT | HANDLED (taskHandler) |
| `delete_task` | EMIT | HANDLED (taskHandler) |
| `edit_task` | EMIT | HANDLED (taskHandler) |
| `task_sync` | -- | EMIT (broadcast sala) |
| `pomodoro_action` | EMIT | HANDLED (pomodoroHandler) |
| `timer_tick` | -- | EMIT (broadcast sala) |
| `pomodoro_finished` | -- | EMIT (broadcast sala) |

##### Inicio responsivo

- `HomeScreen` decide por ancho (`kLandingBreakpoint` = 960 px, en `landing_hero.dart`):
  - **≥ 960 (laptop, tablet horizontal):** el inicio es directamente `CreateRoomScreen(landing: true)`: a la izquierda `LandingHero` (panel de marca, token `brand`, con "StudyHub" en grande, la frase, 3 etiquetas y, si sobra alto, la animación del chico estudiando `STUDENT.json` directo sobre el verde, abajo y centrada, sin tarjeta) y a la derecha el formulario Crear / Unirte a la vista, sin clic intermedio. Si hay sesión restaurada, la misma pantalla pasa a la sala (no se empuja otra ruta).
  - **< 960 (celular, tablet vertical):** mismo lenguaje visual (panel verde, nombre grande, frase, etiquetas, animación) con el botón blanco "Crear o unirse a una sala", que abre `CreateRoomScreen` como ruta. Las piezas compartidas (`LandingBrandRow`, `LandingWordmark`, `LandingTagline`, `LandingFeatures`, `LandingIllustration`) viven en `landing_hero.dart`.

##### Sala rediseñada (paleta "Estudio" + iconos Lucide)

- `lib/ui/room/room_workspace.dart`: contenedor de la sala. Elige distribución por ancho (`RoomLayout`): **wide** ≥1100 (reloj · tareas · chat), **tablet** ≥700 (reloj + pestañas Tareas/Chat), **phone** (navegación inferior Foco/Tareas/Chat + mini reloj). El chat se puede ocultar (pref `chat_hidden`). En **wide** el chat se pliega a un **riel de 56 px** (`_ChatRail` en `room_workspace.dart`) que queda a la derecha con el botón para reabrirlo y el contador numérico de no leídos; el botón de plegar vive en la cabecera de la tarjeta del chat (`ChatBox(onCollapse:)`), no en el header. El chat sigue montado al plegarlo (conserva borrador y scroll) y el reloj mide siempre 440 px (las tareas absorben el cambio de ancho; ya no hay 50/50). En tablet y celular el chat es una pestaña: se cierra con una X (en tablet, junto a las pestañas Tareas/Chat mientras el chat está seleccionado; en celular, en el título del chat) y el botón del header sigue disponible para volver a mostrarlo.
- **Borde de la barra del chat (regla):** en `_buildChatColumn` el fondo, el borde y el radio los pinta el `AnimatedContainer` que se encoge, **no** un `RoomCard` ni un `Material` dentro. El contenido de ancho fijo (`OverflowBox`, 360 px, alineado a la izquierda) lo recorta el `ClipRRect`, así que una tarjeta con borde propio perdía su línea derecha en cuanto el ancho bajaba de 360 y se quedaba un corte sin borde; ahora el borde es del tamaño exacto de la barra y no se mueve nunca. Por el mismo motivo `_ChatRail` no lleva `Material` propio (solo el `InkWell`, con el `Material(type: transparency)` del contenedor como lienzo del ripple, recortado por el radio).
- `lib/ui/room/room_header.dart`: barra superior (salir, nombre, código, QR, avatares, chat [solo tablet y celular], botón de tema, ayuda) y hoja de miembros/invitación (`showRoomMembersSheet`, aquí el anfitrión expulsa y **tu propia fila abre `showAvatarPicker`**).
- `lib/ui/room/room_widgets.dart`: `RoomCard`, `RoomIconButton`, `RoomChip`, `RoomAvatar`, `RoomLayout`.
- Paleta de la sala: tokens de `AppColors` (un color por modo del reloj: estudio verde azulado, descanso corto ámbar, largo índigo), ver sección 8. Sin chat en laptop queda el riel y las tareas ocupan el resto.
- Iconos: Lucide, con fuente propia recortada. Se usan como `AppIcons.circleHelp` (camelCase del nombre Lucide). `lib/core/app_icons.dart` y `assets/fonts/Lucide.ttf` se generan con `python3 tool/gen_icons.py` (requiere `pip install fonttools`) a partir de los `AppIcons.*` que aparecen en el código. No se usa el paquete `lucide_icons_flutter`: declaraba 7 fuentes (3.7 MB) que el navegador descargaba al arrancar.

##### Rendimiento (web)

- **Fuentes:** `assets/fonts/*` están recortadas por `tool/subset_fonts.sh` (originales en `tool/fonts/original`): Recursive con solo los ejes `wght` y `slnt` y glifos Latin (2.4 MB → 0.43 MB), Cascadia con ASCII (0.74 MB → 0.08 MB). Hay que conservar la característica `rvrn` (elige el cero liso). Solo se declaran los pesos usados (400-800); cada entrada del `pubspec` es una descarga y una copia en memoria.
- **Animaciones Lottie:** siempre con `frameRate: FrameRate.composition` (12 y 25 fps en lugar de 60) y dentro de un `RepaintBoundary`, para que no repinten el resto de la pantalla en cada cuadro. En celular, las secciones fuera de vista se pausan con `TickerMode`.
- **Reconstrucciones:** `ref.watch(x.select(...))` para observar solo lo que se dibuja (chat, no leídos). Tareas con `ValueKey(taskId)`.
- **InactivityDetector:** guarda una marca de tiempo por evento y revisa cada 30 s; antes creaba un `Timer` por cada evento de puntero.
- **Backend:** el catálogo de estados de tarea se lee una vez y se guarda en memoria; tras guardar una tarea se reutiliza la sala ya cargada (de 5 consultas a 2 por acción). El historial del chat devuelve los 100 mensajes más recientes (antes los más antiguos) con índice `{roomId, timestamp}`.
- `PomodoroTimer`, `TaskList` y `ChatBox` ya no dibujan su propia tarjeta: van dentro de `RoomCard`. Requieren alto acotado.

#### 6. PROVIDERS Y ESTADO (RIVERPod)

| Provider | StateNotifier | State Fields | Archivo |
|----------|---------------|-------------|---------|
| `roomProvider` | `RoomNotifier` | `room: Room?`, `localUser: User?`, `users: List<User>`, `isCreating: bool`, `isRestoring: bool`, `error: String?` | `room_provider.dart` |
| `chatProvider` | `ChatNotifier` | `messages: List<Message>`, `isLoadingHistory: bool`, `error: String?`, `unreadCount: int`, `typingUsers: Map<String, String>` | `chat_provider.dart` |
| `taskProvider` | `TaskNotifier` | `tasks: List<Task>`, `error: String?`, `newTaskCount: int`, `lastAddedTaskTitle: String?` | `task_provider.dart` |
| `pomodoroProvider` | `PomodoroNotifier` | `timeRemaining: int` (1800), `totalSeconds: int` (1800), `status: String` ('PAUSED'), `isFinished: bool`, `mode: String` ('FOCUS'), `completedFocus: int` (0), `finishedMode: String?` | `pomodoro_provider.dart` |
| `socketServiceProvider` | -- (Provider) | `WebSocketService` | `socket_provider.dart` |
| `soundProvider` | `SoundNotifier` | `isEnabled: bool` (true) | `sound_service.dart` |
| `themeProvider` | `ThemeNotifier` | `ThemeMode` (`system` por defecto; `light` / `dark` tras elegir) | `theme_provider.dart` |
| `initialThemeModeProvider` | -- (Provider) | `ThemeMode` leído de preferencias antes de `runApp`; `main` lo sobrescribe | `theme_provider.dart` |

**Regla:** Ningún widget de UI debe hacer llamadas directas a Socket.io. Todo pasa por providers.

**Chat State extra:** `_isChatVisible` (bool, privado en Notifier) + `setChatVisible(bool)` + `clearUnread()`. El `unreadCount` se incrementa cuando llega `new_message` y el chat no es visible.

**Chat reacciones / escribiendo:** `toggleReaction(messageId, emoji)` (valida contra `kReactionEmojis`) y `notifyTyping(bool)`. Escuchan `message_reactions` (reemplaza las reacciones de ese mensaje) y `user_typing`. Reaccionar no cuenta como mensaje no leído. El selector marca un solo emoji por mensaje: `_MessageItem` resuelve la reacción propia como `String?` (el primero de `kReactionEmojis` que contenga al usuario local), así que un mensaje con datos viejos duplicados nunca muestra dos emojis activos a la vez.

**Tema:** `themeProvider` guarda solo el `ThemeMode`; `toggle(isDark:)` recibe el brillo efectivo en pantalla (no el guardado), así el botón es un interruptor de dos estados aunque el usuario aún siguiera al sistema. La elección se persiste en `SharedPreferences` (`theme_mode`). `main.dart` lee la preferencia **antes** de `runApp` para que el primer frame ya salga con el tema correcto (sin destello claro).

**Room State extra (avatares):** `setAvatarSeed(seed)` devuelve `String?` con el nombre de quien ya tiene esa maceta (y en ese caso no emite), o `null` si se aplicó. Actualiza `localUser` al instante, emite `set_avatar` y guarda la pref `avatar_seed`. `room_users_update` **también** reemplaza `localUser` por la entrada de la lista con el mismo id (si no aparece, se conserva el anterior): sin eso el usuario local nunca vería su propio avatar. `_joinRoom` manda `avatarSeed` (la de `localUser` o la de la pref) para no empezar con una maceta al azar.

**Task State extra:** `_pendingLocalAdd` (bool, privado en Notifier) + `consumeNewTask()`. Permite distinguir tareas agregadas por el usuario local vs remotas, para no mostrar notificación en tareas propias.

**Room State extra:** `leaveRoom()` emite `leave_room` y limpia sesión local. `kickUser(userId)` emite `kick_user` con verificación de host.

#### 7. MODELOS DE DATOS (DART)

| Modelo | Campos | Notas |
|--------|--------|-------|
| `User` | `id: String`, `name: String`, `avatarSeed: String?` | Factory `generateLocal(name)` genera ID con timestamp + random. `avatarSeed` lo pone el servidor o lo elige el usuario (nula con un servidor viejo: `RoomAvatar` cae a las iniciales). `copyWith({name, avatarSeed})` |
| `Room` | `roomId: String`, `name: String`, `hostId: String` | |
| `Message` | `id: String`, `roomId: String`, `senderId: String`, `senderName: String`, `text: String`, `timestamp: DateTime`, `reactions: Map<String, List<String>>` | `.toLocal()` en factory. `isOwn(userId)` helper. `reactionsFromJson` tolera servidores sin el campo. `copyWith(reactions:)` |
| `Task` | `taskId: String`, `title: String`, `stateCode: String`, `stateLabel: String`, `createdAt: DateTime?` | |

#### 8. DISEÑO VISUAL (THEME)

**Paleta y modo oscuro:** definidos en `core/theme.dart` como `AppColors`, una `ThemeExtension` con dos instancias constantes: `AppColors.light` y `AppColors.dark`. `buildTheme(Brightness)` construye el `ThemeData` de cada una y `main.dart` los pasa como `theme` / `darkTheme` con el `themeMode` de `themeProvider`.

- **Regla:** la UI nunca usa `Color(0x...)` ni `Colors.*` sueltos para superficies, texto o acentos. Pide el token al contexto: `final c = context.colors;` (un solo `context.colors` por método `build`). Ya no existen los `kColor*` ni los `kRoom*`.
- **Métodos auxiliares sin contexto** (en un `State`): getter `AppColors get c => context.colors;`. En un `CustomPainter`, el color se pasa por parámetro.
- **Tokens:** neutros `bg`, `surface`, `ink`, `muted`, `line`, `track`, `ringTrack`, `disabled`; modos del reloj `study` / `studySoft`, `rest` / `restSoft` / `restInk`, `longRest` / `longRestSoft`; errores `error` / `errorSoft` / `errorLine`; `sageMid`; `onAccent` (texto e iconos SOBRE `study`, `rest` o `longRest`: en oscuro los acentos son claros, así que es un verde casi negro; nunca usar `Colors.white` ahí); `snackBg` / `snackText`; `shadow`; `brand` (panel de marca del inicio). `modeColor(mode)` y `modeSoft(mode)` resuelven el color según la fase.
- **Excepciones legítimas:** el QR va en blanco fijo (debe poder escanearse), el texto del panel de marca es blanco sobre `brand` (verde profundo en ambos modos) y la pantalla de error global de `main.dart` usa `AppColors.light` porque se dibuja cuando el árbol ya falló.
- **Al añadir un color:** agregarlo al constructor, `light`, `dark`, `copyWith` y `lerp` de `AppColors`. Los dos valores deben tener contraste suficiente (texto normal 4.5:1) contra su fondo.
- **Botón de tema:** `ThemeToggleIconButton` (superficies del tema; header de la sala, barra de "Crear o unirse" y panel del formulario en laptop), `ThemeTogglePillButton` (sobre el panel de marca del inicio en celular) y `ThemeToggleRow` (con etiqueta, hoja de miembros en celular). El icono muestra el DESTINO: luna en claro, sol en oscuro. Solo hacen `ref.read`; el color lo toman del tema, no se suscriben al provider.
- **Avatares:** `RoomAvatar(name, index, seed?)` dibuja el SVG de `avatarSvg(seed)` dentro de un círculo cuyo fondo sale de los tokens (`paletteOf(c)[index % 4]`), por eso se ve bien en claro y oscuro. El SVG se genera SIN fondo propio (`backgroundColor: []`; DiceBear trae uno saturado distinto por seed que chocaría con la paleta) y sin `<metadata>` (flutter_svg avisa por consola). Sin `seed` muestra las iniciales. Tiene `Semantics(label: name)`.
- **Avatares en el chat:** `_MessageItem` pone el `RoomAvatar` del emisor **fuera** del `GestureDetector` de la burbuja (si no, el tap abriría las reacciones), en el lado exterior según quién escribe, y solo en el primer mensaje de cada racha (`showHeader`: cambia de `senderId`). El nombre va dentro de la burbuja: `"Tú"` si es propia, si no el de quien envía, con `onAccent` al 75% sobre el verde de la propia (el `muted` no contrasta ahí). Seed e índice salen de `roomProvider.users`, observado con `select` (solo cambia al entrar, salir o cambiar un avatar). Tocar **tu** avatar abre el selector; el ajeno no es interactivo. `_MessageAvatar` es de 36 px: la vía accesible de verdad es la fila propia de la hoja de miembros.
- **Selector de avatar:** `avatar_picker.dart` → `showAvatarPicker(context)`. Rejilla de las 23 `kAvatarSeeds` (3-5 columnas según ancho); la tuya con anillo `study` y check, las de otra persona atenuadas, sin `InkWell` y con tooltip/semantics de quién las tiene (los avatares siguen siendo únicos por sala). Se aplica al tocar y cierra; si el `setAvatarSeed` devuelve el nombre de quien la bloquea, avisa con `showCustomNotification` y no cierra.
- **Barra de estado:** `MaterialApp.builder` envuelve la app en `AnnotatedRegion<SystemUiOverlayStyle>` según el brillo activo.
- Nuevos componentes de UI (reacciones, indicador de escritura, papelera de tareas, mascota) siguen la misma regla y tienen pruebas en claro y oscuro.

**Tokens de tamaño de fuente (`AppType`):**
- `sizeMicro`: 10
- `sizeCaption`: 12
- `sizeLabel`: 13
- `sizeBody`: 14
- `sizeBodyMedium`: 15
- `sizeBodyLarge`: 16
- `sizeTitle`: 20
- `sizeHeadline`: 22
- `sizeDisplay`: 28
- `sizeHero`: 40
- `sizeGiant`: 48
- `sizeTimerCompact`: 38
- `sizeTimerDisplay`: 44
- `sizeTimerLarge`: 56

**Weights:** `weightRegular` (400), `weightMedium` (500), `weightSemiBold` (600), `weightBold` (700).

**Métodos de estilo:**
- `AppType.secondaryItalic({required context, size, color})` - Texto secundario cursiva; el `color` por defecto sale del tema (`muted`)
- `AppType.monoTimer({required context, fontSize, color})` - Fuente monoespaciada para timers; `color` por defecto `ink` del tema

**Fuentes:** `Recursive` (variable, 100-900) como fuente principal, `Cascadia Code` como monoespaciada.

#### 9. PLATAFORMA Y PERMISOS

- **iOS** (`Info.plist`): `NSCameraUsageDescription` = "StudyHub necesita acceso a la camara para escanear codigos QR de salas."
- **Android** (`AndroidManifest.xml`): `android.permission.CAMERA`
- **iOS Audio:** `audioplayers` requiere `AudioContext(iOS: AudioContextIOS(category: AVAudioSessionCategory.playback))` para reproducir audio en modo silencio. Esto se configura en el constructor de `sound_service.dart` y en `unlock()`.
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

**Notificación de tareas nuevas:** Banner animado (`AnimatedSize`) en `_buildWorkspace`, debajo del header de usuarios. Muestra "Nueva tarea: [nombre]" con `showCustomNotification` (fondo `snackBg`, texto `snackText`). Auto-dismiss después de 3 segundos.

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
| **Sound unlock (edit)** | `sound_service.dart`, `inactivity_detector.dart` | `unlock()` prima los dos reproductores (alarma y aviso) con un clip mudo en el primer toque de cualquier parte de la app (`InactivityDetector`), no solo al pulsar Iniciar; si falla se reintenta en el siguiente toque. Un reproductor por tipo de sonido para que no se pisen |
| **Sonido por fase + silenciar** | `sound_service.dart`, `pomodoro_provider.dart`, `pomodoro_timer.dart` | `playPomodoroFinishedSound(focusFinished:)` elige la campana según la fase que terminó; botón de volumen en la esquina del reloj (`_SoundToggle`) |
| **Pomodoro bottom sheet (edit)** | `pomodoro_timer.dart` | `_promptCustomDuration` en `showModalBottomSheet` con `AnimatedPadding` (sigue al teclado), sin `SingleChildScrollView`, input numérico (`digitsOnly`, max 3). Fix salto iOS al abrir |
| **Traspaso de dueño** | `roomHandler.ts`, `room_provider.dart`, `room_model.dart` | Al irse el dueño y quedar 1+ usuario, el 1ro que se queda pasa a ser dueño (Mongo + evento `host_transferred`) |
| **Eliminar sala vacía** | `roomHandler.ts` | Al quedar 0 usuarios conectados se borra `Room` + `Message` del chat |
| **Modo oscuro** | `theme.dart`, `theme_provider.dart`, `theme_toggle.dart`, `main.dart` | `AppColors` claro/oscuro, `themeProvider` persistido, lectura previa a `runApp`, botón en header de sala, inicio (celular y laptop), "Crear o unirse" y hoja de miembros. Ver sección 8 |
| **Reacciones rápidas** | `chat_box.dart`, `chat_provider.dart`, `message_model.dart`, `chatHandler.ts`, `Message.ts` | Tocar un mensaje abre un selector con 🚀 🔥 🍅; chips con cuenta bajo el mensaje (resaltado si es tuya, tocar alterna). Una sola reacción por usuario y mensaje: elegir otro emoji mueve la anterior. Alternar atómico en Mongo y `message_reactions` a la sala |
| **Indicador "escribiendo"** | `chat_box.dart`, `chat_provider.dart`, `chatHandler.ts` | "Ana está escribiendo" / "Ana y Marco..." / "Varios..." con puntos animados sobre el campo; eventos `typing` / `user_typing`, caduca a los 5 s |
| **Avatares por defecto** | `avatars.dart`, `room_widgets.dart`, `user_model.dart`, `avatarSeeds.ts`, `roomHandler.ts` | Macetas "Sprouts" de DiceBear asignadas por el servidor, únicas por sala y estables al reconectar; render local sin red (`dicebear_core` + `flutter_svg`), caché por seed y precalentamiento tras el primer cuadro. Ver sección 5 |
| **Elegir avatar a mano** | `avatar_picker.dart`, `room_header.dart`, `chat_box.dart`, `room_provider.dart`, `avatarSeeds.ts` | Desde tu fila en la hoja de miembros o tocando tu avatar en el chat. Solo ofrece las macetas libres de la sala, se guarda en el dispositivo (pref `avatar_seed`) y viaja en el `join_room`, así que no se persiste en Mongo. Con las 23 ocupadas no queda ninguna: pendiente valorar un límite de personas por sala |
| **Papelera de tareas** | `task_list.dart` | Al arrastrar una tarea aparece una papelera; soltarla encima pide confirmación y elimina (no reordena) |
| **Mascota reactiva** | `pomodoro_mascot.dart`, `pomodoro_timer.dart` | El cangrejo del dial cambia según `moodFor(PomodoroState)`: quieto en pausa, rebote en foco, lento con "zzz" en descanso, salto al terminar. `kMascotAssets` permite dar un Lottie propio a cada ánimo |

#### 12. REGLAS DE CODIFICACIÓN

- **Flutter:** `flutter analyze` debe pasar con 0 errores siempre, y `flutter test` con todo en verde.
- **Backend:** `tsc --noEmit` debe pasar con 0 errores siempre.
- **Sin comentarios** en el código a menos que el usuario lo pida explícitamente.
- **Sin emojis** en archivos a menos que el usuario lo pida. Excepción pedida: los emojis de reacción (🚀 🔥 🍅) en `kReactionEmojis` y `ALLOWED_REACTIONS`, y sus pruebas.
- **Colores:** nunca hardcodeados en la UI; siempre `context.colors.<token>` (ver sección 8). Toda pantalla o widget nuevo debe verse bien en claro y oscuro.
- **Naming:** `snake_case` para archivos, `camelCase` para variables/métodos, `PascalCase` para clases.
- **Variables privadas:** Prefijo `_` (e.g. `_socketService`, `_pendingLocalAdd`).
- **Constants:** Prefijo `k` (e.g. `kDefaultPomodoroSeconds`, `kReactionEmojis`). Los colores NO son constantes `k*`: son tokens de `AppColors`.
- **IDs de usuario local:** Se generan con `User.generateLocal(name)` usando timestamp + random.
- **Código de sala:** 6 caracteres de `'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'` (sin I/0/O).
- **Room host:** `hostId` se guarda en MongoDB Room model y se usa para permisos de kick. Si el dueño sale y quedan usuarios, el cargo se transfiere al 1ro que se queda (`host_transferred`).
- **Sala vacía:** Si quedan 0 usuarios conectados (`usersByRoom`), la sala y sus mensajes se eliminan de Mongo automáticamente (`handleRoomAfterLeave`).
- **Users in-memory:** Se trackean en `usersByRoom` Map (keyed by socket `id`), no persistidos.
- **Audio iOS:** Requiere `AudioContext` con `AVAudioSessionCategory.playback` para funcionar en silencio.
- **PopScope:** Usado en `create_room_screen.dart` para interceptar back button cuando hay sala activa.
- **`addPostFrameCallback`:** Siempre usar antes de `showSnackBar` o `setState` en `ref.listen` para evitar errores de build phase.
- **`AnimatedSize`:** Usado para banners de notificación con transiciones suaves.
