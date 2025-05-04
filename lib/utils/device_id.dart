// import 'dart:io';
// import 'package:device_info_plus/device_info_plus.dart';

// class DeviceIdService {
//   static Future<String?> getDeviceId() async {
//     final deviceInfo = DeviceInfoPlugin();

//     if (Platform.isAndroid) {
//       final androidInfo = await deviceInfo.androidInfo;
//       return androidInfo.isPhysicalDevice
//           ? androidInfo.id
//           : null; // Tùy phiên bản Android
//     } else if (Platform.isIOS) {
//       final iosInfo = await deviceInfo.iosInfo;
//       return iosInfo.identifierForVendor;
//     }
//     return null;
//   }
// }
