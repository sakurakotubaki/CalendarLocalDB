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
