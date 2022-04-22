import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quote Recipient',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Quote Recipient'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Map<dynamic, dynamic> quotesSet = {
    'Нет данных': 0
  }; // Карта для содержания сырого результата
  List<Quote> sortedSet = [
    const Quote('Нет данных', 0)
  ]; // Массив квот для содержания набора из 5 отсортированных котировок

  // Загружаем котировки в quotesSet
  Future<void> _loadQuotes() async {
    var request = http.Request(
        'POST', Uri.parse('https://finviz.com/api/map_perf.ashx?t=sec&st=w4'));
    http.StreamedResponse response = await request.send();
    if (response.statusCode == 200) {
      String loadedQuotes = await response.stream.bytesToString();
      var t = json.decode(loadedQuotes);
      quotesSet = t['nodes'];
    }
  }

  // Сортируем котировки. Добавляем 20 сортированных в список
  void _createSortedList() {
    if (quotesSet.length > 1) {
      sortedSet = [];
      for (int i = 0; i < 20; i++) {
        sortedSet.add(const Quote('none', 9999));
      }
      quotesSet.forEach((key, value) {
        final Quote quote = Quote(key, value);
        for (int i = 0; i < 20; i++) {
          if (Quote.isFirstQuoteLessThenSecond(quote, sortedSet[i])) {
            sortedSet.insert(i, quote);
            sortedSet.removeLast();
            break;
          }
        }
      });
    }
  }

  // Главный метод, который запускает остальные методы в правильном порядке
  void _orderMethod() {
    debugPrint('Начинаем');
    _loadQuotes().then((_) {
      debugPrint('Загрузка прошла, теперь сортируем.');
      _createSortedList();
      debugPrint('Отсортировали. Обновляем стейт');
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    Iterable<Widget> setText() {
      List<Widget> texts = [];
      for (var element in sortedSet) {
        texts.add(Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${element.name} : ${element.value}'),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TicketInfoPage(
                      ticket: element.name,
                    ),
                  ),
                );
              },
              icon: Icon(Icons.auto_graph_outlined),
            ),
          ],
        ));
      }
      for (int i = 0; i < 19; i++) {}
      return texts;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (sortedSet.length == 1)
                Text('${sortedSet[0].name} : ${sortedSet[0].value}')
              else
                ...setText()
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _orderMethod,
        tooltip: 'Get',
        child: const Icon(Icons.download_for_offline_outlined),
      ),
    );
  }
}

class TicketInfoPage extends StatelessWidget {
  final String ticket;
  const TicketInfoPage({Key? key, required this.ticket}) : super(key: key);

  Future<Widget?> getChart(String ticket) async {
    var request = http.Request(
        'GET',
        Uri.parse(
            'https://charts2-node.finviz.com/chart.ashx?cs=m&t=$ticket&tf=d&ct=candle_stick'));

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      var binaryImg = await response.stream.toBytes(); //bytesToString();
      var img = Image.memory(binaryImg);
      //debugPrint(img);
      return img;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ticket),
      ),
      body: FutureBuilder(
          future: getChart(ticket),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            List<Widget> children;
            if (snapshot.hasData) {
              children = <Widget>[
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 60,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: snapshot.data,
                )
              ];
            } else if (snapshot.hasError) {
              children = <Widget>[
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text('Error: ${snapshot.error}'),
                )
              ];
            } else {
              children = const <Widget>[
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text('Awaiting result...'),
                )
              ];
            }
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: children,
              ),
            );
          }),
    );
  }
}

class Quote {
  final String name;
  final double value;
  const Quote(this.name, this.value);

  static bool isFirstQuoteLessThenSecond(Quote a, Quote b) {
    return a.value < b.value ? true : false;
  }
}
