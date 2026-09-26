## Qué cambia

<!-- Una o dos líneas. Sin esto nadie sabe qué abrir este PR. -->

## Por qué

<!-- El problema, no la solución. Si es un fix, el symptom que se veía. -->

## Cómo lo probé

<!-- Los 3 checks, tal cual los corriste. Obligatorio: si alguno falla, no se fusiona. -->

- `cd F_StudyHub && flutter analyze`
- `cd F_StudyHub && flutter test`
- `cd B_StudyHub && npm run typecheck`

## Alcance

- [ ] Solo frontend (`F_StudyHub`)
- [ ] Solo backend (`B_StudyHub`)
- [ ] Docs
- [ ] Toca ambos (explica el contrato si cambia un evento de socket)

## Antes de fusionar

- [ ] Un solo tema (si son dos, son dos PRs)
- [ ] Sin secretos, datos de prueba ni `print`/`console.log` olvidados
- [ ] Si cambió un evento de socket, `context/instrucciones.md` está actualizado
