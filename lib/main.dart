import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';
import 'package:violet_issue/script_manager.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ScriptManager.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<GlobalKey>? _keys;
  HttpClient? hc;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: FutureBuilder(
        future: Future.value(0).then((value) async {
          const target = 1249129;

          final imgs = await ScriptManager.runHitomiGetImageList(target);
          final header =
              await ScriptManager.runHitomiGetHeaderContent(target.toString());

          _keys =
              List<GlobalKey>.generate(imgs!.length, (index) => GlobalKey());

          return Tuple2(imgs, header);
        }),
        builder: (context,
            AsyncSnapshot<Tuple2<List<String>?, Map<String, String>>>
                snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();

          final data = snapshot.data!;

          return ListView.builder(
            itemCount: data.item1!.length,
            itemExtent: 300.0,
            itemBuilder: ((context, index) {
              return Image.network(
                data.item1![index],
                key: _keys![index],
                headers: data.item2,
                cacheHeight: 500,
                fit: BoxFit.fitWidth,
                loadingBuilder: (context, widget, chunk) {
                  return SizedBox(
                    height: 300.0,
                    child: widget,
                  );
                },
                errorBuilder: (context, error, st) {
                  if (kDebugMode) {
                    print(error);
                  }

                  return SizedBox(
                    height: 300.0,
                    child: Center(
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: IconButton(
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.black,
                            ),
                            onPressed: () {
                              hc ??= HttpClient()..autoUncompress = false;
                              hc!
                                  .getUrl(Uri.parse(data.item1![index]))
                                  .then((e) async {
                                data.item2.forEach((String name, String value) {
                                  e.headers.add(name, value);
                                });
                                final HttpClientResponse response =
                                    await e.close();
                                if (kDebugMode) {
                                  print(response.statusCode);
                                }
                              });

                              http
                                  .get(Uri.parse(data.item1![index]),
                                      headers: data.item2)
                                  .then((res) => print(res.contentLength));

                              setState(() {
                                _keys![index] = GlobalKey();
                              });
                            }),
                      ),
                    ),
                  );
                },
              );
            }),
          );
        },
      ),
    );
  }
}
