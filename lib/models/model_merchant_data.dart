/// Model class which defines the basic merchant info displayed in invoices.
///
class IgModelMerchantData {
  IgModelMerchantData({
    required this.name,
    required this.email,
    required this.address,
    required this.oib,
    required this.mb,
    required this.iban,
    required this.phoneNumber,
  });

  /// Legal subject name.
  ///
  final String name;

  /// Contact email.
  ///
  final String email;

  /// Full address.
  final String address;

  /// Company identification number regulated by the government of Croatia ("osobni identifikacijski broj").
  ///
  final String oib;

  /// Company identification number regulated by the government of Croatia ("matični broj").
  ///
  final String mb;

  /// International bank account number.
  ///
  final String iban;

  /// Full phone number.
  ///
  final String phoneNumber;

  factory IgModelMerchantData.fromJson(Map<String, dynamic> json) {
    return IgModelMerchantData(
      name: json['name'],
      email: json['email'],
      address: json['address'],
      oib: json['oib'],
      mb: json['mb'],
      iban: json['iban'],
      phoneNumber: json['phoneNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'email': email,
      'address': address,
      'oib': oib,
      'mb': mb,
      'iban': iban,
      'phoneNumber': phoneNumber,
    };
  }
}
