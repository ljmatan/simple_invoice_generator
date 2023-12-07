import 'package:flutter/material.dart';
import 'package:simple_invoice_generator/services/service_cache_manager.dart';

class IgDialogCookieConsent extends StatefulWidget {
  const IgDialogCookieConsent({super.key});

  @override
  State<IgDialogCookieConsent> createState() => _IgDialogCookieConsentState();
}

class _IgDialogCookieConsentState extends State<IgDialogCookieConsent> {
  @override
  Widget build(BuildContext context) {
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
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
          onPressed: () async {
            await IgServiceCacheManager.instance.clear();
            IgServiceCacheManager.cookieConsentApproved = false;
            Navigator.pop(context);
          },
        ),
        TextButton(
          child: const Text('PRISTAJEM'),
          onPressed: () async {
            await IgServiceCacheManager.instance.setBool('cookieConsentApproved', true);
            IgServiceCacheManager.cookieConsentApproved = true;
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
