class Budget {
  final int id;
  final String month;
  final double amount;
  final double spent;

  Budget({
    required this.id,
    required this.month,
    required this.amount,
    required this.spent,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'month': month,
      'amount': amount,
      'spent': spent,
    };
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      month: json['month'],
      amount: json['amount'],
      spent: json['spent'],
    );
  }

  Budget copyWith({
    int? id,
    String? month,
    double? amount,
    double? spent,
  }) {
    return Budget(
      id: id ?? this.id,
      month: month ?? this.month,
      amount: amount ?? this.amount,
      spent: spent ?? this.spent,
    );
  }
}
