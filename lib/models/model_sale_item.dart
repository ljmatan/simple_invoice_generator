/// Model class defining product or service details.
///
class IgModelSaleItem {
  IgModelSaleItem({
    required this.name,
    required this.measure,
    required this.price,
  });

  /// Product or service name.
  ///
  final String name;

  /// Product measure (e.g., kg, L, or piece)
  ///
  final String measure;

  /// Product price expressed as any number.
  ///
  final num price;

  factory IgModelSaleItem.fromJson(Map<String, dynamic> json) {
    return IgModelSaleItem(
      name: json['name'],
      measure: json['measure'],
      price: json['price'],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'measure': measure,
      'price': price,
    };
  }
}
