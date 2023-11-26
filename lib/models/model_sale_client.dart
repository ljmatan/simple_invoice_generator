/// Model class defining the client data.
///
class IgModelSaleClient {
  IgModelSaleClient({
    required this.name,
    required this.oib,
    required this.address,
  });

  /// Client name.
  ///
  final String name;

  /// Client personal identification number determined by the government of Croatia (osobni identifikacijski broj).
  ///
  final String? oib;

  /// Client address.
  ///
  final String? address;

  factory IgModelSaleClient.fromJson(Map<String, dynamic> json) {
    return IgModelSaleClient(
      name: json['name'],
      oib: json['oib'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'oib': oib,
      'address': address,
    };
  }
}
