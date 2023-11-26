import 'package:flutter/foundation.dart';

/// This class provides functionality for translating text and supports multiple languages.
///
mixin class IgInternationalization {
  /// Language code retrieved from this user device.
  ///
  static final _locale = PlatformDispatcher.instance.locale.languageCode;

  /// Returns the translated text value, if found.
  ///
  /// Parent widget instance is forwarded as a [view] parameter
  /// in order to identify the section of the app where this text will be applied.
  ///
  String i18n(IgInternationalization view, String id) {
    final languageMap = _values.firstWhere((value) => value.languageCode.contains(_locale));
    final value = languageMap.routeValues[view.runtimeType.toString()]?[id];
    if (value == null) debugPrint('IgI18n: not found: $id');
    return value ?? 'N/A';
  }

  static const _values = <({String languageCode, Map<String, Map<String, String>> routeValues})>[
    (
      languageCode: 'hr,bs,sr',
      routeValues: <String, Map<String, String>>{
        '_IgRouteClientInfoEntryState': {
          'clientInfoEntry': 'Unos podataka klijenta',
          'clientInfoEntryDisclaimer':
              'Donje podatke unosite kako biste prilikom ponovnog ulaska u stranicu ponovno pristupili tim informacijama.',
          'clientName': 'Naziv klijenta',
          'address': 'Adresa',
          'addANewRecord': 'Dodaj novi zapis',
          'personalIdNumber': 'Osobni identifikacijski broj',
          'saveData': 'SPREMI',
          'exit': 'IZLAZ',
        },
      },
    ),
    (
      languageCode: 'en',
      routeValues: {
        '_IgRouteClientInfoEntryState': {
          'clientInfoEntry': 'Client info entry',
          'clientInfoEntryDisclaimer': 'The following information is provided in order to be displayed on the generated PDF file, '
              'and is persisted to your device.',
          'clientName': 'Client name',
          'address': 'Address',
          'addANewRecord': 'Add a new record',
          'personalIdNumber': 'Identification number',
          'saveData': 'SAVE DATA',
          'exit': 'EXIT',
        },
      }
    ),
  ];
}
