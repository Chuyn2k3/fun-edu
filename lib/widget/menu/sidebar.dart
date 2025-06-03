import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fun_edu/constant/dimens.dart';
import 'package:fun_edu/core/theme/app_themes.dart';
import 'package:fun_edu/cubit/sidebar/sidebar_cubit.dart';
import 'package:fun_edu/dashboard/theme/app_sidebar_theme.dart';
import 'package:fun_edu/data/term/constants.dart';
import 'package:fun_edu/gen/assets.gen.dart';
import 'package:fun_edu/utils/enum/sidebar_function/sidebar_function.dart';
import 'package:fun_edu/widget/menu/master_layout_config.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class SidebarMenuConfig {
  final String uri;
  final String? icon; // For image assets
  final String? iconSvgAssets; // For SVG assets
  final IconData? iconData; // New field for FlutterAwesome or Material icons
  final bool isFlutterAwesome; // Flag to determine icon type
  final String Function(BuildContext context) title;
  final List<SidebarChildMenuConfig> children;
  final VoidCallback? onTap;
  final SidebarFunction? sidebarFunction;

  const SidebarMenuConfig({
    required this.uri,
    required this.title,
    this.icon,
    this.iconSvgAssets,
    this.iconData,
    this.isFlutterAwesome = false,
    List<SidebarChildMenuConfig>? children,
    this.onTap,
    this.sidebarFunction,
  }) : children = children ?? const [];

  // Helper constructor for FlutterAwesome icons
  const SidebarMenuConfig.withFlutterAwesome({
    required this.uri,
    required this.title,
    required this.iconData,
    List<SidebarChildMenuConfig>? children,
    this.onTap,
    this.sidebarFunction,
  })  : icon = null,
        iconSvgAssets = null,
        isFlutterAwesome = true,
        children = children ?? const [];

  // Helper constructor for Material icons
  const SidebarMenuConfig.withMaterialIcon({
    required this.uri,
    required this.title,
    required this.iconData,
    List<SidebarChildMenuConfig>? children,
    this.onTap,
    this.sidebarFunction,
  })  : icon = null,
        iconSvgAssets = null,
        isFlutterAwesome = false,
        children = children ?? const [];
}

class SidebarChildMenuConfig {
  final String uri;
  final String? icon; // For image assets
  final String? iconSvgAssets; // For SVG assets
  final IconData? iconData; // New field for FlutterAwesome or Material icons
  final bool isFlutterAwesome; // Flag to determine icon type
  final String Function(BuildContext context) title;
  final VoidCallback? onTap;
  final SidebarFunction? sidebarFunction;

  const SidebarChildMenuConfig({
    required this.uri,
    required this.title,
    this.icon,
    this.iconSvgAssets,
    this.iconData,
    this.isFlutterAwesome = false,
    this.onTap,
    this.sidebarFunction,
  });

  // Helper constructor for FlutterAwesome icons
  const SidebarChildMenuConfig.withFlutterAwesome({
    required this.uri,
    required this.title,
    required this.iconData,
    this.onTap,
    this.sidebarFunction,
  })  : icon = null,
        iconSvgAssets = null,
        isFlutterAwesome = true;

  // Helper constructor for Material icons
  const SidebarChildMenuConfig.withMaterialIcon({
    required this.uri,
    required this.title,
    required this.iconData,
    this.onTap,
    this.sidebarFunction,
  })  : icon = null,
        iconSvgAssets = null,
        isFlutterAwesome = false;
}

class Sidebar extends StatefulWidget {
  final bool autoSelectMenu;
  final String? selectedMenuUri;
  final void Function() onAccountButtonPressed;
  final void Function() onLogoutButtonPressed;
  final List<SidebarMenuConfig> sidebarConfigs;

  const Sidebar({
    Key? key,
    this.autoSelectMenu = true,
    this.selectedMenuUri,
    required this.onAccountButtonPressed,
    required this.onLogoutButtonPressed,
    required this.sidebarConfigs,
  }) : super(key: key);

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> with TickerProviderStateMixin {
  final _scrollController = ScrollController();
  late AnimationController _avatarAnimationController;
  late Animation<double> _avatarAnimation;
  late AnimationController _sparkleAnimationController;
  late Animation<double> _sparkleAnimation;
  final Map<String, bool> _expandedMenus = {};
  @override
  void initState() {
    super.initState();

    // Animation cho avatar
    _avatarAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _avatarAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _avatarAnimationController,
      curve: Curves.elasticOut,
    ));

