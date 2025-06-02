import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:fun_edu/utils/color_const.dart';
import 'package:fun_edu/utils/custom_app_bar.dart';
import 'package:fun_edu/widget/main_screen_card.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:universal_html/html.dart' as html;

import 'pdf_viewer.dart';

// Enums for better type safety
enum MathOperation { sum, minus, multiplication, division }

enum QuestionType { essay, multipleChoice }

// Data models for better structure
class QuestionConfig {
  final int questionCount;
  final int maxValue1;
  final int maxValue2;
  final MathOperation operation;

  const QuestionConfig({
    required this.questionCount,
    required this.maxValue1,
    required this.maxValue2,
    required this.operation,
  });

  bool get isValid => questionCount > 0 && maxValue1 > 0 && maxValue2 > 0;
}

class MathQuestion {
  final int questionNumber;
  final int operand1;
  final int operand2;
  final MathOperation operation;
  final dynamic answer;
  final List<dynamic>? choices; // For MCQ

  MathQuestion({
    required this.questionNumber,
    required this.operand1,
    required this.operand2,
    required this.operation,
    required this.answer,
    this.choices,
  });

  String get questionText {
    final operatorSymbol = _getOperatorSymbol();
    return '$questionNumber] $operand1 $operatorSymbol $operand2 = ______';
  }

  String get questionTextWithAnswer {
    final operatorSymbol = _getOperatorSymbol();
    return '$questionNumber] $operand1 $operatorSymbol $operand2 = $answer';
  }

  String get mcqQuestionText {
    final operatorSymbol = _getOperatorSymbol();
    return '$questionNumber] $operand1 $operatorSymbol $operand2 = ?';
  }

  String get mcqChoicesText {
    if (choices == null || choices!.length != 4) return '';
    return 'A) ${choices![0]} B) ${choices![1]} C) ${choices![2]} D) ${choices![3]}';
  }

  String get correctAnswerLetter {
    if (choices == null) return '';
    final index = choices!.indexOf(answer);
    return ['A', 'B', 'C', 'D'][index];
  }

  String _getOperatorSymbol() {
    switch (operation) {
      case MathOperation.sum:
        return '+';
      case MathOperation.minus:
        return '-';
      case MathOperation.multiplication:
        return '*';
      case MathOperation.division:
        return '/';
    }
  }
}

// Service for generating math questions
class MathQuestionGenerator {
  static final Random _random = Random();

  static List<MathQuestion> generateQuestions(QuestionConfig config) {
    final questions = <MathQuestion>[];

    for (int i = 1; i <= config.questionCount; i++) {
      final operand1 = _random.nextInt(config.maxValue1) + 1;
      final operand2 = _random.nextInt(config.maxValue2) + 1;
      final answer = _calculateAnswer(operand1, operand2, config.operation);

      questions.add(MathQuestion(
        questionNumber: i,
        operand1: operand1,
        operand2: operand2,
        operation: config.operation,
        answer: answer,
      ));
    }

    return questions;
  }

  static List<MathQuestion> generateMCQQuestions(QuestionConfig config) {
    final questions = generateQuestions(config);

    return questions.map((question) {
      final choices = _generateMCQChoices(question.answer, question.operation);
      return MathQuestion(
        questionNumber: question.questionNumber,
        operand1: question.operand1,
        operand2: question.operand2,
        operation: question.operation,
        answer: question.answer,
        choices: choices,
      );
    }).toList();
  }

  static dynamic _calculateAnswer(
      int operand1, int operand2, MathOperation operation) {
    switch (operation) {
      case MathOperation.sum:
        return operand1 + operand2;
      case MathOperation.minus:
        return operand1 - operand2;
      case MathOperation.multiplication:
        return operand1 * operand2;
      case MathOperation.division:
        return (operand1 / operand2).toStringAsFixed(2);
    }
  }

