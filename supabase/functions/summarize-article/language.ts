// Resolución de idioma extraída a una función pura y testeable sin
// necesitar levantar la request completa. El backend no confía ciegamente
// en lo que mande el cliente: si el valor recibido no matchea ninguno de
// los idiomas soportados por AppLocalizations (o falta), cae a inglés
// como default seguro.
// Copia intencional de summarize-articles/language.ts (ver entitlement.ts
// en esta misma carpeta para el motivo).
export type SupportedLanguage = "en" | "es" | "fr";

const SUPPORTED_LANGUAGES: readonly SupportedLanguage[] = ["en", "es", "fr"];

export function resolveLanguage(language: unknown): SupportedLanguage {
  if (
    typeof language === "string" &&
    (SUPPORTED_LANGUAGES as readonly string[]).includes(language)
  ) {
    return language as SupportedLanguage;
  }
  return "en";
}
