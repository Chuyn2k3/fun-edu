import 'dart:io';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';

enum FileType { image, video, unknown }

extension FileExtension on File {
  static const kilobyteUnit = 1024;
  static const megabyteUnit = 1024 * 1024;
  static const gigabyteUnit = 1024 * 1024 * 1024;

  FileType get type {
    final mimeType = lookupMimeType(path);

    if (mimeType != null) {
      if (mimeType.contains('.jpg') || mimeType.contains('.png')) {
        return FileType.image;
      } else if (mimeType.contains('.mp4')) {
        return FileType.video;
      }
    }

    return FileType.unknown;
  }

  String get name {
    final fileName = path.split('/').last;
    if (fileName.length > 25) {
      return fileName.substring(fileName.length - 25, fileName.length);
    } else {
      return fileName;
    }
  }

  String get sizeInString {
    NumberFormat numberFormat = NumberFormat("0.00");
    final bytes = lengthSync();

    if (bytes > gigabyteUnit) {
      return "${numberFormat.format(sizeInGb)}GB";
    }

    if (bytes > megabyteUnit) {
      return "${numberFormat.format(sizeInMb)}MB";
    }

    if (bytes > kilobyteUnit) {
      return "${numberFormat.format(sizeInKb)}KB";
    }

    return "${bytes}Byte";
  }

  double get sizeInGb {
    return lengthSync() / gigabyteUnit;
  }

  double get sizeInMb {
    return lengthSync() / megabyteUnit;
  }

  double get sizeInKb {
    return lengthSync() / kilobyteUnit;
  }
}
