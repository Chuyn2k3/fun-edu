import 'package:flutter/widgets.dart';
import 'package:fun_edu/feature/operation_feature/operator_type.dart';
import 'package:fun_edu/feature/operation_feature/widget/operator_card.dart';
import 'package:fun_edu/utils/base_scaffold.dart';
import 'package:fun_edu/utils/custom_app_bar.dart';

/// {@template operation_page}
/// OperationPage widget.
/// {@endtemplate}
class OperationPage extends StatelessWidget {
  /// {@macro operation_page}
  const OperationPage({
    super.key, // ignore: unused_element
  });

  @override
  Widget build(BuildContext context) {
    var mq = MediaQuery.sizeOf(context);
    return BaseScaffold(
      appBar: CustomAppbar.basic(
        onTap: () => Navigator.pop(context),
        title: "Phép toán",
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(
            horizontal: mq.width * .04, vertical: mq.height * .015),
        children: OperatorType.values.map((e) => OperatorCard(operatorType: e)).toList(),
      ),
    );
  }
}
