import 'package:flutter/widgets.dart';
import 'package:fun_edu/feature/operation_feature/widget/card_video.dart';
import 'package:fun_edu/helper/c_video.dart';
import 'package:fun_edu/model/learn_model.dart';
import 'package:fun_edu/utils/base_scaffold.dart';
import 'package:fun_edu/utils/common_app.dart';
import 'package:fun_edu/utils/custom_app_bar.dart';

class VideoLearnMathScreen extends StatelessWidget {

  const VideoLearnMathScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context)  {
   return BaseScaffold(
      appBar: CustomAppbar.basic(
        onTap: () => Navigator.pop(context),
        title: "Cộng trừ số nhỏ",
        styleTitle: TextStyle(
          overflow: TextOverflow.ellipsis,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: colorApp.labelPrimary,
        ),
      ),
      body: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: ControllerVideo.dataLengthMath,
        itemBuilder: (context, index) {
          LearnModel video = ControllerVideo.dataVideoMath[index];
          return CardVideo(data: video);
        },
      ),
    );
  }
}
