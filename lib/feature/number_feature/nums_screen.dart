import 'package:flutter/material.dart';
import 'package:fun_edu/data/term/constants.dart';
import 'package:fun_edu/model/model_nums.dart';
import 'package:fun_edu/utils/base_scaffold.dart';
import 'package:fun_edu/utils/custom_app_bar.dart';

class NumsScreen extends StatefulWidget {
  const NumsScreen({super.key});

  @override
  State<NumsScreen> createState() => _NumsScreenState();
}

class _NumsScreenState extends State<NumsScreen> {
  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      appBar: CustomAppbar.basic(
        onTap: () {
          Navigator.pop(context);
        },
        title: "Chữ số",
      ),
      body: Center(
        child: buildModels(),
      ),
    );
  }

  Widget buildModels() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: numsList.length,
        itemBuilder: (context, index) {
          return ModelStyle(
            cardModel: CustomCardModel(
              title: numsList[index].title,
              subImage: numsList[index].subImage,
              image: numsList[index].image,
              color: numsList[index].color,
            ),
          );
        },
      ),
    );
  }
}
