// import 'package:flutter/material.dart';
// import 'package:fun_edu/constant/dimens.dart';
// import 'package:fun_edu/core/theme/app_themes.dart';
// import 'package:fun_edu/gen/assets.gen.dart';

// class ResponsiveAppBarTitle extends StatelessWidget {
//   final Color light = const Color(0xFFF7F8FC);
//   final Color lightGray = const Color(0xFFA4A6B3);
//   final Color dark = const Color(0xFF363740);
//   final Color active = const Color(0xFF3C19C0);

//   const ResponsiveAppBarTitle({
//     Key? key,
//   }) : super(key: key);

//   void changeLanguage(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setState) {
//             return changeLanguageDialog(context, "vi");
//           },
//         );
//       },
//     );
//   }

//   Widget changeLanguageDialog(BuildContext context, String languageCode) {
//     return AlertDialog(
//       title: const Text("Đổi ngôn ngữ"),
//       content: StatefulBuilder(builder: (context, setState) {
//         return Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             RadioListTile(
//               title: const Text(
//                 "Tiếng việt",
//                 style: TextStyle(
//                   color: Colors.black,
//                 ),
//               ),
//               value: "vi",
//               groupValue: languageCode,
//               onChanged: (value) {
//                 setState(() {
//                   languageCode = "vi";
//                 });
//               },
//             ),
//             RadioListTile(
//               title: const Text(
//                 "Tiếng anh",
//                 style: TextStyle(
//                   color: Colors.black,
//                 ),
//               ),
//               value: "en",
//               groupValue: languageCode,
//               onChanged: (value) {
//                 setState(() {
//                   languageCode = "en";
//                 });
//               },
//             ),
//           ],
//         );
//       }),
//       actions: <Widget>[
//         TextButton(
//           child: const Text("Xác nhận"),
//           onPressed: () {
//             Navigator.of(context).pop();
//           },
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final mediaQueryData = MediaQuery.of(context);

