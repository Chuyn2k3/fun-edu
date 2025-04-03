import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fun_edu/data/color/color.dart';
import 'package:fun_edu/feature/digit_feature/enum/digit_enum.dart';
import 'package:fun_edu/feature/digit_feature/number/digit_number.dart';
import 'package:fun_edu/widget/background_v2.dart';

class DigitRecogizePage extends StatelessWidget {
  const DigitRecogizePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorBase.secondaryBackground,
      body: Stack(
        children: [
          const BackgroundV2(),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  _buildBody(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 4),
          child: Text(
            'Nhận diện thông minh',
            style: TextStyle(
              fontFamily: 'Sukhumvit Set',
              fontSize: 28,
              letterSpacing: 0.0,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Cùng bé luyện viết số dễ dàng!',
            style: TextStyle(
              fontFamily: 'Sukhumvit Set',
              fontSize: 18,
              letterSpacing: 0.0,
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
  ) {
    const digitEnum = DigitRecogize.values;
    return Column(
        children: digitEnum
            .map((e) => _buildItem(
                  context,
                  e,
                  e.onTap,
                ))
            .toList());
  }

  Widget _buildItem(
      BuildContext context, DigitRecogize digitRecogize, VoidCallback onTap) {
    return Container(
      //width: MediaQuery.sizeOf(context).width * 0.91,
      margin: const EdgeInsets.symmetric(vertical: 8),
      //height: 180,
      decoration: BoxDecoration(
        color: digitRecogize.color,
        boxShadow: [
          BoxShadow(
            blurRadius: 0,
            color: digitRecogize.colorB,
            offset: const Offset(
              4,
              4,
            ),
            spreadRadius: 0,
          )
        ],
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: const AlignmentDirectional(0, 0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          //mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 6),
                    child: Text(
                      digitRecogize.title,
                      style: const TextStyle(
                        fontFamily: 'Sukhumvit Set',
                        fontSize: 16,
                        letterSpacing: 0.0,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: onTap,
                    child: Container(
                      //width: 75,
                      //height: 25,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: digitRecogize.colorB,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Khám phá!',
                            style: TextStyle(
                              fontFamily: 'Sukhumvit Set',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: Image.asset(
                'assets/images/${digitRecogize.image}',
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
