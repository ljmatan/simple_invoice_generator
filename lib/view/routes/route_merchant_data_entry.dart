import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:simple_invoice_generator/models/model_merchant_data.dart';
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

  final _nameTextController = TextEditingController(text: kDebugMode ? 'Tvrtka j.d.o.o.' : null),
      _emailTextController = TextEditingController(text: kDebugMode ? 'email@email.com' : null),
      _addressTextController = TextEditingController(text: kDebugMode ? 'Ulica ta i ta 15' : null),
      _oibTextController = TextEditingController(text: kDebugMode ? '55545787885' : null),
      _mbTextController = TextEditingController(text: kDebugMode ? '01554972' : null),
      _ibanTextController = TextEditingController(text: kDebugMode ? 'HR4624020068809568865' : null),
      _phoneNumberTextController = TextEditingController(text: kDebugMode ? '+385955604626' : null);

  Future<void> _continue() async {
    if (_formKey.currentState?.validate() == true) {
      final merchantData = IgModelMerchantData(
        name: _nameTextController.text.trim(),
        email: _emailTextController.text.trim(),
        address: _addressTextController.text.trim(),
        oib: _oibTextController.text.trim(),
        mb: _mbTextController.text.trim(),
        iban: _ibanTextController.text.replaceAll(' ', ''),
        phoneNumber: _phoneNumberTextController.text.replaceAll(' ', ''),
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
      // Show cookie consent dialog.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog.adaptive(
                title: const Text('Obavijest o kolačićima (Cookies)'),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '\nDatum zadnje izmjene: 25.11.2023.\n\n'
                      'Dobrodošli na našu platformu za generiranje računa za tvrtke. '
                      'Ova obavijest opisuje kako koristimo kolačiće kako bismo poboljšali vaše iskustvo na našoj stranici.\n',
                      textAlign: TextAlign.left,
                    ),
                    for (final textSection in <({String title, String description})>{
                      (
                        title: 'Što su kolačići (Cookies)',
                        description: 'Kolačići su male datoteke koje se pohranjuju na vašem računalu kada posjetite našu web stranicu. '
                            'Ove datoteke sadrže informacije koje olakšavaju navigaciju i pružaju '
                            'personalizirano iskustvo prilikom korištenja naše usluge.',
                      ),
                      (
                        title: 'Vrste kolačića koje koristimo',
                        description: 'Koristimo kolačiće koji se odnose isključivo na sesiju, '
                            'te ne prikupljamo osobne podatke o vašoj tvrtki. '
                      ),
                      (
                        title: 'Svrha upotrebe kolačića',
                        description: 'Kolačići se koriste radi optimizacije funkcionalnosti naše usluge, poput prilagodbe sučelja. '
                            'Oni ne prikupljaju osobne podatke o vašoj tvrtki.',
                      ),
                      (
                        title: 'Upotreba kolačića trećih strana',
                        description: 'Stranica ne upotrebljava servise trećih strana koji prikupljaju korisničke podatke.',
                      ),
                      (
                        title: 'Upravljanje kolačićima',
                        description: 'Možete kontrolirati ili izbrisati kolačiće putem postavki vašeg preglednika.',
                      ),
                      (
                        title: 'Izmjene obavijesti o kolačićima',
                        description: 'Pridržavamo pravo izmjene ove obavijesti. Svaka izmjena bit će ažurirana na ovoj stranici, '
                            'a datum zadnje izmjene će biti naveden.',
                      ),
                    }.indexed) ...[
                      Text.rich(
                        TextSpan(
                          text: '${textSection.$1 + 1}. ',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                          ),
                          children: [
                            TextSpan(
                              text: '${textSection.$2.title}:',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 10),
                        child: Text(
                          textSection.$2.description,
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                    const Text(
                      'Potvrdom ove obavijesti pristajete na korištenje kolačića.',
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    child: const Text('NE PRISTAJEM'),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  TextButton(
                    child: const Text('PRISTAJEM'),
                    onPressed: () async {
                      await IgServiceCacheManager.instance.setBool('cookieConsentApproved', true);
                      Navigator.pop(context);
                    },
                  ),
                ],
              );
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
                          keyboardType: TextInputType.number,
                          validator: (input) => IgServiceInputValidation.mb(input),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _ibanTextController,
                          decoration: const InputDecoration(
                            label: Text(
                              'IBAN broj tvrtke',
                            ),
                          ),
                          keyboardType: TextInputType.streetAddress,
                          validator: (input) => IgServiceInputValidation.iban(input),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _phoneNumberTextController,
                          decoration: const InputDecoration(
                            label: Text(
                              'Kontakt telefon',
                            ),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (input) => IgServiceInputValidation.phone(input),
                        ),
                        const SizedBox(height: 16),
                        if (MediaQuery.of(context).size.width >= 1000)
                          OutlinedButton(
                            child: const Text(
                              'NASTAVI',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () async => await _continue(),
                          ),
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
                    offset: Offset(0, 7),
                    blurRadius: 15,
                    color: Colors.black12,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: GestureDetector(
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
                  onTap: () async => await _continue(),
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
    _emailTextController.dispose();
    _addressTextController.dispose();
    _oibTextController.dispose();
    _mbTextController.dispose();
    _ibanTextController.dispose();
    _phoneNumberTextController.dispose();
    super.dispose();
  }
}