//     return MouseRegion(
//       cursor: SystemMouseCursors.click,
//       child: GestureDetector(
//         onTap: () {},
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // Visibility(
//             //   visible: (mediaQueryData.size.width > kScreenWidthSm),
//             //   child: Container(
//             //     padding: const EdgeInsets.only(right: kDefaultPadding * 0.7),
//             //     height: 40.0,
//             //     child: Assets.images.logoIbmeLab.image(fit: BoxFit.fitWidth),
//             //   ),
//             // ),
//             Expanded(
//               child: Text(
//                 "FUN EDU",
//                 overflow: TextOverflow.ellipsis,
//                 maxLines: 1,
//               ),
//             ),
//             _buildSetting(),
//             const SizedBox(width: 1),
//             _buildNotification(context),
//             Container(
//               width: 1,
//               height: 22,
//               color: lightGray,
//             ),
//             const SizedBox(
//               width: 16,
//             ),
//             _buildUserProfileWidget(context, mediaQueryData)
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildUserProfileWidget(
//     BuildContext context,
//     MediaQueryData mediaQueryData,
//     //ProfileUserState state,
//   ) {
//     return GestureDetector(
//       onTap: () {
//         _redirectToProfileKeyCloak(context);
//         // if (GoRouter.of(context).location != RouteUri.myProfile) {
//         //   GoRouter.of(context).push(RouteUri.myProfile);
//         // }
//       },
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const SizedBox(width: 2),
//           _buildUserAvatar(),
//           Flexible(
//             child: _buildUserName(mediaQueryData),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSetting() {
//     return PopupMenuButton(
//       tooltip: "Setting",
//       icon: const Icon(
//         Icons.settings,
//       ),
//       itemBuilder: (BuildContext context) => <PopupMenuEntry<Widget>>[
//         _buildPopupMenuItem(
//           context,
//           iconData: Icons.password,
//           label: "Đổi mật khẩu",
//           onTap: () {
//             // _changePassword(context);
//           },
//         ),
//         _buildPopupMenuItem(
//           context,
//           iconData: Icons.flutter_dash,
//           label: "Đổi logo",
//           onTap: () {
//             //_changeBrandSetting(context);
//           },
//         ),
//       ],
//     );
//   }

//   Widget _buildNotification(BuildContext context) {
//     return Stack(
//       children: [
//         IconButton(
//           icon: const Icon(
//             Icons.notifications,
//             color: Colors.white,
//           ),
//           onPressed: () {
//             //_onHandleClickNotification(context);
//           },
//         ),
//         Positioned(
//           top: 7,
//           right: 7,
//           child: Container(
//             width: 12,
//             height: 12,
//             padding: const EdgeInsets.all(4),
//             decoration: BoxDecoration(
//               color: active,
//               borderRadius: BorderRadius.circular(30),
//               border: Border.all(
//                 color: light,
//                 width: 2,
//               ),
//             ),
//           ),
//         )
//       ],
//     );
//   }

//   Widget _buildUserName(MediaQueryData mediaQueryData) {
//     return Visibility(
//       visible: (mediaQueryData.size.width > kScreenWidthSm),
//       child: Container(
//         margin: const EdgeInsets.only(left: 6),
//         child: const Text(
//           "Chuyen",
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 16,
//             fontWeight: FontWeight.normal,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildUserAvatar() {
//     return Container(
//       height: 40,
//       width: 40,
//       decoration: BoxDecoration(
//         color: active.withOpacity(.5),
//         borderRadius: BorderRadius.circular(30),
//       ),
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(30),
//         ),
//         padding: const EdgeInsets.all(2),
//         margin: const EdgeInsets.all(2),
//         child: CircleAvatar(
//           backgroundColor: light,
//           child: Icon(
//             Icons.person_outline,
//             color: dark,
//           ),
//         ),
//       ),
//     );
//   }

//   PopupMenuItem<Widget> _buildPopupMenuItem(
//     BuildContext context, {
//     IconData? iconData,
//     Widget? customIcon,
//     required String label,
//     required VoidCallback? onTap,
//   }) {
//     return PopupMenuItem<Widget>(
//       onTap: onTap,
//       child: Row(
//         children: [
//           customIcon ??
//               Icon(
//                 iconData,
//                 size: 15,
//                 color: AppThemes.of(context).appColors.neutral.shade800,
//               ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(
//               label,
//               style: TextStyle(
//                 fontSize: 15,
//                 color: AppThemes.of(context).appColors.neutral.shade800,
//               ),
//             ),
//           )
//         ],
//       ),
//     );
//   }

//   // void _onHandleClickNotification(BuildContext context) {
//   //   AppRouteHandle.goToNotificationList(context);
//   // }

//   // void _changeBrandSetting(BuildContext context) {
//   //   SettingDashboardLogoPopup.show(context);
//   // }
//   //
//   // void _changePassword(BuildContext context) {
//   //   _redirectToProfileKeyCloak(context);
//   //   // showDialog(
//   //   //   context: context,
//   //   //   builder: (context) {
//   //   //     return const ChangePassWidget();
//   //   //   },
//   //   // );
//   // }

//   void _redirectToProfileKeyCloak(BuildContext context) {
//     // launchUrlString(
//     //     "${BuildConstants.keyCloakDomainUrl}/realms/selex/account/");
//   }
// }
///////////////////////////////////////////////

// import 'package:flutter/material.dart';
// import 'package:fun_edu/constant/dimens.dart';
// import 'package:fun_edu/core/theme/app_themes.dart';
// import 'package:fun_edu/gen/assets.gen.dart';

// class ResponsiveAppBarTitle extends StatefulWidget {
//   const ResponsiveAppBarTitle({
//     Key? key,
//   }) : super(key: key);

//   @override
//   State<ResponsiveAppBarTitle> createState() => _ResponsiveAppBarTitleState();
// }

// class _ResponsiveAppBarTitleState extends State<ResponsiveAppBarTitle>
//     with TickerProviderStateMixin {
//   late AnimationController _heartController;
//   late AnimationController _notificationController;
//   int notificationCount = 3;

//   // Child-friendly colors
//   final Color primaryPink = const Color(0xFFFF6B9D);
//   final Color primaryPurple = const Color(0xFF9B59B6);
//   final Color primaryBlue = const Color(0xFF3498DB);
//   final Color brightYellow = const Color(0xFFFFD93D);
//   final Color brightOrange = const Color(0xFFFF8C42);
//   final Color brightGreen = const Color(0xFF2ECC71);
//   final Color brightRed = const Color(0xFFE74C3C);

//   @override
//   void initState() {
//     super.initState();
//     _heartController = AnimationController(
//       duration: const Duration(milliseconds: 1000),
//       vsync: this,
//     )..repeat(reverse: true);

//     _notificationController = AnimationController(
//       duration: const Duration(milliseconds: 500),
//       vsync: this,
//     )..repeat(reverse: true);
//   }

//   @override
//   void dispose() {
//     _heartController.dispose();
//     _notificationController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final mediaQueryData = MediaQuery.of(context);

//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.centerLeft,
//           end: Alignment.centerRight,
//           colors: [primaryPink, primaryPurple, primaryBlue],
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: primaryPurple.withOpacity(0.3),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             child: Row(
//               children: [
//                 // Logo and Title Section
//                 Expanded(
//                   child: Row(
//                     children: [
//                       // Star Logo
//                       Container(
//                         width: 40,
//                         height: 40,
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(20),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.1),
//                               blurRadius: 8,
//                               offset: const Offset(0, 2),
//                             ),
//                           ],
//                         ),
//                         child: Icon(
//                           Icons.star,
//                           color: brightYellow,
//                           size: 24,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       // Title
//                       const Text(
//                         "FUN EDU",
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                           letterSpacing: 1.2,
//                           shadows: [
//                             Shadow(
//                               offset: Offset(1, 1),
//                               blurRadius: 3,
//                               color: Colors.black26,
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       // Animated Heart
//                       AnimatedBuilder(
//                         animation: _heartController,
//                         builder: (context, child) {
//                           return Transform.scale(
//                             scale: 0.8 + (_heartController.value * 0.4),
//                             child: Icon(
//                               Icons.favorite,
//                               color: brightRed.withOpacity(0.8),
//                               size: 20,
//                             ),
//                           );
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//                 // Right Side Actions
//                 Row(
//                   children: [
//                     _buildSetting(),
//                     const SizedBox(width: 8),
//                     _buildNotification(context),
//                     Container(
//                       width: 1,
//                       height: 24,
//                       margin: const EdgeInsets.symmetric(horizontal: 12),
//                       color: Colors.white.withOpacity(0.3),
//                     ),
//                     _buildUserProfileWidget(context, mediaQueryData),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           // Decorative bottom border
//           Container(
//             height: 4,
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [brightYellow, primaryPink, primaryPurple],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildUserProfileWidget(
//     BuildContext context,
//     MediaQueryData mediaQueryData,
//   ) {
//     return GestureDetector(
//       onTap: () {
//         _redirectToProfileKeyCloak(context);
//       },
//       child: Container(
//         padding: const EdgeInsets.all(2),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [brightYellow, brightOrange],
//           ),
//           borderRadius: BorderRadius.circular(25),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.2),
//               blurRadius: 8,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Stack(
//           children: [
//             Container(
//               width: 40,
//               height: 40,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Icon(
//                 Icons.person,
//                 color: primaryPurple,
//                 size: 24,
//               ),
//             ),
//             // Online status indicator
//             Positioned(
//               bottom: 0,
//               right: 0,
//               child: Container(
//                 width: 12,
//                 height: 12,
//                 decoration: BoxDecoration(
//                   color: brightGreen,
//                   borderRadius: BorderRadius.circular(6),
//                   border: Border.all(color: Colors.white, width: 2),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSetting() {
//     return PopupMenuButton(
//       tooltip: "Cài đặt",
//       icon: Container(
//         width: 40,
//         height: 40,
//         decoration: BoxDecoration(
//           color: Colors.white.withOpacity(0.2),
//           borderRadius: BorderRadius.circular(20),
//         ),
//         child: const Icon(
//           Icons.settings,
//           color: Colors.white,
//           size: 20,
//         ),
//       ),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       color: Colors.white,
//       elevation: 8,
//       itemBuilder: (BuildContext context) => <PopupMenuEntry<Widget>>[
//         _buildPopupMenuItem(
//           context,
//           iconData: Icons.lock,
//           iconColor: primaryBlue,
//           backgroundColor: const Color(0xFFE3F2FD),
//           label: "Đổi mật khẩu",
//           onTap: () {
//             // Handle password change
//           },
//         ),
//         _buildPopupMenuItem(
//           context,
//           iconData: Icons.palette,
//           iconColor: brightGreen,
//           backgroundColor: const Color(0xFFE8F5E8),
//           label: "Đổi giao diện",
//           onTap: () {
//             // Handle theme change
//           },
//         ),
//       ],
//     );
//   }

//   Widget _buildNotification(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           notificationCount = 0;
//         });
//       },
//       child: Container(
//         width: 40,
//         height: 40,
//         decoration: BoxDecoration(
//           color: Colors.white.withOpacity(0.2),
//           borderRadius: BorderRadius.circular(20),
//         ),
//         child: Stack(
//           children: [
//             const Center(
//               child: Icon(
//                 Icons.notifications,
//                 color: Colors.white,
//                 size: 20,
//               ),
//             ),
//             if (notificationCount > 0)
//               Positioned(
//                 top: 6,
//                 right: 6,
//                 child: AnimatedBuilder(
//                   animation: _notificationController,
//                   builder: (context, child) {
//                     return Transform.translate(
//                       offset: Offset(0, _notificationController.value * 2),
//                       child: Container(
//                         width: 16,
//                         height: 16,
//                         decoration: BoxDecoration(
//                           color: brightRed,
//                           borderRadius: BorderRadius.circular(8),
//                           border: Border.all(color: Colors.white, width: 2),
//                         ),
//                         child: Center(
//                           child: Text(
//                             notificationCount.toString(),
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 10,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   PopupMenuItem<Widget> _buildPopupMenuItem(
//     BuildContext context, {
//     required IconData iconData,
//     required Color iconColor,
//     required Color backgroundColor,
//     required String label,
//     required VoidCallback? onTap,
//   }) {
//     return PopupMenuItem<Widget>(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
//         child: Row(
//           children: [
//             Container(
//               width: 32,
//               height: 32,
//               decoration: BoxDecoration(
//                 color: backgroundColor,
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Icon(
//                 iconData,
//                 size: 16,
//                 color: iconColor,
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Text(
//                 label,
//                 style: TextStyle(
//                   fontSize: 15,
//                   fontWeight: FontWeight.w500,
//                   color: Colors.grey[800],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _redirectToProfileKeyCloak(BuildContext context) {
//     // Handle profile navigation
//   }
// }
///////////////////////
import 'package:flutter/material.dart';
import 'package:fun_edu/constant/dimens.dart';
import 'package:fun_edu/core/theme/app_themes.dart';
import 'package:fun_edu/gen/assets.gen.dart';

class ResponsiveAppBarTitle extends StatefulWidget {
  const ResponsiveAppBarTitle({
    Key? key,
  }) : super(key: key);

  @override
  State<ResponsiveAppBarTitle> createState() => _ResponsiveAppBarTitleState();
}

class _ResponsiveAppBarTitleState extends State<ResponsiveAppBarTitle>
    with TickerProviderStateMixin {
  late AnimationController _heartController;
  late AnimationController _notificationController;
  late AnimationController _characterController;
  int notificationCount = 3;
  int _selectedCharacter = 0;
  final List<Map<String, dynamic>> _characters = [
    {
      'icon': Icons.emoji_emotions,
      'color': const Color(0xFFFFD93D),
      'name': 'Vui vẻ'
    },
    {'icon': Icons.pets, 'color': const Color(0xFFFF8C42), 'name': 'Thú cưng'},
    {
      'icon': Icons.rocket_launch,
      'color': const Color(0xFF3498DB),
      'name': 'Phi hành gia'
    },
    {
      'icon': Icons.emoji_nature,
      'color': const Color(0xFF2ECC71),
      'name': 'Thiên nhiên'
    },
  ];

  // Child-friendly colors
  final Color primaryPink = const Color(0xFFFF6B9D);
  final Color primaryPurple = const Color(0xFF9B59B6);
  final Color primaryBlue = const Color(0xFF3498DB);
  final Color brightYellow = const Color(0xFFFFD93D);
  final Color brightOrange = const Color(0xFFFF8C42);
  final Color brightGreen = const Color(0xFF2ECC71);
  final Color brightRed = const Color(0xFFE74C3C);

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _notificationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);

    _characterController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _heartController.dispose();
    _notificationController.dispose();
    _characterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [primaryPink, primaryPurple, primaryBlue],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Logo and Title Section
                Expanded(
                  child: Row(
                    children: [
                      // Star Logo
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.star,
                          color: brightYellow,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Title
                      const Text(
                        "FUN EDU",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 3,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Animated Heart
                      AnimatedBuilder(
                        animation: _heartController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 0.8 + (_heartController.value * 0.4),
                            child: Icon(
                              Icons.favorite,
                              color: brightRed.withOpacity(0.8),
                              size: 20,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Right Side Actions
                Row(
                  children: [
                    _buildSetting(),
                    const SizedBox(width: 8),
                    _buildNotification(context),
                    Container(
                      width: 1,
                      height: 24,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: Colors.white.withOpacity(0.3),
                    ),
                    _buildCharacterSelector(context),
                  ],
                ),
              ],
            ),
          ),
          // Decorative bottom border
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [brightYellow, primaryPink, primaryPurple],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Thay thế _buildUserProfileWidget bằng _buildCharacterSelector
  Widget _buildCharacterSelector(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showCharacterSelectionDialog(context);
      },
      child: AnimatedBuilder(
        animation: _characterController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _characterController.value * 3),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _characters[_selectedCharacter]['color'],
                    _characters[_selectedCharacter]['color'].withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _characters[_selectedCharacter]['icon'],
                  color: _characters[_selectedCharacter]['color'],
                  size: 24,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCharacterSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Chọn nhân vật của bạn",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF9B59B6),
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _characters.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCharacter = index;
                    });
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _characters[index]['color'].withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _characters[index]['color'],
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _characters[index]['color'].withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _characters[index]['icon'],
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _characters[index]['name'],
                          style: TextStyle(
                            color: _characters[index]['color'],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      },
    );
  }

  Widget _buildSetting() {
    return PopupMenuButton(
      tooltip: "Cài đặt",
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.settings,
          color: Colors.white,
          size: 20,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      elevation: 8,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<Widget>>[
        // Thay đổi tùy chọn đổi mật khẩu thành chế độ chơi
        _buildPopupMenuItem(
          context,
          iconData: Icons.sports_esports,
          iconColor: primaryPink,
          backgroundColor: const Color(0xFFFCE4EC),
          label: "Chế độ chơi",
          onTap: () {
            // Xử lý chuyển chế độ chơi
          },
        ),
        _buildPopupMenuItem(
          context,
          iconData: Icons.palette,
          iconColor: brightGreen,
          backgroundColor: const Color(0xFFE8F5E8),
          label: "Đổi giao diện",
          onTap: () {
            // Xử lý đổi giao diện
          },
        ),
        // Thêm tùy chọn mới: Âm thanh
        _buildPopupMenuItem(
          context,
          iconData: Icons.music_note,
          iconColor: brightYellow,
          backgroundColor: const Color(0xFFFFFDE7),
          label: "Âm nhạc",
          onTap: () {
            // Xử lý bật/tắt âm nhạc
          },
        ),
      ],
    );
  }

  Widget _buildNotification(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          notificationCount = 0;
        });
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            const Center(
              child: Icon(
                Icons.notifications,
                color: Colors.white,
                size: 20,
              ),
            ),
            if (notificationCount > 0)
              Positioned(
                top: 6,
                right: 6,
                child: AnimatedBuilder(
                  animation: _notificationController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _notificationController.value * 2),
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: brightRed,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            notificationCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<Widget> _buildPopupMenuItem(
    BuildContext context, {
    required IconData iconData,
    required Color iconColor,
    required Color backgroundColor,
    required String label,
    required VoidCallback? onTap,
  }) {
    return PopupMenuItem<Widget>(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                iconData,
                size: 16,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
