// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';
import 'package:simple_invoice_generator/models/model_invoice.dart';
import 'package:simple_invoice_generator/services/service_cache_manager.dart';

/// Class defining the PDF invoice generator methods and properties.
///
class IgServicePdfGenerator {
  const IgServicePdfGenerator._();

  /// Stores the PDF file to the user device using web browser mechanisms.
  ///
  static Future<void> _saveToDevice({
    required Uint8List fileBytes,
    required String filenamePrefix,
  }) async {
    final blob = html.Blob([fileBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = '${filenamePrefix}_${DateTime.now().millisecondsSinceEpoch.toString()}.pdf';
    html.document.body!.children.add(anchor);
    anchor.click();
    anchor.remove();
  }

  /// Generates the PDF file with the given parameters, and stores it to the device.
  ///
  static Future<void> generatePdfInvoice(
    IgModelInvoice invoice, {
    /// Whether this is a valid invoice or just a sale offer.
    bool offerOnly = false,
  }) async {
    final pdf = Document();
    Font? pdfFont;
    try {
      final fontData = await rootBundle.load('assets/fonts/Asap-VariableFont_wdth,wght.ttf');
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${context.pageNumber} / ${context.pagesCount} - ' +
                    (offerOnly ? '' : 'Račun br. ${invoice.paymentId} - ') +
                    '${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year} '
                        '${DateTime.now().hour}:${DateTime.now().minute} - '
                        '${IgServiceCacheManager.merchantData?.name}, '
                        '${IgServiceCacheManager.merchantData?.address}, '
                        'OIB ${IgServiceCacheManager.merchantData?.oib}\n'
                        '${IgServiceCacheManager.merchantData?.overseeingCourtBody}, '
                        'članovi uprave: ${IgServiceCacheManager.merchantData?.boardMembers} - '
                        'temeljni kapital društva uplaćen u cijelosti: '
                        '${IgServiceCacheManager.merchantData?.capitalBalance.toStringAsFixed(2)} EUR',
                style: const TextStyle(
                  fontSize: 6,
                ),
              ),
              SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (IgServiceCacheManager.merchantData != null)
                          for (final merchantInfo in IgServiceCacheManager.merchantData!.formattedInfo.indexed)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: RichText(
                                text: TextSpan(
                                  text: merchantInfo.$1 == 0 ? '' : '${merchantInfo.$2.label}: ',
                                  style: TextStyle(
                                    color: PdfColor.fromHex('#5A5A5A'),
                                    fontSize: 8,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: merchantInfo.$2.value,
                                      style: merchantInfo.$1 == 0
                                          ? TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: PdfColor.fromHex('#000000'),
                                              fontSize: 12,
                                            )
                                          : TextStyle(
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
                          offerOnly ? 'PONUDA' : 'RAČUN BROJ ${invoice.paymentId}',
                          if (invoice.clientInfo.name.isNotEmpty) invoice.clientInfo.name.toUpperCase(),
                          if (invoice.clientInfo.oib != null) 'OIB ${invoice.clientInfo.oib!}',
                          if (invoice.clientInfo.address != null) invoice.clientInfo.address!.toUpperCase(),
                        }.indexed)
                          Text(
                            clientInfoValue.$2,
                            style: clientInfoValue.$1 == 0
                                ? TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: PdfColor.fromHex('#000000'),
                                    fontSize: 12,
                                  )
                                : TextStyle(
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
                  border: Border.all(width: .1),
                ),
                child: Row(
                  children: [
                    for (final label in <String>{
                      'Naziv proizvoda ili usluge',
                      'Količina',
                      'Mj. jedinica',
                      'Cijena EUR',
                      'Cijena HRK',
                      if (IgServiceCacheManager.merchantData?.vatApplied == true) 'PDV',
                    }.indexed)
                      Expanded(
                        flex: label.$1 == 0 ? 2 : 1,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            label.$2,
                            textAlign: label.$1 == 0 ? null : TextAlign.center,
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
            for (final invoiceItem in invoice.invoiceItems.indexed)
              DecoratedBox(
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(width: .1),
                    top: BorderSide.none,
                    right: BorderSide(width: .1),
                    bottom: BorderSide(width: .1),
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
                              0 => invoiceItem.$2.name.toUpperCase(),
                              1 => invoiceItem.$2.amount.toStringAsFixed(2),
                              2 => invoiceItem.$2.measure,
                              3 => (invoiceItem.$2.price * invoiceItem.$2.amount).toStringAsFixed(2) +
                                  (invoiceItem.$2.amount == 1
                                      ? ''
                                      : ' (${invoiceItem.$2.amount} x ${invoiceItem.$2.price.toStringAsFixed(2)}€)'),
                              int() => throw 'Not implemented.',
                            },
                            textAlign: i == 0 ? null : TextAlign.center,
                            style: const TextStyle(
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ),
                    if (DateTime.now().year < 2024)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            invoiceItem.$2.amount == 1
                                ? (invoiceItem.$2.price * 7.5345).toStringAsFixed(2)
                                : (invoiceItem.$2.price * invoiceItem.$2.amount * 7.5345).toStringAsFixed(2) +
                                    ' (${invoiceItem.$2.amount} x ${(invoiceItem.$2.price * 7.5345).toStringAsFixed(2)})',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ),
                    if (IgServiceCacheManager.merchantData?.vatApplied == true)
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
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
                        for (var item in invoice.invoiceItems) {
                          sum += (item.price * item.amount);
                        }
                        return Text(
                          '${sum.toStringAsFixed(2)} EUR',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 8,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (DateTime.now().year < 2024)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Builder(
                        builder: (context) {
                          num sum = 0;
                          for (var item in invoice.invoiceItems) {
                            sum += (item.price * item.amount);
                          }
                          sum *= 7.5345;
                          return Text(
                            '${sum.toStringAsFixed(2)} HRK',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 8,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                if (IgServiceCacheManager.merchantData?.vatApplied == true)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Builder(
                        builder: (context) {
                          num sum = 0;
                          for (var item in invoice.invoiceItems) {
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
              if (IgServiceCacheManager.merchantData?.vatApplied != true)
                (
                  label: 'PDV',
                  value: 'nije obračunan sukladno odredbama članka 90. stavka 2. Zakona o PDVu',
                ),
              (
                label: 'Datum i vrijeme',
                value: '${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year} '
                    '${DateTime.now().hour}:${DateTime.now().minute}',
              ),
              if (invoice.paymentMethod.isNotEmpty)
                (
                  label: 'Način plaćanja',
                  value: invoice.paymentMethod,
                ),
              if (!offerOnly)
                (
                  label: 'Šifra namjene',
                  value: invoice.paymentId.replaceAll('/', ''),
                ),
              if (invoice.paymentModel.isNotEmpty)
                (
                  label: 'Model plaćanja',
                  value: invoice.paymentModel,
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
      ),
    );
    final pdfBytes = await pdf.save();
    await _saveToDevice(
      fileBytes: pdfBytes,
      filenamePrefix: offerOnly ? 'Ponuda' : 'Racun',
    );
    if (!offerOnly) {
      try {
        IgServiceCacheManager.invoices.add(invoice);
        await IgServiceCacheManager.instance.setStringList(
          'invoices',
          IgServiceCacheManager.invoices
              .map(
                (invoice) => jsonEncode(invoice.toJson()),
              )
              .toList(),
        );
      } catch (e) {
        debugPrint('IgServicePdfGenerator.generatePdfInvoice: Cache failed: $e');
      }
    }
  }
}
