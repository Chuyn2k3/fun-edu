import 'package:flutter/material.dart';
import 'package:fun_edu/feature/digit_feature/number/prediction.dart';

class PredictionWidget extends StatelessWidget {
  final List<Prediction> predictions;

  const PredictionWidget({Key? key, required this.predictions})
      : super(key: key);

  Widget _numberWidget(int num, Prediction? prediction) {
    return Column(
      children: <Widget>[
        Text(
          '$num',
          style: TextStyle(
            fontFamily: 'Sukhumvit Set',
            fontSize: 60,
            fontWeight: FontWeight.bold,
            color: prediction == null
                ? Colors.black
                : Colors.red.withOpacity(
                    (prediction.confidence * 2).clamp(0, 1).toDouble(),
                  ),
          ),
        ),
        Text(
          prediction != null ? prediction.confidence.toStringAsFixed(3) : '',
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Sukhumvit Set',
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        )
      ],
    );
  }

  List<Prediction?> getPredictionStyles(List<Prediction> predictions) {
    List<Prediction?> data = List.filled(10, null);

    for (var prediction in predictions) {
      if (prediction.index >= 0 && prediction.index < 10) {
        data[prediction.index] = prediction;
      }
    }

    return data;
  }

  @override
  Widget build(BuildContext context) {
    var styles = getPredictionStyles(predictions);

    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            for (var i = 0; i < 5; i++) _numberWidget(i, styles[i])
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            for (var i = 5; i < 10; i++) _numberWidget(i, styles[i])
          ],
        )
      ],
    );
  }
}
