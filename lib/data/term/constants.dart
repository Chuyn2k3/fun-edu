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

//ANIMALS LIST
const animalsList = [
  {
    'imagePath': 'assets/animals/leo.png',
    'voice': 'voices/leo.mp3',
    'name': 'أسد',
  },
  {
    'imagePath': 'assets/animals/duck.png',
    'voice': 'voices/duck.mp3',
    'name': 'بطة',
  },
  {
    'imagePath': 'assets/animals/chicken.png',
    'voice': 'voices/chicken.mp3',
    'name': 'دجاجة',
  },
  {
    'imagePath': 'assets/animals/horse.png',
    'voice': 'voices/horse.mp3',
    'name': 'حصان',
  },
  {
    'imagePath': 'assets/animals/goat.png',
    'voice': 'voices/goat.mp3',
    'name': 'ماعز',
  },
  {
    'imagePath': 'assets/animals/cat.png',
    'voice': 'voices/cat.mp3',
    'name': 'قطة',
  },
  {
    'imagePath': 'assets/animals/mouse.png',
    'voice': 'voices/mouse.mp3',
    'name': 'فأر',
  },
  {
    'imagePath': 'assets/animals/frog.png',
    'voice': 'voices/frog.mp3',
    'name': 'ضفدع',
  },
  {
    'imagePath': 'assets/animals/dog.png',
    'voice': 'voices/dog.mp3',
    'name': 'كلب',
  },
  {
    'imagePath': 'assets/animals/cow.png',
    'voice': 'voices/cow.mp3',
    'name': 'بقرة',
  },
];

//LETTERS LIST
const lettersList = [
  {
    'imagePath': 'assets/letters/أ.png',
    'subImage': 'assets/letters/avatars/أرنب.png',
    'name': 'أ',
  },
  {
    'imagePath': 'assets/letters/ب.png',
    'subImage': 'assets/letters/avatars/بطة.png',
    'name': 'ب',
  },
  {
    'imagePath': 'assets/letters/ت.png',
    'subImage': 'assets/letters/avatars/تفاح.png',
    'name': 'ت',
  },
  {
    'imagePath': 'assets/letters/ث.png',
    'subImage': 'assets/letters/avatars/ثلج.png',
    'name': 'ث',
  },
  {
    'imagePath': 'assets/letters/ج.png',
    'subImage': 'assets/letters/avatars/جَزَر.png',
    'name': 'ج',
  },
  {
    'imagePath': 'assets/letters/ح.png',
    'subImage': 'assets/letters/avatars/حصان.png',
    'name': 'ح',
  },
  {
    'imagePath': 'assets/letters/خ.png',
    'subImage': 'assets/letters/avatars/خيمة.png',
    'name': 'خ',
  },
  {
    'imagePath': 'assets/letters/د.png',
    'subImage': 'assets/letters/avatars/دولفين.png',
    'name': 'د',
  },
  {
    'imagePath': 'assets/letters/ذ.png',
    'subImage': 'assets/letters/avatars/ذُره.png',
    'name': 'ذ',
  },
  {
    'imagePath': 'assets/letters/ر.png',
    'subImage': 'assets/letters/avatars/ريشة.png',
    'name': 'ر',
  },
  {
    'imagePath': 'assets/letters/ز.png',
    'subImage': 'assets/letters/avatars/زرافة.png',
    'name': 'ز',
  },
  {
    'imagePath': 'assets/letters/س.png',
    'subImage': 'assets/letters/avatars/سلحفاة.png',
    'name': 'س',
  },
  {
    'imagePath': 'assets/letters/ش.png',
    'subImage': 'assets/letters/avatars/شمعة.png',
    'name': 'ش',
  },
  {
    'imagePath': 'assets/letters/ص.png',
    'subImage': 'assets/letters/avatars/صقر.png',
    'name': 'ص',
  },
  {
    'imagePath': 'assets/letters/ض.png',
    'subImage': 'assets/letters/avatars/ضفدع.png',
    'name': 'ض',
  },
  {
    'imagePath': 'assets/letters/ط.png',
    'subImage': 'assets/letters/avatars/طائرة.png',
    'name': 'ط',
  },
  {
    'imagePath': 'assets/letters/ظ.png',
    'subImage': 'assets/letters/avatars/ظرف.png',
    'name': 'ظ',
  },
  {
    'imagePath': 'assets/letters/ع.png',
    'subImage': 'assets/letters/avatars/عصفور.png',
    'name': 'ع',
  },
  {
    'imagePath': 'assets/letters/غ.png',
    'subImage': 'assets/letters/avatars/غزالة.png',
    'name': 'غ',
  },
  {
    'imagePath': 'assets/letters/ف.png',
    'subImage': 'assets/letters/avatars/فراولة.png',
    'name': 'ف',
  },
  {
    'imagePath': 'assets/letters/ق.png',
    'subImage': 'assets/letters/avatars/قلم.png',
    'name': 'ق',
  },
  {
    'imagePath': 'assets/letters/ك.png',
    'subImage': 'assets/letters/avatars/كرة.png',
    'name': 'ك',
  },
  {
    'imagePath': 'assets/letters/ل.png',
    'subImage': 'assets/letters/avatars/لمبة.png',
    'name': 'ل',
  },
  {
    'imagePath': 'assets/letters/م.png',
    'subImage': 'assets/letters/avatars/موز.png',
    'name': 'م',
  },
  {
    'imagePath': 'assets/letters/ن.png',
    'subImage': 'assets/letters/avatars/نجمة.png',
    'name': 'ن',
  },
  {
    'imagePath': 'assets/letters/ه.png',
    'subImage': 'assets/letters/avatars/هرم.png',
    'name': 'ه',
  },
  {
    'imagePath': 'assets/letters/و.png',
    'subImage': 'assets/letters/avatars/وردة.png',
    'name': 'و',
  },
  {
    'imagePath': 'assets/letters/ي.png',
    'subImage': 'assets/letters/avatars/يد.png',
    'name': 'ي',
  },
];

