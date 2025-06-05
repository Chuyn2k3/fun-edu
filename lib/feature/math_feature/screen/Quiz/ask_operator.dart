import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fun_edu/feature/math_feature/customWidget/button_icon.dart';
import 'package:fun_edu/feature/math_feature/screen/PDF/pdf_generaton_screen.dart';
import 'package:fun_edu/feature/math_feature/screen/Quiz/quiz_question_screen.dart';
import 'package:fun_edu/utils/base_scaffold.dart';
import 'package:fun_edu/utils/custom_app_bar.dart';
import 'package:fun_edu/widget/menu/portal_master_layout.dart';
import 'package:go_router/go_router.dart';

class AskOperator extends StatelessWidget {
  const AskOperator({super.key, required this.isQuiz});
  final bool isQuiz;
  @override
  Widget build(BuildContext context) {
    return kIsWeb
        ? PortalMasterLayout(
            body: _buildBody(context),
          )
        : _buildBody(context);
  }

  Widget _buildBody(BuildContext context) {
    return BaseScaffold(
      appBar: CustomAppbar.basic(
        isLeading: !kIsWeb,
        onTap: !kIsWeb
            ? () {
                context.pop(context);
              }
            : null,
        title: "Chọn phép tính toán",
      ),
      body: SafeArea(
        child: SizedBox(
          height: double.infinity,
          child: Center(
            child: SingleChildScrollView(
              physics: const ScrollPhysics(parent: ScrollPhysics()),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ButtonIcon(
                        icon: FontAwesomeIcons.plus,
                        function: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => isQuiz
                                  ? const QuizQuestionScreen(
                                      icon: FontAwesomeIcons.plus,
                                    )
                                  : const PdfGenerationScreen(
                                      icon: FontAwesomeIcons.plus,
                                      operator: 'sum',
                                    ),
                            )),
                      ),
                      ButtonIcon(
                        icon: FontAwesomeIcons.minus,
                        function: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => isQuiz
                                  ? const QuizQuestionScreen(
                                      icon: FontAwesomeIcons.minus,
                                      operator: 'minus',
                                    )
                                  : const PdfGenerationScreen(
                                      icon: FontAwesomeIcons.minus,
                                      operator: 'minus',
                                    ),
                            )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ButtonIcon(
                        icon: FontAwesomeIcons.xmark,
                        function: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => isQuiz
                                  ? const QuizQuestionScreen(
                                      icon: FontAwesomeIcons.xmark,
                                      operator: 'multiplication')
                                  : const PdfGenerationScreen(
                                      icon: FontAwesomeIcons.xmark,
                                      operator: 'multiplication'),
                            )),
                      ),
                      ButtonIcon(
                        icon: FontAwesomeIcons.divide,
                        function: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => isQuiz
                                ? const QuizQuestionScreen(
                                    icon: FontAwesomeIcons.divide,
                                    operator: 'division',
                                  )
                                : const PdfGenerationScreen(
                                    icon: FontAwesomeIcons.divide,
                                    operator: 'division',
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
