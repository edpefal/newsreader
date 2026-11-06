// Borra al cliente de RevenueCat al eliminar una cuenta. Es best-effort: si
// falla, se registra el error (sin PII) y el borrado de la cuenta sigue.
// Ver openspec/changes/migrate-to-revenuecat/design.md (D8).
const REVENUECAT_API = "https://api.revenuecat.com/v1";

/**
 * Devuelve `true` si el cliente quedó borrado (o ya no existía) y `false` si
 * no se pudo borrar. Nunca lanza, y el mensaje de error no incluye el
 * `appUserId` ni nada derivado del usuario.
 */
export async function deleteRevenueCatCustomer(opts: {
  appUserId: string;
  secretKey: string | undefined;
  fetchFn?: typeof fetch;
  logError?: (message: string) => void;
}): Promise<boolean> {
  const fetchFn = opts.fetchFn ?? fetch;
  const logError = opts.logError ?? console.error;

  if (!opts.secretKey) {
    logError("REVENUECAT_SECRET_API_KEY no configurado: cliente no borrado");
    return false;
  }

  try {
    const response = await fetchFn(
      `${REVENUECAT_API}/subscribers/${encodeURIComponent(opts.appUserId)}`,
      {
        method: "DELETE",
        headers: { Authorization: `Bearer ${opts.secretKey}` },
      },
    );
    await response.body?.cancel();
    // 404: el cliente nunca existió en RevenueCat, no hay nada que borrar.
    if (response.ok || response.status === 404) return true;
    logError(`RevenueCat no borró al cliente: respondió ${response.status}`);
    return false;
  } catch {
    logError("RevenueCat no borró al cliente: error de red");
    return false;
  }
}
