// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// class DashboardScreen extends StatelessWidget {
//   const DashboardScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return BlocConsumer<ProfileUserCubit, ProfileUserState>(
//       builder: (context, state) {
//         final isLazada = (state is ProfileUserLoadedState)
//             ? (state).user.login == "admin_lazada"
//             : false;
//         final isGrab = (state is ProfileUserLoadedState)
//             ? (state).user.login == "admin_grab"
//             : false;
//         return PortalMasterLayout(
//             body: isLazada
//                 ? const AssetGenImage('assets/images/lazada.png')
//                     .image(fit: BoxFit.fitWidth, height: double.maxFinite)
//                 : isGrab
//                     ? const AssetGenImage('assets/images/grab.png')
//                         .image(fit: BoxFit.fitWidth, height: double.maxFinite)
//                     : Assets.images.heroCamel
//                         .image(fit: BoxFit.fill, height: double.maxFinite));
//       },
//       listener: (BuildContext context, ProfileUserState state) {
//         if (state is ProfileUserLoadedState) {
//           final userPermission = state.user.permissions ?? [];
//           if (userPermission.isNotEmpty) {
//             final userPerCubit = context.read<CurrentUserPermissionCubit>();
//             userPerCubit.setUserPermissions(userPermission);
//           }
//         }
//       },
//     );
//   }
// }
