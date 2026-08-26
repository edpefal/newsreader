## 1. Ajuste del badge del Inbox

- [x] 1.1 En `lib/presentation/app/router.dart`, quitar el `Badge.count` que envolvía `icon`/`selectedIcon` del destino Inbox y dejarlos como íconos simples (`Icons.inbox_outlined` / `Icons.inbox`).
- [x] 1.2 Mover el `BlocBuilder<InboxCubit, InboxState>` al `label` del destino Inbox, componiendo un `Row` con el texto "Inbox" + separación + `Badge.count(count: count)` standalone cuando `count > 0`.

## 2. Verificación

- [x] 2.1 Correr la app y revisar visualmente el drawer con conteos de 1, 2 y 4+ dígitos (ej. forzando `999+`), en estado seleccionado y no seleccionado, confirmando que el badge no se superpone al ícono ni al texto.
- [x] 2.2 Correr `flutter analyze` y confirmar que no hay warnings nuevos.
