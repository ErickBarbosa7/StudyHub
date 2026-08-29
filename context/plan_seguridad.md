# Plan de Endurecimiento de Seguridad — StudyHub

**Objetivo:** Mantener la funcionalidad actual (crear/unirse a salas, chat, tareas, pomodoro) pero eliminar vulnerabilidades críticas para desplegar de forma segura en producción. Documentado como hoja de ruta por fases, listo para ejecutarse.

**Stack afectado:** Backend Node.js/Express/Socket.io (`B_StudyHub`), Frontend Flutter (`F_StudyHub`), MongoDB (Docker), despliegue (Render + Netlify).

---

## Estado actual — Vulnerabilidades detectadas

| # | Severidad | Problema | Archivo(s) |
|---|-----------|----------|-----------|
| 1 | 🔴 Crítico | Sin autenticación ni control de acceso en WebSocket; cualquier cliente opera salas con solo el código de 6 chars y puede suplantar `senderId` | `src/sockets/*`, `F_StudyHub/lib/data/services/websocket_service.dart` |
| 2 | 🔴 Crítico | CORS abierto `*` en Express y Socket.io | `src/index.ts:16-20`, `B_StudyHub/.env` |
| 3 | 🔴 Crítico | Sin rate limiting (spam/DoS en `POST /api/rooms`, `send_message`, etc.) | `src/index.ts`, `src/sockets/*` |
| 4 | 🔴 Crítico | Sin límite de tamaño de body (`express.json()` sin `limit`) | `src/index.ts:21` |
| 5 | 🟠 Alto | Sin cabeceras de seguridad HTTP (no hay `helmet`) | `src/index.ts` |
| 6 | 🟠 Alto | Mongo sin credenciales y puerto expuesto al host | `docker-compose.yml`, `src/config/database.ts` |
| 7 | 🟠 Alto | URLs de producción hardcodeadas en `netlify.toml` | `netlify.toml` |
| 8 | 🟡 Medio | Validación de inputs incompleta en payloads de socket | `src/sockets/*` |
| 9 | 🟡 Medio | Sin logging/observabilidad de seguridad | `src/*` |
| 10 | 🟡 Medio | Sesiones en `shared_preferences` sin cifrar | `F_StudyHub/lib/logic/room_provider.dart` |

---

## Fase 1 — Transporte HTTP (backend `B_StudyHub`)

1. **`helmet`**: añadir dependencia y `app.use(helmet())` → `X-Content-Type-Options`, `X-Frame-Options`, CSP, HSTS, `Referrer-Policy`.
2. **Límite de body**: `app.use(express.json({ limit: '10kb' }))`.
3. **CORS cerrado**: lista blanca configurable; reemplazar `app.use(cors())` y `origins: '*'` del `Server` de Socket.io por el origen de producción (Netlify). Si `CORS_ORIGIN` es `*` en producción → fallar o rechazar.
4. **Rate limiting** (`express-rate-limit`):
   - `POST /api/rooms`: p. ej. `windowMs: 15min, limit: 50`.
   - API global: `limit: 300 / 15min`.
   - Opcional: límite por evento de socket (`send_message`, `add_task`).
5. **Manejo central de errores**: middleware final con status 500 tipado y `next(err)`.

---

## Fase 2 — Autenticación y autorización en WebSocket (token por usuario + pertenencia de sala)

**Modelo elegido:** al crear o unirse a una sala, el servidor emite un **token de sesión** (`sessionToken`) que el cliente guarda y envía en el handshake. Un middleware de socket.io valida el token y vincula el socket a un `roomId` y `userId` autenticados. Los handlers usan esa identidad, no la del payload del cliente.

1. **Servidor** (`src/index.ts`, nuevo `src/sockets/auth.ts`):
   - Generar token (crypto) al `createRoom`/`joinRoom` REST o en `join_room`.
   - `io.use((socket, next) => { ...validar token... })` que establece `socket.data.userId` y `socket.data.roomId`.
   - Almacén en memoria (`Map<token, { userId, roomId }>`) o token firmado (HMAC con `SESSION_TOKEN_SECRET`).
2. **Autenticación en handshake**: el cliente envía el token vía `transportOptions`/`auth` (socket_io_client lo soporta).
3. **Autorización en handlers**:
   - `send_message`: usar `socket.data.userId` como `senderId` (ignorar el enviado por el cliente) → elimina suplantación.
   - `join_room`: validar pertenencia.
   - `leave_room`, `kick_user`, `add_task`, `update_task_status`, `delete_task`, `edit_task`, `pomodoro_action`: verificar `roomId` del socket contra lo autenticado.
4. **Cliente Flutter**: `WebSocketService` guarda y reenvía el token; manejo de reconexión reemitiéndolo.

---

## Fase 3 — Configuración segura de Mongo y despliegue

1. **`docker-compose.yml`**: quitar el mapeo del puerto `27017` al host (o solo `127.0.0.1:27017:27017`) y definir `MONGO_INITDB_ROOT_USERNAME` / `MONGO_INITDB_ROOT_PASSWORD` (env).
2. **`src/config/database.ts`**: exigir `MONGODB_URI` en producción (falla si ausente) y soportar `mongodb+srv://` con credenciales.
3. **`.env.example`** (nuevo, sin secretos reales): documentar `PORT`, `MONGODB_URI`, `CORS_ORIGIN`, `SESSION_TOKEN_SECRET`, credenciales de Mongo.
4. **`netlify.toml`**: reemplazar las URLs inline por variables de entorno del build (`--dart-define=API_URL=${API_URL}`), gestionadas como env vars/secretos en Netlify y Render.
5. **Frontend web**: añadir `_headers` con CSP y cabeceras de seguridad.

---

## Fase 4 — Validación y observabilidad

1. **Validación de payloads** con `zod` (schemas para `join_room`, `send_message`, `add_task`, `update_task_status`, `delete_task`, `edit_task`, `pomodoro_action`) y sanitización de nombres/textos.
2. **Logging estructurado** (p. ej. `pino`): registrar eventos de seguridad, intentos fallidos de autenticación, kicking y desconexiones.
3. **Auditoría**: `npm audit` y revisión de dependencias (`typescript@7`, `express@5`, `mongoose@9`).

---

## Fase 5 — Seguridad del frontend (Flutter)

1. `flutter_secure_storage` para `session_room_id` / `session_user_id` / token en lugar de `shared_preferences`.
2. Endurecer `F_StudyHub/web/index.html` y `_headers` (CSP).
3. Manejo de errores de conexión/autenticación con mensajes amigables.

---

## Verificación posterior

- Backend: `npx tsc --noEmit`, `npm audit`, pruebas manuales de `/health` y `POST /api/rooms`.
- Frontend: `flutter analyze`.
- Probar flujos: crear sala, unirse, chat, tareas, pomodoro; verificar que un cliente sin token no pueda operar.

---

## Notas de alcance

- La **Fase 2** (token en WebSocket) es la única que cambia el diseño del flujo cliente/servidor y toca archivos de socket + cliente Flutter.
- Fases 1, 3, 4 y 5 endurecen sin cambiar funcionalidad ni arquitectura.
- Reglas de codificación a respetar (según `instrucciones.md`): `flutter analyze` 0 errores, `tsc --noEmit` 0 errores, sin comentarios salvo petición explícita.
