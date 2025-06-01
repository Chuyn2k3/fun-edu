part of 'sidebar_cubit.dart';

@freezed
class SidebarState with _$SidebarState {
  const factory SidebarState({
    @Default(false) bool isCollapse,
    String? screenGoRoutePath,
    String? version,
    String? buildNumber,
    DateTime? deployTime,
  }) = _SidebarState;
}
