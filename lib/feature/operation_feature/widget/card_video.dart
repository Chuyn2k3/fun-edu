import 'package:flutter/material.dart';
import 'package:fun_edu/feature/operation_feature/widget/web_view.dart';
import 'package:fun_edu/model/learn_model.dart';
import 'package:google_fonts/google_fonts.dart';

class CardVideo extends StatelessWidget {
  final LearnModel data;
  CardVideo({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppWebView(
              linkWebView: data.pageUrl,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        height: 220,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // 🌟 Bo góc mềm mại
          ),
          color: Colors.yellow[100], // 🌟 Nền màu tươi sáng
          elevation: 8,
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    data.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: Text(
                    data.title,
                    style: GoogleFonts.permanentMarker(
                      // 🌟 Font chữ vui nhộn
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
