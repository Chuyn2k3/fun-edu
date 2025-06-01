// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sidebar_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SidebarState {
  bool get isCollapse => throw _privateConstructorUsedError;
  String? get screenGoRoutePath => throw _privateConstructorUsedError;
  String? get version => throw _privateConstructorUsedError;
  String? get buildNumber => throw _privateConstructorUsedError;
  DateTime? get deployTime => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $SidebarStateCopyWith<SidebarState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SidebarStateCopyWith<$Res> {
  factory $SidebarStateCopyWith(
          SidebarState value, $Res Function(SidebarState) then) =
      _$SidebarStateCopyWithImpl<$Res, SidebarState>;
  @useResult
  $Res call(
      {bool isCollapse,
      String? screenGoRoutePath,
      String? version,
      String? buildNumber,
      DateTime? deployTime});
}

/// @nodoc
class _$SidebarStateCopyWithImpl<$Res, $Val extends SidebarState>
    implements $SidebarStateCopyWith<$Res> {
  _$SidebarStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isCollapse = null,
    Object? screenGoRoutePath = freezed,
    Object? version = freezed,
    Object? buildNumber = freezed,
    Object? deployTime = freezed,
  }) {
    return _then(_value.copyWith(
      isCollapse: null == isCollapse
          ? _value.isCollapse
          : isCollapse // ignore: cast_nullable_to_non_nullable
              as bool,
      screenGoRoutePath: freezed == screenGoRoutePath
          ? _value.screenGoRoutePath
          : screenGoRoutePath // ignore: cast_nullable_to_non_nullable
              as String?,
      version: freezed == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String?,
      buildNumber: freezed == buildNumber
          ? _value.buildNumber
          : buildNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      deployTime: freezed == deployTime
          ? _value.deployTime
          : deployTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SidebarStateImplCopyWith<$Res>
    implements $SidebarStateCopyWith<$Res> {
  factory _$$SidebarStateImplCopyWith(
          _$SidebarStateImpl value, $Res Function(_$SidebarStateImpl) then) =
      __$$SidebarStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isCollapse,
      String? screenGoRoutePath,
      String? version,
      String? buildNumber,
      DateTime? deployTime});
}

/// @nodoc
class __$$SidebarStateImplCopyWithImpl<$Res>
    extends _$SidebarStateCopyWithImpl<$Res, _$SidebarStateImpl>
    implements _$$SidebarStateImplCopyWith<$Res> {
  __$$SidebarStateImplCopyWithImpl(
      _$SidebarStateImpl _value, $Res Function(_$SidebarStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isCollapse = null,
    Object? screenGoRoutePath = freezed,
    Object? version = freezed,
    Object? buildNumber = freezed,
    Object? deployTime = freezed,
  }) {
    return _then(_$SidebarStateImpl(
      isCollapse: null == isCollapse
          ? _value.isCollapse
          : isCollapse // ignore: cast_nullable_to_non_nullable
              as bool,
      screenGoRoutePath: freezed == screenGoRoutePath
          ? _value.screenGoRoutePath
          : screenGoRoutePath // ignore: cast_nullable_to_non_nullable
              as String?,
      version: freezed == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String?,
      buildNumber: freezed == buildNumber
          ? _value.buildNumber
          : buildNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      deployTime: freezed == deployTime
          ? _value.deployTime
          : deployTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

class _$SidebarStateImpl implements _SidebarState {
  const _$SidebarStateImpl(
      {this.isCollapse = false,
      this.screenGoRoutePath,
      this.version,
      this.buildNumber,
      this.deployTime});

  @override
  @JsonKey()
  final bool isCollapse;
  @override
  final String? screenGoRoutePath;
  @override
  final String? version;
  @override
  final String? buildNumber;
  @override
  final DateTime? deployTime;

  @override
  String toString() {
    return 'SidebarState(isCollapse: $isCollapse, screenGoRoutePath: $screenGoRoutePath, version: $version, buildNumber: $buildNumber, deployTime: $deployTime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SidebarStateImpl &&
            (identical(other.isCollapse, isCollapse) ||
                other.isCollapse == isCollapse) &&
            (identical(other.screenGoRoutePath, screenGoRoutePath) ||
                other.screenGoRoutePath == screenGoRoutePath) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.buildNumber, buildNumber) ||
                other.buildNumber == buildNumber) &&
            (identical(other.deployTime, deployTime) ||
                other.deployTime == deployTime));
  }

  @override
  int get hashCode => Object.hash(runtimeType, isCollapse, screenGoRoutePath,
      version, buildNumber, deployTime);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SidebarStateImplCopyWith<_$SidebarStateImpl> get copyWith =>
      __$$SidebarStateImplCopyWithImpl<_$SidebarStateImpl>(this, _$identity);
}

abstract class _SidebarState implements SidebarState {
  const factory _SidebarState(
      {final bool isCollapse,
      final String? screenGoRoutePath,
      final String? version,
      final String? buildNumber,
      final DateTime? deployTime}) = _$SidebarStateImpl;

  @override
  bool get isCollapse;
  @override
  String? get screenGoRoutePath;
  @override
  String? get version;
  @override
  String? get buildNumber;
  @override
  DateTime? get deployTime;
  @override
  @JsonKey(ignore: true)
  _$$SidebarStateImplCopyWith<_$SidebarStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