  static List<dynamic> _generateMCQChoices(
      dynamic correctAnswer, MathOperation operation) {
    final choices = <dynamic>[correctAnswer];

    if (operation == MathOperation.division) {
      final baseValue = double.parse(correctAnswer.toString());
      choices.addAll([
        (baseValue + _random.nextInt(10) + 1).toStringAsFixed(2),
        (baseValue - _random.nextInt(10) - 1).toStringAsFixed(2),
        (baseValue + _random.nextInt(16) + 1).toStringAsFixed(2),
      ]);
    } else {
      final baseValue = correctAnswer as int;
      choices.addAll([
        baseValue + _random.nextInt(10) + 1,
        baseValue - _random.nextInt(10) - 1,
        baseValue + _random.nextInt(16) + 1,
      ]);
    }

    // Shuffle choices
    for (int i = choices.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final temp = choices[i];
      choices[i] = choices[j];
      choices[j] = temp;
    }

    return choices;
  }
}

// Service for PDF generation
class PDFGenerationService {
  static Future<Uint8List> generateEssayPDF(
      List<MathQuestion> questions) async {
    final pdf = pw.Document();

    // Group questions into chunks of 3 for better layout
    final questionChunks = _chunkList(questions, 3);
    final answerChunks = _chunkList(questions, 3);

    // Add questions page
    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Header(level: 0, text: 'Questions'),
          pw.Table.fromTextArray(
            context: context,
            data: [
              ['Questions', 'Questions', 'Questions'],
              ...questionChunks
                  .map((chunk) => chunk.map((q) => q.questionText).toList()),
            ],
          ),
          pw.Padding(padding: const pw.EdgeInsets.all(10)),
        ],
      ),
    );

    // Add answers page
    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Padding(padding: const pw.EdgeInsets.all(10)),
          pw.Header(text: 'Answer Sheet'),
          pw.Table.fromTextArray(
            context: context,
            data: [
              ['Answer', 'Answer', 'Answer'],
              ...answerChunks.map((chunk) =>
                  chunk.map((q) => q.questionTextWithAnswer).toList()),
            ],
          ),
        ],
      ),
    );

    return await pdf.save();
  }

  static Future<Uint8List> generateMCQPDF(List<MathQuestion> questions) async {
    final pdf = pw.Document();

    // Prepare question data
    final questionData = <List<String>>[];
    questionData.add(['Questions']);

    for (final question in questions) {
      questionData.add([question.mcqQuestionText]);
      questionData.add([question.mcqChoicesText]);
    }

    // Prepare answer data
    final answerChunks = _chunkList(questions, 7);
    final answerData = <List<String>>[];
    answerData.add(['Answers']);

    for (final chunk in answerChunks) {
      answerData.add(chunk
          .map((q) => '${q.questionNumber}] ${q.correctAnswerLetter}')
          .toList());
    }

    // Add questions page
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        orientation: pw.PageOrientation.portrait,
        build: (pw.Context context) => [
          pw.Table.fromTextArray(context: context, data: questionData),
          pw.Padding(padding: const pw.EdgeInsets.all(10)),
        ],
      ),
    );

    // Add answers page
    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Padding(padding: const pw.EdgeInsets.all(5)),
          pw.Header(text: 'Answer Sheet'),
          pw.Table.fromTextArray(context: context, data: answerData),
        ],
      ),
    );

    return await pdf.save();
  }

  static List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    final chunks = <List<T>>[];
    for (int i = 0; i < list.length; i += chunkSize) {
      chunks.add(list.sublist(
          i, i + chunkSize > list.length ? list.length : i + chunkSize));
    }
    return chunks;
  }
}

// Service for file operations
class FileService {
  static Future<void> downloadPDFWeb(
      Uint8List pdfBytes, String fileName) async {
    final blob = html.Blob(
      [pdfBytes],
      'application/pdf',
    );
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  static Future<String> savePDFMobile(
      Uint8List pdfBytes, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$fileName';
    final file = File(path);
    await file.writeAsBytes(pdfBytes);
    return path;
  }

  static String generateFileName(QuestionType type) {
    final prefix = type == QuestionType.essay ? 'NoMcq' : 'WithMcq';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${prefix}__$timestamp.pdf';
  }
}

class PdfGenerationScreen extends StatefulWidget {
  const PdfGenerationScreen({
    super.key,
    required this.icon,
    required this.operator,
  });

