import 'package:flutter/material.dart';
import 'package:fun_edu/data/color/color.dart';
import 'package:fun_edu/feature/game_feature/enum/game_enum.dart';
import 'package:fun_edu/widget/background_v2.dart';

class ListGamePage extends StatelessWidget {
  const ListGamePage({
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
            'Học giỏi chơi vui',
            style: TextStyle(
              fontFamily: 'LilitaOne',
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
            'Chinh phục thử thách!',
            style: TextStyle(
              fontFamily: 'LilitaOne',
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
    const digitEnum = GameEnum.values;
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
      BuildContext context, GameEnum digitRecogize, VoidCallback onTap) {
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
            Flexible(
              flex: 4,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 6),
                    child: Text(
                      digitRecogize.getName,
                      style: const TextStyle(
                        fontFamily: 'LilitaOne',
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
                              fontFamily: 'LilitaOne',
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
            // const Spacer(),
            Expanded(flex: 1, child: SizedBox()),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle, // Hình tròn
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/${digitRecogize.getImage}',
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
