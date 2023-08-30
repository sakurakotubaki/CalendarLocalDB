# iPhoneみたいなカレンダーアプリを作って見たかった
Flutterでカレンダーアプリを何度か作ろうとしていて、FireStoreとローカルDB両方やって見たのですが、これ動いているのかな〜と思いつつ色々作っておりました。

今回は、Objectboxを使用してデータの保存、表示、削除を実装して見ました。

Objectboxの設定について知りたい人はこんぶさんの記事を見ると参考になります。
https://zenn.dev/pressedkonbu/articles/flutter-object-box

まずは、必要なパッケージを追加する。
pubspec.yamlは設定する位置が決まっているので、注意が必要。
```yaml:pubspec.yaml
name: local_calendart
description: A new Flutter project.
# The following line prevents the package from being accidentally published to
# pub.dev using `flutter pub publish`. This is preferred for private packages.
publish_to: 'none' # Remove this line if you wish to publish to pub.dev

# The following defines the version and build number for your application.
# A version number is three numbers separated by dots, like 1.2.43
# followed by an optional build number separated by a +.
# Both the version and the builder number may be overridden in flutter
# build by specifying --build-name and --build-number, respectively.
# In Android, build-name is used as versionName while build-number used as versionCode.
# Read more about Android versioning at https://developer.android.com/studio/publish/versioning
# In iOS, build-name is used as CFBundleShortVersionString while build-number is used as CFBundleVersion.
# Read more about iOS versioning at
# https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html
# In Windows, build-name is used as the major, minor, and patch parts
# of the product and file versions while build-number is used as the build suffix.
version: 1.0.0+1

environment:
  sdk: '>=3.0.5 <4.0.0'

# Dependencies specify other packages that your package needs in order to work.
# To automatically upgrade your package dependencies to the latest versions
# consider running `flutter pub upgrade --major-versions`. Alternatively,
# dependencies can be manually updated by changing the version numbers below to
# the latest version available on pub.dev. To see which dependencies have newer
# versions available, run `flutter pub outdated`.
dependencies:
  flutter:
    sdk: flutter


  # The following adds the Cupertino Icons font to your application.
  # Use with the CupertinoIcons class for iOS style icons.
  cupertino_icons: ^1.0.2
  path_provider: ^2.1.0
  table_calendar: ^3.0.9
  objectbox: ^2.2.1
  objectbox_flutter_libs: ^2.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter

  # The "flutter_lints" package below contains a set of recommended lints to
  # encourage good coding practices. The lint set provided by the package is
  # activated in the `analysis_options.yaml` file located at the root of your
  # package. See that file for information about deactivating specific lint
  # rules and activating additional ones.
  flutter_lints: ^2.0.0
  objectbox_generator: ^2.2.1
  build_runner: ^2.4.6

# For information on the generic Dart part of this file, see the
# following page: https://dart.dev/tools/pub/pubspec

# The following section is specific to Flutter packages.
flutter:

  # The following line ensures that the Material Icons font is
  # included with your application, so that you can use the icons in
  # the material Icons class.
  uses-material-design: true

  # To add assets to your application, add an assets section, like this:
  # assets:
  #   - images/a_dot_burr.jpeg
  #   - images/a_dot_ham.jpeg

  # An image asset can refer to one or more resolution-specific "variants", see
  # https://flutter.dev/assets-and-images/#resolution-aware

  # For details regarding adding assets from package dependencies, see
  # https://flutter.dev/assets-and-images/#from-packages

  # To add custom fonts to your application, add a fonts section here,
  # in this "flutter" section. Each entry in this list should have a
  # "family" key with the font family name, and a "fonts" key with a
  # list giving the asset and other descriptors for the font. For
  # example:
  # fonts:
  #   - family: Schyler
  #     fonts:
  #       - asset: fonts/Schyler-Regular.ttf
  #       - asset: fonts/Schyler-Italic.ttf
  #         style: italic
  #   - family: Trajan Pro
  #     fonts:
  #       - asset: fonts/TrajanPro.ttf
  #       - asset: fonts/TrajanPro_Bold.ttf
  #         weight: 700
  #
  # For details regarding fonts from package dependencies,
  # see https://flutter.dev/custom-fonts/#from-packages
```

