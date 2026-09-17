// Determina si una invocación de `sync-feeds` corresponde al modo
// "background" (cron del servidor, sin usuario, procesando el lote
// globalmente menos recientemente sincronizado) en vez del modo on-demand
// habitual (pull-to-refresh/login/agregar fuente, con el JWT de un usuario)
// -- ver openspec/changes/add-automatic-daily-summary/design.md, Decisión 1.
// Extraído a una función pura y testeable, mismo patrón que
// `isSafePublicUrl`/`hasActiveEntitlement`.
export function isBackgroundInvocation(
  token: string,
  serviceRoleKey: string,
  requestedMode: unknown,
): boolean {
  return requestedMode === "background" && token === serviceRoleKey;
}
