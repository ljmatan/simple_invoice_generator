import 'package:flutter/material.dart';
import 'package:simple_invoice_generator/models/model_invoice.dart';
import 'package:simple_invoice_generator/models/model_invoice_item.dart';
import 'package:simple_invoice_generator/models/model_sale_client.dart';
import 'package:simple_invoice_generator/view/dialogs/dialog_cookies.dart';
import 'package:simple_invoice_generator/view/routes/route_data_overview.dart';
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
  late Set<({String title, void Function() onTap})> _actions;

  final _formKey = GlobalKey<FormState>();

  final _paymentIdTextController = TextEditingController(),
      _paymentLocationIdTextController = TextEditingController(text: '1'),
      _paymentRegisterIdTextController = TextEditingController(text: '1'),
      _clientNameTextController = TextEditingController(),
      _clientOibTextController = TextEditingController(),
      _clientAddressTextController = TextEditingController();

  final _invoiceItemNameTextController = TextEditingController(),
      _invoiceItemAmountTextController = TextEditingController(),
      _invoiceItemMeasureTextController = TextEditingController(),
      _invoiceItemPriceTextController = TextEditingController();

  final _paymentMethodTextController = TextEditingController(
        text: IgServiceCacheManager.instance.getString('paymentMethod') ?? 'Transakcija na bankovni račun',
      ),
      _paymentModelTextController = TextEditingController(
        text: IgServiceCacheManager.instance.getString('paymentModel') ?? 'HR99',
      );
  final _paymentMethodFocusNode = FocusNode(), _paymentModelFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _actions = <({String title, void Function() onTap})>{
      (
        title: 'PRAVILA PRIVATNOSTI',
        onTap: () {
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
        },
      ),
      if (IgServiceCacheManager.cookieConsentApproved)
        (
          title: 'PREGLED PODATAKA',
          onTap: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const IgRouteDataOverview(),
              ),
              (Route<dynamic> route) => false,
            );
          },
        )
      else
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
    };
    _paymentMethodTextController.addListener(() {
      IgServiceCacheManager.instance.setString('paymentMethod', _paymentMethodTextController.text.trim());
    });
    _paymentModelTextController.addListener(() {
      IgServiceCacheManager.instance.setString('paymentModel', _paymentModelTextController.text.trim());
    });
  }

  String? _invoiceItemValidationError;

  final _invoiceItems = <IgModelInvoiceItem>[];

  bool _generatingInvoice = false;

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final _scrollController = ScrollController();

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
        toolbarHeight: MediaQuery.of(context).size.width < 1000
            ? kToolbarHeight
            : MediaQuery.of(context).size.height * .07 > 100
                ? 100
                : MediaQuery.of(context).size.height * .07,
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
                      action.$2.title,
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
                  action.$2.title,
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
      body: Form(
        key: _formKey,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Osnovni podatci',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Tooltip(
                  child: Icon(
                    Icons.help,
                    size: 26,
                    color: Theme.of(context).primaryColor,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.all(12),
                  textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: MediaQuery.of(context).size.width < 1000 ? null : 16,
                      ),
                  message: 'Sekcija sadrži informativne podatke o tvrtci, te nekoliko polja sa mogučnošću uređivanja sadržaja.\n\n'
                      '"Način plaćanja" i "Model plaćanja" su informacije koje se prema potrebi mogu uređivati ili obrisati, '
                      'te im se zadana vrijednost odnosi na bankovnu uplatu.\n\n'
                      'Polja za redni broj računa, broj poslovnog prostora, i broj naplatnog uređaj su obavezna, '
                      'dok su ostala polja opcionalna.',
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),
            MediaQuery.of(context).size.width < 1000
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (IgServiceCacheManager.merchantData != null)
                        for (final merchantInfo in IgServiceCacheManager.merchantData!.formattedInfo)
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
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Text('Način plaćanja:  '),
                            Flexible(
                              child: EditableText(
                                controller: _paymentMethodTextController,
                                focusNode: _paymentMethodFocusNode,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                cursorColor: Colors.black,
                                backgroundCursorColor: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Text('Model plaćanja:  '),
                            Flexible(
                              child: EditableText(
                                controller: _paymentModelTextController,
                                focusNode: _paymentModelFocusNode,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                cursorColor: Colors.black,
                                backgroundCursorColor: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _paymentIdTextController,
                        decoration: const InputDecoration(
                          label: Text(
                            'Redni broj računa',
                          ),
                        ),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        keyboardType: TextInputType.number,
                        validator: (input) => IgServiceInputValidation.number(input),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _paymentLocationIdTextController,
                        decoration: const InputDecoration(
                          label: Text(
                            'Poslovni prostor',
                          ),
                        ),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        keyboardType: TextInputType.number,
                        validator: (input) => IgServiceInputValidation.number(input),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _paymentRegisterIdTextController,
                        decoration: const InputDecoration(
                          label: Text(
                            'Naplatni uređaj',
                          ),
                        ),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        keyboardType: TextInputType.number,
                        validator: (input) => IgServiceInputValidation.number(input),
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
                        autovalidateMode: AutovalidateMode.onUserInteraction,
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
                        autovalidateMode: AutovalidateMode.onUserInteraction,
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
                            if (IgServiceCacheManager.merchantData != null)
                              for (final merchantInfo in IgServiceCacheManager.merchantData!.formattedInfo)
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
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).textTheme.bodyMedium?.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  const Text('Način plaćanja:  '),
                                  Flexible(
                                    child: EditableText(
                                      controller: _paymentMethodTextController,
                                      focusNode: _paymentMethodFocusNode,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        background: Paint()..color = Colors.grey.shade100,
                                      ),
                                      cursorColor: Colors.black,
                                      backgroundCursorColor: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  const Text('Model plaćanja:  '),
                                  Flexible(
                                    child: EditableText(
                                      controller: _paymentModelTextController,
                                      focusNode: _paymentModelFocusNode,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        background: Paint()..color = Colors.grey.shade100,
                                      ),
                                      cursorColor: Colors.black,
                                      backgroundCursorColor: Colors.black,
                                    ),
                                  ),
                                ],
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
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _paymentIdTextController,
                                    decoration: const InputDecoration(
                                      label: Text(
                                        'Redni broj računa',
                                      ),
                                    ),
                                    autovalidateMode: AutovalidateMode.onUserInteraction,
                                    keyboardType: TextInputType.number,
                                    validator: (input) => IgServiceInputValidation.number(input),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _paymentLocationIdTextController,
                                    decoration: const InputDecoration(
                                      label: Text(
                                        'Poslovni prostor',
                                      ),
                                    ),
                                    autovalidateMode: AutovalidateMode.onUserInteraction,
                                    keyboardType: TextInputType.number,
                                    validator: (input) => IgServiceInputValidation.number(input),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _paymentRegisterIdTextController,
                                    decoration: const InputDecoration(
                                      label: Text(
                                        'Naplatni uređaj',
                                      ),
                                    ),
                                    autovalidateMode: AutovalidateMode.onUserInteraction,
                                    keyboardType: TextInputType.number,
                                    validator: (input) => IgServiceInputValidation.number(input),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
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
                              autovalidateMode: AutovalidateMode.onUserInteraction,
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
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              keyboardType: TextInputType.streetAddress,
                              validator: (input) => input?.isNotEmpty == true ? IgServiceInputValidation.address(input) : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Artikli',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Tooltip(
                    child: Icon(
                      Icons.help,
                      size: 26,
                      color: Theme.of(context).primaryColor,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.all(12),
                    textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: MediaQuery.of(context).size.width < 1000 ? null : 16,
                        ),
                    message: 'U ovu sekciju unosite popis artikala za ispis na računu.\n\n'
                        'Nakon unosa informacija u donja polja, potrebno je potvrditi unos pritiskom na tipku "Dodaj stavku"'
                        'kako bi se informacija zapisala.',
                  ),
                ],
              ),
            ),
            const Divider(),
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
                        autovalidateMode: AutovalidateMode.onUserInteraction,
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
                            'KILOGRAM',
                            'LITRA',
                            'KOMAD',
                            'METAR',
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
                        autovalidateMode: AutovalidateMode.onUserInteraction,
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
                          autovalidateMode: AutovalidateMode.onUserInteraction,
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
                            'KILOGRAM',
                            'LITRA',
                            'KOMAD',
                            'METAR',
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
                          autovalidateMode: AutovalidateMode.onUserInteraction,
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
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '➕   DODAJ STAVKU',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
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
                        final parsedAmountNumber = num.tryParse(_invoiceItemAmountTextController.text.replaceAll(',', '.').trim());
                        if (parsedAmountNumber == null || parsedAmountNumber < 0) {
                          setThisState(() {
                            _invoiceItemValidationError =
                                'Molimo provjerite unesenu količinu. Količina može biti cijeli ili decimalni broj.';
                          });
                          return;
                        }
                        if (num.tryParse(_invoiceItemPriceTextController.text.replaceAll(',', '.').trim()) == null) {
                          setThisState(() {
                            _invoiceItemValidationError = 'Molimo provjerite unesenu cijenu. Cijena može biti cijeli ili decimalni broj.';
                          });
                          return;
                        }
                        _invoiceItems.add(
                          IgModelInvoiceItem(
                            name: _invoiceItemNameTextController.text.trim(),
                            measure: _invoiceItemMeasureTextController.text.trim(),
                            amount: num.parse(_invoiceItemAmountTextController.text.replaceAll(',', '.').trim()),
                            price: num.parse(_invoiceItemPriceTextController.text.replaceAll(',', '.').trim()),
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
            const SizedBox(height: 10),
            if (_invoiceItems.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 18),
                    child: Row(
                      children: [
                        const Text(
                          'Ukupno: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Builder(
                          builder: (context) {
                            num productPriceSum = 0;
                            for (var item in _invoiceItems) {
                              productPriceSum += item.amount * item.price;
                            }
                            return Text(
                              '${productPriceSum.toStringAsFixed(2)} EUR' +
                                  (DateTime.now().year < 2024 ? ' - ${(productPriceSum * 7.5345).toStringAsFixed(2)} HRK' : ''),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
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
                          label: 'Cijena u EUR',
                          value: invoiceItem.$2.amount == 1
                              ? '${invoiceItem.$2.price.toStringAsFixed(2)} EUR'
                              : '${(invoiceItem.$2.price * invoiceItem.$2.amount).toStringAsFixed(2)} EUR '
                                  '(${invoiceItem.$2.price.toStringAsFixed(2)}€ x ${invoiceItem.$2.amount})',
                        ),
                      }.indexed) ...[
                        if (info.$1 == 0) const SizedBox(height: 10),
                        info.$1 == 0
                            ? Row(
                                children: [
                                  Expanded(
                                    child: Text.rich(
                                      TextSpan(
                                        text: '${info.$1 + 1}. ',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 16,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: info.$2.value,
                                            style: TextStyle(
                                              color: Theme.of(context).textTheme.bodyMedium?.color,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          TextSpan(text: ' ${invoiceItem.$2.price.toStringAsFixed(2)} EUR'),
                                        ],
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    child: const Text(
                                      'UKLONI',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onPressed: () {
                                      setState(() => _invoiceItems.remove(invoiceItem.$2));
                                    },
                                  ),
                                ],
                              )
                            : Text.rich(
                                TextSpan(
                                  text: '${info.$2.label}: ',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: info.$2.value,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ],
                    ]
                  else ...[
                    for (var invoiceItem in _invoiceItems.indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
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
                                label: 'Cijena u EUR',
                                value: invoiceItem.$2.amount == 1
                                    ? '${invoiceItem.$2.price.toStringAsFixed(2)} EUR'
                                    : '${(invoiceItem.$2.price * invoiceItem.$2.amount).toStringAsFixed(2)} EUR '
                                        '(${invoiceItem.$2.price.toStringAsFixed(2)}€ x ${invoiceItem.$2.amount})',
                              ),
                            }.indexed)
                              if (info.$1 == 0)
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      width: .5,
                                    ),
                                  ),
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width / 2.5,
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text.rich(
                                            TextSpan(
                                              text: '${info.$1 + 1}. ',
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 16,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: info.$2.value,
                                                  style: TextStyle(
                                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                TextSpan(text: ' ${invoiceItem.$2.price.toStringAsFixed(2)} EUR'),
                                              ],
                                            ),
                                          ),
                                          TextButton(
                                            child: const Text(
                                              'UKLONI',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            onPressed: () {
                                              setState(() => _invoiceItems.remove(invoiceItem.$2));
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
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
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).textTheme.bodyMedium?.color,
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
                      ),
                  ],
                ],
              ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          for (int i = 0; i < 3; i++)
            i == 1
                ? const SizedBox(width: 16)
                : StatefulBuilder(
                    builder: (context, setThisState) {
                      return FloatingActionButton.extended(
                        heroTag: null,
                        label: _generatingInvoice
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(),
                              )
                            : Text(
                                'IZRADI ${i == 0 ? 'PONUDU' : 'RAČUN'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.black45,
                                ),
                              ),
                        onPressed: _generatingInvoice
                            ? null
                            : () async {
                                if (i == 0 || _formKey.currentState?.validate() == true) {
                                  if (_invoiceItems.isEmpty) {
                                    _scrollController.jumpTo(0);
                                    setState(() {
                                      _invoiceItemValidationError =
                                          'Molimo unesite bar jednu vrijednost i stisnite tipku "Dodaj novi zapis".';
                                    });
                                    return;
                                  }
                                  setThisState(() => _generatingInvoice = true);
                                  await IgServicePdfGenerator.generatePdfInvoice(
                                    IgModelInvoice(
                                      paymentId: '${_paymentIdTextController.text.trim()}/'
                                          '${_paymentLocationIdTextController.text.trim()}/'
                                          '${_paymentRegisterIdTextController.text.trim()}',
                                      time: DateTime.now(),
                                      paymentMethod: _paymentMethodTextController.text.trim(),
                                      paymentModel: _paymentModelTextController.text.trim(),
                                      invoiceItems: _invoiceItems,
                                      clientInfo: IgModelSaleClient(
                                        name: _clientNameTextController.text.trim(),
                                        oib: _clientOibTextController.text.trim().isEmpty ? null : _clientOibTextController.text.trim(),
                                        address: _clientAddressTextController.text.trim().isEmpty
                                            ? null
                                            : _clientAddressTextController.text.trim(),
                                      ),
                                    ),
                                    offerOnly: i == 0,
                                  );
                                  setThisState(() => _generatingInvoice = false);
                                } else {
                                  _scrollController.jumpTo(0);
                                }
                              },
                      );
                    },
                  ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _paymentIdTextController.dispose();
    _paymentLocationIdTextController.dispose();
    _paymentRegisterIdTextController.dispose();
    _clientNameTextController.dispose();
    _clientOibTextController.dispose();
    _clientAddressTextController.dispose();
    _invoiceItemNameTextController.dispose();
    _invoiceItemAmountTextController.dispose();
    _invoiceItemMeasureTextController.dispose();
    _invoiceItemPriceTextController.dispose();
    _paymentMethodTextController.dispose();
    _paymentModelTextController.dispose();
    _paymentMethodFocusNode.dispose();
    _paymentModelFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