## 💾モデルを作る
Objectboxには、DateTimeがあるらしいが今回使って見たところ使えない？？？
int型にデータを変換して、保存して表示するときはint -> DateTimeに変換して使わないとロジックを作れなかったです。
sqlfliteでもStringに変換しないと保存できない問題がありましたので、保存するときは別のデータ型にする必要があるのかもしれません🤔
```dart:memo.dart
import 'package:objectbox/objectbox.dart';

@Entity()
class Memo {
  int id;

  String content;
  int dateMillis; // DateTimeをミリ秒単位で保存

  Memo({this.id = 0, required this.content, required this.dateMillis});
}
```

Objectboxの設定をするコードを書いて自動生成するコマンドを実行して、importのエラーを解消して、設定ファイルを作成します。
```dart:object_box.dart
import 'package:objectbox/objectbox.dart';
import 'objectbox.g.dart'; // created by `flutter pub run build_runner build`

late ObjectBox objectbox;

class ObjectBox {
  /// The Store of this app.
  late final Store store;

  ObjectBox._create(this.store) {
    // Add any additional setup code, e.g. build queries.
  }

  /// Create an instance of ObjectBox to use throughout the app.
  static Future<ObjectBox> create() async {
    final store = await openStore();
    return ObjectBox._create(store);
  }
}
```
コマンドを実行する
```
flutter pub run build_runner build
```

## カレンダーアプリのページを作る
カレンダーのUIを作るのには、今回は公式のこのコードだけでいいみたいです。
**コードの解説**
TableCalendar では、firstDay、lastDay、focusDay を指定する必要があります：

firstDay は、カレンダーで使用可能な最初の日です。ユーザはそれ以前の日にアクセスすることはできません。
lastDay は、カレンダーの利用可能な最後の日です。ユーザーはそれ以降の日にアクセスすることはできません。
focusedDay は、現在ターゲットになっている日です。このプロパティを使用して、現在表示されている月を決定します。

```dart
TableCalendar(
  firstDay: DateTime.utc(2010, 10, 16),
  lastDay: DateTime.utc(2030, 3, 14),
  focusedDay: DateTime.now(),
);
``

アプリのコードだとこんな風に書いてます。
```dart
TableCalendar(
            focusedDay: _focusedDay,// どの日付を選択したか
            firstDay: DateTime(1990),// 最初に利用可能な日付
            lastDay: DateTime(2050),// 最後に利用可能な日付
            calendarFormat: _calendarFormat,
            // カレンダーウィジェットに以下のコードを追加すると、ユーザーのタップに反応し、
            // タップされた日を選択されたようにマークします
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),// 選択された日付をマークする
            onDaySelected: (selectedDay, focusedDay) {// 日付が選択されたときに呼び出される
              _focusedDay = focusedDay;
              _selectedDay = selectedDay;
              setState(() {});
            },
          ),
```

----

データを追加するには、画面右上のプラスボタンを押してダイアログを出して、こちらで入力します。
```dart
appBar: AppBar(
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () {
                if (_selectedDay != null) {
                  TextEditingController textController =
                      TextEditingController();
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('メモを追加'),
                        content: SingleChildScrollView(
                          child: TextField(
                            controller: textController,
                            decoration: const InputDecoration(
                              hintText: 'メモを入力してください',
                            ),
                          ),
                        ),
                        actions: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('キャンセル'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              String content = textController.text;
                              final memo = Memo(
                                content: content,
                                dateMillis:
                                    _selectedDay!.millisecondsSinceEpoch,
                              );
                              memoBox.put(memo);
                              setState(() {});
                              Navigator.pop(context);
                            },
                            child: const Text('保存'),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              icon: const Icon(Icons.add)),
        ],
        backgroundColor: Colors.black87,
        title: const Text('Calendar Memo'),
      ),
