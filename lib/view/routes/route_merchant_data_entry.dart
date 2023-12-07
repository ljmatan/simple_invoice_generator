// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:simple_invoice_generator/models/model_invoice.dart';
import 'package:simple_invoice_generator/models/model_merchant_data.dart';
import 'package:simple_invoice_generator/models/model_sale_client.dart';
import 'package:simple_invoice_generator/models/model_sale_item.dart';
import 'package:simple_invoice_generator/view/dialogs/dialog_cookies.dart';
import 'package:simple_invoice_generator/view/routes/route_invoice_generator.dart';
import 'package:simple_invoice_generator/services/service_cache_manager.dart';
import 'package:simple_invoice_generator/services/service_input_validation.dart';

class IgRouteMerchantDataEntry extends StatefulWidget {
  const IgRouteMerchantDataEntry({super.key});

  @override
  State<IgRouteMerchantDataEntry> createState() => _IgRouteMerchantDataEntryState();
}

class _IgRouteMerchantDataEntryState extends State<IgRouteMerchantDataEntry> {
  final _formKey = GlobalKey<FormState>();

  final _nameTextController = TextEditingController(
        text: IgServiceCacheManager.merchantData?.name ?? (kDebugMode ? 'Tvrtka j.d.o.o.' : null),
      ),
      _emailTextController = TextEditingController(
        text: IgServiceCacheManager.merchantData?.email ?? (kDebugMode ? 'email@email.com' : null),
      ),
      _addressTextController = TextEditingController(
        text: IgServiceCacheManager.merchantData?.address ?? (kDebugMode ? 'Ulica ta i ta 15' : null),
      ),
      _oibTextController = TextEditingController(
        text: IgServiceCacheManager.merchantData?.oib ?? (kDebugMode ? '55545787885' : null),
      ),
      _mbTextController = TextEditingController(
        text: IgServiceCacheManager.merchantData?.mb ?? (kDebugMode ? '01554972' : null),
      ),
      _ibanTextController = TextEditingController(
        text: IgServiceCacheManager.merchantData?.iban ?? (kDebugMode ? 'HR4624020068809568865' : null),
      ),
      _swiftCodeTextController = TextEditingController(
        text: IgServiceCacheManager.merchantData?.swiftCode ?? (kDebugMode ? 'ZABAHR2X' : null),
      ),
      _phoneNumberTextController = TextEditingController(
        text: IgServiceCacheManager.merchantData?.phoneNumber ?? (kDebugMode ? '+385955604626' : null),
      ),
      _overseeingCourtBodyTextController = TextEditingController(
        text: IgServiceCacheManager.merchantData?.overseeingCourtBody ?? (kDebugMode ? 'Trgovački sud u Zagrebu, Tt-23/44576-2' : null),
      ),
      _boardMembersTextController = TextEditingController(
        text: IgServiceCacheManager.merchantData?.boardMembers ?? (kDebugMode ? 'Član Uprave, Drugi Član Uprave' : null),
      ),
      _capitalBalanceTextController = TextEditingController(
        text: IgServiceCacheManager.merchantData?.capitalBalance.toStringAsFixed(2) ?? (kDebugMode ? '100,00' : null),
      );

  final _vatAppliedNotifier = ValueNotifier<bool>(IgServiceCacheManager.merchantData?.vatApplied ?? false);

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

