// ignore_for_file: unnecessary_null_comparison, constant_identifier_names

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension EmailValidator on String {
  bool isValidEmail() {
    return RegExp(
            r"^((([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+(\.([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+)*)|((\x22)((((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(([\x01-\x08\x0b\x0c\x0e-\x1f\x7f]|\x21|[\x23-\x5b]|[\x5d-\x7e]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(\\([\x01-\x09\x0b\x0c\x0d-\x7f]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]))))*(((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(\x22)))@((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))$")
        .hasMatch(this);
  }
}

extension GetTime on String? {
  String formatTime({String format = "HH:mm dd-MM-yyyy"}) {
    if (this == null) return "_";
    var dateValue =
        DateFormat("yyyy-MM-ddTHH:mm:ssZ").parseUTC(this!).toLocal();
    String formattedDate = DateFormat(format).format(dateValue);
    return formattedDate;
  }

  String formatTimeGMT({String format = "HH:mm dd-MM-yyyy"}) {
    if (this == null) return "_";
    var dateValue =
        DateFormat("yyyy-MM-ddTHH:mm:ssZ").parseUTC(this!);
    String formattedDate = DateFormat(format).format(dateValue);
    return formattedDate;
  }

  String formatTimeDay({String format = "dd-MM-yyyy"}) {
    if (this == null) return "";
    var dateValue =
        DateFormat("yyyy-MM-ddTHH:mm:ssZ").parseUTC(this!).toLocal();
    String formattedDate = DateFormat(format).format(dateValue);
    return formattedDate;
  }

  String formatDateTimeZone({String format = "yyyy-MM-dd"}) {
    if (this == null) return "";
    var dateValue =
        DateFormat("yyyy-MM-ddTHH:mm:ssZ").parseUTC(this!).toLocal();
    String formattedDate = DateFormat(format).format(dateValue);

    return formattedDate;
  }

  TimeOfDay toTimeOfDay({String format = "HH:mm"}) {
    if (this == null) return TimeOfDay.now();
    final dateTime = DateFormat(format).parse(this!);
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }

  String formatTimeStamp12H() {
    if (this == null) return "";
    String dateTime = '$this' 'T12:00:00Z';
    return dateTime.toString();
  }

  String timeAgo(DateTime timeObserve, [String format = "HH:mm dd-MM-yyyy"]) {
    Duration diff = timeObserve.difference(DateTime.parse(this!));
    if (diff.inDays > 365) {
      final value = (diff.inDays / 365).floor();
      return "$value y";
    }
    if (diff.inDays > 30) {
      final value = (diff.inDays / 30).floor();
      return "$value m";
    }
    if (diff.inDays > 7) {
      final value = (diff.inDays / 7).floor();
      return "$value w";
    }
    if (diff.inDays > 0) {
      final value = diff.inDays;
      return "$value d";
    }
    if (diff.inHours > 0) {
      final value = diff.inHours;
      return "$value h";
    }
    if (diff.inMinutes > 0) {
      final value = diff.inMinutes;
      return "$value p";
    }
    return "";
  }

  String timeAgo1(DateTime timeObserve, [String format = "HH:mm dd-MM-yyyy"]) {
    Duration diff = timeObserve.difference(DateFormat(format).parse(this!));
    if (diff.inDays > 365) {
      final value = (diff.inDays / 365).floor();
      return "$value năm trước";
    }
    if (diff.inDays > 30) {
      final value = (diff.inDays / 30).floor();
      return "$value tháng trước";
    }
    if (diff.inDays > 7) {
      final value = (diff.inDays / 7).floor();
      return "$value tuần trước";
    }
    if (diff.inDays > 0) {
      final value = diff.inDays;
      return "$value ngày trước";
    }
    if (diff.inHours > 0) {
      final value = diff.inHours;
      return "$value giờ trước";
    }
    if (diff.inMinutes > 0) {
      final value = diff.inMinutes;
      return "$value phút trước";
    }
    return "Vừa truy nhập";
  }
}

extension ConfigTime on TimeOfDay? {
  String formatTimePicker() {
    if (this == null) return "";
    String formattedTime = '';
    if (this!.minute < 10) {
      formattedTime = '${this!.hour}:0${this!.minute}';
    } else if (this!.hour < 10) {
      formattedTime = '0${this!.hour}:${this!.minute}';
    } else if (this!.hour < 10 && this!.minute < 10) {
    } else {
      formattedTime = '${this!.hour}:${this!.minute}';
    }
    return formattedTime;
  }

