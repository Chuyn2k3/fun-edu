// import 'dart:io';
// import 'dart:typed_data';

// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart';
// import 'package:flutter_app/service/gen/assets.gen.dart';
// import 'package:flutter_app/modules/upload/model/file_upload_model.dart';
// import 'package:flutter_app/utils/file_extension.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:video_thumbnail/video_thumbnail.dart';

// extension ConvertFileToUploadFile on File {
//   Future<UploadFile> toUploadFile() async {
//     switch (type) {
//       case FileType.image:
//         return UploadFile(
//           file: this,
//           thumnaill: Image.file(
//             this,
//             width: 32,
//             height: 32,
//           ),
//           fileName: name,
//           fileSize: sizeInString,
//         );
//       case FileType.video:
//         final uint8list = await VideoThumbnail.thumbnailData(
//           video: path,
//           imageFormat: ImageFormat.JPEG,
//           maxWidth: 32,
//           quality: 100,
//         );
//         return UploadFile(
//           file: this,
//           thumnaill: Stack(
//             children: [
//               Image.memory(
//                 uint8list ?? Uint8List(0),
//                 width: 32,
//                 height: 32,
//               ),
//               Positioned.fill(
//                 child: Align(
//                   alignment: Alignment.center,
//                   child: SvgPicture.asset(
//                     Assets.icon.iconVideo,
//                     width: 16,
//                     height: 16,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           fileName: name,
//           fileSize: sizeInString,
//         );

//       case FileType.unknown:
//         return UploadFile(
//           file: this,
//           thumnaill: SvgPicture.asset(Assets.icon.iconVideo),
//           fileName: name,
//           fileSize: sizeInString,
//         );
//     }
//   }
// }
