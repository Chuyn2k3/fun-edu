import 'package:flutter/material.dart';
import 'package:fun_edu/core/colors/app_colors.dart';
import 'package:fun_edu/model/model_nums.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kBgColor = Color.fromARGB(255, 216, 234, 247);
const Color hBlueColor = Color.fromARGB(255, 61, 117, 212);
const Color kDarkGreyColor = Color(0xFF727C9B);
const Color kGreenColor = Color.fromARGB(255, 83, 193, 87);
const Color kBlueColor = Color(0xFF07062e);
const Color logout = Colors.black54;
const Color hYellowColor = Color.fromARGB(255, 233, 215, 45);
List<String> desc = [
  'Cùng nhau học tập',
  'Làm bài kiểm tra',
  'Giải toán thông minh',
  'Vừa học vừa chơichơi'
];

// ignore_for_file: prefer_function_declarations_over_variables

const defaultLat = 21.009851406870357;
const defaultLng = 105.82004548309281;
const defaultPadding = 16.0;
const default32 = 32.0;
const default24 = 24.0;
const default16 = 16.0;
const default8 = 8.0;
const default4 = 4.0;
const double fixedWidthColumnDefault = 150;
const double fixedWidthColumnTableSmall = 90;
const double fixedWidthColumnTableMedium = 140;
const double fixedWidthColumnTableLarge = 190;
const double fixedWidthColumnTableExtraLarge = 300;
const double fixedWidthColumnDefaultMobile = 200;
const int maxExportExcel = 5000;

const themeColor1 = Color(0xFF81D4FA);
const themeColor3 = Color(0xFF64B5F6);
const themeColor2 = Color(0xFFE3F2FD);
const themeColor = Color(0xFFBBDEFB);
const Color bluebland = Color(0XFF51CDF5);
const Color bluedark = Color(0XFF0D47A1);
const Color bluedark1 = Color(0XFF0F156D);
const Color redbland = Color(0XFFFF6E40);
const Color red = Color(0XFFEF5350);
const Color redColor = Color(0XFFF43F5E);
const Color lightRedColor = Color(0XFFFF3D00);
const Color grayColor = Color.fromARGB(255, 159, 164, 166);
const Color lightGrayColor = Color(0XFFEEEEEE);
const Color blackColor = Color(0XFF212121);
const Color lightblue = Color(0XFF64B5F6);
const Color orange = Color(0XFFFFA000);
const Color orangeyellow = Color(0XFFFFFF00);
const Color lightorange = Color(0XFFFFECB3);
const Color lightorange1 = Color(0XFFFFCA28);
const Color green = Color(0XFF22C55E);
const Color lightgreen = Color(0XFFCCFF90);
const Color violet = Color(0XFFE040FB);
const Color lightviolet = Color(0XFFEA80FC);
const Color lemonyellow = Color(0XFFC0CA33);
const Color lightlemonyellow = Color(0XFFE6EE9C);
const Color powderblue = Color(0XFF00B8D4);
const Color lightpowderblue = Color(0XFF18FFFF);
const Color grey1 = Color(0XFF033544);
const Color grey = Color(0XFF033544);

const styleHintText = TextStyle(
    color: grey1,
    fontWeight: FontWeight.w400,
    fontSize: 15,
    fontFamily: 'Inter',
    decoration: TextDecoration.none);
const styleHintText1 = TextStyle(
    color: Color.fromARGB(255, 159, 164, 166),
    fontWeight: FontWeight.w400,
    fontSize: 15,
    fontFamily: 'Inter',
    decoration: TextDecoration.none);
const styleHeadingRow = TextStyle(
    color: grey1,
    fontWeight: FontWeight.w900,
    fontSize: 15,
    fontFamily: 'Inter',
    decoration: TextDecoration.none);
const style15grey = TextStyle(
    color: grey1,
    fontWeight: FontWeight.w900,
    fontSize: 15,
    fontFamily: 'Inter',
    decoration: TextDecoration.none);
const style10grey = TextStyle(
    color: grey1,
    fontWeight: FontWeight.w800,
    fontSize: 10,
    fontFamily: 'Inter',
    decoration: TextDecoration.none);
