class IgModelInvoiceItem {
  IgModelInvoiceItem({
    required this.name,
    required this.measure,
    required this.amount,
    required this.price,
  });

  /// Product or service name.
  ///
  final String name;

  /// Product measure (e.g., kg, L, or piece)
  ///
  final String measure;

  /// Amount of items.
  ///
  final num amount;

  /// Product price expressed as any number.
  ///
  final num price;

  factory IgModelInvoiceItem.fromJson(Map<String, dynamic> json) {
    return IgModelInvoiceItem(
      name: json['name'],
      measure: json['measure'],
      amount: json['amount'],
      price: json['price'],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'measure': measure,
      'amount': amount,
      'price': price,
    };
  }
}
