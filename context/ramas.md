#### FLUJO DE TRABAJO CON RAMAS

Este proyecto usa **3 ramas de vida larga** (`main`, `dev`) y **ramas cortas por tema**. El objetivo no es burocracia: es poder trabajar sin miedo, poder probar y poder volver atrás. Antes trabajábamos todo sobre `main`, así que un error de medio día llegaba directo a producción sin forma de separar "lo terminado" de "lo que estaba experimenting".

```
main    A───B──────────────────M1        producción (cada M = un deploy de Netlify)
          \                  /
dev        C──D──E──F──G────H             integración (todo lo terminado y probado)
              \        /
feature/x       J──K                       1-3 días, un solo tema
```

##### Las reglas

1. **`main` es producción.** Siempre desplegable. Nunca recibe push directo, ni siquiera el tuyo. Solo cambia por un PR desde `dev`.
2. **`dev` es la integración.** Ahí llega todo lo terminado, con sus checks en verde. Nunca se despliega.
3. **Una rama por tema y de 1 a 3 días.** Si dura más, está haciendo dos cosas: divídela. Si dura horas y es una corrección, es `fix/`.
4. **Toda rama nace de `dev`** y se fusiona en `dev`. La única excepción es `hotfix/`, que nace de `main`.
5. **Se borra la rama al fusionar.** Una rama sin abrir PR no existe; para lo experimental, `git switch dev && git branch -D feature/x`.
6. **`dev` nunca se reescribe.** Ni `reset`, ni `rebase` sobre lo ya publicado. Su historia es la historia de lo que se va a producción.
7. **Nada entra a `dev` sin los 3 checks en verde** (sección 5).

##### Tipos de rama

| Prefijo | Para qué | Nace de | Va a | Dura |
|---|---|---|---|---|
| `feature/` | Funcionalidad nueva | `dev` | `dev` | 1-3 días |
| `fix/` | Corrección de un bug | `dev` | `dev` | Horas |
| `refactor/` | Reordenar sin cambiar comportamiento | `dev` | `dev` | 1-2 días |
| `docs/` | Documentación (este archivo) | `dev` | `dev` | - |
| `hotfix/` | **Producción rota** | `main` | `main` y `dev` | Lo antes posible |

El prefijo va en inglés (es la convención estándar) y la descripción en español sin tildes, igual que tus mensajes: `feature/avatares-manuales`, `fix/overflow-sala-320`, `docs/ramas`. Un tema, un nombre: si el nombre necesita un "y", son dos ramas.

##### El ciclo, paso a paso

**1. Empezar un tema.** `dev` siempre al día antes de crear la rama:

```bash
git switch dev
git pull
git switch -c feature/avatares-manuales
```

**2. Trabajar.** Commits pequeños y con mensaje `tipo: resumen` (`feature: selector de avatares`). El prefijo es `feature`, `fix`, `refactor`, `docs` o `chore`. Commit frecuente: la rama es tu red de seguridad, y una rama abandonada con 20 commits es trabajo perdido.

**3. Antes de abrir el PR, los 3 checks** (sección 5). En local, no en el PR: si algo falla, lo arreglas antes de que GitHub te lo recuerde.

**4. Publicar la rama:**

```bash
git push -u origin feature/avatares-manuales
```

**5. Abrir el pull request** contra `dev` (no contra `main`):

```bash
gh pr create --base dev --title "feature: selector de avatares" --body "$(cat <<'EOF'
## Qué cambia
Selector de macetas para cambiar el avatar desde la hoja de miembros.

## Por qué
No había forma de elegir avatar; el servidor lo sortea al entrar.

## Cómo lo probé
- cd F_StudyHub && flutter analyze
- cd F_StudyHub && flutter test
- cd B_StudyHub && npm run typecheck
EOF
)"
```

**6. Revisarlo.** Un PR es la única vez que lees tu propio código como lo leerá otra persona. Tienes comandos para no abrir el navegador: `gh pr diff`, `gh pr view`, `gh pr checks`. Si eres de navegador, el link sale en la salida del `gh pr create`.

**7. Fusionar**, siempre con *Squash and merge* + *Delete branch* (o desde terminal, `gh pr merge --squash --delete-branch`). El squash deja un commit por feature en `dev`: tu log se lee como una lista de cambios, no como 40 commits de "arreglando cosas".

**8. Publicar a producción.** Cuando quieras que algo llegue a `main` (y por tanto a Netlify), se abre un PR de `dev` a `main` y **se fusiona con "Create a merge commit", NO con squash**:

```bash
gh pr create --base main --head dev --title "release: avatares y reacciones" --body "Todo lo que lleva un tiempo probado en dev."
```

Aquí el squash está prohibido: aplastaría en un solo commit todo lo que lleva en `dev`, y el siguiente release repetiría el mismo diff porque `main` y `dev` dejarían de compartir historia. El merge commit no se puede evitar, y es el precio de tener las dos ramas.

**9. Volver a `dev`:** `git switch dev && git pull`. `main` ya tiene lo tuyo; no hace falta hacer nada más en local.

##### Pull requests en 30 segundos

Un PR **no** es un push: es una propuesta de cambio que se revisa antes de entrar. Con una rama, haces 20 commits privados; con un PR, esos commits se convierten en 1 cambio legible con descripción, contexto y checks, y hasta que tú no lo fusionas, `dev` no cambia.

