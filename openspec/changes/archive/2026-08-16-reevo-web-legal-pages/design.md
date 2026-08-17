## Context

Reevo no tiene ningún proyecto web hoy. El código Flutter vive en `/Users/eder/Development/Flutter/newsreader` con su propio OpenSpec; este change crea un repositorio nuevo y separado para lo web, planeado desde el vamos para escalar a landing page y luego a una web app, sin que eso implique rehacer el stack más adelante. Ver `proposal.md` para el motivo (bloqueante del submit a Apple).

## Goals / Non-Goals

**Goals:**
- Dejar `/terms` y `/privacy` públicas y desplegadas en Vercel, con URLs listas para pegar en el editor de Superwall.
- Elegir una estructura de proyecto (Next.js App Router) que no haya que reestructurar cuando se agregue la landing o la web app.

**Non-Goals:**
- No se construye la landing page de lanzamiento en este change (solo se deja el proyecto listo para agregarla).
- No se construye la versión web de la app.
- No se configura dominio personalizado — se usa el subdominio `.vercel.app` por defecto; si el usuario después compra un dominio, es un change aparte.
- No se automatiza la redacción legal final — el contenido es un borrador para que el usuario lo revise/ajuste antes de publicar en producción.

## Decisions

**Next.js (App Router) + Vercel, proyecto separado del repo Flutter.**
- Alternativa considerada: página estática suelta en Supabase Storage. Más rápida para *solo* estas dos páginas, pero no sirve de base para landing/web app — se descarta porque el usuario ya pidió pensar en ese crecimiento.
- Next.js porque es el framework con el que Vercel tiene mejor soporte de primera clase (herramientas de Vercel ya disponibles en este entorno), y porque una landing + web app en React/Next.js es el camino más común y con menos fricción a futuro.
- App Router (no Pages Router) porque es el estándar actual de Next.js — evita tener que migrar de router más adelante.

**Contenido legal como componentes/páginas estáticas server-rendered, sin CMS.**
- Para dos páginas de texto no se justifica un headless CMS. Si en el futuro el volumen de contenido (landing, blog, etc.) lo amerita, se puede introducir en un change aparte.

**Repositorio Git separado, no un monorepo con el proyecto Flutter.**
- El repo Flutter (`newsreader`) es exclusivamente la app; mezclar un proyecto Next.js ahí complicaría el CI/tooling de ambos sin beneficio real, dado que no comparten código ni dependencias.

## Risks / Trade-offs

- **[Riesgo] El contenido legal armado como borrador puede no ser exacto/completo para la jurisdicción del usuario** → Mitigación: se marca explícitamente como borrador a revisar por el usuario (y opcionalmente un asesor legal) antes de considerar el change "terminado" para efectos de cumplimiento; no bloquea tener las páginas técnicamente desplegadas.
- **[Riesgo] Usar el subdominio `.vercel.app` en vez de un dominio propio queda "feo" en la ficha de la App Store / paywall** → Mitigación: aceptable para destrabar el submit ahora; migrar a dominio propio es un change incremental sin romper las URLs si se configuran redirects.
- **[Trade-off] Repo separado significa un checkout/proyecto más para mantener** → Aceptado a cambio de no acoplar el tooling de una app Flutter con el de un proyecto Next.js.