  final IconData icon;
  final String operator;

  @override
  _PdfGenerationScreenState createState() => _PdfGenerationScreenState();
}

class _PdfGenerationScreenState extends State<PdfGenerationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _range1Controller = TextEditingController();
  final _range2Controller = TextEditingController();

  bool _isLoading = false;

  MathOperation get _operation {
    switch (widget.operator) {
      case 'sum':
        return MathOperation.sum;
      case 'minus':
        return MathOperation.minus;
      case 'multiplication':
        return MathOperation.multiplication;
      case 'division':
        return MathOperation.division;
      default:
        return MathOperation.sum;
    }
  }

  QuestionConfig? get _config {
    if (!_formKey.currentState!.validate()) return null;

    return QuestionConfig(
      questionCount: int.tryParse(_questionController.text) ?? 0,
      maxValue1: int.tryParse(_range1Controller.text) ?? 0,
      maxValue2: int.tryParse(_range2Controller.text) ?? 0,
      operation: _operation,
    );
  }

  Future<void> _generatePDF(QuestionType type) async {
    final config = _config;
    if (config == null || !config.isValid) {
      _showErrorSnackBar('Please fill in valid values');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final Uint8List pdfBytes;
      final String fileName = FileService.generateFileName(type);

      if (type == QuestionType.essay) {
        final questions = MathQuestionGenerator.generateQuestions(config);
        pdfBytes = await PDFGenerationService.generateEssayPDF(questions);
      } else {
        final questions = MathQuestionGenerator.generateMCQQuestions(config);
        pdfBytes = await PDFGenerationService.generateMCQPDF(questions);
      }

      if (kIsWeb) {
        await FileService.downloadPDFWeb(pdfBytes, fileName);
        _navigateToPDFViewer(fileName, pdfBytes: pdfBytes);
      } else {
        final path = await FileService.savePDFMobile(pdfBytes, fileName);
        _navigateToPDFViewer(fileName, path: path, pdfBytes: pdfBytes);
      }
    } catch (e) {
      _showErrorSnackBar('Error generating PDF: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToPDFViewer(String fileName,
      {String? path, Uint8List? pdfBytes}) {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => PdfViewer(
    //       pdfName: fileName,
    //       path: path,
    //       pdfSave: pdfBytes,
    //     ),
    //   ),
    // );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    _range1Controller.dispose();
    _range2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbar.basic(
        onTap: () => context.pop(context),
      ),
      body: ModalProgressHUD(
        inAsyncCall: _isLoading,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return Center(
      child: Container(
        height: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildHeroIcon(),
              const SizedBox(height: 30),
              _buildForm(),
              const SizedBox(height: 30),
              _buildActionButtons(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroIcon() {
    return Hero(
      tag: widget.icon,
      child: Icon(
        widget.icon,
        size: 70,
        color: baseColor,
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          MainScreenCard(
            ques: _questionController,
            icon: widget.icon,
            max: 3,
            label: 'Số câu hỏi',
            maxValue: 100,
            hint: '20',
          ),
          MainScreenCard(
            ques: _range1Controller,
            icon: widget.icon,
            max: 5,
            label: 'Giá trị tối đa số thứ nhất',
            hint: '35',
          ),
          MainScreenCard(
            ques: _range2Controller,
            icon: widget.icon,
            max: 5,
            label: 'Giá trị tối đa số thứ hai',
            hint: '58',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _PDFGenerationButton(
          text: 'Dạng tự luận',
          onPressed: () => _generatePDF(QuestionType.essay),
          isDisabled: _isLoading,
        ),
        const SizedBox(height: 20),
        _PDFGenerationButton(
          text: 'Dạng trắc nghiệm',
          onPressed: () => _generatePDF(QuestionType.multipleChoice),
          isDisabled: _isLoading,
        ),
      ],
    );
  }
}

class _PDFGenerationButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isDisabled;

  const _PDFGenerationButton({
    required this.text,
    required this.onPressed,
    required this.isDisabled,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: isDisabled ? null : onPressed,
      elevation: 30,
      color: isDisabled ? Colors.grey : baseColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
