import 'package:logger/logger.dart';

var logger = Logger();

class Log {
  Log._();

  static void logPrint(Object message) {
    // ignore: avoid_print
    print(message);
  }

  static void d(Object message) {
    logger.d(message);
  }

  static void e(Object message) {
    logger.e(message);
  }
}
