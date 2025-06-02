// import 'dart:developer';
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:flutter/material.dart';
// import 'package:fun_edu/utils/snack_bar.dart';
// import 'package:pdf/pdf.dart';
// import 'package:printing/printing.dart';
// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
// import 'package:universal_html/html.dart' as html;

// class PdfViewer extends StatefulWidget {
//   const PdfViewer({
//     super.key,
//     required this.pdfName,
//     this.path,
//     this.pdfSave,
//     this.anchor,
//   });

//   final String pdfName;
//   final String? path;
//   final dynamic
//       pdfSave; // nên define rõ nếu có thể: FutureOr<Uint8List> hoặc PdfDocument
//   final dynamic anchor;

//   @override
//   State<PdfViewer> createState() => _PdfViewerState();
// }

// class _PdfViewerState extends State<PdfViewer> {
//   Uint8List? pdfBytes;

//   @override
//   void initState() {
//     super.initState();
//     if (kIsWeb && widget.pdfSave is Uint8List) {
//       pdfBytes = widget.pdfSave as Uint8List;
//     }
//   }

//   Future<void> _downloadPdf() async {
//     try {
//       if (kIsWeb) {
//         if (widget.anchor != null) {
//           widget.anchor.click();
//           html.document.body?.children.remove(widget.anchor);
//         }
//       } else {
//         if (widget.pdfSave != null) {
//           final bytes = await (widget.pdfSave.save() as Future<Uint8List>);
//           await Printing.layoutPdf(
//             onLayout: (PdfPageFormat format) async => bytes,
//           );
//         }
//       }
//     } catch (e) {
//       log("Lỗi tải xuống PDF: $e");
//       if (!mounted) return;
//       context.showSnackBarFail(text: "Không thể tải xuống PDF: $e");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final pdfTitle = widget.pdfName;

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.grey[300],
//         elevation: 1,
//         title: Text(
//           pdfTitle,
//           overflow: TextOverflow.ellipsis,
//           style: const TextStyle(
//             color: Colors.black,
//             letterSpacing: 1.5,
//             fontSize: 20,
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.download_sharp, color: Colors.black),
//             onPressed: _downloadPdf,
//             tooltip: 'Tải xuống PDF',
//           )
//         ],
//       ),
//       body: Builder(
//         builder: (_) {
//           if (kIsWeb) {
//             return pdfBytes != null
//                 ? SfPdfViewer.memory(pdfBytes!)
//                 : const Center(child: CircularProgressIndicator());
//           } else {
//             return widget.path != null
//                 ? SfPdfViewer.file(File(widget.path!))
//                 : const Center(child: Text("Không tìm thấy file PDF"));
//           }
//         },
//       ),
//     );
//   }
// }
