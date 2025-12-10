import 'gift_type.dart';

class GiftExchangeBalances {
  final int fitneksTokens;
  final int rubies;
  final int protein;
  final int proteinShakes;
  final int proteinBars;

  GiftExchangeBalances({
    required this.fitneksTokens,
    required this.rubies,
    required this.protein,
    required this.proteinShakes,
    required this.proteinBars,
  });

  factory GiftExchangeBalances.fromJson(Map<String, dynamic> json) {
    return GiftExchangeBalances(
      fitneksTokens: json['fitneksTokens'] ?? 0,
      rubies: json['rubies'] ?? 0,
      protein: json['protein'] ?? 0,
      proteinShakes: json['proteinShakes'] ?? 0,
      proteinBars: json['proteinBars'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fitneksTokens': fitneksTokens,
      'rubies': rubies,
      'protein': protein,
      'proteinShakes': proteinShakes,
      'proteinBars': proteinBars,
    };
  }

  // Helper method to get gift quantity by type
  int getGiftQuantity(GiftType type) {
    switch (type) {
      case GiftType.protein:
        return protein;
      case GiftType.proteinShake:
        return proteinShakes;
      case GiftType.proteinBar:
        return proteinBars;
    }
  }
}