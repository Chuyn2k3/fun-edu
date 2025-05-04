import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:universal_html/html.dart' as html;

class PdfViewer extends StatefulWidget {
  const PdfViewer({
    required this.pdfName,
    this.path,
    this.pdfSave,
    super.key,
    this.anchor,
  });
  final String pdfName;
  final path;
  final pdfSave;
  final anchor;

  @override
  _PdfViewerState createState() => _PdfViewerState();
}

class _PdfViewerState extends State<PdfViewer> {
  Uint8List? pdfBytes;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      if (kIsWeb) {
        pdfBytes = widget.pdfSave as Uint8List;
      }
      setState(() {});
    } catch (e) {
      log("Lỗi khi tải PDF: $e");
    }
  }

  void _downloadPdf() async {
    try {
      // if (!kIsWeb) {
      //   await Printing.layoutPdf(
      //     onLayout: (PdfPageFormat format) async =>
      //         widget.pdfSave.save() as Future<Uint8List>,
      //   );
      // } else {
      //   final bytes = await widget.pdfSave.save() as Uint8List;
      //   final blob = html.Blob([bytes], 'application/pdf');
      //   final url = html.Url.createObjectUrlFromBlob(blob);
      //   final anchor = html.AnchorElement(href: url)
      //     ..setAttribute("download", widget.pdfName)
      //     ..click();
      //   html.Url.revokeObjectUrl(url);
      // }
    } catch (e) {
      log("Lỗi tải xuống PDF: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey,
        elevation: 1,
        title: Text(
          widget.pdfName,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              color: Colors.black, letterSpacing: 2, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_sharp),
            onPressed: () {
              if (!kIsWeb) {
                try {
                  Printing.layoutPdf(
                    onLayout: (PdfPageFormat format) async =>
                        widget.pdfSave.save() as Future<Uint8List>,
                  );
                } catch (e) {
                  log(e.toString());
                }
              } else {
                widget.anchor.click();
                html.document.body?.children.remove(widget.anchor);
              }
            },
          )
        ],
      ),
      body: kIsWeb
          ? (pdfBytes != null
              ? SfPdfViewer.memory(pdfBytes!)
              : const Center(child: CircularProgressIndicator()))
          : (widget.path != null
              ? SfPdfViewer.file(File(widget.path! as String))
              : const Center(
                  child: Text("Không tìm thấy file PDF"),
                )),
    );
  }
}
