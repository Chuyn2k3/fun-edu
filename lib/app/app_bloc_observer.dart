import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

class AppBlocObserver extends BlocObserver {
  final void Function(Object error, StackTrace stackTrace)? onErrorLogged;
  final Logger _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  AppBlocObserver({this.onErrorLogged});

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    _logger.d('[BLoC Change] ${bloc.runtimeType}: ${change.currentState} -> ${change.nextState}');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    _logger.e('[BLoC Error] in ${bloc.runtimeType}: $error');
    onErrorLogged?.call(error, stackTrace);
    super.onError(bloc, error, stackTrace);
  }
}
