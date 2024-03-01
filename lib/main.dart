import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';
import 'package:intl/intl.dart';

void main() {
  print('Debug Log\n');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Giá vàng Hà Nội',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
                seedColor: Color.fromARGB(255, 85, 29, 148)),
            scaffoldBackgroundColor: Color.fromARGB(255, 255, 231, 171)),
        home: _MyHomePageState(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  Map<String, List<num>> goldPrices = {
    'DOJI_SJC': [0, 0],
    'DOJI_NHAN': [0, 0],
    'PNJ_SJC': [0, 0],
    'PNJ_NHAN': [0, 0],
    'SJC_SJC': [0, 0],
    'SJC_NHAN': [0, 0],
    'BTMC_SJC': [0, 0],
    'BTMC_NHAN': [0, 0],
  };

  String updateTime = '';
  String dateFormat = 'HH:mm:ss dd/MM/yyyy';
  bool isLoading = false;

  Future<void> updateDoji() async {
    var responseDoji = await http.get(Uri.parse('http://giavang.doji.vn/'));
    //If the http request is successful the statusCode will be 200
    if (responseDoji.statusCode == 200) {
      String htmlToParse = responseDoji.body;
      var document = parse(htmlToParse);
      var table =
          document.getElementsByClassName('label')[0].parentNode?.parentNode;
      var sjc = table?.children[0];
      var htv = table?.children[2];

      goldPrices['DOJI_SJC']![0] = num.parse(sjc!.children[1].innerHtml);
      goldPrices['DOJI_SJC']![1] = num.parse(sjc.children[2].innerHtml);
      goldPrices['DOJI_NHAN']![0] = num.parse(htv!.children[1].innerHtml);
      goldPrices['DOJI_NHAN']![1] = num.parse(htv.children[2].innerHtml);
    }
  }

  Future<void> updateBtmc() async {
    var responseBtmc = await http
        .get(Uri.parse('https://btmc.vn/bieu-do-gia-vang.html?t=ngay'));
    if (responseBtmc.statusCode == 200) {
      String htmlToParse = responseBtmc.body;
      var document = parse(htmlToParse);
      var table =
          document.getElementsByClassName('bd_price_home')[0].children[0];

      var nhanBuy = table.children[2].children[2].children[0].innerHtml.trim();
      var nhanSell = table.children[2].children[3].children[0].innerHtml.trim();
      var sjcBuy = table.children[4].children[3].children[0].innerHtml.trim();
      var sjcSell = table.children[4].children[4].children[0].innerHtml.trim();

      goldPrices['BTMC_SJC']![0] = num.parse(sjcBuy);
      goldPrices['BTMC_SJC']![1] = num.parse(sjcSell);
      goldPrices['BTMC_NHAN']![0] = num.parse(nhanBuy);
      goldPrices['BTMC_NHAN']![1] = num.parse(nhanSell);
    }
  }

  Future<void> updatePnj() async {
    var responsePnj = await http
        .get(Uri.parse('https://www.pnj.com.vn/blog/gia-vang/?zone=11'));
    if (responsePnj.statusCode == 200) {
      String htmlToParse = responsePnj.body;
      var document = parse(htmlToParse);
      var table = document.getElementById('content-price');

      var sjcBuy = table?.children[0].children[1].children[0].innerHtml
          .replaceAll(RegExp('[,]'), '')
          .trim();
      var sjcSell = table?.children[0].children[2].children[0].innerHtml
          .replaceAll(RegExp('[,]'), '')
          .trim();
      var pnjBuy = table?.children[1].children[1].children[0].innerHtml
          .replaceAll(RegExp('[,]'), '')
          .trim();
      var pnjSell = table?.children[1].children[2].children[0].innerHtml
          .replaceAll(RegExp('[,]'), '')
          .trim();

      goldPrices['PNJ_SJC']![0] = num.parse(sjcBuy!);
      goldPrices['PNJ_SJC']![1] = num.parse(sjcSell!);
      goldPrices['PNJ_NHAN']![0] = num.parse(pnjBuy!);
      goldPrices['PNJ_NHAN']![1] = num.parse(pnjSell!);
    }
  }

  Future<void> updateSjc() async {
    var responseSjc =
        await http.get(Uri.parse('https://sjc.com.vn/giavang/textContent.php'));
    if (responseSjc.statusCode == 200) {
      String htmlToParse = responseSjc.body;
      var document = parse(htmlToParse);
      var table = document.getElementsByClassName('bg_bl');
      num kDivisor = 10000;

      var sjcBuy =
          table[0].children[0].innerHtml.replaceAll(RegExp('[,]'), '').trim();
      var sjcSell =
          table[1].children[0].innerHtml.replaceAll(RegExp('[,]'), '').trim();
      var nhanBuy =
          table[6].children[0].innerHtml.replaceAll(RegExp('[,]'), '').trim();
      var nhanSell =
          table[7].children[0].innerHtml.replaceAll(RegExp('[,]'), '').trim();
      goldPrices['SJC_SJC']![0] = num.parse(sjcBuy) ~/ kDivisor;
      goldPrices['SJC_SJC']![1] = num.parse(sjcSell) ~/ kDivisor;
      goldPrices['SJC_NHAN']![0] = num.parse(nhanBuy) ~/ kDivisor;
      goldPrices['SJC_NHAN']![1] = num.parse(nhanSell) ~/ kDivisor;
    }
  }

  void updateGoldPrice() async {
    print('Update gold price');
    isLoading = true;
    notifyListeners();

    try {
      await Future.wait([updateDoji(), updateBtmc(), updatePnj(), updateSjc()]
          as Iterable<Future>);
    } catch (e) {
      print(e);
    }

    updateTime = DateFormat(dateFormat).format(DateTime.now());
    isLoading = false;

    notifyListeners();
  }
}

