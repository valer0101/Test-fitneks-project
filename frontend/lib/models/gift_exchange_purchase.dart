class GiftExchangePurchase {
  final String id;
  final DateTime date;
  final int quantity;
  final String giftName;

  GiftExchangePurchase({
    required this.id,
    required this.date,
    required this.quantity,
    required this.giftName,
  });

  factory GiftExchangePurchase.fromJson(Map<String, dynamic> json) {
    return GiftExchangePurchase(
      id: json['id'],
      date: DateTime.parse(json['date']),
      quantity: json['quantity'],
      giftName: json['giftName'],
    );
  }
}