// Conteo simple de palabras (separando por espacios en blanco, no un
// tokenizer real) usado para aplicar el presupuesto diario de IA -- ver
// ai-usage-budget. Es una aproximación aceptada a propósito (Gemini cobra
// por token, no por palabra); el límite diario está pensado con margen.
export interface ArticleExcerpt {
  title: string;
  excerpt: string;
  sourceName: string;
}

function countWords(text: string): number {
  const trimmed = text.trim();
  if (trimmed.length === 0) return 0;
  return trimmed.split(/\s+/).length;
}

export function countArticleWords(articles: ArticleExcerpt[]): number {
  return articles.reduce(
    (total, article) =>
      total + countWords(article.title) + countWords(article.excerpt),
    0,
  );
}
