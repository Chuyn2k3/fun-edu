import 'package:flutter/widgets.dart';
import 'package:fun_edu/feature/operation_feature/widget/card_video.dart';
import 'package:fun_edu/helper/c_video.dart';
import 'package:fun_edu/model/learn_model.dart';
import 'package:fun_edu/utils/base_scaffold.dart';
import 'package:fun_edu/utils/common_app.dart';
import 'package:fun_edu/utils/custom_app_bar.dart';

/// {@template add_sub_page}
/// AddSubPage widget.
/// {@endtemplate}
class AddSubPage extends StatelessWidget {
  /// {@macro add_sub_page}
  const AddSubPage({
    super.key, // ignore: unused_element
  });

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      appBar: CustomAppbar.basic(
        onTap: () => Navigator.pop(context),
        title: "Dấu lớn hơn(>), nhỏ hơn(<), bằng(=)",
         styleTitle: TextStyle(
          overflow: TextOverflow.ellipsis,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: colorApp.labelPrimary,
        ),
      ),
      body: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: ControllerVideo.dataLengthAddSub,
        itemBuilder: (context, index) {
          LearnModel video = ControllerVideo.dataVideoAddSub[index];
          return CardVideo(data: video);
        },
      ),
    );
  }
}