//FAMILY LIST
const familyList = [
  {
    'imagePath': 'assets/family/0.png',
    'name': 'الجد',
  },
  {
    'imagePath': 'assets/family/1.png',
    'name': 'الجدة',
  },
  {
    'imagePath': 'assets/family/2.png',
    'name': 'الأب',
  },
  {
    'imagePath': 'assets/family/3.png',
    'name': 'الأم',
  },
  {
    'imagePath': 'assets/family/4.png',
    'name': 'العم/الخال',
  },
  {
    'imagePath': 'assets/family/5.png',
    'name': 'العمة/الخالة',
  },
  {
    'imagePath': 'assets/family/6.png',
    'name': 'الابن',
  },
  {
    'imagePath': 'assets/family/7.png',
    'name': 'الابنة',
  },
  {
    'imagePath': 'assets/family/8.png',
    'name': 'ابن/ابنة العم',
  },
];

const fruitsList = [
  {
    'imagePath': 'assets/fruits/مانجو.png',
    'name': 'مانجو',
  },
  {
    'imagePath': 'assets/fruits/بطيخ.png',
    'name': 'بطيخ',
  },
  {
    'imagePath': 'assets/fruits/كيوي.png',
    'name': 'كيوي',
  },
  {
    'imagePath': 'assets/fruits/عنب.png',
    'name': 'عنب',
  },
  {
    'imagePath': 'assets/fruits/أناناس.png',
    'name': 'أناناس',
  },
];

const vegetablesList = [
  {
    'imagePath': 'assets/vegetables/بطاطس.png',
    'name': 'بطاطس',
  },
  {
    'imagePath': 'assets/vegetables/بازلاء.png',
    'name': 'بازلاء',
  },
  {
    'imagePath': 'assets/vegetables/فلفل.png',
    'name': 'فلفل',
  },
  {
    'imagePath': 'assets/vegetables/باذنجان.png',
    'name': 'باذنجان',
  },
  {
    'imagePath': 'assets/vegetables/خيار.png',
    'name': 'خيار',
  },
];
