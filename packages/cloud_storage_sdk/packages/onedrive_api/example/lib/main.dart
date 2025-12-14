import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:onedrive_api/onedrive_rest_api.dart';

void main() async {
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final account = OAuth2Account(appPrefix: "dropbox_api_client");
  final service = "microsoft";

  @override
  void initState() {
    var ms = Microsoft(
      clientId: dotenv.env["ONEDRIVE_CLIENT_ID"]!,
      redirectUri: "aircomix://${dotenv.env["ONEDRIVE_CLIENT_ID"]!}/",
      scopes: [
        "User.Read",
        "Files.ReadWrite.All",
        "Files.Read.All",
        "openid",
        "email",
        "offline_access",
      ],
    );

    if (Platform.isMacOS) {
      ms = Microsoft(
        clientId: dotenv.env["ONEDRIVE_CLIENT_ID"]!,
        redirectUri: "http://localhost:8713/pobpob",
        scopes: [
          "User.Read",
          "Files.ReadWrite.All",
          "Files.Read.All",
          "openid",
          "email",
          "offline_access",
        ],
      );
    }

    account.addProvider(ms);

    super.initState();
  }

  int _counter = 0;

  Future<List<OneDriveDriveItem>> listFiles(
    OneDriveApi api,
    String path, {
    int pageSize = 1,
  }) async {
    List<OneDriveDriveItem> items = [];
    var response = await api.listChildren(path);
    items.addAll(response.value);

    while (response.hasMore) {
      response = await api.listChildren(path, nextLink: response.nextLink);
      items.addAll(response.value);
    }

    return items;
  }

  void _incrementCounter() async {
    var token = await account.any(service: service);
    token ??= await account.newLogin(service);
    if (token?.timeToLogin ?? false) {
      token = await account.forceRelogin(token!);
    }

    if (token == null) throw Exception("login frist");
    var client = await account.createClient(token);

    OneDriveApi drive = OneDriveRestApi(client);

    /*
    var list = await listFiles(drive, "추억/개발");
    for (var item in list) {
      debugPrint(item.name);
      if (item.isFile) {
        var stream = await drive.download(item.name);
        var size = await stream.length;
        debugPrint("${item.name} =  $size");
        break;
      }
    }
    
    var uploaded = await drive.upload(
      "/추억/ㄱㄴㄷ.txt",
      Stream.value(utf8.encode("test2")),
    );
    debugPrint(uploaded.name);
    */

    //await drive.move("/ㄱㄴㄷ2.txt", "/추억/ㄱㄴㄷ7.txt");
    var folder = await drive.createFolder('/test13579');
    debugPrint(folder.name);

    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
