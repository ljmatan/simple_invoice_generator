import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:simple_invoice_generator/models/model_sale_client.dart';
import 'package:simple_invoice_generator/view/routes/route_invoice_generator.dart';
import 'package:simple_invoice_generator/services/service_cache_manager.dart';
import 'package:simple_invoice_generator/services/service_input_validation.dart';

class IgRouteClientInfoEntry extends StatefulWidget {
  const IgRouteClientInfoEntry({super.key});

  @override
  State<IgRouteClientInfoEntry> createState() => _IgRouteClientInfoEntryState();
}

class _IgRouteClientInfoEntryState extends State<IgRouteClientInfoEntry> {
  final _formKey = GlobalKey<FormState>();

  final _nameTextController = TextEditingController(),
      _oibTextController = TextEditingController(),
      _addressTextController = TextEditingController();

  Future<void> _saveData() async {
    final client = IgModelSaleClient(
      name: _nameTextController.text.trim(),
      oib: _oibTextController.text.trim(),
      address: _addressTextController.text.trim(),
    );
    IgServiceCacheManager.clients.add(client);
    IgServiceCacheManager.instance.setStringList(
      'clients',
      IgServiceCacheManager.clients.map((client) => jsonEncode(client.toJson())).toList(),
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
                    'Unos podataka klijenta',
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
                        'Unos podataka klijenta',
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
                      for (final textInput in <({
                        String label,
                        TextEditingController controller,
                        String? Function(String?) validator,
                      })>{
                        (
                          label: 'Naziv klijenta',
                          controller: _nameTextController,
                          validator: IgServiceInputValidation.name,
                        ),
                        (
                          label: 'Osobni identifikacijski broj',
                          controller: _oibTextController,
                          validator: IgServiceInputValidation.oib,
                        ),
                        (
                          label: 'Adresa',
                          controller: _addressTextController,
                          validator: IgServiceInputValidation.address,
                        ),
                      }.indexed)
                        Padding(
                          padding: textInput.$1 == 2 ? const EdgeInsets.only(bottom: 16) : const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            controller: textInput.$2.controller,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            decoration: InputDecoration(
                              label: Text(
                                textInput.$2.label,
                              ),
                            ),
                            validator: textInput.$2.validator,
                          ),
                        ),
                      if (MediaQuery.of(context).size.width >= 1000) ...[
                        OutlinedButton(
                          child: const Text(
                            'NASTAVI',
                          ),
                          onPressed: () async {
                            if (_formKey.currentState?.validate() == true) await _saveData();
                          },
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          child: const Text(
                            'IZLAZ',
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
    _oibTextController.dispose();
    _addressTextController.dispose();
    super.dispose();
  }
}