const style13grey = TextStyle(
    color: grey1,
    fontWeight: FontWeight.w800,
    fontSize: 13,
    fontFamily: 'Inter',
    decoration: TextDecoration.none);
const style15Blue = TextStyle(
    color: bluebland,
    fontWeight: FontWeight.w900,
    fontSize: 15,
    fontFamily: 'Inter',
    decoration: TextDecoration.none);
const style15White = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w900,
    fontSize: 15,
    fontFamily: 'Inter',
    decoration: TextDecoration.none);
const style18Blue = TextStyle(
    color: Color(0xFF51CDF5),
    fontWeight: FontWeight.w900,
    fontSize: 18,
    decoration: TextDecoration.none);

const style20White = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w900,
    fontSize: 20,
    fontFamily: 'Inter',
    decoration: TextDecoration.none);
const style22White = TextStyle(
    color: Colors.white,
    fontSize: 22,
    fontFamily: 'Inter',
    decoration: TextDecoration.none);
const style25White = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w900,
    fontSize: 25,
    fontFamily: 'Inter',
    decoration: TextDecoration.none);
const style12White = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w800,
    fontSize: 12,
    fontFamily: 'Inter',
    decoration: TextDecoration.none);
const style10White = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w500,
    fontSize: 10,
    fontFamily: 'Inter',
    decoration: TextDecoration.none);
const style18White = TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.w900,
  fontSize: 18,
  fontFamily: 'Inter',
  decoration: TextDecoration.none,
);
const style16White = TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.w800,
  fontSize: 16,
  fontFamily: 'Inter',
  decoration: TextDecoration.none,
);
const style30White = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w800,
    fontSize: 30,
    fontFamily: 'Inter',
    decoration: TextDecoration.none);
const style20 = TextStyle(
    color: grey1,
    fontWeight: FontWeight.w800,
    fontSize: 20,
    fontFamily: 'Inter',
    decoration: TextDecoration.none);
var style20blue = TextStyle(
    color: Colors.blue.shade400,
    fontWeight: FontWeight.w900,
    fontSize: 20,
    decoration: TextDecoration.none);
const stylelarge = TextStyle(
    color: grey1,
    fontWeight: FontWeight.w800,
    fontSize: 25,
    fontFamily: 'Inter',
    decoration: TextDecoration.none);

const styleWarning = TextStyle(
    color: bluedark1,
    fontWeight: FontWeight.w800,
    fontSize: 20,
    fontFamily: 'Inter',
    decoration: TextDecoration.none);
const styleBottomCard = TextStyle(
    color: bluebland,
    fontWeight: FontWeight.w800,
    fontSize: 15,
    fontFamily: 'Inter',
    decoration: TextDecoration.none);
const styleDataTable = TextStyle(
    color: grey1,
    fontWeight: FontWeight.w500,
    fontSize: 15,
    fontFamily: 'Inter',
    decoration: TextDecoration.none);
const styleDataTable1 = TextStyle(
    color: grey1,
    fontWeight: FontWeight.w500,
    fontSize: 15,
    fontFamily: 'Inter',
    decoration: TextDecoration.underline);

var decoratedCircular8White = const BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.all(Radius.circular(8)),
  boxShadow: [
    BoxShadow(
      color: Colors.black12,
      offset: Offset(1.0, 2.0),
      blurRadius: 2.0,
      spreadRadius: 2.0,
    ),
  ],
);

var decoratedCircular20White = const BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.all(Radius.circular(20)),
  boxShadow: [
    BoxShadow(
      color: Colors.black12,
      offset: Offset(1.0, 2.0),
      blurRadius: 2.0,
      spreadRadius: 2.0,
    ),
  ],
);

var decoratedCircular30 = const BoxDecoration(
  borderRadius: BorderRadius.all(Radius.circular(30)),
  boxShadow: [
    BoxShadow(
      color: Colors.black12,
      offset: Offset(1.0, 2.0),
      blurRadius: 2.0,
      spreadRadius: 2.0,
    ),
  ],
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
    colors: [Color(0xFF4CB1F1), Color(0xFF4FC5F3), Color(0xFF53D9F6)],
  ),
);
var decoratedBlue = const BoxDecoration(
  borderRadius: BorderRadius.all(Radius.circular(16)),
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 1.0],
    colors: [Color(0xFF53DCF6), Color(0xFF4AAEEF)],
  ),
);

