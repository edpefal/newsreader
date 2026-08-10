## 1. UI: pantallas

- [x] 1.1 `sources_screen.dart`: FAB tooltip "Agregar newsletter" → "Agregar fuente"; empty state "Aún no tienes newsletters" → "Aún no tienes fuentes"; "Agrega tu primer newsletter para empezar a leer." → "Agrega tu primera fuente para empezar a leer."; CTA "Agregar mi primer newsletter" → "Agregar mi primera fuente".
- [x] 1.2 `inbox_screen.dart`: empty state "Tu espacio para leer newsletters fuera del email." → "Tu espacio para leer tus fuentes fuera del email."; CTA "Agregar tu primer newsletter" → "Agregar tu primera fuente".
- [x] 1.3 `add_source_screen.dart`: `AppBar` "Agregar newsletter" → "Agregar fuente"; hint del formulario "Pega el link de tu newsletter (o la URL del feed RSS si la tienes)." → "Pega el link del sitio (o la URL del feed RSS si la tienes)." La card y el diálogo de generación de email (todo lo que menciona "newsletter" en el flujo de email-to-RSS) **no se toca**.

## 2. Docs y metadata

- [x] 2.1 `pubspec.yaml`: actualizar `description` para que no hable exclusivamente de newsletters.
- [x] 2.2 `README.md`: generalizar la línea de apertura a "fuentes RSS/Atom"; la sección de email-to-RSS queda sin cambios.
- [x] 2.3 `PRD.md`: generalizar las líneas 27, 45, 58 y 71 (flujo general de agregar fuentes y resúmenes); dejar sin cambios las líneas 23, 46 y 147 (específicas de la feature email-to-RSS).

## 3. Tests

- [x] 3.1 `sources_screen_test.dart`: actualizar los `find.text(...)` de empty state y CTA al nuevo copy.
- [x] 3.2 `inbox_screen_test.dart`: actualizar los `find.text(...)` del CTA al nuevo copy.
- [x] 3.3 Confirmar que `add_source_screen_test.dart` no requiere cambios (no assertea el `AppBar` ni el hint del formulario; las assertions sobre la card de email quedan intactas porque ese copy no cambia).

## 4. Verificación

- [x] 4.1 Correr `flutter analyze` sin warnings.
- [x] 4.2 Correr `flutter test` y confirmar que toda la suite pasa.
- [x] 4.3 Revisar visualmente (o por lectura del diff) que ningún texto de la card/diálogo de email-to-RSS haya sido tocado por error.
