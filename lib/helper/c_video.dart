import 'package:fun_edu/model/learn_model.dart';


class ControllerVideo {
  static final List<LearnModel> _dataVideoComparsion = [
    LearnModel(
        imageUrl: 'https://i.ytimg.com/vi/gQWeteOOIzk/maxresdefault.jpg',
        title: 'Lớn hơn, dấu lớn hơn. Bé hơn, dấu bé hơn. Bằng nhau, dấu bằng',
        pageUrl: 'https://youtu.be/gQWeteOOIzk'),
    LearnModel(
        imageUrl:
            'https://i.pinimg.com/vi/zA-w8wROazU&t=1s/maxresdefault.jpg',
        title: 'Lớn hơn, bé hơn, bằng nhau',
        pageUrl: 'https://youtu.be/zA-w8wROazU&t=1s'),
    LearnModel(
        imageUrl: 'https://i.ytimg.com/vi/ucrn2YNJArM/maxresdefault.jpg',
        title: "Lớn hơn, bé hơn, bằng nhau",
        pageUrl: 'https://youtu.be/ucrn2YNJArM'),
    LearnModel(
        imageUrl: 'https://i.ytimg.com/vi/rWFztLVWuL0/maxresdefault.jpg',
        title: "Lớn hơn, bé hơn, bằng nhau",
        pageUrl: 'https://youtu.be/rWFztLVWuL0'),
        LearnModel(
        imageUrl: 'https://i.ytimg.com/vi/Z8P-pmHMxDU/maxresdefault.jpg',
        title: "Nhiều hơn, ít hơn, bằng nhau",
        pageUrl: 'https://youtu.be/Z8P-pmHMxDU'),

  ];
  static List<LearnModel> get dataVideoComparsion => _dataVideoComparsion;
  static int get dataLengthComparsion => _dataVideoComparsion.length;
    static final List<LearnModel> _dataVideoAddSub = [
    LearnModel(
        imageUrl: 'https://i.ytimg.com/vi/ywEkJJ5VEKQ/maxresdefault.jpg',
        title: 'Làm quen Phép cộng - Dấu cộng',
        pageUrl: 'https://youtu.be/ywEkJJ5VEKQ'),
    LearnModel(
        imageUrl:
            'https://i.pinimg.com/vi/jCUnWHLoUTY/maxresdefault.jpg',
        title: 'Làm quen Phép trừ - Dấu trừ',
        pageUrl: 'https://youtu.be/jCUnWHLoUTY'),
    LearnModel(
        imageUrl: 'https://i.ytimg.com/vi/gGLlRjoCIT4/maxresdefault.jpg',
        title: "Làm quen với phép cộng, dấu cộng",
        pageUrl: 'https://youtu.be/gGLlRjoCIT4'),
    LearnModel(
        imageUrl: 'https://i.ytimg.com/vi/1G8WQ6y4q18/maxresdefault.jpg',
        title: "Làm quen với phép trừ, dấu trừ",
        pageUrl: 'https://youtu.be/1G8WQ6y4q18'),
        LearnModel(
        imageUrl: 'https://i.ytimg.com/vi/Qq8r7-feu6s/maxresdefault.jpg',
        title: "Lớn hơn, bé hơn, bằng nhau",
        pageUrl: 'https://youtu.be/Qq8r7-feu6s'),
        LearnModel(
        imageUrl: 'https://i.ytimg.com/vi/s-goxNdmJPE/maxresdefault.jpg',
        title: "Lớn hơn, bé hơn, bằng nhau",
        pageUrl: 'https://youtu.be/s-goxNdmJPE'),

  ];
  static List<LearnModel> get dataVideoAddSub => _dataVideoAddSub;
  static int get dataLengthAddSub => _dataVideoAddSub.length;

    static final List<LearnModel> _dataVideoMath = [
    LearnModel(
        imageUrl: 'https://i.ytimg.com/vi/oNWQC-TZ2PE/maxresdefault.jpg',
        title: 'Phép trừ trong phạm vi 10',
        pageUrl: 'https://youtu.be/oNWQC-TZ2PE'),
    LearnModel(
        imageUrl:
            'https://i.pinimg.com/vi/ck3QeXIlSbo/maxresdefault.jpg',
        title: 'Phép trừ trong phạm vi 4',
        pageUrl: 'https://youtu.be/ck3QeXIlSbo'),
    LearnModel(
        imageUrl: 'https://i.ytimg.com/vi/ppOLTrXWX2s/maxresdefault.jpg',
        title: "Phép cộng trong phạm vi 4",
        pageUrl: 'https://youtu.be/ppOLTrXWX2s'),

  ];
  static List<LearnModel> get dataVideoMath => _dataVideoMath;
  static int get dataLengthMath => _dataVideoMath.length;
}
