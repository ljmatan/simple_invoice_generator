// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';
import 'package:simple_invoice_generator/models/model_invoice_item.dart';
import 'package:simple_invoice_generator/models/model_sale_client.dart';
import 'package:simple_invoice_generator/services/service_cache_manager.dart';

/// Class defining the PDF invoice generator methods and properties.
///
class IgServicePdfGenerator {
  const IgServicePdfGenerator._();

  /// Stores the PDF file to the user device using web browser mechanisms.
  ///
  static Future<void> _saveToDevice({
    required Uint8List fileBytes,
    String? fileName,
  }) async {
    final blob = html.Blob([fileBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = 'Racun_${fileName ?? DateTime.now().millisecondsSinceEpoch.toString()}.pdf';
    html.document.body!.children.add(anchor);
    anchor.click();
    anchor.remove();
  }

  /// Generates the PDF file with the given parameters, and stores it to the device.
  ///
  static Future<void> generatePdfInvoice({
    required String paymentId,
    required List<IgModelInvoiceItem> invoiceItems,
    required IgModelSaleClient clientInfo,
    required String paymentModel,
    required String paymentMethod,
  }) async {
    final pdf = Document();
    Font? pdfFont;
    try {
      final fontData = await rootBundle.load('assets/fonts/TimesNewRoman-Regular.ttf');
      pdfFont = Font.ttf(fontData);
    } catch (e) {
      debugPrint('IgServicePdfGenerator.generatePdfInvoice error: $e');
    }
    pdf.addPage(
      MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const EdgeInsets.fromLTRB(16, 18, 16, 12),
        theme: ThemeData.withFont(
          base: pdfFont,
          bold: pdfFont,
        ),
        header: (context) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                            child: RichText(
                              text: TextSpan(
                                text: '${merchantInfo.label}: ',
                                style: TextStyle(
                                  color: PdfColor.fromHex('#5A5A5A'),
                                  fontSize: 8,
                                ),
                                children: [
                                  TextSpan(
                                    text: merchantInfo.value,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: PdfColor.fromHex('#000000'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final clientInfoValue in <String>{
                          'Račun br. $paymentId',
                          if (clientInfo.name.isNotEmpty) clientInfo.name,
                          if (clientInfo.oib != null) clientInfo.oib!,
                          if (clientInfo.address != null) clientInfo.address!,
                        })
                          Text(
                            clientInfoValue,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: PdfColor.fromHex('#000000'),
                              fontSize: 8,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(),
                ),
                child: Row(
                  children: [
                    for (final label in <String>{
                      'Naziv proizvoda ili usluge',
                      'Količina',
                      'Mj. jedinica',
                      'Cijena EUR',
                      'Cijena HRK',
                      'PDV',
                    }.indexed)
                      Expanded(
                        flex: label.$1 == 0 ? 2 : 1,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            label.$2,
                            textAlign: label.$2 == 'PDV' ? TextAlign.center : null,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
        build: (context) {
          return [
            for (final invoiceItem in invoiceItems.indexed)
              DecoratedBox(
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(),
                    top: BorderSide.none,
                    right: BorderSide(),
                    bottom: BorderSide(),
                  ),
                ),
                child: Row(
                  children: [
                    for (int i = 0; i < 4; i++)
                      Expanded(
                        flex: i == 0 ? 2 : 1,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            switch (i) {
                              0 => invoiceItem.$2.name,
                              1 => invoiceItem.$2.amount.toStringAsFixed(2),
                              2 => invoiceItem.$2.measure,
                              3 => invoiceItem.$2.price.toStringAsFixed(2),
                              int() => throw 'Not implemented.',
                            },
                            style: const TextStyle(
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          (invoiceItem.$2.price * 7.5345).toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 8,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          '25%',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      'UKUPNO:',
                      style: const TextStyle(
                        fontSize: 8,
                      ),
                    ),
                  ),
                ),
                for (int i = 0; i < 2; i++)
                  Expanded(
                    child: SizedBox(),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Builder(
                      builder: (context) {
                        num sum = 0;
                        for (var item in invoiceItems) {
                          sum += (item.price * item.amount);
                        }
                        return Text(
                          sum.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 8,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Builder(
                      builder: (context) {
                        num sum = 0;
                        for (var item in invoiceItems) {
                          sum += (item.price * item.amount);
                        }
                        sum *= 7.5345;
                        return Text(
                          sum.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 8,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Builder(
                      builder: (context) {
                        num sum = 0;
                        for (var item in invoiceItems) {
                          sum += (item.price * item.amount);
                        }
                        sum *= .25;
                        return Text(
                          '${sum.toStringAsFixed(2)} EUR\n${(sum * 7.5345).toStringAsFixed(2)} HRK',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 8,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            for (final paymentInfo in <({String label, String value})>{
              (
                label: 'Datum i vrijeme',
                value: '${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year} '
                    '${DateTime.now().hour}:${DateTime.now().minute}',
              ),
              (
                label: 'Način plaćanja',
                value: paymentMethod,
              ),
              (
                label: 'Šifra namjene',
                value: paymentId,
              ),
              (
                label: 'Model plaćanja',
                value: paymentModel,
              ),
            })
              Padding(
                padding: const EdgeInsets.all(4),
                child: RichText(
                  text: TextSpan(
                    text: '${paymentInfo.label}: ',
                    style: TextStyle(
                      fontSize: 8,
                      color: PdfColor.fromHex('#5A5A5A'),
                    ),
                    children: [
                      TextSpan(
                        text: paymentInfo.value,
                        style: TextStyle(
                          color: PdfColor.fromHex('#000000'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ];
        },
        footer: (context) {
          return Row(
            children: [
              Expanded(
                child: Text(
                  'Račun br. $paymentId, ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year} '
                  '${DateTime.now().hour}:${DateTime.now().minute}',
                  style: const TextStyle(
                    fontSize: 6,
                  ),
                ),
              ),
              if (IgServiceCacheManager.merchantData != null) ...[
                Text(
                  '${IgServiceCacheManager.merchantData!.name}, '
                  '${IgServiceCacheManager.merchantData!.address}, '
                  'OIB ${IgServiceCacheManager.merchantData!.oib}',
                  style: const TextStyle(
                    fontSize: 6,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
    final pdfBytes = await pdf.save();
    await _saveToDevice(fileBytes: pdfBytes);
  }
}