var decoratedRed = const BoxDecoration(
  borderRadius: BorderRadius.all(Radius.circular(16)),
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 1.0],
    colors: [Color(0xFFF6B553), Color(0xFFEF4A4A)],
  ),
);
var decoratedGrey = BoxDecoration(
    borderRadius: const BorderRadius.all(Radius.circular(16)),
    border: Border.all(color: const Color(0xFFD1D1D6)),
    color: const Color(0xFF787880).withOpacity(0.16));

var decoratedGradient = (List<Color> color) => BoxDecoration(
      borderRadius: const BorderRadius.all(Radius.circular(30)),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0.0, 0.5, 1.0],
        colors: color,
      ),
    );

var decoratedCircular20Blue = BoxDecoration(
    borderRadius: const BorderRadius.all(Radius.circular(20)),
    border: Border.all(color: const Color(0XFF51C6F4), width: 2));
var greyBackgroundCircular = (int circular) => BoxDecoration(
      borderRadius: BorderRadius.all(Radius.circular(circular.toDouble())),
      color: const Color(0xFFF5F5F5),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          offset: Offset(1.0, 2.0),
          blurRadius: 2.0,
          spreadRadius: 2.0,
        ),
      ],
    );

var decoratedBoder = BoxDecoration(border: Border.all(color: Colors.grey));

// import 'package:audioplayers/audioplayers.dart';

//RESPONSIVE SCREENS
class ScreenSize {
  BuildContext context;

  ScreenSize(this.context) : assert(true);

  double get width => MediaQuery.of(context).size.width;
  double get height => MediaQuery.of(context).size.height;
}

// //USED COLORS
// class AppColors {
//   static const white = Color(0xffEEEEEE);
//   static const black = Color(0xff1e212d);
//   static const backGround = Color(0xff87C7F1);
//   static const yellow = Color(0xff8FDDE7);
//   //  static const secondary = Color(0xff8eecf5);
//   static const crimson = Color(0xffEACFFF);
//   static const secondary = Color(0xffdaf2dc);
//   static const orange = Color(0xffffab4c);
//   static const Lpink = Color(0xffffcce7);
//   static const sage = Color(0xffdaf2dc);
//   static const tale = Color(0xffdaf2dc);
// }

//USED COLORS
// class AppColors {
//   static const white = Color(0xffEEEEEE);
//   static const black = Color(0xff1e212d);
//   static const backGround = Color(0xffaf8aff);
//   static const secondary = Color(0xff5fffe0);
//   static const crimson = Color(0xffff5f7e);
//   static const yellow = Color(0xfffbe698);
//   static const orange = Color(0xffff884b);
//   static const Lpink = Color(0xffffcce7);
//   static const sage = Color(0xffdaf2dc);
//   static const pale = Color(0xffeacfff);
//   static const tale = Color(0xffdaf2dc);
// }

//FONT STYLING
class PrimaryText extends StatelessWidget {
  final double size;
  final FontWeight fontWeight;
  final Color color;
  final String text;
  final double height;

  const PrimaryText({
    required this.text,
    this.fontWeight = FontWeight.w400,
    this.color = Colors.black,
    this.size = 20,
    this.height = 1.3,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.almarai(
        height: height,
        fontSize: size,
        fontWeight: fontWeight,
        color: color,
      ),
    );
  }
}

//BACKGROUND MUSIC CONTROLLER
// class Music {
//   static AudioPlayer music = AudioPlayer();
//   static AudioCache player = AudioCache(fixedPlayer: music);
//   void play() {
//     player.loop("voices/music.mp3", volume: 0.85);
//   }
//   volDown() {
//     music.setVolume(0.25);
//   }
//   volUp() {
//     music.setVolume(0.85);
//   }
// }

//CATEGORIES
const CardsList = [
  {
    'imagePath': 'assets/nums.png',
    'name': 'الأرقام',
  },
  {
    'imagePath': 'assets/letters.png',
    'name': ' الحروف',
  },
  {
    'imagePath': 'assets/animals.png',
    'name': 'الحيوانات',
  },
  {
    'imagePath': 'assets/family.png',
    'name': 'العائلة',
  },
  {
    'imagePath': 'assets/fruits.png',
    'name': 'الفواكه',
  },
  {
    'imagePath': 'assets/vegetables.png',
    'name': 'الخضراوات',
  },
];