    // Animation cho sparkle effect
    _sparkleAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _sparkleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sparkleAnimationController,
      curve: Curves.easeInOut,
    ));

    _avatarAnimationController.forward();
    _sparkleAnimationController.repeat();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final sidebarCubit = context.read<SidebarCubit>();
      sidebarCubit.getVersionAndBuild();
      sidebarCubit.readTimeFromFile(context);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _avatarAnimationController.dispose();
    _sparkleAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    final isMobile = (mediaQueryData.size.width <= kScreenWidthLg);

    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFF9A9E), // Hồng nhạt
              Color(0xFFFECFEF), // Tím hồng nhạt
              Color(0xFFFECFEF), // Tím hồng nhạt
              Color(0xFF96E6A1), // Xanh lá nhạt
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Column(
          children: [
            // Header với avatar và tên ứng dụng
            Container(
              padding: const EdgeInsets.only(top: 40, bottom: 20),
              child: Column(
                children: [
                  // Avatar với animation
                  AnimatedBuilder(
                    animation: _avatarAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _avatarAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [
                                Color(0xFFFFE082), // Vàng sáng
                                Color(0xFFFFB74D), // Cam nhạt
                                Color(0xFFFF8A65), // Cam đậm
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.transparent,
                            child: Stack(
                              children: [
                                // Icon chính
                                const Center(
                                  child: Icon(
                                    Icons.school,
                                    size: 50,
                                    color: Colors.white,
                                  ),
                                ),
                                // Sparkles decoration với animation
                                AnimatedBuilder(
                                  animation: _sparkleAnimation,
                                  builder: (context, child) {
                                    return Positioned(
                                      top: 5 + (5 * _sparkleAnimation.value),
                                      right: 10,
                                      child: Transform.rotate(
                                        angle: _sparkleAnimation.value * 6.28,
                                        child: Icon(
                                          Icons.star,
                                          size: 16,
                                          color: const Color(0xFFFFE082)
                                              .withOpacity(0.8 +
                                                  0.2 *
                                                      _sparkleAnimation.value),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                AnimatedBuilder(
                                  animation: _sparkleAnimation,
                                  builder: (context, child) {
                                    return Positioned(
                                      bottom: 8 +
                                          (3 * (1 - _sparkleAnimation.value)),
                                      left: 8,
                                      child: Transform.scale(
                                        scale:
                                            0.8 + 0.4 * _sparkleAnimation.value,
                                        child: Icon(
                                          Icons.favorite,
                                          size: 14,
                                          color: const Color(0xFFFF8A80)
                                              .withOpacity(0.7 +
                                                  0.3 *
                                                      _sparkleAnimation.value),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // Tên ứng dụng
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white.withOpacity(0.9),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      "🌟 Fun Edu 🌟",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6A4C93),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Close button cho mobile
            Visibility(
              visible: isMobile,
              child: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  child: IconButton(
                    onPressed: () {
                      if (Scaffold.of(context).isDrawerOpen) {
                        Scaffold.of(context).closeDrawer();
                      }
                    },
                    icon: const Icon(Icons.close_rounded),
                    color: const Color(0xFF6A4C93),
                    tooltip: "Đóng menu",
                  ),
                ),
              ),
            ),

            // Menu list
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: Scrollbar(
                  controller: _scrollController,
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    children: [
                      _sidebarMenuList(context),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _getTimeDeploy(),
                  const SizedBox(height: 8),
                  _buildVersionAndBuildWidget(),
                  //const SizedBox(height: 12),
                  //if (!isMobile) _collapseBtn(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _collapseBtn() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8A80), Color(0xFFFF5722)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8A80).withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: () {
          final sidebarCubit = context.read<SidebarCubit>();
          sidebarCubit.toggle();
        },
        icon: const Icon(
          Icons.menu,
          color: Colors.white,
          size: 24,
        ),
        tooltip: "Thu gọn menu",
      ),
    );
  }

  Widget _getTimeDeploy() {
    return BlocBuilder<SidebarCubit, SidebarState>(
      builder: (context, state) {
        final dateTime = state.deployTime;
        if (dateTime == null) return const SizedBox.shrink();

        String formattedDate =
            DateFormat('dd/MM/yyyy HH:mm').format(dateTime.toLocal());

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.white.withOpacity(0.8),
          ),
          child: Text(
            "📅 $formattedDate",
            style: const TextStyle(
              color: Color(0xFF6A4C93),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  Widget _buildVersionAndBuildWidget() {
    return BlocBuilder<SidebarCubit, SidebarState>(
      builder: (context, state) {
        String version = state.version ?? "";
        String buildNumber = state.buildNumber ?? "";
        if (version.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667eea).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            "🚀 v$version.$buildNumber",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  Widget _sidebarMenuList(BuildContext context) {
    var currentLocation = widget.selectedMenuUri ?? '';

    if (currentLocation.isEmpty && widget.autoSelectMenu) {
      currentLocation = GoRouter.of(context).location;
    }

    return Column(
      children: widget.sidebarConfigs.map<Widget>(
        (menu) {
          if (menu.children.isEmpty) {
            return _sidebarMenu(
              context,
              const EdgeInsets.all(default8),
              menu.uri,
              menu.icon,
              menu.iconSvgAssets,
              menu.iconData,
              menu.isFlutterAwesome,
              menu.title(context),
              menu.onTap,
              menu.sidebarFunction,
              menu.sidebarFunction?.index ?? 0,
            );
          }
          return _expandableSidebarMenu(
            context,
            const EdgeInsets.all(default8),
            menu.uri,
            menu.icon,
            menu.iconSvgAssets,
            menu.iconData,
            menu.isFlutterAwesome,
            menu.title(context),
            menu.children,
            currentLocation,
            menu.sidebarFunction?.index ?? 0,
          );
        },
      ).toList(growable: false),
    );
  }

  Widget _buildIconWidget(
    String? icon,
    String? iconSvgAsset,
    IconData? iconData,
    bool isFlutterAwesome,
    List<Color> colorPair,
    bool isSelected,
  ) {
    Widget iconChild;

    if (iconData != null) {
      if (isFlutterAwesome) {
        iconChild = FaIcon(
          iconData,
          size: 24,
          color: Colors.white,
        );
      } else {
        iconChild = Icon(
          iconData,
          size: 24,
          color: Colors.white,
        );
      }
    } else if (icon != null) {
      iconChild = Image.asset(
        icon,
        width: 24,
        height: 24,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.error, size: 24, color: Colors.white);
        },
      );
    } else if (iconSvgAsset != null) {
      iconChild = SvgPicture.asset(
        iconSvgAsset,
        width: 24,
        height: 24,
        fit: BoxFit.contain,
      );
    } else {
      iconChild = const Icon(
        Icons.star,
        size: 24,
        color: Colors.white,
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.1)
                ],
              )
            : LinearGradient(colors: colorPair),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorPair[0].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(child: iconChild),
    );
  }

  Widget _sidebarMenu(
    BuildContext context,
    EdgeInsets padding,
    String uri,
    String? icon,
    String? iconSvgAsset,
    IconData? iconData,
    bool isFlutterAwesome,
    String title,
    VoidCallback? onTap,
    SidebarFunction? sidebarFunction,
    int colorIndex,
  ) {
    // Màu sắc vui nhộn cho từng menu
    final List<List<Color>> menuColors = [
      [const Color(0xFFFF6B6B), const Color(0xFFFFE66D)], // Đỏ - Vàng
      [const Color(0xFF4ECDC4), const Color(0xFF44A08D)], // Xanh ngọc
      [const Color(0xFFFFBE0B), const Color(0xFFFB8500)], // Vàng - Cam
      [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)], // Tím
      [const Color(0xFF06FFA5), const Color(0xFF00D4AA)], // Xanh lá
      [const Color(0xFFFF8A80), const Color(0xFFFF5722)], // Hồng - Cam
    ];

    return BlocBuilder<SidebarCubit, SidebarState>(
      builder: (context, state) {
        final isCollapse = state.isCollapse;
        final isSelected = state.screenGoRoutePath?.contains(uri) ?? false;

        final colorPair = menuColors[colorIndex % menuColors.length];

        Widget iconWidget = _buildIconWidget(
          icon,
          iconSvgAsset,
          iconData,
          isFlutterAwesome,
          colorPair,
          isSelected,
        );

        return Padding(
          padding: padding,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: isSelected
                  ? LinearGradient(
                      colors: colorPair,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
              color: isSelected ? null : Colors.white.withOpacity(0.7),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? colorPair[0].withOpacity(0.4)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: isSelected ? 15 : 8,
                  offset: Offset(0, isSelected ? 6 : 3),
                ),
              ],
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  iconWidget,
                  if (!isCollapse) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF2D3748),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              onTap: () {
                if (sidebarFunction != null) {
                  final sidebarCubit = context.read<SidebarCubit>();
                  sidebarCubit.selectSidebarBy(uri);
                }

                if (onTap != null) {
                  onTap();
                } else {
                  if (GoRouter.of(context).location != uri) {
                    GoRouter.of(context).go(uri);
                  } else {
                    // Đã ở đúng màn, chỉ đóng Drawer
                    Navigator.of(context).pop();
                  }
                }
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _expandableSidebarMenu(
    BuildContext context,
    EdgeInsets padding,
    String uri,
    String? icon,
    String? iconSvgAsset,
    IconData? iconData,
    bool isFlutterAwesome,
    String title,
    List<SidebarChildMenuConfig> children,
    String currentLocation,
    int colorIndex,
  ) {
    final hasSelectedChild =
        children.any((e) => currentLocation.startsWith(e.uri));
    final List<List<Color>> menuColors = [
      [const Color(0xFFFF6B6B), const Color(0xFFFFE66D)], // Đỏ - Vàng
      [const Color(0xFF4ECDC4), const Color(0xFF44A08D)], // Xanh ngọc
      [const Color(0xFFFFBE0B), const Color(0xFFFB8500)], // Vàng - Cam
      [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)], // Tím
      [const Color(0xFF06FFA5), const Color(0xFF00D4AA)], // Xanh lá
      [const Color(0xFFFF8A80), const Color(0xFFFF5722)], // Hồng - Cam
    ];

    final colorPair = menuColors[colorIndex % menuColors.length];
    final isExpanded = _expandedMenus[uri] ?? hasSelectedChild;
    Widget iconWidget = _buildIconWidget(
      icon,
      iconSvgAsset,
      iconData,
      isFlutterAwesome,
      colorPair,
      hasSelectedChild,
    );

    return Padding(
      padding: padding,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withOpacity(0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ExpansionTile(
          key: PageStorageKey(uri), // Giữ trạng thái khi rebuild
          textColor: const Color(0xFF2D3748),
          collapsedTextColor: const Color(0xFF2D3748),
          iconColor: colorPair[0],
          collapsedIconColor: colorPair[0],
          initiallyExpanded: isExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _expandedMenus[uri] = expanded;
            });
          },
          childrenPadding:
              const EdgeInsets.only(top: 8, bottom: 8, left: 16, right: 16),
          title: Row(
            children: [
              iconWidget,
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          children: children.asMap().entries.map<Widget>((entry) {
            final idx = entry.key;
            final childMenu = entry.value;
            return _sidebarMenu(
              context,
              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              childMenu.uri,
              childMenu.icon,
              childMenu.iconSvgAssets,
              childMenu.iconData,
              childMenu.isFlutterAwesome,
              childMenu.title(context),
              childMenu.onTap,
              childMenu.sidebarFunction,
              idx + 1,
            );
          }).toList(),
        ),
      ),
    );
  }
}

// Example usage:
/*
final sidebarConfigs = [
  // Using FlutterAwesome icon
  SidebarMenuConfig.withFlutterAwesome(
    uri: '/dashboard',
    title: (context) => 'Dashboard',
    iconData: FontAwesomeIcons.chartLine,
  ),
  
  // Using Material icon
  SidebarMenuConfig.withMaterialIcon(
    uri: '/settings',
    title: (context) => 'Settings',
    iconData: Icons.settings,
  ),
  
  // Using traditional image/SVG (still supported)
  SidebarMenuConfig(
    uri: '/profile',
    title: (context) => 'Profile',
    icon: 'assets/icons/profile.png',
  ),
  
  // Mixed usage in expandable menu
  SidebarMenuConfig.withFlutterAwesome(
    uri: '/reports',
    title: (context) => 'Reports',
    iconData: FontAwesomeIcons.fileAlt,
    children: [
      SidebarChildMenuConfig.withMaterialIcon(
        uri: '/reports/sales',
        title: (context) => 'Sales Report',
        iconData: Icons.trending_up,
      ),
      SidebarChildMenuConfig.withFlutterAwesome(
        uri: '/reports/analytics',
        title: (context) => 'Analytics',
        iconData: FontAwesomeIcons.chartPie,
      ),
    ],
  ),
];
*/