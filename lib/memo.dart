import 'package:objectbox/objectbox.dart';

@Entity()
class Memo {
  int id;

  String content;
  int dateMillis; // DateTimeをミリ秒単位で保存

  Memo({this.id = 0, required this.content, required this.dateMillis});
}
