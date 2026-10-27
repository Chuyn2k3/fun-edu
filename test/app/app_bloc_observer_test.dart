import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/app/app_bloc_observer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class _SimpleCubit extends Cubit<int> {
  _SimpleCubit() : super(0);
}

void main() {
  test('AppBlocObserver handles errors gracefully without bubbling', () {
    var errorHandled = false;
    final observer = AppBlocObserver(onErrorLogged: (_, __) {
      errorHandled = true;
    });

    final cubit = _SimpleCubit();
    observer.onError(cubit, Exception("error"), StackTrace.empty);
    expect(errorHandled, isTrue);
  });
}
