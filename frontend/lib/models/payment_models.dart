class PaymentMethod {
  final String id;
  final String cardBrand;
  final String cardLast4;
  final int cardExpMonth;
  final int cardExpYear;
  bool isDefault;
  final DateTime createdAt;

  PaymentMethod({
    required this.id,
    required this.cardBrand,
    required this.cardLast4,
    required this.cardExpMonth,
    required this.cardExpYear,
    required this.isDefault,
    required this.createdAt,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      cardBrand: json['cardBrand'],
      cardLast4: json['cardLast4'],
      cardExpMonth: json['cardExpMonth'],
      cardExpYear: json['cardExpYear'],
      isDefault: json['isDefault'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class SetupIntentResponse {
  final String clientSecret;
  final String customerId;

  SetupIntentResponse({
    required this.clientSecret,
    required this.customerId,
  });

  factory SetupIntentResponse.fromJson(Map<String, dynamic> json) {
    return SetupIntentResponse(
      clientSecret: json['clientSecret'],
      customerId: json['customerId'],
    );
  }
}

class PurchaseHistoryItem {
  final String id;
  final int rubiesAmount;
  final int costCents;
  final String status;
  final String paymentMethodLast4;
  final String paymentMethodBrand;
  final DateTime createdAt;

  PurchaseHistoryItem({
    required this.id,
    required this.rubiesAmount,
    required this.costCents,
    required this.status,
    required this.paymentMethodLast4,
    required this.paymentMethodBrand,
    required this.createdAt,
  });

  factory PurchaseHistoryItem.fromJson(Map<String, dynamic> json) {
    return PurchaseHistoryItem(
      id: json['id'],
      rubiesAmount: json['rubiesAmount'],
      costCents: json['costCents'],
      status: json['status'],
      paymentMethodLast4: json['paymentMethodLast4'],
      paymentMethodBrand: json['paymentMethodBrand'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class PurchaseHistoryResponse {
  final List<PurchaseHistoryItem> purchases;
  final int total;
  final int page;
  final int totalPages;
  final int totalRubies;
  final int totalSpentCents;

  PurchaseHistoryResponse({
    required this.purchases,
    required this.total,
    required this.page,
    required this.totalPages,
    required this.totalRubies,
    required this.totalSpentCents,
  });

  factory PurchaseHistoryResponse.fromJson(Map<String, dynamic> json) {
    return PurchaseHistoryResponse(
      purchases: (json['purchases'] as List)
          .map((item) => PurchaseHistoryItem.fromJson(item))
          .toList(),
      total: json['total'],
      page: json['page'],
      totalPages: json['totalPages'],
      totalRubies: json['totalRubies'],
      totalSpentCents: json['totalSpentCents'],
    );
  }
}

class PurchaseResponse {
  final String id;
  final String clientSecret;
  final String status;
  final int rubiesAmount;
  final int costCents;

  PurchaseResponse({
    required this.id,
    required this.clientSecret,
    required this.status,
    required this.rubiesAmount,
    required this.costCents,
  });

  factory PurchaseResponse.fromJson(Map<String, dynamic> json) {
    return PurchaseResponse(
      id: json['id'],
      clientSecret: json['clientSecret'],
      status: json['status'],
      rubiesAmount: json['rubiesAmount'],
      costCents: json['costCents'],
    );
  }
}