//ROUTES
const routesList = [
  {
    'routePath': '/Nums',
  },
  {
    'routePath': '/Letters',
  },
  {
    'routePath': '/Animals',
  },
  {
    'routePath': '/Family',
  },
  {
    'routePath': '/Fruits',
  },
  {
    'routePath': '/Vegetables',
  },
];

const GamesList = [
  {'GameName': 'وصلة', 'imagePath': 'assets/games/color.png'},
  {'GameName': 'ميمو', 'imagePath': 'assets/games/memo.png'},
];

const gamesRoutes = [
  {'routePath': '/Color'},
  {'routePath': '/Memory'},
];

//NUMS LIST
var numsList = [
  CustomCardModel(
    color: AppColors.light().blue,
    image: 'assets/number/0.png',
    subImage: 'assets/counters/hands0.png',
    title: "Số Không",
  ),
  CustomCardModel(
    color: AppColors.light().teal,
    image: 'assets/number/1.png',
    subImage: 'assets/counters/hands1.png',
    title: "Số Một",
  ),
  CustomCardModel(
    color: AppColors.light().yellow,
    image: 'assets/number/2.png',
    subImage: 'assets/counters/hands2.png',
    title: "Số Hai",
  ),
  CustomCardModel(
    color: AppColors.light().cyan,
    image: 'assets/number/3.png',
    subImage: 'assets/counters/hands3.png',
    title: "Số Ba",
  ),
  CustomCardModel(
    color: AppColors.light().green,
    image: 'assets/number/4.png',
    subImage: 'assets/counters/hands4.png',
    title: "Số Bốn",
  ),
  CustomCardModel(
    color: AppColors.light().mint,
    image: 'assets/number/5.png',
    subImage: 'assets/counters/hands5.png',
    title: "Số Năm",
  ),
  CustomCardModel(
    color: AppColors.light().magenta,
    image: 'assets/number/6.png',
    subImage: 'assets/counters/hands6.png',
    title: "Số Sáu",
  ),
  CustomCardModel(
    color: AppColors.light().neutral,
    image: 'assets/number/7.png',
    subImage: 'assets/counters/hands7.png',
    title: "Số Bảy",
  ),
  CustomCardModel(
    color: AppColors.light().orange,
    image: 'assets/number/8.png',
    subImage: 'assets/counters/hands8.png',
    title: "Số Tám",
  ),
  CustomCardModel(
    color: AppColors.light().primary,
    image: 'assets/number/9.png',
    subImage: 'assets/counters/hands9.png',
    title: "Số Chín",
  ),
];

class Const {
  Const._();

  static const slUsername = "SL_USERNAME";
  static const slPassword = "SL_PASSWORD";
  static const slRememberPassword = "SL_REMEMBER_PASSWORD";
  static const defaultLimit = 20;
  static const defaultPage = 1;
  static const lstSize = [20, 30, 50, 100];
  static const sizeSmall = 600;

  //Payment type
  static const subscriptionPay = 'SUBSCRIPTION';
  static const onlinePayment = 'ONLINE_PAYMENT';
  static const directPay = 'DIRECT_PAY';

  //Status swapping
  static const inProcessStatus = 'IN_PROCESS';
  static const waitPaymentStatus = 'WAIT_PAYMENT';
  static const timeOutStatus = 'TIME_OUT';
  static const completeStatus = 'COMPLETE';
  static const waitConfirmStatus = 'WAIT_CONFIRM';
  static const cancelStatus = 'CANCEL';
  static const refundStatus = 'REFUND';

  //Bss type
  static const bssManual = 'MANUAL';
  static const bssAuto = 'AUTOMATION';

  //Message
  static const int messageError = 2;
  static const int messageSuccess = 1;

  static final dateDeploy = (time) => "${"Cập nhật lúc"}: $time";

  static var qrCodeBanking = (bank, accountNumber, amount, txnRef,
          accountOwner) =>
      "https://img.vietqr.io/image/$bank-$accountNumber-compact.png?amount=$amount&addInfo=$txnRef&accountName=$accountOwner";

