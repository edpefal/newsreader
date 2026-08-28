// Conteo simple de palabras (separando por espacios en blanco, no un
// tokenizer real) usado para aplicar el presupuesto diario de IA -- ver
// ai-usage-budget. Mismo criterio que summarize-articles/word_count.ts,
// adaptado a un solo artículo (título + contenido) en vez de una lista.
export interface ArticleContent {
  title: string;
  content: string;
}

function countWords(text: string): number {
  const trimmed = text.trim();
  if (trimmed.length === 0) return 0;
  return trimmed.split(/\s+/).length;
}

export function countSingleArticleWords(article: ArticleContent): number {
  return countWords(article.title) + countWords(article.content);
}
