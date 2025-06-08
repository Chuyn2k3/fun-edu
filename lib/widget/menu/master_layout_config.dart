import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fun_edu/gen/assets.gen.dart';
import 'package:fun_edu/router/go_router_name_enum.dart';
import 'sidebar.dart';

final sidebarMenuConfigs = [
  SidebarMenuConfig(
    uri: GoRouterName.overView.routePath,
    iconData: FontAwesomeIcons.houseChimney,
    isFlutterAwesome: true,
    title: (context) => "Trang chính",
  ),
  SidebarMenuConfig(
    uri: GoRouterName.numberStudy.routePath,
    iconData: FontAwesomeIcons.hashtag,
    title: (context) => "Học chữ số",
    isFlutterAwesome: true,
    children: [
      SidebarChildMenuConfig(
        uri: GoRouterName.numberByAudio.routePath,
        iconData: FontAwesomeIcons.volumeHigh,
        isFlutterAwesome: true,
        title: (context) => "Học số cơ bản",
      ),
      SidebarChildMenuConfig(
        uri: GoRouterName.numberByMatchImage.routePath,
        iconData: FontAwesomeIcons.puzzlePiece,
        isFlutterAwesome: true,
        title: (context) => "Ghép số với hình",
      ),
      SidebarChildMenuConfig(
        uri: GoRouterName.numberBySort.routePath,
        iconData: FontAwesomeIcons.arrowDown19,
        isFlutterAwesome: true,
        title: (context) => "Sắp xếp số",
      ),
      SidebarChildMenuConfig(
        uri: GoRouterName.evenOdd.routePath,
        iconData: FontAwesomeIcons.circleHalfStroke,
        isFlutterAwesome: true,
        title: (context) => "Chẵn lẻ",
      ),
      SidebarChildMenuConfig(
        uri: GoRouterName.countShape.routePath,
        iconData: FontAwesomeIcons.shapes,
        isFlutterAwesome: true,
        title: (context) => "Đếm hình",
      ),
    ],
  ),
  SidebarMenuConfig(
    uri: GoRouterName.operationStudy.routePath,
    iconData: FontAwesomeIcons.equals,
    title: (context) => "Phép so sánh",
    isFlutterAwesome: true,
    children: [
      SidebarChildMenuConfig(
        uri: GoRouterName.compareNumber.routePath,
        isFlutterAwesome: true,
        iconData: FontAwesomeIcons.sortNumericAsc,
        title: (context) => "So sánh số",
      ),
      SidebarChildMenuConfig(
        uri: GoRouterName.compareNumberByImage.routePath,
        iconData: FontAwesomeIcons.images,
        isFlutterAwesome: true,
        title: (context) => "So sánh bằng hình",
      ),
    ],
  ),
  SidebarMenuConfig(
    uri: GoRouterName.mathStudy.routePath,
    iconData: FontAwesomeIcons.calculator,
    title: (context) => "Luyện tập tính toán",
    isFlutterAwesome: true,
    children: [
      SidebarChildMenuConfig(
        uri: GoRouterName.mathGame.routePath,
        iconData: FontAwesomeIcons.spaceShuttle,
        isFlutterAwesome: true,
        title: (context) => "Trò chơi cộng trừ",
      ),
      SidebarChildMenuConfig(
        uri: GoRouterName.quiz.routePath,
        iconData: FontAwesomeIcons.plusMinus,
        isFlutterAwesome: true,
        title: (context) => "Câu hỏi trắc nghiệm",
      ),
    ],
  ),
  SidebarMenuConfig(
    uri: GoRouterName.mathGame.routePath,
    iconData: FontAwesomeIcons.gamepad,
    isFlutterAwesome: true,
    title: (context) => "Trò chơi",
    children: [
      SidebarChildMenuConfig(
        uri: GoRouterName.dinoRun.routePath,
        icon: Assets.images.dino.path,
        title: (context) => "Khủng Long thoát hiểm",
        isFlutterAwesome: true,
      ),
      SidebarChildMenuConfig(
        uri: GoRouterName.multiPlayerQuiz.routePath,
        icon: Assets.images.dualQuiz.path,
        isFlutterAwesome: true,
        title: (context) => "Đố vui đọ não",
      ),
      SidebarChildMenuConfig(
        uri: GoRouterName.sweep.routePath,
        icon: Assets.images.gameSweepPng.path,
        isFlutterAwesome: true,
        title: (context) => "Giải cứu đại dương",
      ),
    ],
  ),
  SidebarMenuConfig(
    uri: GoRouterName.managerUser.routePath,
    iconData: FontAwesomeIcons.user,
    isFlutterAwesome: true,
    title: (context) => "Người dùng",
  ),
];
