import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fun_edu/utils/common_app.dart';

Widget emptyScreen(BuildContext context,
    [String content = "Không có nội dung"]) {
  return SingleChildScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    child: SizedBox(
      height: MediaQuery.of(context).size.height / 3,
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              "assets/icon/payment_empty.svg",
              height: 120,
              width: 120,
            ),
            Text(
              content,
              textAlign: TextAlign.center,
              style: textTheme.t14M.copyWith(color: Colors.black),
            ),
          ],
        ),
      ),
    ),
  );
}
