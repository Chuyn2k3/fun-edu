import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fun_edu/utils/logs.dart';
import 'package:package_info_plus/package_info_plus.dart';

part 'sidebar_cubit.freezed.dart';
part 'sidebar_state.dart';

class SidebarCubit extends Cubit<SidebarState> {
  SidebarCubit() : super(const SidebarState());

  Future<void> getVersionAndBuild() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    String version = packageInfo.version;
    String buildNumber = packageInfo.buildNumber;

    emit(state.copyWith(version: version, buildNumber: buildNumber));
  }

  Future<void> readTimeFromFile(BuildContext context) async {
    try {
      final fileData = await DefaultAssetBundle.of(context)
          .loadString('assets/file_time.txt');
      final dateString = fileData.toString();
      final dateTime = DateTime.tryParse(dateString.trim());
      emit(state.copyWith(deployTime: dateTime));
    } catch (e) {
      Log.d(e);
    }
  }

  void toggle() {
    emit(state.copyWith(isCollapse: !state.isCollapse));
  }

  void selectSidebarBy(String screenGoRoutePath) {
    emit(state.copyWith(screenGoRoutePath: screenGoRoutePath));
  }

  void clearSidebarSelected() {
    emit(state.copyWith(screenGoRoutePath: null));
  }
}