// class MyHomePage extends StatefulWidget {
//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

class _MyHomePageState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
            backgroundColor: Color.fromARGB(255, 168, 0, 0),
            title: const Text(
              'Bảng giá vàng Hà Nội',
              style: TextStyle(color: Color.fromARGB(255, 255, 217, 0)),
            )),
        body: MainClass(),
      ),
    );
  }
}

class MainClass extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5.0, right: 5.0, bottom: 5.0),
          child: Table(
            border: TableBorder.all(),
            columnWidths: const <int, TableColumnWidth>{
              0: FlexColumnWidth(),
              1: FixedColumnWidth(72),
              2: FixedColumnWidth(72),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: <TableRow>[
              TableRow(
                children: <Widget>[
                  Center(
                    heightFactor: 2,
                    child: Text('Cửa hàng - Loại vàng'),
                  ),
                  Center(
                    child: Text('Giá mua'),
                  ),
                  Center(
                    child: Text('Giá bán'),
                  ),
                ],
              ),
              TableRow(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 5.0),
                    child: Text('DOJI - Vàng miếng SJC'),
                  ),
                  Center(
                    heightFactor: 1.5,
                    child: Text('${appState.goldPrices['DOJI_SJC']![0]}'),
                  ),
                  Center(
                    child: Text('${appState.goldPrices['DOJI_SJC']![1]}'),
                  ),
                ],
              ),
              TableRow(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 5.0),
                    child: Text('DOJI - Vàng nhẫn HTV'),
                  ),
                  Center(
                    heightFactor: 1.5,
                    child: Text('${appState.goldPrices['DOJI_NHAN']![0]}'),
                  ),
                  Center(
                    child: Text('${appState.goldPrices['DOJI_NHAN']![1]}'),
                  ),
                ],
              ),
              TableRow(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 5.0),
                    child: Text('SJC - Vàng miếng 1 lượng'),
                  ),
                  Center(
                    heightFactor: 1.5,
                    child: Text('${appState.goldPrices['SJC_SJC']![0]}'),
                  ),
                  Center(
                    child: Text('${appState.goldPrices['SJC_SJC']![1]}'),
                  ),
                ],
              ),
              TableRow(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Text('SJC - Vàng nhẫn 1 chỉ'),
                  ),
                  Center(
                    heightFactor: 1.5,
                    child: Text('${appState.goldPrices['SJC_NHAN']![0]}'),
                  ),
                  Center(
                    child: Text('${appState.goldPrices['SJC_NHAN']![1]}'),
                  ),
                ],
              ),
              TableRow(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 5.0),
                    child: Text('PNJ - Vàng miếng SJC'),
                  ),
                  Center(
                    heightFactor: 1.5,
                    child: Text('${appState.goldPrices['PNJ_SJC']![0]}'),
                  ),
                  Center(
                    child: Text('${appState.goldPrices['PNJ_SJC']![1]}'),
                  ),
                ],
              ),
              TableRow(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 5.0),
                    child: Text('PNJ - Vàng nhẫn trơn 9999'),
                  ),
                  Center(
                    heightFactor: 1.5,
                    child: Text('${appState.goldPrices['PNJ_NHAN']![0]}'),
                  ),
                  Center(
                    child: Text('${appState.goldPrices['PNJ_NHAN']![1]}'),
                  ),
                ],
              ),
              TableRow(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 5.0),
                    child: Text('BTMC - Vàng miếng SJC'),
                  ),
                  Center(
                    heightFactor: 1.5,
                    child: Text('${appState.goldPrices['BTMC_SJC']![0]}'),
                  ),
                  Center(
                    child: Text('${appState.goldPrices['BTMC_SJC']![1]}'),
                  ),
                ],
              ),
              TableRow(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 5.0),
                    child: Text('BTMC - Vàng nhẫn trơn 9999'),
                  ),
                  Center(
                    heightFactor: 1.5,
                    child: Text('${appState.goldPrices['BTMC_NHAN']![0]}'),
                  ),
                  Center(
                    child: Text('${appState.goldPrices['BTMC_NHAN']![1]}'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Text(
            'Thời gian cập nhật: ${appState.updateTime}',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 120.0),
            child: ElevatedButton.icon(
              onPressed: () => appState.updateGoldPrice(),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 168, 0, 0),
                  foregroundColor: Color.fromARGB(255, 255, 217, 0),
                  padding: const EdgeInsets.all(16.0)),
              icon: appState.isLoading
                  ? Container(
                      width: 24,
                      height: 24,
                      padding: const EdgeInsets.all(2.0),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color.fromARGB(255, 255, 217, 0),
                      ),
                    )
                  : const Icon(Icons.refresh),
              label: const Text('Cập nhật'),
            ),
          ),
        ),
      ],
    );
  }
}
