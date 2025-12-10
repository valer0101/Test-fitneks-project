enum GiftType {
  protein('PROTEIN', 'Protein'),
  proteinShake('PROTEIN_SHAKE', 'Protein Shake'),
  proteinBar('PROTEIN_BAR', 'Protein Bar');

  const GiftType(this.value, this.displayName);
  final String value;
  final String displayName;
}

enum CurrencyType {
  tokens('TOKENS', 'Tokens'),
  rubies('RUBIES', 'Rubies');

  const CurrencyType(this.value, this.displayName);
  final String value;
  final String displayName;
}