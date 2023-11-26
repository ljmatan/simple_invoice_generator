/// Helper methods for validating user input.
///
class IgServiceInputValidation {
  const IgServiceInputValidation._();

  static String? name(String? input) {
    if ((input?.trim().length ?? 0) < 3) return 'Ime mora sadržavati minimalno 3 znamenke.';
    return null;
  }

  static String? email(String? input) {
    if (!RegExp(
      r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?",
    ).hasMatch(input?.trim() ?? '')) return 'Email adresa nije u ispravnom formatu.';
    return null;
  }

  static String? address(String? input) {
    if ((input?.trim().length ?? 0) < 3) return 'Adresa mora sadržavati minimalno 3 znamenke.';
    return null;
  }

  static String? oib(String? input) {
    const inputValidationErrorMessage = 'OIB nije u ispravnom formatu.';
    if (input == null || input.length != 11 || int.tryParse(input) == null) return inputValidationErrorMessage;
    int isoVar = 10;
    for (int i = 0; i < 10; i++) {
      int currentElement;
      currentElement = int.parse(input.substring(i, i + 1));
      isoVar += currentElement;
      isoVar = isoVar % 10;
      if (isoVar == 0) isoVar = 10;
      isoVar *= 2;
      isoVar = isoVar % 11;
    }
    int lastDigit = 11 - isoVar;
    if (lastDigit == 10) lastDigit = 0;
    if (lastDigit != int.parse(input.substring(10))) return inputValidationErrorMessage;
    return null;
  }

  static String? mb(String? input) {
    if (int.tryParse(input ?? '') == null) return 'Matični broj nije u ispravnom formatu.';
    return null;
  }

  static String? iban(String? input) {
    if (!RegExp(r'^HR\d{19}$').hasMatch(input?.replaceAll(' ', '') ?? '')) return 'IBAN nije u ispravnom formatu.';
    return null;
  }

  static String? phone(String? input) {
    if (!RegExp(r'^\+?(\d+)$').hasMatch(input?.replaceAll(' ', '') ?? '')) return 'Molimo provjerite uneseni telefonski broj.';
    return null;
  }
}
