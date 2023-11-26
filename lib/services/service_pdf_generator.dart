// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

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
    required List<IgModelInvoiceItem> invoiceItems,
    required IgModelSaleClient clientInfo,
  }) async {
    final pdf = Document();
    pdf.addPage(
      MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const EdgeInsets.fromLTRB(16, 18, 16, 12),
        header: (context) {
          return Column(
            children: [
              Row(
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
                      children: [],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        build: (context) {
          return [
            for (final invoiceItem in invoiceItems.indexed)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: invoiceItem.$1 == 0
                      ? const Border(
                          left: BorderSide(),
                          top: BorderSide(),
                          right: BorderSide(),
                          bottom: BorderSide.none,
                        )
                      : invoiceItem.$1 == invoiceItems.length - 1
                          ? const Border(
                              left: BorderSide(),
                              top: BorderSide.none,
                              right: BorderSide(),
                              bottom: BorderSide(),
                            )
                          : Border.all(),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        invoiceItem.$2.name,
                      ),
                    ),
                  ],
                ),
              ),
          ];
        },
        footer: (context) {
          return Row(
            children: [],
          );
        },
      ),
    );
    final pdfBytes = await pdf.save();
    await _saveToDevice(fileBytes: pdfBytes);
  }
}
