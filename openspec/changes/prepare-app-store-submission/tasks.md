## 1. Export compliance (repo `newsreader`)

- [x] 1.1 Agregar `ITSAppUsesNonExemptEncryption` con valor `false` a `ios/Runner/Info.plist`
- [x] 1.2 Correr `flutter analyze` y confirmar que el build de iOS sigue compilando localmente
- [ ] 1.3 Rama nueva, PR contra `main`, esperar CI en verde, mergear (según flujo del proyecto)

## 2. Página de soporte (repo `reevo-web`, fuera de este repo)

- [ ] 2.1 Crear la ruta `/support` en `reevo-web`, mismo patrón que `/terms` y `/privacy`
- [ ] 2.2 Definir el método de contacto real (email o mailto:) a mostrar en la página
- [ ] 2.3 Deploy a Vercel y verificar que `/support` resuelve con status 200

## 3. Ficha de App Store Connect (configuración manual, sin código)

- [ ] 3.1 Age rating: completar el cuestionario declarando acceso a contenido web sin filtrar (ver `design.md` - Decisions, para el porqué)
- [ ] 3.2 Elegir categoría primaria de la ficha (News o Productivity) — decisión pendiente con el usuario
- [ ] 3.3 Cargar el Support URL (`/support` de `reevo-web`) en la ficha
- [ ] 3.4 Confirmar o cargar Marketing URL (opcional)
- [ ] 3.5 Completar "App Review Information / Notes" indicando que no hace falta cuenta demo — el reviewer puede iniciar sesión con su propio Apple ID vía Sign in with Apple

## 4. Verificación final

- [ ] 4.1 Confirmar en App Store Connect que la sección "App Privacy" (nutrition labels) está completa y refleja lo declarado en las specs `product-analytics` y `observability` (sin PII, datos ligados solo al identificador de usuario)
- [ ] 4.2 Revisar que todos los items de este checklist estén resueltos antes de disparar el primer submit a revisión desde Codemagic
