import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:simple_invoice_generator/models/model_sale_item.dart';
import 'package:simple_invoice_generator/view/routes/route_invoice_generator.dart';
import 'package:simple_invoice_generator/services/service_cache_manager.dart';

class IgRouteInvoiceItemEntry extends StatefulWidget {
  const IgRouteInvoiceItemEntry({super.key});

  @override
  State<IgRouteInvoiceItemEntry> createState() => _IgRouteInvoiceItemEntryState();
}

class _IgRouteInvoiceItemEntryState extends State<IgRouteInvoiceItemEntry> {
  final _formKey = GlobalKey<FormState>();

  final _nameTextController = TextEditingController(),
      _measureTextController = TextEditingController(),
      _priceTextController = TextEditingController();

  Future<void> _saveData() async {
    final invoiceItem = IgModelSaleItem(
      name: _nameTextController.text.trim(),
      measure: _measureTextController.text.trim(),
      price: num.parse(_priceTextController.text.trim()),
    );
    IgServiceCacheManager.invoiceItems.add(invoiceItem);
    await IgServiceCacheManager.instance.setStringList(
      'invoiceItems',
      IgServiceCacheManager.invoiceItems.map((invoiceItem) => jsonEncode(invoiceItem.toJson())).toList(),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const IgRouteInvoiceGenerator(),
      ),
      (Route<dynamic> route) => false,
    );
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Unos podataka proizvoda',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 21,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Donje podatke unosite kako biste prilikom ponovnog ulaska u stranicu ponovno pristupili tim informacijama.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: MediaQuery.of(context).size.width < 1000
                    ? const EdgeInsets.symmetric(horizontal: 16, vertical: 20)
                    : EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 4),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Unos podataka proizvoda',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 21,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Donje podatke unosite kako biste prilikom ponovnog ulaska u stranicu ponovno pristupili tim informacijama.',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (final textInput in <({String label, TextEditingController controller})>{
                        (
                          label: 'Naziv proizvoda ili usluge',
                          controller: _nameTextController,
                        ),
                        (
                          label: 'Mjerna jedinica',
                          controller: _measureTextController,
                        ),
                        (
                          label: 'Cijena u EUR',
                          controller: _priceTextController,
                        ),
                      }.indexed)
                        Padding(
                          padding: textInput.$1 == 2 ? const EdgeInsets.only(bottom: 16) : const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            controller: textInput.$2.controller,
                            decoration: InputDecoration(
                              label: Text(
                                textInput.$2.label,
                              ),
                            ),
                          ),
                        ),
                      if (MediaQuery.of(context).size.width >= 1000) ...[
                        OutlinedButton(
                          child: const Text(
                            'Dodaj novi zapis',
                          ),
                          onPressed: () async {
                            if (_formKey.currentState?.validate() == true) await _saveData();
                          },
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          child: const Text(
                            'Izlaz',
                          ),
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const IgRouteInvoiceGenerator(),
                              ),
                              (Route<dynamic> route) => false,
                            );
                          },
                        ),
                      ],
                    ],
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
                    offset: Offset(0, 7),
                    blurRadius: 15,
                    color: Colors.black12,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  children: [
                    InkWell(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: 48,
                        child: const Center(
                          child: Text(
                            'IZLAZ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const IgRouteInvoiceGenerator(),
                          ),
                          (Route<dynamic> route) => false,
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                        ),
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height: 48,
                          child: const Center(
                            child: Text(
                              'NASTAVI',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      onTap: () async {
                        if (_formKey.currentState?.validate() == true) await _saveData();
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameTextController.dispose();
    _measureTextController.dispose();
    _priceTextController.dispose();
    super.dispose();
  }
}
