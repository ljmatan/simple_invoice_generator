import 'package:simple_invoice_generator/models/model_invoice_item.dart';
import 'package:simple_invoice_generator/models/model_sale_client.dart';

/// A model for cached invoice data.
///
class IgModelInvoice {
  IgModelInvoice({
    required this.paymentId,
    required this.time,
    required this.invoiceItems,
    required this.clientInfo,
    required this.paymentModel,
    required this.paymentMethod,
  });

  /// Unique payment identifier.
  ///
  final String paymentId;

  /// The time the invoice was generated.
  ///
  final DateTime time;

  /// Products and services added to this invoice.
  ///
  final List<IgModelInvoiceItem> invoiceItems;

  /// Client invoice information.
  ///
  final IgModelSaleClient clientInfo;

  /// The specified payment method for this invoice.
  ///
  final String paymentMethod;

  /// Specified payment model for this invoice.
  ///
  final String paymentModel;

  factory IgModelInvoice.fromJson(Map<String, dynamic> json) {
    return IgModelInvoice(
      paymentId: json['paymentId'],
      time: DateTime.parse(json['time']),
      invoiceItems: (json['invoiceItems'] as Iterable).map((invoiceItemJson) => IgModelInvoiceItem.fromJson(invoiceItemJson)).toList(),
      clientInfo: IgModelSaleClient.fromJson(json['clientInfo']),
      paymentMethod: json['paymentMethod'],
      paymentModel: json['paymentModel'],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'paymentId': paymentId,
      'time': time.toIso8601String(),
      'invoiceItems': invoiceItems.map((invoiceItem) => invoiceItem.toJson()).toList(),
      'clientInfo': clientInfo.toJson(),
      'paymentMethod': paymentMethod,
      'paymentModel': paymentModel,
    };
  }
}