  String formatHousMinute() {
    if (this == null) {
      return '';
    } else {
      final now = DateTime.now();
      final dateTime =
          DateTime(now.year, now.month, now.day, this!.hour, this!.minute);
      final formatter = DateFormat('HH:mm');
      return formatter.format(dateTime);
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

extension StringOptionalExtension on String? {
  String display() {
    return this ?? "_";
  }

  String hashcode() {
    return this ?? "";
  }
}

extension IntExtension on int {
  String toReadableDateDdMmYyyy() {
    final date = DateTime.fromMillisecondsSinceEpoch(this);
    return DateFormat("dd-MM-yyyy").format(date);
  }
}

extension PhoneValidtor on String {
  bool isValidPhone() {
    return RegExp(r'(^(?:[+0]9)?[0-9]{10}$)').hasMatch(this);
  }
}

extension NumberValidtor on String {
  bool isValidNumber(String s) {
    if (s == null) {
      return false;
    }
    return double.tryParse(s) != null;
  }
}

extension FormatTime on int {
  String convertTime({String format = 'yyyy-MM-dd'}) {
    var date = DateTime.fromMillisecondsSinceEpoch(this);
    return DateFormat(format).format(date);
  }
}

Color getColor(String? color) {
  switch (color) {
    //add more color as your wish
    case "red":
      return Colors.red;
    case "blue":
      return Colors.blue;
    case "yellow":
      return Colors.yellow;
    case "orange":
      return Colors.orange;
    case "green":
      return Colors.green;
    default:
      return Colors.transparent;
  }
}

extension DateTimeString on DateTime {
  String formatString({String format = "yyyy-MM-dd"}) {
    String formattedDate = DateFormat(format).format(this);
    return formattedDate;
  }

  String formatTimeStamp() {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd");
    return '${dateFormat.format(this)}T00:00:00Z';
  }

  String formatStartTimeStampGMT(
      {String format = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\''}) {
    return DateTime.parse(formatTimeStamp())
        .subtract(DateTime.now().timeZoneOffset)
        .formatString(format: format);
  }

  String formatTimeStampEndDay() {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd");
    return '${dateFormat.format(this)}T24:00:00Z';
  }

  String formatEndTimeStampGMT(
      {String format = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\''}) {
    return DateTime.parse(formatTimeStampEndDay())
        .subtract(DateTime.now().timeZoneOffset)
        .formatString(format: format);
  }

  String get formattedDateTimeISO8601 =>
      "${DateFormat("yyyy-MM-ddTHH:mm:ss").format(this)}.000Z";

  bool isSameDay(DateTime date2) {
    return year == date2.year && month == date2.month && day == date2.day;
  }
}

extension ListExt<E> on List<E> {
  void forEachIndexed(void Function(int index, E element) action) {
    for (var index = 0; index < length; index++) {
      action(index, this[index]);
    }
  }
}

extension ConvertSizeFile on String {
  String getFileSizeString() {
    int bytes = 0;
    int decimals = 0;
    bytes = int.parse(this);
    const suffixes = ["b", "kb", "mb", "gb", "tb"];
    if (bytes == 0) return '0${suffixes[0]}';
    var i = (log(bytes) / log(1024)).floor();
    return ((bytes / pow(1024, i)).toStringAsFixed(decimals)) + suffixes[i];
  }
}

extension GetCurrency on double? {
  String formatCurrency() {
    var format = NumberFormat.currency(locale: "vi_VN").format(this);
    return format;
  }
}

extension DoubleX on double? {
  String formatPercent() {
    return NumberFormat.percentPattern().format(this);
  }

  String formatDisplayDouble() {
    final formatter = NumberFormat.decimalPatternDigits();
    formatter.maximumFractionDigits = 2;

    return formatter.format(this);
  }
}

extension IntX on int? {
  String formatPercent() {
    return NumberFormat.percentPattern().format(this);
  }

  String formatDisplayDouble() {
    final formatter = NumberFormat.decimalPatternDigits();
    formatter.maximumFractionDigits = 2;
    return formatter.format(this);
  }
}

extension GetActive on bool? {
  String toActiveString() {
    switch (this) {
      case true:
        return 'Đang hoạt động';
      case false:
        return 'Ngừng hoạt động';
      default:
        return '-';
    }
  }
}

extension ToStringDateTime on String? {
  String toFunctionRole() {
    if (this == null) {
      return '';
    } else {
      final DateTime dob = DateTime.parse(this!);
      return '${dob.day}/${dob.month}/${dob.year}';
    }
  }
}

extension CamelCasetoSnakeCase on String {
  String camelCaseToSnakeCase() {
    final exp = RegExp('(?<=[a-z])[A-Z]');
    return replaceAllMapped(exp, (m) => '_${m.group(0)}').toLowerCase();
  }
}

extension CustomIntExtension on int {
  String formatToDecimal() {
    double result = (this / 1000).toDouble();
    if (result < 0) return "0";
    return result.toStringAsFixed(2);
  }
}

extension GetSize on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);
}
