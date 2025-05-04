import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fun_edu/feature/math_feature/customWidget/DisplayButton.dart';
import 'package:fun_edu/feature/math_feature/screen/Quiz/ask_operator.dart';
import 'package:fun_edu/utils/base_scaffold.dart';
import 'package:fun_edu/utils/custom_app_bar.dart';
import 'package:go_router/go_router.dart';

/// {@template math_screen}
/// MathScreen widget.
/// {@endtemplate}
class MathScreen extends StatelessWidget {
  /// {@macro math_screen}
  const MathScreen({
    super.key, // ignore: unused_element
  });

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      appBar: CustomAppbar.basic(
        onTap: () {
          Navigator.pop(context);
        },
        title: "Phép tính",
      ),
      body: Container(
        height: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 10, 30, 10),
        child: SingleChildScrollView(
          physics: const ScrollPhysics(parent: ScrollPhysics()),
          child: Center(
            child: Column(
              children: [
                DisplayButton(
                  text: 'Tạo file PDF',
                  function: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AskOperator(isQuiz: false),
                    ),
                  ),
                ),
                SizedBox(
                  height: (MediaQuery.of(context).size.height * 20) / 816,
                ),
                DisplayButton(
                  text: 'Câu hỏi',
                  function: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AskOperator(isQuiz: true),
                      settings: RouteSettings(name: '/askOperator'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
