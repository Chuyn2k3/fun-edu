import 'package:json_annotation/json_annotation.dart';

part 'base_response.g.dart';

@JsonSerializable(
  genericArgumentFactories: true,
)
class BaseResponse<T> {
  final List<T>? data;
  final int? code;
  final String? message;
  final PageInfo? pageInfo;

  BaseResponse(this.data, this.code, this.message, this.pageInfo);

  int totalPage(int pageSize) =>
      ((pageInfo?.totalRecord ?? 0) / pageSize).ceil();

  factory BaseResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$BaseResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object Function(T value) toJsonT) =>
      _$BaseResponseToJson(this, toJsonT);
}

@JsonSerializable(
  genericArgumentFactories: true,
)
class DioResponse<T> {
  final T? data;
  final int? code;
  final String? message;

  DioResponse(
    this.data,
    this.code,
    this.message,
  );

  factory DioResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$DioResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$DioResponseToJson(this, toJsonT);
}

@JsonSerializable()
class PageInfo {
  int? limit;
  int? totalRecord;
  int? offset;
  String? sort;
  PageInfo(this.limit, this.offset, this.sort, this.totalRecord);

  factory PageInfo.fromJson(Map<String, dynamic> json) =>
      _$PageInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PageInfoToJson(this);
}

@JsonSerializable()
class PageInfoRequest {
  String? query;
  int? offset;
  int? limit;
  String? sort;
  PageInfoRequest({
    this.query,
    this.offset,
    this.limit,
    this.sort,
  });

  factory PageInfoRequest.fromJson(Map<String, dynamic> json) =>
      _$PageInfoRequestFromJson(json);
  Map<String, dynamic> toJson() => _$PageInfoRequestToJson(this);
}

@JsonSerializable(
  genericArgumentFactories: true,
)
class BaseArrayResponse<T> {
  final List<T>? data;
  final int? totalElements;
  final int? page;
  final int? pageSize;

  BaseArrayResponse({
    required this.data,
    required this.totalElements,
    required this.page,
    required this.pageSize,
  });

  factory BaseArrayResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$BaseArrayResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object Function(T value) toJsonT) =>
      _$BaseArrayResponseToJson(this, toJsonT);
}
