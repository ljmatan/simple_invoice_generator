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
        primaryColor: const Color(0xffDFCFBD),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xffDFCFBD)),
        fontFamily: 'Asap',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            color: Color(0xff5A4837),
          ),
        ),
        dividerColor: Colors.grey,
        scaffoldBackgroundColor: Colors.white,
        splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        inputDecorationTheme: const InputDecorationTheme(
          isDense: true,
          border: OutlineInputBorder(),
        ),
        appBarTheme: AppBarTheme(
          toolbarHeight: MediaQuery.of(context).size.width < 1000
              ? kToolbarHeight
              : MediaQuery.of(context).size.height * .07 > 100
                  ? 100
                  : MediaQuery.of(context).size.height * .07,
        ),
      ),
      home: IgServiceCacheManager.merchantData == null ? const IgRouteMerchantDataEntry() : const IgRouteInvoiceGenerator(),
    );
  }
}
