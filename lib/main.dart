import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:simple_invoice_generator/view/routes/route_invoice_generator.dart';
import 'package:simple_invoice_generator/view/routes/route_merchant_data_entry.dart';
import 'package:simple_invoice_generator/services/service_cache_manager.dart';

Future<void> main() async {
  if (kReleaseMode) debugPrint = (message, {wrapWidth}) {};

  WidgetsFlutterBinding.ensureInitialized();

  await IgServiceCacheManager.init();

  runApp(const InvoiceGenerator());
}

class InvoiceGenerator extends StatelessWidget {
  const InvoiceGenerator({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        inputDecorationTheme: const InputDecorationTheme(
          isDense: true,
          border: OutlineInputBorder(),
        ),
      ),
      home: IgServiceCacheManager.merchantData == null ? const IgRouteMerchantDataEntry() : const IgRouteInvoiceGenerator(),
    );
  }
}
