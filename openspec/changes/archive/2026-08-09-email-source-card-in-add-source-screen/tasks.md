## 1. Layout de AddSourceScreen

- [x] 1.1 Agregar sección "Otras formas de agregar" debajo del botón "Agregar", que agrupa la card de OPML y la nueva card de email.
- [x] 1.2 Reubicar "Importar desde OPML" como card (ícono `upload_file_outlined` + título), manteniendo su comportamiento actual (tap abre el file picker directo).

## 2. Card de generar dirección de email

- [x] 2.1 Crear widget `_EmailFeedCard` (privado a `add_source_screen.dart`) con estado local `_emailCardExpanded` en `_AddSourceViewState`.
- [x] 2.2 Estado colapsado: ícono `mail_outline`, título "Generar dirección de email", descripción "Para newsletters sin RSS: los correos se convierten en artículos."
- [x] 2.3 Estado expandido (`AnimatedSize`, ~200ms): agrega el texto "Te damos una dirección única. Suscribí el newsletter con ella y cada correo que llegue aparecerá acá." y un botón interno "Generar dirección de email".
- [x] 2.4 El botón interno dispara `context.read<AddSourceCubit>().generateEmailFeed()` (mismo flujo existente: spinner vía `AddSourceGeneratingEmailFeed`, diálogo vía `AddSourceEmailFeedGenerated`).
- [x] 2.5 Auto-colapsar la card (`_emailCardExpanded = false`) al recibir `AddSourceEmailFeedGenerated` tras confirmar en el diálogo, y al recibir `AddSourceSuccess`.

## 3. Snackbar de error de detección

- [x] 3.1 En `_showFeedDiscoveryFailedSnackBar`, quitar el `Align`/`TextButton` de "Generar email" del `content`, dejando solo el `Row` con el mensaje y el ícono de cerrar.
- [x] 3.2 Quitar el método/lógica de disparo de `generateEmailFeed()` que quedó huérfana en el snackbar (si aplica tras 3.1).

## 4. Tests

- [x] 4.1 Widget test: la card de email está visible y colapsada al abrir `AddSourceScreen`, sin haber intentado agregar una fuente.
- [x] 4.2 Widget test: tocar la card colapsada la expande, mostrando el texto detallado y el botón interno.
- [x] 4.3 Widget test: tocar el botón interno de la card expandida llama a `cubit.generateEmailFeed()`.
- [x] 4.4 Widget test: tras `AddSourceEmailFeedGenerated`, la card vuelve a estado colapsado.
- [x] 4.5 Widget test: tras `AddSourceSuccess`, si la card estaba expandida, vuelve a estado colapsado.
- [x] 4.6 Widget test: el snackbar de `AddSourceFeedDiscoveryFailed` ya no muestra ninguna acción ("Generar email" no aparece), solo el mensaje y el ícono de cerrar.
- [x] 4.7 Actualizar/eliminar los tests existentes de `add_source_screen_test.dart` que asumían la acción "Generar email" dentro del snackbar.

## 5. Verificación

- [x] 5.1 Correr `flutter analyze` sin warnings.
- [x] 5.2 Correr `flutter test` y confirmar que toda la suite pasa.
- [x] 5.3 Probar visualmente en un dispositivo/emulador: card colapsada/expandida, generación de email, y que la pantalla no se vea sobrecargada en un tamaño de pantalla chico.
