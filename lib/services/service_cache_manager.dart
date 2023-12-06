import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_invoice_generator/models/model_invoice.dart';
import 'package:simple_invoice_generator/models/model_merchant_data.dart';
import 'package:simple_invoice_generator/models/model_sale_client.dart';
import 'package:simple_invoice_generator/models/model_sale_item.dart';

/// Cache / cookie manager implemented using the shared_preferences package.
///
class IgServiceCacheManager {
  const IgServiceCacheManager._();

  /// A global instance of the underlying cache manager implementation.
  ///
  /// Values can be fetched from this instance.
  ///
  static late SharedPreferences instance;

  /// Defines whether the cookie consent has been given by the user.
  ///
  static late bool cookieConsentApproved;

  /// Cached merchant / user data.
  ///
  static IgModelMerchantData? merchantData;

  /// List of cached sale items.
  ///
  static List<IgModelSaleItem> invoiceItems = [];

  /// List of cached client information.
  ///
  static List<IgModelSaleClient> clients = [];

  /// List of generated invoices.
  ///
  static List<IgModelInvoice> invoices = [];

  /// Initialises the cache manager and this class properties.
  ///
  static Future<void> init() async {
    instance = await SharedPreferences.getInstance();
    // Get cookie consent info.
    cookieConsentApproved = instance.getBool('cookieConsentApproved') ?? false;
    // Get cached merchant data.
    final merchantDataEncodedJson = instance.getString('merchantData');
    if (merchantDataEncodedJson != null) {
      try {
        final merchantDataMap = jsonDecode(merchantDataEncodedJson);
        merchantData = IgModelMerchantData.fromJson(merchantDataMap);
      } catch (e) {
        debugPrint('IgServiceCacheManager.init merchant data serialization error: $e');
      }
    }
    // Get cached product data.
    final invoiceItemsEncodedJson = instance.getStringList('invoiceItems');
    if (invoiceItemsEncodedJson != null) {
      for (var invoiceItemEncodedJson in invoiceItemsEncodedJson) {
        try {
          final invoiceItemMap = jsonDecode(invoiceItemEncodedJson);
          final invoiceItem = IgModelSaleItem.fromJson(invoiceItemMap);
          invoiceItems.add(invoiceItem);
        } catch (e) {
          debugPrint('IgServiceCacheManager.init product serialization error: $e');
        }
      }
    }
    // Get cached client data.
    final clientsEncodedJson = instance.getStringList('clients');
    if (clientsEncodedJson != null) {
      for (var clientEncodedJson in clientsEncodedJson) {
        try {
          final clientMap = jsonDecode(clientEncodedJson);
          final client = IgModelSaleClient.fromJson(clientMap);
          clients.add(client);
        } catch (e) {
          debugPrint('IgServiceCacheManager.init client serialization error: $e');
        }
      }
    }
    // Get cached invoices.
    final invoicesEncodedJson = instance.getStringList('invoices');
    if (invoicesEncodedJson != null) {
      for (var invoiceEncodedJson in invoicesEncodedJson) {
        try {
          final invoiceMap = jsonDecode(invoiceEncodedJson);
          final invoice = IgModelInvoice.fromJson(invoiceMap);
          invoices.add(invoice);
        } catch (e) {
          debugPrint('IgServiceCacheManager.init client serialization error: $e');
        }
      }
    }
  }
}
