import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// Platform abstraction for printing or sharing a generated worksheet PDF.
/// Override [worksheetPrinterProvider] in tests to avoid native channel calls.
abstract class WorksheetPrinter {
  const WorksheetPrinter();

  Future<void> printPdf(Uint8List bytes, {required String jobName});

  Future<void> sharePdf(Uint8List bytes, {required String fileName});
}

class PrintingWorksheetPrinter extends WorksheetPrinter {
  const PrintingWorksheetPrinter();

  @override
  Future<void> printPdf(Uint8List bytes, {required String jobName}) async {
    await Printing.layoutPdf(
      name: jobName,
      format: PdfPageFormat.a4,
      onLayout: (_) async => bytes,
    );
  }

  @override
  Future<void> sharePdf(Uint8List bytes, {required String fileName}) async {
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }
}

final worksheetPrinterProvider = Provider<WorksheetPrinter>(
  (_) => const PrintingWorksheetPrinter(),
);
