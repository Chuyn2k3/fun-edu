import 'package:flutter/material.dart';
import 'dart:math';

import 'package:fun_edu/model/game.dart';

class GameProvider extends ChangeNotifier {
  // Configuration
  int _numberRange = 100;
  int _maxShapes = 15;

  // Game state
  int _score = 0;
  int _level = 1;
  int _combo = 0;

  // Getters
  int get numberRange => _numberRange;
  int get maxShapes => _maxShapes;
  int get score => _score;
  int get level => _level;
  int get combo => _combo;

  // Random number generator
  final Random _random = Random();

  // Generate a random number within the range
  int generateRandomNumber() {
    return _random.nextInt(_numberRange) + 1;
  }

  // Check if a number is even
  bool isEven(int number) {
    return number % 2 == 0;
  }

  // Handle answer for even/odd game
  void checkEvenOddAnswer(int number, bool isEvenAnswer) {
    bool correct =
        (isEven(number) && isEvenAnswer) || (!isEven(number) && !isEvenAnswer);

    if (correct) {
      _score += 1 + _combo;
      _combo++;
      if (_score > 0 && _score % 5 == 0) {
        _level++;
      }
    } else {
      _combo = 0;
    }

    notifyListeners();
  }

  // Generate shapes for the counting game
  List<GameShape> generateShapes() {
    // Determine number of shapes based on level
    int totalShapes = min(5 + _level * 2, _maxShapes);

    // Select target shape and color
    ShapeType targetShape =
        ShapeType.values[_random.nextInt(ShapeType.values.length)];
    Color? targetColor = _level > 3
        ? Colors.primaries[_random.nextInt(Colors.primaries.length)]
        : null;

    // Determine how many target shapes to create
    int targetCount = _random.nextInt(min(6, _level + 2)) + 2;

    List<GameShape> shapes = [];

    // Create target shapes
    for (int i = 0; i < targetCount; i++) {
      shapes.add(GameShape(
        type: targetShape,
        color: targetColor ??
            Colors.primaries[_random.nextInt(Colors.primaries.length)],
        x: _random.nextDouble() * 0.8,
        y: _random.nextDouble() * 0.8,
        rotation: _random.nextDouble() * 2 * pi,
        size: _random.nextDouble() * 30 + 50,
      ));
    }

    // Fill with other shapes
    while (shapes.length < totalShapes) {
      ShapeType shapeType =
          ShapeType.values[_random.nextInt(ShapeType.values.length)];
      Color color = Colors.primaries[_random.nextInt(Colors.primaries.length)];

      // Don't add more target shapes
      if (shapeType == targetShape &&
          (targetColor == null || color == targetColor)) {
        continue;
      }

      shapes.add(GameShape(
        type: shapeType,
        color: color,
        x: _random.nextDouble() * 0.8,
        y: _random.nextDouble() * 0.8,
        rotation: _random.nextDouble() * 2 * pi,
        size: _random.nextDouble() * 20 + 30,
      ));
    }

    return shapes;
  }

  // Check answer for counting game
  void checkCountingAnswer(int userAnswer, int correctAnswer) {
    if (userAnswer == correctAnswer) {
      _score++;
      _combo++;
      if (_score > 0 && _score % 3 == 0) {
        _level++;
      }
    } else {
      _combo = 0;
    }

    notifyListeners();
  }

  // Reset game state
  void resetGame() {
    _score = 0;
    _level = 1;
    _combo = 0;
    notifyListeners();
  }

  // Update number range
  void setNumberRange(int range) {
    _numberRange = range;
    notifyListeners();
  }

  // Update max shapes
  void setMaxShapes(int max) {
    _maxShapes = max;
    notifyListeners();
  }
}
