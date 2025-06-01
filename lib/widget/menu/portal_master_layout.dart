import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fun_edu/constant/dimens.dart';
import 'package:fun_edu/core/theme/app_themes.dart';
import 'package:fun_edu/cubit/sidebar/sidebar_cubit.dart';
import 'master_layout_config.dart';
import 'responsive_appbar_title.dart';
import 'sidebar.dart';

class PortalMasterLayout extends StatelessWidget {
  final Widget body;
  final bool autoSelectMenu;
  final String? selectedMenuUri;
  final void Function(bool isOpened)? onDrawerChanged;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final FloatingActionButtonAnimator? floatingActionButtonAnimator;
  final List<Widget>? persistentFooterButtons;

  const PortalMasterLayout({
    Key? key,
    required this.body,
    this.autoSelectMenu = true,
    this.selectedMenuUri,
    this.onDrawerChanged,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.floatingActionButtonAnimator,
    this.persistentFooterButtons,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    final drawer = (mediaQueryData.size.width <= kScreenWidthLg
        ? _sidebar(context)
        : null);
    final Color primaryPink = const Color(0xFFFF6B9D);
    final Color primaryPurple = const Color(0xFF9B59B6);
    final Color primaryBlue = const Color(0xFF3498DB);
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [primaryPink, primaryPurple, primaryBlue],
            ),
          ),
        ),
        automaticallyImplyLeading: (drawer != null),
        title: const ResponsiveAppBarTitle(),
        backgroundColor: AppThemes.of(context).appColors.primary.shade800,
        actions: const [
          // _toggleThemeButton(context),
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 4.0),
          //   child: VerticalDivider(
          //     width: 1.0,
          //     thickness: 1.0,
          //     color: themeData.appBarTheme.foregroundColor!.withOpacity(0.5),
          //     indent: 14.0,
          //     endIndent: 14.0,
          //   ),
          // ),
          // _changeLanguageButton(context),
          // const SizedBox(width: kDefaultPadding * 0.5),
        ],
      ),
      drawer: drawer,
      drawerEnableOpenDragGesture: false,
      onDrawerChanged: onDrawerChanged,
      body: SelectionArea(child: _responsiveBody(context)),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      floatingActionButtonAnimator: floatingActionButtonAnimator,
      persistentFooterButtons: persistentFooterButtons,
    );
  }

  Widget _sidebar(BuildContext context) {
    //final goRouter = GoRouter.of(context);

    return Sidebar(
      autoSelectMenu: autoSelectMenu,
      selectedMenuUri: selectedMenuUri,
      onAccountButtonPressed: () {},
      onLogoutButtonPressed: () {},
      sidebarConfigs: sidebarMenuConfigs,
    );
  }

  Widget _responsiveBody(BuildContext context) {
    if (MediaQuery.of(context).size.width <= kScreenWidthLg) {
      return body;
    } else {
      return BlocBuilder<SidebarCubit, SidebarState>(
        builder: (context, state) {
          final isCollapse = state.isCollapse;
          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: Dimens.instance.sidebarWidth(isCollapse),
                child: _sidebar(context),
              ),
              Expanded(child: body),
            ],
          );
        },
      );
    }
  }
}