  static const String keyPreorder = "reserve_battery_function";

// DEFINE KEY FILETER FOR VEHICLE COLUMNS

  static const columnsVehicleskey = 'columnsVehicleskey';
  static const columnsSummaryVehicleskey = 'columnsSummaryVehicleskey';

  static const columnsBssesskey = 'columnsBsseskey';

  static const columnsBatteriesKey = 'columnsBatterieskey';
  static const columnsBatteriesOfBssKey = 'columnsBatteriesOfBssKey';

  static const columnPreorderKey = 'columnPreorderKey';
  static const columnsBookingkey = 'columnsBookingkey';
  static const columnsNotificationkey = 'columnsNotificationkey';
  static const columnsGroupNotificationkey = 'columnsGroupNotificationkey';
  static const columnsMarketClaimListKey = 'columnsMarketClaimListKey';
  static const columnsErrorListKey = 'columnsErrorListKey';
  static const columnsListUserkey = 'columnsListUserkey';
  static const columnsHistoryControlBssKey = 'columnsHistoryControlBssKey';
  static const columnsBatteryOperationHistoryKey =
      'columnsBatteryOperationHistoryKey';
  static const columnsBatteryExchangeHistoryInBssKey =
      'columnsBatteryExchangeHistoryInBssKey';
  static const columnsBatteriesOfVehicleKey = 'columnsBatteriesOfVehicleKey';
  static const columnsBatteryExchangeHistoryInVehicleKey =
      'columnsBatteryExchangeHistoryInVehicleKey';
  static const columnsBatteryExchangeHistoryListKey =
      'columnsBatteryExchangeHistoryListKey';
  static const columnsSubscriptionServiceListKey =
      'columnsSubscriptionServiceListKey';
  static const columnsPackageListKey = 'columnsPackageListKey';
  static const columnsBillListKey = 'columnsBillListKey';
  static const columnsActivationListKey = 'columnsActivationListKey';
  static const columnsVehicleBatteryExchangeHistoryKey =
      'columnsVehicleBatteryExchangeHistoryKey';

  ////////////////////////
  ///Dashboard information

  static const dashboardName =
      "Giới thiệu hệ thống quản lý dạy và học ngôn ngữ ký hiệu tiếng Việt (WeSign)";
  static const dashboardSummary =
      "Hệ thống (Phần mềm) Dashboard quản lý dạy và học ngôn ngữ ký hiệu tiếng Việt (WeSign) là một nền tảng hỗ trợ cho người đứng đầu quản lý hoặc giáo viên có thể theo dõi về việc học ngôn ngữ ký hiệu tiếng Việt. Hệ thống cung cấp dữ liệu về người sử dụng, dánh sách lớp học, chủ đề, bài học, danh sách người thực hiện hay đang tiến hành bài học. Phần mềm có thể được dùng trực tiếp từ trình duyệt trên máy tính và trên điện thoại.";
  static const dashboardView =
      "Wesign Dashboard hiện tại là phiên bản thử nghiệm. Phần mềm được phát triển bởi nhóm nghiên cứu iBME lab, Đại học Bách Khoa Hà Nội.";
  static const linkAppAndoirdText =
      "Link tải phần mềm học tập trên di động(Android): ";
  static const linkAppIosText = "Link tải phần mềm học tập trên di động(Ios): ";
  static const linkAppWebText = "Link phần mềm học tập trên Web: ";
  static const linkAppAndoird =
      "https://drive.google.com/drive/folders/1nX4IK4-MydQ891C4_DKE8llHkuxruB0D?usp=drive_link";
  static const linkAppIos = "Vui lòng liên hệ Ibme Lab";
  static const linkAppWeb = "https://we-sign-app.vercel.app";
  static const dashboardGuide = "Hướng dẫn sử dụng phần mềm hỗ trợ học tập";
  static const dashboardGuideLink = "https://bit.ly/wesign_hdsd";
  static const labInfomation =
      "Nếu cần hỗ trợ sử dụng hoặc có góp ý, có thể liên lạc qua ibme.lab@gmail.com hoặc 0912834422.";
}
