/// Normalizes known slogan typos for display without mutating stored values.
String formatBrandSloganForDisplay(String slogan) {
  if (slogan.isEmpty) return slogan;
  return slogan
      .replaceAll('atraves', 'através')
      .replaceAll('Atraves', 'Através')
      .replaceAll('ATRAVES', 'ATRAVÉS');
}
