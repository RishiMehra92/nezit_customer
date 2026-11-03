import 'package:hyper_local/screens/wallet_page/model/prepare_wallet_recharge_model.dart';

class LoyaltyTransaction {
  final int id;
  final int? orderId;
  final int points;
  final int usedPoints;
  final String type;
  final String status;
  final String description;
  final String? expiresAt;
  final String createdAt;

  LoyaltyTransaction({
    required this.id,
    this.orderId,
    required this.points,
    required this.usedPoints,
    required this.type,
    required this.status,
    required this.description,
    this.expiresAt,
    required this.createdAt,
  });

  factory LoyaltyTransaction.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }
    int? parseIntNullable(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    return LoyaltyTransaction(
      id: parseInt(json['id']),
      orderId: parseIntNullable(json['order_id']),
      points: parseInt(json['points']),
      usedPoints: parseInt(json['used_points']),
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      description: json['description'] ?? '',
      expiresAt: json['expires_at'],
      createdAt: json['created_at'] ?? '',
    );
  }

  Transaction toTransaction() {
    final isCredit = points >= 0;
    return Transaction(
      id: id,
      orderId: orderId,
      transactionType: isCredit ? 'deposit' : 'withdrawal',
      amount: points.abs().toString(),
      currencyCode: 'points',
      status: status,
      description: description,
      createdAt: createdAt,
    );
  }
}

class CoinsPagination {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  CoinsPagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory CoinsPagination.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }
    return CoinsPagination(
      currentPage: parseInt(json['current_page']),
      lastPage: parseInt(json['last_page']),
      perPage: parseInt(json['per_page']),
      total: parseInt(json['total']),
    );
  }
}

class CoinsSummaryModel {
  final bool isEnabled;
  final int pointsBalance;
  final double redemptionValue;
  final double equivalentMonetaryValue;
  final String? currencyCode;
  final String? formattedEquivalentMonetaryValue;
  final int expiringPointsIn30Days;
  final List<LoyaltyTransaction> transactions;
  final CoinsPagination? pagination;

  CoinsSummaryModel({
    required this.isEnabled,
    required this.pointsBalance,
    required this.redemptionValue,
    required this.equivalentMonetaryValue,
    this.currencyCode,
    this.formattedEquivalentMonetaryValue,
    required this.expiringPointsIn30Days,
    required this.transactions,
    this.pagination,
  });

  factory CoinsSummaryModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    bool parseBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value == 1 || value == '1' || value == 'true') return true;
      return false;
    }

    var transList = <LoyaltyTransaction>[];
    if (json['transactions'] != null) {
      transList = (json['transactions'] as List)
          .map((i) => LoyaltyTransaction.fromJson(i))
          .toList();
    }

    return CoinsSummaryModel(
      isEnabled: parseBool(json['is_enabled']),
      pointsBalance: parseInt(json['points_balance']),
      redemptionValue: parseDouble(json['redemption_value']),
      equivalentMonetaryValue: parseDouble(json['equivalent_monetary_value']),
      currencyCode: json['currency_code'] ?? json['currency'],
      formattedEquivalentMonetaryValue: json['formatted_equivalent_monetary_value'],
      expiringPointsIn30Days: parseInt(json['expiring_points_in_30_days']),
      transactions: transList,
      pagination: json['pagination'] != null
          ? CoinsPagination.fromJson(json['pagination'])
          : null,
    );
  }
}
