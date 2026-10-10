## Context

Ambas funciones llaman a `generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent` con `generationConfig` que incluye `thinkingConfig: { thinkingBudget: 0 }`; `summarize-article` además exige `responseMimeType: "application/json"` con un `responseSchema`. Hoy funcionan porque Google redirige `gemini-3.7-flash` a `gemini-3.8-flash`, por lo que el modelo efectivo ya es el 3.8: el cambio hace explícito lo que ya corre.

## Goals / Non-Goals

**Goals:**
- Apuntar directamente a `gemini-3.8-flash` en las dos funciones.
- Confirmar con una llamada real que respuestas, JSON estructurado y desactivación del thinking siguen funcionando.

**Non-Goals:**
- No mover el modelo a una variable de entorno ni a configuración remota: son dos constantes y el próximo cambio de modelo seguirá siendo de una línea.
- No cambiar prompts, temperatura, límites de tokens ni presupuesto de uso.
- No evaluar otros modelos (p. ej. uno más barato o más capaz).

## Decisions

**1. Cambiar la constante en cada función, sin compartirla.**
Las funciones son independientes (cada una con su `deno.json`) y no comparten módulos; extraer una constante común requeriría un módulo compartido nuevo por una cadena de texto. Alternativa descartada: variable de entorno `GEMINI_MODEL` en Supabase, que permitiría cambiarlo sin desplegar pero esconde el valor fuera del repo y entre dos proyectos distintos (dev y prod) podría divergir sin que se note.

**2. Verificar en dev antes de prod.**
Se despliega primero a `reevo-dev` y se prueba allí; recién entonces a `reevo`. Dev está en el free tier de Gemini (20 requests/día), suficiente para una verificación puntual de cada función.

## Risks / Trade-offs

- [`thinkingBudget: 0` o `responseSchema` se comportan distinto en 3.8] → Como la redirección ya enruta a 3.8, un fallo aparecería ya hoy en prod; se revisan los logs de ambas funciones y se hace una llamada real en dev. Si falla, se ajusta `generationConfig` en este mismo change.
- [Calidad o tono del texto distinto al 3.7] → Mismo modelo que ya sirve el tráfico actual; se compara un resumen de dev contra los de prod.
- [Olvidar uno de los dos proyectos] → La tarea de despliegue lista ambos y las funciones, y CLAUDE.md exige confirmar los proyectos antes de dar el change por terminado.

## Migration Plan

1. Cambiar las dos constantes y correr los tests de Deno de ambas funciones.
2. Desplegar las dos funciones a `reevo-dev` y verificar con una llamada real.
3. Desplegar a `reevo` (prod).
4. Rollback: volver a `gemini-3.7-flash` mientras Google mantenga la redirección, o revertir el PR y redesplegar.