- **Push**: manda commits directo a una rama. En `dev` y `main` está bloqueado por protección, así que GitHub lo va a rechazar. Eso es intencional.
- **PR**: propone el cambio. Al fusionarlo, entra en la rama destino.
- **Pull request = revisión de ti mismo.** No hay equipo que te revise, pero el formato obliga a escribir el porqué, que es justo lo que se te olvida a las 2 de la mañana. Leer el PR con ojos frescos encuentra bugs que 8 commits seguidos no ven.
- **Checks**: si se configuran, GitHub no te deja fusionar si fallan. En este repo los corres en local (sección 5).
- **Si el PR quedó viejo**, la rama ya no parte de `dev`: `git switch feature/x && git rebase dev` y `git push --force-with-lease`. Con protección de force-push activada, `--force-with-lease` es el único que GitHub acepta, y es seguro (rechaza si alguien más empujó).

##### Los 3 checks antes de cada PR

| Comando | Qué atrapa |
|---|---|
| `cd F_StudyHub && flutter analyze` | Imports rotos, widgets `const` que no deberían, null-safety, estilo. Es el más rápido y el que másaste. |
| `cd F_StudyHub && flutter test` | Overflows de layout, regresiones de UI, la lógica de los providers. 122 tests, ~7 s. |
| `cd B_StudyHub && npm run typecheck` | Los tipos del servidor (los eventos de socket no los atrapa Flutter). |

En el Pull Request se escriben los tres en "Cómo lo probé", aunque ya hayan pasado: si algo falla dos semanas después, esa línea es lo primero que vas a buscar.

##### Si algo sale mal

| Situación | Qué hacer |
|---|---|
| Te equivocaste de rama o la experimentación salió mal | `git switch dev && git branch -D feature/x`. El trabajo no fusionado se pierde, por eso los commits frecuentes. |
| Commit en la rama equivocada | `git reset --soft HEAD~1` y commitea en la rama correcta. Conserva los cambios en el índice. |
| Cambios sin commitear que no quieres | `git restore .` (descarta) o `git stash` (los guarda para luego). |
| Conflictos al rebasear | `git rebase --abort` para volver atrás, y `git status` para ver qué se complicó, luego `git rebase --continue` o `git rebase --skip`. |
| `main` salió roto en producción | `git revert <sha>` y un PR del revert a `main` **y** a `dev`. Un revert crea un commit nuevo: reescribir `main` está prohibido y rompería lo ya desplegado. |
| Te quedaste sin espacio | `git branch -a` y `git branch -d <rama>`; las que ya se fusionaron se borran solas con "Delete branch". |

##### Lo que nunca

- **Push directo a `main` o `dev`.** Está bloqueado. Si GitHub lo rechaza, es que saltaste un paso: abre un PR.
- **`reset --hard` en `main` o `dev`.** Lo ya publicado no se reescribe. En `main`, además, cada commit es un deploy.
- **`force-push` en `main` o `dev`.** Rompe la historia compartida y el deploy puede quedar desincronizado. Solo en tu rama, con `--force-with-lease`.
- **Un commit de 4000 líneas.** Son dos o tres temas; parte en commits lógicos (un commit = un cambio coherente).
- **Commits de relleno** ("wip", "prueba", "asdf"). El log es documentación; escribe qué y por qué.
- **Un tema por PR.** Si el PR mezcla refactor y feature, la revisión se vuelve imposible y el `git bisect` no sirve.

##### Excepciones

- **Feature muy grande** (por ejemplo, reescribir el chat): se parte en varias ramas encadenadas. `feature/chat-a` → PR a `dev` → `feature/chat-b` sale de `dev` (ya tiene A) → PR a `dev`. Cada parte es revisable.
- **Trabajo urgente**: `hotfix/` desde `main`, PR a `main` (merge commit) y PR a `dev` con lo mismo. El orden importa: primero `main` (producción), luego `dev` (para que no se pierda al siguiente release).
- **Rama muy vieja** (más de una semana): probablemente ya no vale la pena seguir. Cierra el PR con una nota de qué quedó y de qué no, y arranca de nuevo desde `dev`; vale más que arrastrar semanas de conflictos.

##### Cómo saber que lo estás haciendo bien

- `main` nunca está roto y siempre es desplegable.
- `dev` acumula trabajo ya probado, sin features a medio hacer.
- Los PRs son chicos: si tienen más de 300 líneas, probablemente son dos temas.
- `git log --oneline main` se lee como una lista de cambios del proyecto, no como ruido.
- No hay `force-push` en ninguna rama compartida.
- Si algo sale mal, `git revert` (no reescribir) siempre funciona.

##### Configuración local (una vez por clonación)

Estas reglas no se suben al repo, viven en `.git/config`. Si clonaste el proyecto de nuevo, ejecuta este bloque otra vez:

```bash
git config --local pull.ff only            # Prohace merges silenciosos: "git pull" nunca fusiona solo
git config --local push.default simple     # Pushea la rama actual a su homónima; nunca a main por accidente
git config --local branch.sort -c          # "git branch" ordena con la más reciente arriba
```

La protección de `main` y `dev` (exigir PR, borrar la rama al fusionar) ya está puesta en GitHub. Para revertirla, Settings → Branches → Branch protection rules.
