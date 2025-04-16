// ignore_for_file: unused_element
import 'package:dio/dio.dart';
import 'package:fun_edu/utils/shared_preferences_manager.dart';
import 'package:get_it/get_it.dart';

import 'api_error_model.dart';
import 'api_exception.dart';

class TokenInterceptor extends InterceptorsWrapper {
  @override
  Future onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final accessToken =
        GetIt.instance.get<SharedPreferencesManager>().getString('accessToken');
    if (accessToken == null) {
      return super.onRequest(options, handler);
    }
    options.headers["Authorization"] = "Bearer $accessToken";
    return super.onRequest(options, handler);
  }


  @override
  Future onError(DioError err, ErrorInterceptorHandler handler) async {
    final apiException = await err.toApiException();
    err.error = apiException;
    final isLogin =
        err.response?.requestOptions.uri.path.contains("authenticate") ?? false;
    if (apiException.statusCode == 401 && !isLogin) {
      handler.reject(err);
    } else {
      handler.next(err);
    }
  }


}


extension on DioError {
  Future<ApiException> toApiException() async {
    final errorCode = response?.statusCode ?? 0;
    final path = response?.requestOptions.uri.path ?? '';

    final apiError = APIError.fromJson(response?.data);
    var titleMessage = apiError.message ?? "";

    switch (errorCode) {
      case 400:
        return ApiException.badRequest(
            path, titleMessage, apiError.status.toString(), errorCode);
      case 401:
        return ApiException.unauthorized(
            path, titleMessage, apiError.status.toString(), errorCode);
      case 403:
        return ApiException.forbidden(
            path, titleMessage, apiError.status.toString(), errorCode);
      case 404:
        return ApiException.notFound(
            path, titleMessage, apiError.status.toString(), errorCode);
      case 500:
        return ApiException.internalServerError(
            path, titleMessage, apiError.status.toString(), errorCode);
      default:
        return ApiException.notFound(
            path, titleMessage, apiError.status.toString(), errorCode);
    }
  }
}

extension on DioError {
  String toMessage() {
    return (error as ApiException).message ?? '';
  }
}
