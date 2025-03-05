import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fun_edu/utils/base_scaffold.dart';
import 'package:fun_edu/utils/colorConst.dart';
import 'package:fun_edu/utils/custom_app_bar.dart';
import 'package:fun_edu/utils/extension.dart';

class UserAnswerScreen extends StatelessWidget {
  const UserAnswerScreen({
    required this.questions,
    required this.answers,
    required this.userAnswer,
    super.key,
  });
  final List<dynamic> questions;
  final List<dynamic> answers;
  final List<dynamic> userAnswer;

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      appBar: CustomAppbar.basic(
        isLeading: true,
        title: "Phép tính",
        styleTitle: TextStyle(
          color: Theme.of(context).lightTextColor,
        ),
        onTap: () => Navigator.pop(context),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 30),
              SizedBox(
                width: MediaQuery.of(context).size.width > 700
                    ? 600
                    : double.infinity,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemBuilder: (c, i) {
                    return Card(
                      color: baseColor,
                      elevation: 10,
                      child: ListTile(
                        leading:
                            userAnswer[i].toString() == answers[i].toString()
                                ? const CircleAvatar(
                                    backgroundColor: Colors.white,
                                    child: Icon(
                                      FontAwesomeIcons.check,
                                      color: baseColorLight,
                                    ))
                                : const CircleAvatar(
                                    backgroundColor: Colors.white,
                                    child: Icon(
                                      FontAwesomeIcons.xmark,
                                      color: redColorLight,
                                    ),
                                  ),
                        title: Text(questions[i].toString(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        subtitle: Text('Answer = ${answers[i].toString()}',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 15)),
                        trailing: Text(userAnswer[i].toString(),
                            style: const TextStyle(
                                fontSize: 20, color: Colors.orangeAccent)),
                      ),
                    );
                  },
                  itemCount: answers.length,
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
