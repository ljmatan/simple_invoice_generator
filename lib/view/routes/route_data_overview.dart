// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:simple_invoice_generator/models/model_invoice.dart';
import 'package:simple_invoice_generator/models/model_merchant_data.dart';
import 'package:simple_invoice_generator/models/model_sale_client.dart';
import 'package:simple_invoice_generator/models/model_sale_item.dart';
import 'package:simple_invoice_generator/services/service_cache_manager.dart';
import 'package:simple_invoice_generator/view/routes/route_client_info_entry.dart';
import 'package:simple_invoice_generator/view/routes/route_invoice_generator.dart';
import 'package:simple_invoice_generator/view/routes/route_invoice_item_entry.dart';

class IgRouteDataOverview extends StatefulWidget {
  const IgRouteDataOverview({super.key});

  @override
  State<IgRouteDataOverview> createState() => _IgRouteDataOverviewState();
}

class _IgRouteDataOverviewState extends State<IgRouteDataOverview> {
  /// Import the company, invoice item and client data which can be exported with the [_exportData] method.
  ///
  Future<void> _importData() async {
    final input = html.FileUploadInputElement()..accept = '.txt,.json';
    input.onChange.listen(
      (event) {
        if (input.files?.isNotEmpty == true) {
          final file = input.files!.first;
          final fileBlob = file.slice();
          final fileReader = html.FileReader();
          fileReader.onLoad.listen(
            (e) async {
              final fileBytes = Uint8List.fromList(fileReader.result as List<int>);
              String fileContents = String.fromCharCodes(fileBytes);
              final Map<String, dynamic> importedData = jsonDecode(fileContents);
              final companyInfoJson = importedData['companyInfo'];
              if (companyInfoJson != null) {
                try {
                  IgServiceCacheManager.merchantData = IgModelMerchantData.fromJson(companyInfoJson);
                  await IgServiceCacheManager.instance.setString('merchantData', jsonEncode(companyInfoJson));
                } catch (e) {
                  debugPrint('$e');
                }
              }
              final invoiceItemsJson = importedData['invoiceItems'];
              if (invoiceItemsJson != null) {
                try {
                  IgServiceCacheManager.invoiceItems.clear();
                  IgServiceCacheManager.invoiceItems.addAll(
                    (invoiceItemsJson as Iterable).map(
                      (invoiceItemJson) => IgModelSaleItem.fromJson(invoiceItemJson),
                    ),
                  );
                  await IgServiceCacheManager.instance.setStringList(
                    'invoiceItems',
                    invoiceItemsJson.map((clientJson) => jsonEncode(clientJson)).toList(),
                  );
                } catch (e) {
                  debugPrint('$e');
                }
              }
              final clientsJson = importedData['clients'];
              if (clientsJson != null) {
                try {
                  IgServiceCacheManager.clients.clear();
                  IgServiceCacheManager.clients.addAll(
                    (clientsJson as Iterable).map(
                      (clientJson) => IgModelSaleClient.fromJson(clientJson),
                    ),
                  );
                  await IgServiceCacheManager.instance.setStringList(
                    'clients',
                    clientsJson.map((clientJson) => jsonEncode(clientJson)).toList(),
                  );
                } catch (e) {
                  debugPrint('$e');
                }
              }
              final invoicesJson = importedData['invoices'];
              if (invoicesJson != null) {
                try {
                  IgServiceCacheManager.invoices.clear();
                  IgServiceCacheManager.invoices.addAll(
                    (invoicesJson as Iterable).map(
                      (invoiceJson) => IgModelInvoice.fromJson(invoiceJson),
                    ),
                  );
                  await IgServiceCacheManager.instance.setStringList(
                    'invoices',
                    invoicesJson.map((invoiceJson) => jsonEncode(invoiceJson)).toList(),
                  );
                } catch (e) {
                  debugPrint('$e');
                }
              }
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const IgRouteInvoiceGenerator(),
                ),
                (Route<dynamic> route) => false,
              );
            },
          );
          fileReader.readAsArrayBuffer(fileBlob);
        }
      },
    );
    input.click();
  }

  /// Export all of the cached data in the JSON format.
  ///
  Future<void> _exportData() async {
    if (html.document.body != null) {
      final cachedData = <String, dynamic>{
        'companyInfo': IgServiceCacheManager.merchantData?.toJson(),
        'invoiceItems': IgServiceCacheManager.invoiceItems.map((invoiceItem) => invoiceItem.toJson()).toList(),
        'clients': IgServiceCacheManager.clients.map((client) => client.toJson()).toList(),
        'invoices': IgServiceCacheManager.invoices.map((invoice) => invoice.toJson()).toList(),
      };
      final text = jsonEncode(cachedData);
      final bytes = utf8.encode(text);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = 'Export_${DateTime.now().millisecondsSinceEpoch}.json';
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    }
  }

  late Set<({String label, void Function() onTap})> _actions;

  @override
  void initState() {
    super.initState();
    _actions = {
      (
        label: 'IMPORT PODATAKA',
        onTap: () async => await _importData(),
      ),
      (
        label: 'EXPORT PODATAKA',
        onTap: () async => await _exportData(),
      ),
      (
        label: 'DODAJ ARTIKL',
        onTap: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const IgRouteInvoiceItemEntry(),
            ),
            (Route<dynamic> route) => false,
          );
        },
      ),
      (
        label: 'DODAJ KLIJENTA',
        onTap: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const IgRouteClientInfoEntry(),
            ),
            (Route<dynamic> route) => false,
          );
        },
      ),
      (
        label: 'POČETNA',
        onTap: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const IgRouteInvoiceGenerator(),
            ),
            (Route<dynamic> route) => false,
          );
        },
      ),
    };
  }

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text(
          'Pregled podataka',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: MediaQuery.of(context).size.width < 1000
            ? [
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                ),
              ]
            : [
                for (final action in _actions.indexed) ...[
                  if (action.$1 != 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade700,
                        ),
                        child: const SizedBox(height: 20, width: 1),
                      ),
                    ),
                  TextButton(
                    child: Text(
                      action.$2.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: action.$2.onTap,
                  ),
                ],
                const SizedBox(width: 16),
              ],
      ),
      endDrawer: Drawer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final action in _actions.indexed)
              TextButton(
                child: Text(
                  action.$2.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                onPressed: action.$2.onTap,
              ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          Text(
            'Podatci tvrtke',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Divider(),
          const SizedBox(height: 10),
          if (IgServiceCacheManager.merchantData != null)
            for (final info in IgServiceCacheManager.merchantData!.formattedInfo)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text.rich(
                  TextSpan(
                    text: '${info.label}: ',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                    children: [
                      TextSpan(
                        text: info.value,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 16),
          Text(
            'Klijenti',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Divider(),
          const SizedBox(height: 10),
          if (IgServiceCacheManager.clients.isEmpty)
            const Text('Nema spremljenih podataka.')
          else
            for (final client in IgServiceCacheManager.clients)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                client.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            OutlinedButton(
                              child: const Text(
                                'UKLONI',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () async {
                                setState(() => IgServiceCacheManager.clients.remove(client));
                                await IgServiceCacheManager.instance.setStringList(
                                  'clients',
                                  IgServiceCacheManager.clients.map((client) => jsonEncode(client.toJson())).toList(),
                                );
                              },
                            ),
                          ],
                        ),
                        Text(
                          'OIB ${client.oib}\n${client.address}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          const SizedBox(height: 16),
          Text(
            'Proizvodi ili usluge',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Divider(),
          const SizedBox(height: 10),
          if (IgServiceCacheManager.invoiceItems.isEmpty)
            const Text('Nema spremljenih podataka.')
          else
            for (final invoiceItem in IgServiceCacheManager.invoiceItems)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                invoiceItem.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            OutlinedButton(
                              child: const Text(
                                'UKLONI',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () async {
                                setState(() => IgServiceCacheManager.invoiceItems.remove(invoiceItem));
                                await IgServiceCacheManager.instance.setStringList(
                                  'invoiceItems',
                                  IgServiceCacheManager.invoiceItems.map((invoiceItem) => jsonEncode(invoiceItem.toJson())).toList(),
                                );
                              },
                            ),
                          ],
                        ),
                        Text(
                          '${invoiceItem.price.toStringAsFixed(2)} EUR\nMjera: ${invoiceItem.measure}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          const SizedBox(height: 16),
          Text(
            'Računi',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Divider(),
          const SizedBox(height: 10),
          if (IgServiceCacheManager.invoices.isEmpty)
            const Text('Nema spremljenih podataka.')
          else
            for (var invoice in IgServiceCacheManager.invoices)
              StatefulBuilder(
                builder: (context, setThisState) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Račun br. ${invoice.paymentId}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                OutlinedButton(
                                  child: const Text(
                                    'UKLONI',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: () async {
                                    setState(() => IgServiceCacheManager.invoices.remove(invoice));
                                    await IgServiceCacheManager.instance.setStringList(
                                      'invoices',
                                      IgServiceCacheManager.invoices.map((invoice) => jsonEncode(invoice.toJson())).toList(),
                                    );
                                  },
                                ),
                              ],
                            ),
                            Text(
                              '${invoice.time.day}.${invoice.time.month}.${invoice.time.year}. '
                              '${invoice.time.hour}:${invoice.time.minute}',
                            ),
                            Builder(
                              builder: (context) {
                                num productSum = 0;
                                for (var product in invoice.invoiceItems) {
                                  productSum += product.price * product.amount;
                                }
                                return Text(
                                  'Cijena: ${productSum.toStringAsFixed(2)} EUR',
                                );
                              },
                            ),
                            ...[
                              for (var invoiceItem in invoice.invoiceItems)
                                Text.rich(
                                  TextSpan(
                                    text: invoiceItem.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    children: [
                                      TextSpan(
                                        text:
                                            ' ${invoiceItem.price.toStringAsFixed(2)} EUR - ${invoiceItem.amount} ${invoiceItem.measure} - '
                                            '${(invoiceItem.price * invoiceItem.amount).toStringAsFixed(2)} EUR',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
        ],
      ),
    );
  }
}
