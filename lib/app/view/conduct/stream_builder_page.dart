import 'dart:async';

import 'package:flutter/material.dart';

class StreamBuilderPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _StreamBuilderPageState();
  }
}

class _StreamBuilderPageState extends State<StreamBuilderPage> {
  var _streamController = StreamController<String>.broadcast();
  Stream<String> get _stream => _streamController.stream;
  StreamSubscription? _streamSubscription;
  @override
  void initState() {
    super.initState();
    _streamSubscription = _stream.listen(
          (event) => print('Event: $event'),
      onDone: () => print('Done'),

      onError: (error) => print(error),
    );

  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  int a = 0;
  void _ok() async {
    for (var i = 0; i < 5; i++) {
      if (a == 1) {print(i);break;}
      await Future.delayed(Duration(seconds: 1));
      _streamController.sink.add('OK $i');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Counter"),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder(
                stream: _stream,
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.hasData) {
                    return Container(
                      child: Text(
                        snapshot.data.toString(),
                      ),
                    );
                  }
                  return CircularProgressIndicator();
                }),
            ElevatedButton(
                onPressed: () async {
                  //a = 1;
                  //_streamController.sink.add('CANCEL');
                  await _streamSubscription!.cancel();
                },
                child: Text('STOP'))
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          a= 0;

          _ok();
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
