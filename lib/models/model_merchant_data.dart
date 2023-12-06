import 'package:simple_invoice_generator/services/service_cache_manager.dart';

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
    required this.swiftCode,
    required this.phoneNumber,
    required this.vatApplied,
    required this.overseeingCourtBody,
    required this.boardMembers,
    required this.capitalBalance,
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

  /// Bank transfer SWIFT code.
  ///
  final String swiftCode;

  /// Full phone number.
  ///
  final String phoneNumber;

  /// Whether the VAT requirement is applied to this merchant (sustav PDV-a).
  ///
  final bool vatApplied;

  /// The overseeing court authority for this company (trgovački sud).
  ///
  final String overseeingCourtBody;

  /// The list of board members (članovi uprave).
  ///
  final String boardMembers;

  /// The amount of company capital balance (temeljni kapital).
  ///
  final num capitalBalance;

  factory IgModelMerchantData.fromJson(Map<String, dynamic> json) {
    return IgModelMerchantData(
      name: json['name'],
      email: json['email'],
      address: json['address'],
      oib: json['oib'],
      mb: json['mb'],
      iban: json['iban'],
      swiftCode: json['swiftCode'],
      phoneNumber: json['phoneNumber'],
      vatApplied: json['vatApplied'],
      overseeingCourtBody: json['overseeingCourtBody'],
      boardMembers: json['boardMembers'],
      capitalBalance: json['capitalBalance'],
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
      'swiftCode': swiftCode,
      'phoneNumber': phoneNumber,
      'vatApplied': vatApplied,
      'overseeingCourtBody': overseeingCourtBody,
      'boardMembers': boardMembers,
      'capitalBalance': capitalBalance,
    };
  }

  /// The formatted display info for this model class, presented in the form of a list.
  ///
  Set<({String label, String value})> get formattedInfo {
    return {
      (
        label: 'Naziv tvrtke',
        value: IgServiceCacheManager.merchantData?.name ?? 'N/A',
      ),
      (
        label: 'Email adresa',
        value: IgServiceCacheManager.merchantData?.email ?? 'N/A',
      ),
      (
        label: 'Adresa tvrtke',
        value: IgServiceCacheManager.merchantData?.address ?? 'N/A',
      ),
      (
        label: 'OIB',
        value: IgServiceCacheManager.merchantData?.oib ?? 'N/A',
      ),
      (
        label: 'MBS',
        value: IgServiceCacheManager.merchantData?.mb ?? 'N/A',
      ),
      (
        label: 'IBAN',
        value: IgServiceCacheManager.merchantData?.iban ?? 'N/A',
      ),
      (
        label: 'SWIFT',
        value: IgServiceCacheManager.merchantData?.swiftCode ?? 'N/A',
      ),
      (
        label: 'Telefonski broj',
        value: IgServiceCacheManager.merchantData?.phoneNumber ?? 'N/A',
      ),
      (
        label: 'Trgovački sud',
        value: IgServiceCacheManager.merchantData?.overseeingCourtBody ?? 'N/A',
      ),
      (
        label: 'Ćlanovi uprave',
        value: IgServiceCacheManager.merchantData?.boardMembers ?? 'N/A',
      ),
      (
        label: 'Temeljni kapital',
        value: '${IgServiceCacheManager.merchantData?.capitalBalance.toStringAsFixed(2) ?? 'N/A'} EUR',
      ),
    };
  }
}
