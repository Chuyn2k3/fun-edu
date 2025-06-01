import 'package:flutter/material.dart';

class HeaderTitleWidget extends StatelessWidget {
  final String title;
  const HeaderTitleWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: const Icon(Icons.arrow_back)),
        const SizedBox(
          width: 16,
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ],
    );
  }
}
