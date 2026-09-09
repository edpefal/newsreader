## 1. Corrección

- [x] 1.1 Agregar una prueba de regresión del origen y los archivos enviados al canal nativo. Falla antes de la corrección por origen ausente.
- [x] 1.2 Enviar un origen no vacío desde SharePlusFileSharer.

## 2. Verificación

- [x] 2.1 Ejecutar flutter analyze, flutter test y validación estricta de OpenSpec. Sin issues; 582 pruebas pasan; change válido.
- [ ] 2.2 Verificar manualmente en iPhone con iOS 26 e iPad que se abre el menú y permite guardar ambos archivos (a cargo del usuario).
