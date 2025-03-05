import 'package:design_system_sl/design_system_sl.dart';
import 'package:flutter/material.dart';
import 'package:fun_edu/data/term/app_colors.dart';
import 'package:fun_edu/helper/pref.dart';
import 'package:fun_edu/utils/base_scaffold.dart';
import 'package:fun_edu/utils/colorConst.dart';
import 'package:fun_edu/utils/custom_app_bar.dart';
import 'package:fun_edu/utils/extension.dart';
import 'package:fun_edu/widget/MainScreenCard.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'quiz_screen.dart';

class QuizQuestionScreen extends StatefulWidget {
  const QuizQuestionScreen({
    super.key,
    this.icon = Icons.add,
    this.operator = 'sum',
  });
  final IconData icon;
  final String operator;

  @override
  State<QuizQuestionScreen> createState() => _QuizQuestionScreenState();
}

class _QuizQuestionScreenState extends State<QuizQuestionScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _ques = TextEditingController();

  final TextEditingController _range1 = TextEditingController();

  final TextEditingController _range2 = TextEditingController();
  var time = 10;
  final List<int> lists = [5, 10, 15, 20, 25, 30];
  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      appBar: CustomAppbar.basic(
        isLeading: true,
        title: "Phép tính",
        styleTitle: TextStyle(color: Theme.of(context).lightTextColor),
        onTap: () => Navigator.pop(context),
      ),
      body: Center(
        child: Container(
          height: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: SingleChildScrollView(
            physics: const ScrollPhysics(parent: ScrollPhysics()),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Hero(
                  tag: widget.icon,
                  child: Icon(
                    widget.icon,
                    size: 70,
                    color: baseColor,
                  ),
                ),
                const SizedBox(height: 30),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      MainScreenCard(
                          ques: _ques,
                          icon: widget.icon,
                          max: 3,
                          label: 'Số câu hỏi',
                          maxValue: 100,
                          hint: '20'),
                      MainScreenCard(
                          ques: _range1,
                          icon: widget.icon,
                          max: 5,
                          label: 'Giá trị tối đa toán tử thứ nhất',
                          hint: '20'),
                      MainScreenCard(
                          ques: _range2,
                          icon: widget.icon,
                          max: 5,
                          label: 'Giá trị tối đa toán tử thứ hai',
                          hint: '55'),
                    ],
                  ),
                ),
                const Row(
                  children: [
                    Text('Thời gian', style: TextStyle(fontSize: 16)),
                    SizedBox(
                      width: 8,
                    ),
                    Icon(Icons.watch_later_outlined),
                  ],
                ),
                const SizedBox(
                  height: 4,
                ),
                Container(
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(4))),
                  child: DropdownSearch<int>(
                    items: lists,
                    popupProps: PopupProps.menu(
                        showSearchBox: false,
                        searchFieldProps: TextFieldProps(
                            style: PrimaryFont.medium(13)
                                .copyWith(color: AppColors.greyColor)),
                        itemBuilder: (context, item, _) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text("${item}s",
                                style: PrimaryFont.medium(13)
                                    .copyWith(color: AppColors.greyColor)),
                          );
                        }),
                    clearButtonProps: const ClearButtonProps(isVisible: false),
                    //  selectedItem: lists.first,
                    dropdownBuilder: (context, item) {
                      return Text(
                        item != null ? "${item}s" : "10s",
                        style: PrimaryFont.medium(13)
                            .copyWith(color: AppColors.greyColor),
                      );
                    },
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        suffixIconColor:
                            Pref.isDarkMode ? Colors.black : Colors.white,
                        contentPadding:
                            const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                        border: InputBorder.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        time = value ?? 10;
                      });
                    },
                  ),
                ),
                // ExpansionTile(
                //   title: const Text('Time'),
                //   childrenPadding: const EdgeInsets.fromLTRB(30, 2, 30, 10),
                //   leading: const Icon(Icons.watch_later_rounded),
                //   trailing: Text('${time.toString()}s'),
                //   children: [
                //     ListTile(
                //       title: const Text('5s'),
                //       onTap: () {
                //         setState(() {
                //           time = 5;
                //         });
                //       },
                //     ),
                //     ListTile(
                //       title: const Text('10s'),
                //       onTap: () {
                //         setState(() {
                //           time = 10;
                //         });
                //       },
                //     ),
                //     ListTile(
                //       title: const Text('15s'),
                //       onTap: () {
                //         setState(() {
                //           time = 15;
                //         });
                //       },
                //     ),
                //     ListTile(
                //       title: const Text('20s'),
                //       onTap: () {
                //         setState(() {
                //           time = 20;
                //         });
                //       },
                //     ),
                //   ],
                // ),
                const SizedBox(
                  height: 30,
                ),
                MaterialButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => QuizScreen(
                                operator: widget.operator,
                                numOfQuestions: _ques.text,
                                range1: _range1.text,
                                range2: _range2.text,
                                duration: time)),
                      );
                    }
                  },
                  elevation: 20,
                  color: baseColor,
                  child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Tạo Quiz',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w600))),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
