// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:simple_invoice_generator/models/model_invoice_item.dart';
import 'package:simple_invoice_generator/models/model_merchant_data.dart';
import 'package:simple_invoice_generator/models/model_sale_client.dart';
import 'package:simple_invoice_generator/models/model_sale_item.dart';
import 'package:simple_invoice_generator/view/routes/route_client_info_entry.dart';
import 'package:simple_invoice_generator/view/routes/route_invoice_item_entry.dart';
import 'package:simple_invoice_generator/view/routes/route_merchant_data_entry.dart';
import 'package:simple_invoice_generator/services/service_cache_manager.dart';
import 'package:simple_invoice_generator/services/service_input_validation.dart';
import 'package:simple_invoice_generator/services/service_pdf_generator.dart';

class IgRouteInvoiceGenerator extends StatefulWidget {
  const IgRouteInvoiceGenerator({super.key});

  @override
  State<IgRouteInvoiceGenerator> createState() => _IgRouteInvoiceGeneratorState();
}

class _IgRouteInvoiceGeneratorState extends State<IgRouteInvoiceGenerator> {
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
              debugPrint('$companyInfoJson');
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
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const IgRouteInvoiceGenerator(),
        ),
        (Route<dynamic> route) => false,
      );
    }
  }

  final _formKey = GlobalKey<FormState>();

  final _clientNameTextController = TextEditingController(),
      _clientOibTextController = TextEditingController(),
      _clientAddressTextController = TextEditingController();

  final _invoiceItemNameTextController = TextEditingController(),
      _invoiceItemAmountTextController = TextEditingController(),
      _invoiceItemMeasureTextController = TextEditingController(),
      _invoiceItemPriceTextController = TextEditingController();

  final _paymentMethodTextController = TextEditingController(text: 'Transakcija na bankovni račun'),
      _paymentModelTextController = TextEditingController(text: 'HR99'),
      _paymentCodeTextController = TextEditingController(text: DateTime.now().millisecondsSinceEpoch.toString());

  String? _invoiceItemValidationError;

  final _invoiceItems = <IgModelInvoiceItem>[];

  bool _generatingInvoice = false;

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text(
          'Izrada računa',
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
                for (final action in <({String title, void Function() onTap})>{
                  (
                    title: 'IMPORT PODATAKA',
                    onTap: () async => await _importData(),
                  ),
                  (
                    title: 'EXPORT PODATAKA',
                    onTap: () async => await _exportData(),
                  ),
                  (
                    title: 'DODAJ ARTIKL',
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
                    title: 'DODAJ KLIJENTA',
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
                    title: 'IZMIJENI PODATKE TVRTKE',
                    onTap: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const IgRouteMerchantDataEntry(),
                        ),
                        (Route<dynamic> route) => false,
                      );
                    },
                  ),
                }.indexed)
                  Row(
                    children: [
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
                          action.$2.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: action.$2.onTap,
                      ),
                    ],
                  ),
                const SizedBox(width: 16),
              ],
      ),
      endDrawer: Drawer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final action in <({String title, void Function() onTap})>{
              (
                title: 'IMPORT PODATAKA',
                onTap: () async => await _importData(),
              ),
              (
                title: 'EXPORT PODATAKA',
                onTap: () async => await _exportData(),
              ),
              (
                title: 'DODAJ ARTIKL',
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
                title: 'DODAJ KLIJENTA',
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
                title: 'IZMIJENI PODATKE TVRTKE',
                onTap: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const IgRouteMerchantDataEntry(),
                    ),
                    (Route<dynamic> route) => false,
                  );
                },
              ),
            }.indexed)
              TextButton(
                child: Text(
                  action.$2.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: action.$2.onTap,
              ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 80),
          children: [
            Text(
              'U donja polja upisujete podatke kupca, te usluga ili artikala koji će biti prikazani na generiranom računu.\n',
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
            MediaQuery.of(context).size.width < 1000
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final merchantInfo in <({String label, String value})>{
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
                          label: 'MB',
                          value: IgServiceCacheManager.merchantData?.mb ?? 'N/A',
                        ),
                        (
                          label: 'IBAN',
                          value: IgServiceCacheManager.merchantData?.iban ?? 'N/A',
                        ),
                        (
                          label: 'Telefonski broj',
                          value: IgServiceCacheManager.merchantData?.phoneNumber ?? 'N/A',
                        ),
                      })
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text.rich(
                            TextSpan(
                              text: '${merchantInfo.label}: ',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                              ),
                              children: [
                                TextSpan(
                                  text: merchantInfo.value,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      DropdownMenu(
                        controller: _clientNameTextController,
                        label: const Text(
                          'Naziv klijenta (opcionalno)',
                        ),
                        width: MediaQuery.of(context).size.width - 32,
                        inputDecorationTheme: Theme.of(context).inputDecorationTheme,
                        enableFilter: true,
                        enableSearch: true,
                        dropdownMenuEntries: [
                          for (var client in IgServiceCacheManager.clients)
                            DropdownMenuEntry(
                              value: client,
                              label: client.name,
                            ),
                        ],
                        onSelected: (client) {
                          _clientNameTextController.text = client?.name ?? '';
                          _clientOibTextController.text = client?.oib ?? '';
                          _clientAddressTextController.text = client?.address ?? '';
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _clientOibTextController,
                        decoration: const InputDecoration(
                          label: Text(
                            'OIB klijenta (opcionalno)',
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (input) => input?.isNotEmpty == true ? IgServiceInputValidation.oib(input) : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _clientAddressTextController,
                        decoration: const InputDecoration(
                          label: Text(
                            'Adresa klijenta (opcionalno)',
                          ),
                        ),
                        keyboardType: TextInputType.streetAddress,
                        validator: (input) => input?.isNotEmpty == true ? IgServiceInputValidation.address(input) : null,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final merchantInfo in <({String label, String value})>{
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
                                label: 'MB',
                                value: IgServiceCacheManager.merchantData?.mb ?? 'N/A',
                              ),
                              (
                                label: 'IBAN',
                                value: IgServiceCacheManager.merchantData?.iban ?? 'N/A',
                              ),
                              (
                                label: 'Telefonski broj',
                                value: IgServiceCacheManager.merchantData?.phoneNumber ?? 'N/A',
                              ),
                            })
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text.rich(
                                  TextSpan(
                                    text: '${merchantInfo.label}: ',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: merchantInfo.value,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            DropdownMenu(
                              controller: _clientNameTextController,
                              label: const Text(
                                'Naziv klijenta (opcionalno)',
                              ),
                              width: MediaQuery.of(context).size.width / 2 - 21,
                              inputDecorationTheme: Theme.of(context).inputDecorationTheme,
                              enableFilter: true,
                              enableSearch: true,
                              dropdownMenuEntries: [
                                for (var client in IgServiceCacheManager.clients)
                                  DropdownMenuEntry(
                                    value: client,
                                    label: client.name,
                                  ),
                              ],
                              onSelected: (client) {
                                _clientNameTextController.text = client?.name ?? '';
                                _clientOibTextController.text = client?.oib ?? '';
                                _clientAddressTextController.text = client?.address ?? '';
                              },
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _clientOibTextController,
                              decoration: const InputDecoration(
                                label: Text(
                                  'OIB klijenta (opcionalno)',
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (input) => input?.isNotEmpty == true ? IgServiceInputValidation.oib(input) : null,
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _clientAddressTextController,
                              decoration: const InputDecoration(
                                label: Text(
                                  'Adresa klijenta (opcionalno)',
                                ),
                              ),
                              keyboardType: TextInputType.streetAddress,
                              validator: (input) => input?.isNotEmpty == true ? IgServiceInputValidation.address(input) : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Za svaki proizvod ili uslugu prikazanu na računu su definirana 4 obavezna polja:\n\n'
                '- Naziv proizvoda ili usluge (npr. "Zavjese")\n'
                '- Količina (npr. "2")\n'
                '- Mjerna jedinica (npr. "Kom")\n'
                '- Pojedinačna (ne ukupna) cijena proizvoda u EUR, npr. "10.50")\n\n'
                'Nakon unosa svih vrijednosti, stisnite na "Dodaj novi zapis" tipku kako bi se napravio zapis.',
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            if (_invoiceItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (MediaQuery.of(context).size.width < 1000)
                      for (var invoiceItem in _invoiceItems.indexed) ...[
                        if (invoiceItem.$1 != 0) const Divider(),
                        for (final info in <({String label, String value})>{
                          (
                            label: 'Naziv',
                            value: invoiceItem.$2.name,
                          ),
                          (
                            label: 'Količina',
                            value: invoiceItem.$2.amount.toString(),
                          ),
                          (
                            label: 'Mj. jedinica',
                            value: invoiceItem.$2.measure,
                          ),
                          (
                            label: 'Cijena proizvoda u EUR',
                            value: '${invoiceItem.$2.price} EUR',
                          ),
                        }.indexed) ...[
                          if (info.$1 == 0) const SizedBox(height: 10),
                          Text.rich(
                            TextSpan(
                              text: '${info.$2.label}: ',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                              ),
                              children: [
                                TextSpan(
                                  text: info.$2.value,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        OutlinedButton(
                          child: const Text('UKLONI'),
                          onPressed: () {
                            setState(() => _invoiceItems.remove(invoiceItem.$2));
                          },
                        ),
                      ]
                    else
                      for (var invoiceItem in _invoiceItems.indexed) ...[
                        if (invoiceItem.$1 != 0) const Divider(),
                        Row(
                          children: [
                            for (final info in <({String label, String value})>{
                              (
                                label: 'Naziv',
                                value: invoiceItem.$2.name,
                              ),
                              (
                                label: 'Količina',
                                value: invoiceItem.$2.amount.toString(),
                              ),
                              (
                                label: 'Mjerna jedinica',
                                value: invoiceItem.$2.measure,
                              ),
                              (
                                label: 'Cijena proizvoda u EUR',
                                value: '${invoiceItem.$2.price} EUR',
                              ),
                            }.indexed)
                              if (info.$1 == 0)
                                SizedBox(
                                  width: MediaQuery.of(context).size.width / 2.5,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text.rich(
                                        TextSpan(
                                          text: '${info.$2.label}: ',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: info.$2.value,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      OutlinedButton(
                                        child: const Text('UKLONI'),
                                        onPressed: () {
                                          setState(() => _invoiceItems.remove(invoiceItem.$2));
                                        },
                                      ),
                                    ],
                                  ),
                                )
                              else ...[
                                if (info.$1 != 2) const SizedBox(width: 10),
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      text: '${info.$2.label}: ',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: info.$2.value,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (info.$1 != 3) const SizedBox(width: 10),
                              ],
                          ],
                        ),
                      ],
                  ],
                ),
              ),
            const SizedBox(height: 16),
            MediaQuery.of(context).size.width < 1000
                ? Column(
                    children: [
                      DropdownMenu(
                        controller: _invoiceItemNameTextController,
                        label: const Text(
                          'Naziv proizvoda ili usluge',
                        ),
                        width: MediaQuery.of(context).size.width - 32,
                        inputDecorationTheme: Theme.of(context).inputDecorationTheme,
                        dropdownMenuEntries: [
                          for (var invoiceItem in IgServiceCacheManager.invoiceItems)
                            DropdownMenuEntry(
                              value: invoiceItem,
                              label: invoiceItem.name,
                            ),
                        ],
                        onSelected: (invoiceItem) {
                          _invoiceItemNameTextController.text = invoiceItem?.name ?? '';
                          _invoiceItemMeasureTextController.text = invoiceItem?.measure ?? '';
                          _invoiceItemPriceTextController.text = invoiceItem?.price.toString() ?? '';
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _invoiceItemAmountTextController,
                        decoration: const InputDecoration(
                          label: Text('Količina'),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 10),
                      DropdownMenu(
                        controller: _invoiceItemMeasureTextController,
                        label: const Text('Mjerna jedinica'),
                        inputDecorationTheme: Theme.of(context).inputDecorationTheme,
                        width: MediaQuery.of(context).size.width - 32,
                        dropdownMenuEntries: [
                          for (final measure in <String>{
                            'KG',
                            'L',
                            'Kom',
                            'm',
                          }..addAll(IgServiceCacheManager.invoiceItems.map((invoiceItem) => invoiceItem.measure)))
                            DropdownMenuEntry(
                              value: measure,
                              label: measure,
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _invoiceItemPriceTextController,
                        decoration: const InputDecoration(
                          label: Text('Cijena proizvoda u EUR'),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      DropdownMenu(
                        controller: _invoiceItemNameTextController,
                        label: const Text(
                          'Naziv proizvoda ili usluge',
                        ),
                        width: MediaQuery.of(context).size.width / 2.5,
                        inputDecorationTheme: Theme.of(context).inputDecorationTheme,
                        dropdownMenuEntries: [
                          for (var invoiceItem in IgServiceCacheManager.invoiceItems)
                            DropdownMenuEntry(
                              value: invoiceItem,
                              label: invoiceItem.name,
                            ),
                        ],
                        onSelected: (invoiceItem) {
                          _invoiceItemNameTextController.text = invoiceItem?.name ?? '';
                          _invoiceItemMeasureTextController.text = invoiceItem?.measure ?? '';
                          _invoiceItemPriceTextController.text = invoiceItem?.price.toString() ?? '';
                        },
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _invoiceItemAmountTextController,
                          decoration: const InputDecoration(
                            label: Text('Količina'),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      DropdownMenu(
                        controller: _invoiceItemMeasureTextController,
                        label: const Text('Mjerna jedinica'),
                        inputDecorationTheme: Theme.of(context).inputDecorationTheme,
                        width: (MediaQuery.of(context).size.width - (MediaQuery.of(context).size.width / 2.5) - 30) / 3,
                        dropdownMenuEntries: [
                          for (final measure in <String>{
                            'KG',
                            'L',
                            'Kom',
                            'm',
                          }..addAll(IgServiceCacheManager.invoiceItems.map((invoiceItem) => invoiceItem.measure)))
                            DropdownMenuEntry(
                              value: measure,
                              label: measure,
                            ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _invoiceItemPriceTextController,
                          decoration: const InputDecoration(
                            label: Text('Cijena proizvoda u EUR'),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 8),
            StatefulBuilder(
              builder: (context, setThisState) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _invoiceItemValidationError != null
                        ? Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 12),
                            child: Text(
                              _invoiceItemValidationError!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          )
                        : const SizedBox(height: 8),
                    InkWell(
                      child: Ink(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green.shade200,
                                ),
                                child: const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Center(
                                    child: Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const Text(
                                '  Dodaj novi zapis',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      onTap: () {
                        if (_invoiceItemNameTextController.text.trim().length < 3) {
                          setThisState(() {
                            _invoiceItemValidationError = 'Molimo provjerite uneseni naziv. Naziv mora sadržavati minimalno 3 znakova.';
                          });
                          return;
                        }
                        if (_invoiceItemMeasureTextController.text.trim().isEmpty) {
                          setThisState(() {
                            _invoiceItemValidationError = 'Molimo provjerite unesenu mjernu jedinicu. Mjerna jedinica sadrži samo slova.';
                          });
                          return;
                        }
                        if (_invoiceItemAmountTextController.text.trim().isEmpty ||
                            num.tryParse(_invoiceItemAmountTextController.text.trim()) == null) {
                          setThisState(() {
                            _invoiceItemValidationError =
                                'Molimo provjerite unesenu količinu. Količina može biti cijeli ili decimalni broj.';
                          });
                          return;
                        }
                        if (_invoiceItemPriceTextController.text.trim().isEmpty ||
                            num.tryParse(_invoiceItemPriceTextController.text.trim()) == null) {
                          setThisState(() {
                            _invoiceItemValidationError = 'Molimo provjerite unesenu cijenu. Cijena može biti cijeli ili decimalni broj.';
                          });
                          return;
                        }
                        _invoiceItems.add(
                          IgModelInvoiceItem(
                            name: _invoiceItemNameTextController.text.trim(),
                            measure: _invoiceItemMeasureTextController.text.trim(),
                            amount: num.parse(_invoiceItemAmountTextController.text.trim()),
                            price: num.parse(_invoiceItemPriceTextController.text.trim()),
                          ),
                        );
                        _invoiceItemNameTextController.clear();
                        _invoiceItemMeasureTextController.clear();
                        _invoiceItemAmountTextController.clear();
                        _invoiceItemPriceTextController.clear();
                        setState(() => _invoiceItemValidationError = null);
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Donja polja definiraju način plaćanja, te šifru namjene i model plaćanja ukoliko se plaćanje vodi bankovnom transakcijom.\n\n'
              'Način plaćanja i šifra namjene su polja u koje možete unijeti bilo koju vrijednost.\n\n'
              'Šifra namjene se automatski popunjava trenutnim vremenom u formatu koji kompjuter prepoznaje, '
              'stoga je šifra namjene uvijek unikatna za svaki račun, te se iz nje može iščitati vrijeme izdavanja računa.',
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Način plaćanja:  '),
                Flexible(
                  child: TextField(
                    controller: _paymentMethodTextController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Šifra namjene:  '),
                Flexible(
                  child: TextField(
                    controller: _paymentCodeTextController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Model plaćanja:  '),
                DropdownMenu(
                  controller: _paymentModelTextController,
                  inputDecorationTheme: Theme.of(context).inputDecorationTheme,
                  dropdownMenuEntries: [
                    for (int i = 0; i < 100; i++)
                      DropdownMenuEntry(
                        value: 'HR' + (i < 10 ? '0$i' : '$i'),
                        label: 'HR' + (i < 10 ? '0$i' : '$i'),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: StatefulBuilder(
        builder: (context, setThisState) {
          return FloatingActionButton.extended(
            label: _generatingInvoice
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(),
                  )
                : const Text(
                    'GENERIRAJ RAČUN',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            icon: _generatingInvoice ? null : const Icon(Icons.file_download),
            onPressed: _generatingInvoice
                ? null
                : () async {
                    if (_invoiceItems.isEmpty) {
                      setState(() {
                        _invoiceItemValidationError = 'Molimo unesite bar jednu vrijednost i stisnite tipku "Dodaj novi zapis".';
                      });
                      return;
                    }
                    setThisState(() => _generatingInvoice = true);
                    await IgServicePdfGenerator.generatePdfInvoice(
                      invoiceItems: _invoiceItems,
                      clientInfo: IgModelSaleClient(
                        name: _clientNameTextController.text.trim(),
                        oib: _clientOibTextController.text.trim().isEmpty ? null : _clientOibTextController.text.trim(),
                        address: _clientAddressTextController.text.trim().isEmpty ? null : _clientAddressTextController.text.trim(),
                      ),
                    );
                    setThisState(() => _generatingInvoice = false);
                  },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _clientNameTextController.dispose();
    _clientOibTextController.dispose();
    _clientAddressTextController.dispose();
    _invoiceItemNameTextController.dispose();
    _invoiceItemAmountTextController.dispose();
    _invoiceItemMeasureTextController.dispose();
    _invoiceItemPriceTextController.dispose();
    _paymentMethodTextController.dispose();
    _paymentModelTextController.dispose();
    _paymentCodeTextController.dispose();
    super.dispose();
  }
}
