## 1. Export compliance (repo `newsreader`)

- [x] 1.1 Agregar `ITSAppUsesNonExemptEncryption` con valor `false` a `ios/Runner/Info.plist`
- [x] 1.2 Correr `flutter analyze` y confirmar que el build de iOS sigue compilando localmente
- [x] 1.3 Rama nueva, PR contra `main`, esperar CI en verde, mergear (según flujo del proyecto) — PR #10, mergeado

## 2. Página de soporte (repo `reevo-web`, fuera de este repo)

- [x] 2.1 Crear la ruta `/support` en `reevo-web`, mismo patrón que `/terms` y `/privacy`
- [x] 2.2 Definir el método de contacto real (email o mailto:) a mostrar en la página — `edpefal@gmail.com`, mismo email ya usado en `/privacy` y `/terms`
- [x] 2.3 Deploy a Vercel y verificar que `/support` resuelve con status 200 — https://getreevo.co/support

## 3. Ficha de App Store Connect (configuración manual, sin código)

- [x] 3.1 Age rating: completar el cuestionario declarando acceso a contenido web sin filtrar (ver `design.md` - Decisions, para el porqué) — completado en App Store Connect, resultado: 16+ (173 países/regiones), A16 en Brasil, 15+ en Corea del Sur
- [x] 3.2 Elegir categoría primaria de la ficha — **News**, validada contra Matter y Feedly (ambas listadas en News). Ya estaba cargada en App Store Connect (Primary: News, Secondary: Productivity) — no hizo falta tocarla.
- [x] 3.3 Cargar el Support URL (`/support` de `reevo-web`) en la ficha — cargado en App Store Connect (Reevo Digest, iOS App Version 1.0)
- [x] 3.4 Confirmar o cargar Marketing URL (opcional) — cargado (`https://getreevo.co`)
- [x] 3.5 Completar "App Review Information / Notes" indicando que no hace falta cuenta demo — el reviewer puede iniciar sesión con su propio Apple ID vía Sign in with Apple — nota cargada. Pendiente: el checkbox "Sign-in required" sigue tildado sin usuario/contraseña — el usuario decide si deja así o carga una cuenta demo real
- [x] Keywords field también cargado en la misma sesión (no era una tarea separada, pero quedó resuelto): `substack,ghost,wordpress,feed,boletines,suscripciones,digest,opml,lectura,blogs,noticias,correo`

## 4. Verificación final

- [x] 4.1 Confirmar en App Store Connect que la sección "App Privacy" (nutrition labels) está completa y refleja lo declarado en las specs `product-analytics` y `observability` (sin PII, datos ligados solo al identificador de usuario) — encontrados y corregidos 3 gaps que no estaban en el alcance original de este change:
  - Privacy Policy URL estaba vacío en App Privacy → cargado `https://getreevo.co/privacy`
  - Faltaba declarar **Email Address** (Contact Info) — se recolecta en el login vía Google/Apple Sign-In; declarado como "App Functionality", ligado a la identidad, sin uso para tracking
  - Faltaba declarar **Crash Data** (Diagnostics, de Sentry) y **Purchase History** (de la suscripción vía Superwall) — ambos declarados como "App Functionality", ligados a la identidad, sin uso para tracking
  - Estado final: 5 data types (Email Address, Product Interaction, User ID, Purchase History, Crash Data), ninguno usado para advertising/tracking, todos ligados a la identidad solo mientras hay sesión activa — consistente con `product-analytics` y `observability`
- [x] 4.2 Revisar que todos los items de este checklist estén resueltos antes de disparar el primer submit a revisión desde Codemagic — checklist completo
