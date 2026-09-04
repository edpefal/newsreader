## ADDED Requirements

### Requirement: Enriquecimiento sin restricción de suscripción

El enriquecimiento de menciones (capability `article-mentions`, requirement "Enriquecimiento de menciones vía proveedor externo") SHALL requerir únicamente una sesión de usuario autenticada, sin exigir suscripción activa. El control de acceso relevante ocurre en `article-summaries` (donde se detectan las menciones raw y se descuenta el límite diario correspondiente); para cuando se solicita el enriquecimiento, el resumen y las menciones ya se generaron dentro de ese límite. Como el enriquecimiento no invoca a la API de IA ni descuenta ningún presupuesto (ver requirement "Enriquecimiento de menciones vía proveedor externo"), no hay costo que justificar limitándolo a usuarios con suscripción activa.

#### Scenario: Usuario sin suscripción activa recibe enriquecimiento completo

- **WHEN** un usuario autenticado sin suscripción activa, dentro de su cupo diario gratis de `article-summaries`, genera el resumen de un artículo con menciones detectadas
- **THEN** el sistema enriquece esas menciones igual que a un usuario con suscripción activa (portadas de libro/podcast/música, Open Graph de artículos), sin degradar el resultado por falta de suscripción

#### Scenario: Solicitud de enriquecimiento sin sesión autenticada

- **WHEN** una solicitud de enriquecimiento de menciones no incluye un token que corresponda a una sesión de usuario autenticada
- **THEN** el sistema la rechaza con un error de autenticación, sin consultar a ningún proveedor externo