```

-----

画面に保存したデータの表示と削除をするには、LiseViewを使用します。
```dart
Expanded(
            child: _selectedDay == null
                ? const Center(child: Text("日付を選択してください。"))
                : ListView(
                    children: memoBox
                        .query(Memo_.dateMillis
                            .equals(_selectedDay!.millisecondsSinceEpoch))
                        .build()
                        .find()
                        .map((memo) {
                      return ListTile(
                        title: Text(memo.content),
                        subtitle: Text(
                            DateTime.fromMillisecondsSinceEpoch(memo.dateMillis)
                                .toLocal()
                                .toString()),
                        trailing: IconButton(
                          onPressed: () {
                            memoBox.remove(memo.id);
                            setState(() {});
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                        ),
                      );
                    }).toList(),
                  ),
          ),
```

## 全体のコード
こちらが設定したコードです。ビルドしたらアプリを実行できます。
iOSのシュミレーターだと、ダイアログを開いところから重くなる💦
```dart:main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_calendart/objec_box.dart';
import 'package:local_calendart/objectbox.g.dart';
import 'package:table_calendar/table_calendar.dart';
import 'memo.dart'; // ← Memoエンティティが定義されている場所

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 画面の向きを縦に固定する。AndroidだとOverflowが起きる!
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,//縦固定
  ]);
  // ObjectBoxの初期化
  objectbox = await ObjectBox.create();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CalendarScreen(),
    );
  }
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final Box<Memo> memoBox;
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    // アプリが起動したときに呼び出される
    super.initState();
    // MemoエンティティのBoxを取得
    memoBox = objectbox.store.box<Memo>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // キーボードが出てきても画面が崩れないようにする
      appBar: AppBar(
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () {
                if (_selectedDay != null) {
                  TextEditingController textController =
                      TextEditingController();
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('メモを追加'),
                        content: SingleChildScrollView(
                          child: TextField(
                            controller: textController,
                            decoration: const InputDecoration(
                              hintText: 'メモを入力してください',
                            ),
                          ),
                        ),
                        actions: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('キャンセル'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              String content = textController.text;
                              final memo = Memo(
                                content: content,
                                dateMillis:
                                    _selectedDay!.millisecondsSinceEpoch,
                              );
                              memoBox.put(memo);
                              setState(() {});
                              Navigator.pop(context);
                            },
                            child: const Text('保存'),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              icon: const Icon(Icons.add)),
        ],
        backgroundColor: Colors.black87,
        title: const Text('Calendar Memo'),
      ),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,// どの日付を選択したか
            firstDay: DateTime(1990),// 最初に利用可能な日付
            lastDay: DateTime(2050),// 最後に利用可能な日付
            calendarFormat: _calendarFormat,
            // カレンダーウィジェットに以下のコードを追加すると、ユーザーのタップに反応し、
            // タップされた日を選択されたようにマークします
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),// 選択された日付をマークする
            onDaySelected: (selectedDay, focusedDay) {// 日付が選択されたときに呼び出される
              _focusedDay = focusedDay;
              _selectedDay = selectedDay;
              setState(() {});
            },
          ),
          Expanded(
            child: _selectedDay == null
                ? const Center(child: Text("日付を選択してください。"))
                : ListView(
                    children: memoBox
                        .query(Memo_.dateMillis
                            .equals(_selectedDay!.millisecondsSinceEpoch))
                        .build()
                        .find()
                        .map((memo) {
                      return ListTile(
                        title: Text(memo.content),
                        subtitle: Text(
                            DateTime.fromMillisecondsSinceEpoch(memo.dateMillis)
                                .toLocal()
                                .toString()),
                        trailing: IconButton(
                          onPressed: () {
                            memoBox.remove(memo.id);
                            setState(() {});
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
```
