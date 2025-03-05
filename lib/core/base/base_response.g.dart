// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'base_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BaseResponse<T> _$BaseResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) =>
    BaseResponse<T>(
      (json['data'] as List<dynamic>?)?.map(fromJsonT).toList(),
      (json['code'] as num?)?.toInt(),
      json['message'] as String?,
      json['pageInfo'] == null
          ? null
          : PageInfo.fromJson(json['pageInfo'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BaseResponseToJson<T>(
  BaseResponse<T> instance,
  Object? Function(T value) toJsonT,
) =>
    <String, dynamic>{
      'data': instance.data?.map(toJsonT).toList(),
      'code': instance.code,
      'message': instance.message,
      'pageInfo': instance.pageInfo,
    };

DioResponse<T> _$DioResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) =>
    DioResponse<T>(
      _$nullableGenericFromJson(json['data'], fromJsonT),
      (json['code'] as num?)?.toInt(),
      json['message'] as String?,
    );

Map<String, dynamic> _$DioResponseToJson<T>(
  DioResponse<T> instance,
  Object? Function(T value) toJsonT,
) =>
    <String, dynamic>{
      'data': _$nullableGenericToJson(instance.data, toJsonT),
      'code': instance.code,
      'message': instance.message,
    };

T? _$nullableGenericFromJson<T>(
  Object? input,
  T Function(Object? json) fromJson,
) =>
    input == null ? null : fromJson(input);

Object? _$nullableGenericToJson<T>(
  T? input,
  Object? Function(T value) toJson,
) =>
    input == null ? null : toJson(input);

PageInfo _$PageInfoFromJson(Map<String, dynamic> json) => PageInfo(
      (json['limit'] as num?)?.toInt(),
      (json['offset'] as num?)?.toInt(),
      json['sort'] as String?,
      (json['totalRecord'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PageInfoToJson(PageInfo instance) => <String, dynamic>{
      'limit': instance.limit,
      'totalRecord': instance.totalRecord,
      'offset': instance.offset,
      'sort': instance.sort,
    };

PageInfoRequest _$PageInfoRequestFromJson(Map<String, dynamic> json) =>
    PageInfoRequest(
      query: json['query'] as String?,
      offset: (json['offset'] as num?)?.toInt(),
      limit: (json['limit'] as num?)?.toInt(),
      sort: json['sort'] as String?,
    );

Map<String, dynamic> _$PageInfoRequestToJson(PageInfoRequest instance) =>
    <String, dynamic>{
      'query': instance.query,
      'offset': instance.offset,
      'limit': instance.limit,
      'sort': instance.sort,
    };

BaseArrayResponse<T> _$BaseArrayResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) =>
    BaseArrayResponse<T>(
      data: (json['data'] as List<dynamic>?)?.map(fromJsonT).toList(),
      totalElements: (json['totalElements'] as num?)?.toInt(),
      page: (json['page'] as num?)?.toInt(),
      pageSize: (json['pageSize'] as num?)?.toInt(),
    );

Map<String, dynamic> _$BaseArrayResponseToJson<T>(
  BaseArrayResponse<T> instance,
  Object? Function(T value) toJsonT,
) =>
    <String, dynamic>{
      'data': instance.data?.map(toJsonT).toList(),
      'totalElements': instance.totalElements,
      'page': instance.page,
      'pageSize': instance.pageSize,
    };