  Future<void> _continue() async {
    if (_formKey.currentState?.validate() == true) {
      final merchantData = IgModelMerchantData(
        name: _nameTextController.text.trim(),
        email: _emailTextController.text.trim(),
        address: _addressTextController.text.trim(),
        oib: _oibTextController.text.trim(),
        mb: _mbTextController.text.trim(),
        iban: _ibanTextController.text.replaceAll(' ', ''),
        swiftCode: _swiftCodeTextController.text.trim(),
        phoneNumber: _phoneNumberTextController.text.replaceAll(' ', ''),
        vatApplied: _vatAppliedNotifier.value,
        overseeingCourtBody: _overseeingCourtBodyTextController.text.trim(),
        boardMembers: _boardMembersTextController.text.trim(),
        capitalBalance: num.parse(_capitalBalanceTextController.text.replaceAll(',', '.').trim()),
      );
      if (IgServiceCacheManager.cookieConsentApproved) {
        final merchantDataJson = merchantData.toJson();
        final merchantDataEncodedJson = jsonEncode(merchantDataJson);
        await IgServiceCacheManager.instance.setString('merchantData', merchantDataEncodedJson);
      }
      IgServiceCacheManager.merchantData = merchantData;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const IgRouteInvoiceGenerator(),
        ),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    if (!IgServiceCacheManager.cookieConsentApproved) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          showDialog(
            context: context,
            builder: (context) {
              return const IgDialogCookieConsent();
            },
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (MediaQuery.of(context).size.width < 1000)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                children: [
                  const Text(
                    'Unesite podatke svoje tvrtke',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 21,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Donje podatke zapisujemo na računalo u svrhu prikaza na generiranom računu. Sva polja su obavezna.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: MediaQuery.of(context).size.width < 1000
                        ? const EdgeInsets.symmetric(horizontal: 20)
                        : EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (MediaQuery.of(context).size.width >= 1000) ...[
                          const Padding(
                            padding: EdgeInsets.only(top: 16, bottom: 10),
                            child: Text(
                              'Unesite podatke svoje tvrtke',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 21,
                              ),
                            ),
                          ),
                          Text(
                            'Donje podatke zapisujemo na računalo u svrhu prikaza na generiranom računu. Sva polja su obavezna.',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameTextController,
                          decoration: const InputDecoration(
                            label: Text(
                              'Naziv tvrtke',
                            ),
                          ),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          keyboardType: TextInputType.name,
                          validator: (input) => IgServiceInputValidation.name(input),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _emailTextController,
                          decoration: const InputDecoration(
                            label: Text(
                              'Email adresa',
                            ),
                          ),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          keyboardType: TextInputType.emailAddress,
                          validator: (input) => IgServiceInputValidation.email(input),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _addressTextController,
                          decoration: const InputDecoration(
                            label: Text(
                              'Adresa tvrtke',
                            ),
                          ),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          keyboardType: TextInputType.streetAddress,
                          validator: (input) => IgServiceInputValidation.address(input),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _oibTextController,
                          decoration: const InputDecoration(
                            label: Text(
                              'OIB tvrtke',
                            ),
                          ),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          keyboardType: TextInputType.number,
                          validator: (input) => IgServiceInputValidation.oib(input),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _mbTextController,
                          decoration: const InputDecoration(
                            label: Text(
                              'Matični broj tvrtke',
                            ),
                          ),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          keyboardType: TextInputType.number,
                          validator: (input) => IgServiceInputValidation.mb(input),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _ibanTextController,
                          decoration: const InputDecoration(
                            label: Text(
                              'IBAN broj bankovnog računa',
                            ),
                          ),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          keyboardType: TextInputType.streetAddress,
                          validator: (input) => IgServiceInputValidation.iban(input),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _swiftCodeTextController,
                          decoration: const InputDecoration(
                            label: Text(
                              'SWIFT kod bankovnog računa',
                            ),
                          ),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          keyboardType: TextInputType.streetAddress,
                          validator: (input) => IgServiceInputValidation.name(input),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _phoneNumberTextController,
                          decoration: const InputDecoration(
                            label: Text(
                              'Kontakt telefon',
                            ),
                          ),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          keyboardType: TextInputType.phone,
                          validator: (input) => IgServiceInputValidation.phone(input),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _overseeingCourtBodyTextController,
                          decoration: const InputDecoration(
                            label: Text(
                              'Trgovački sud',
                            ),
                          ),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          keyboardType: TextInputType.name,
                          validator: (input) => IgServiceInputValidation.name(input),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _boardMembersTextController,
                          decoration: const InputDecoration(
                            label: Text(
                              'Članovi uprave',
                            ),
                          ),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          keyboardType: TextInputType.name,
                          validator: (input) => IgServiceInputValidation.name(input),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _capitalBalanceTextController,
                          decoration: const InputDecoration(
                            label: Text(
                              'Temeljni kapital u EUR',
                            ),
                          ),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (input) => IgServiceInputValidation.number(input),
                        ),
                        const SizedBox(height: 10),
                        ValueListenableBuilder(
                          valueListenable: _vatAppliedNotifier,
                          builder: (context, vatApplied, child) {
                            return Row(
                              children: [
                                const Expanded(
                                  child: Text('U sustavu PDV-a: '),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (int i = 0; i < 2; i++)
                                      TextButton(
                                        child: Text(
                                          i == 0 ? 'DA' : 'NE',
                                          style: i == 0 && vatApplied || i == 1 && !vatApplied
                                              ? const TextStyle(
                                                  decoration: TextDecoration.underline,
                                                  fontWeight: FontWeight.bold,
                                                )
                                              : const TextStyle(
                                                  color: Colors.grey,
                                                ),
                                        ),
                                        onPressed: () => _vatAppliedNotifier.value = i == 0,
                                      ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                        if (MediaQuery.of(context).size.width >= 1000) ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton(
                                child: const Text(
                                  'IMPORT',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () async => await _importData(),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton(
                                child: const Text(
                                  'NASTAVI',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () async => await _continue(),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (MediaQuery.of(context).size.width < 1000)
            DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                boxShadow: [
                  BoxShadow(
                    offset: Offset(0, -7),
                    blurRadius: 15,
                    color: Colors.black12,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  for (int i = 0; i < 2; i++)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: GestureDetector(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                          ),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: 48,
                            child: Center(
                              child: Text(
                                i == 0 ? 'IMPORT' : 'NASTAVI',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                        onTap: () async => i == 0 ? await _importData() : await _continue(),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameTextController.dispose();
    _emailTextController.dispose();
    _addressTextController.dispose();
    _oibTextController.dispose();
    _mbTextController.dispose();
    _ibanTextController.dispose();
    _swiftCodeTextController.dispose();
    _phoneNumberTextController.dispose();
    _overseeingCourtBodyTextController.dispose();
    _boardMembersTextController.dispose();
    _capitalBalanceTextController.dispose();
    _vatAppliedNotifier.dispose();
    super.dispose();
  }
}
