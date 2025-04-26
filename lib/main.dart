import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Flutter Demo',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
    ),
    home: const MyHomePage(title: 'Flutter Demo Home Page'),
  );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({required this.title, super.key});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Worker 1 (Compiled Dart)
  web.Worker? _dartWorker;
  String _dartWorkerResult = 'Dart Worker: No result yet.';
  bool _dartWorkerReady = false;
  int _dartCounter = 0;

  // Worker 2 (Pure JS)
  web.Worker? _jsWorker;
  String _jsWorkerResult = 'JS Worker: No result yet.';
  bool _jsWorkerReady = false;
  int _jsCounter = 100; // Start JS counter differently for distinction

  @override
  void initState() {
    super.initState();
    _initDartWorker();
    _initJsWorker();
  }

  @override
  void dispose() {
    _dartWorker?.terminate();
    _jsWorker?.terminate();
    super.dispose();
  }

  // --- Dart Worker Initialization and Handling ---
  void _initDartWorker() {
    _dartWorker = web.Worker('my_worker.dart.js'.toJS);
    // Assign the result of the helper, which now returns the correct type
    _dartWorker?.onmessage = _createMessageHandler(
      'Dart Worker',
      (result) {
        _dartWorkerResult = result;
      },
      // Pass the callback matching the named parameter signature
      ({required bool isReady}) {
        _dartWorkerReady = isReady;
      },
    );
    // Assign the result of the helper, which now returns the correct type
    _dartWorker?.onerror = _createErrorHandler('Dart Worker', (result) {
      _dartWorkerResult = result;
    });
  }

  void _sendToDartWorker() {
    if (_dartWorker != null && _dartWorkerReady) {
      setState(() {
        _dartCounter++;
        _dartWorkerResult = 'Dart Worker: Sent $_dartCounter...';
      });
      _dartWorker!.postMessage(_dartCounter.toJS);
    } else {
      setState(() {
        _dartWorkerResult = 'Dart Worker not ready.';
      });
    }
  }

  // --- JS Worker Initialization and Handling ---
  void _initJsWorker() {
    _jsWorker = web.Worker('my_other_worker.js'.toJS);
    // Assign the result of the helper, which now returns the correct type
    _jsWorker?.onmessage = _createMessageHandler(
      'JS Worker',
      (result) {
        _jsWorkerResult = result;
      },
      // Pass the callback matching the named parameter signature
      ({required bool isReady}) {
        _jsWorkerReady = isReady;
      },
    );
    // Assign the result of the helper, which now returns the correct type
    _jsWorker?.onerror = _createErrorHandler('JS Worker', (result) {
      _jsWorkerResult = result;
    });
  }

  void _sendToJsWorker() {
    if (_jsWorker != null && _jsWorkerReady) {
      setState(() {
        _jsCounter++;
        _jsWorkerResult = 'JS Worker: Sent $_jsCounter...';
      });
      _jsWorker!.postMessage(_jsCounter.toJS);
    } else {
      setState(() {
        _jsWorkerResult = 'JS Worker not ready.';
      });
    }
  }

  // --- Generic Message/Error Handlers ---
  // Update the return type to the specific EventHandler type alias
  web.EventHandler _createMessageHandler(
    String workerName,
    void Function(String) setResult,
    // Change the function signature to expect a named 'isReady' parameter
    void Function({required bool isReady}) setReady,
  ) =>
      (web.Event event) {
        // EventHandler expects web.Event
        // Cast event to MessageEvent to access data
        final web.MessageEvent messageEvent = event as web.MessageEvent;
        final JSAny? data = messageEvent.data;
        debugPrint('$workerName received: $data');

        setState(() {
          if (data != null &&
              data.isA<JSString>() &&
              (data as JSString).toDart == 'Worker Ready') {
            // Call setReady using the named parameter
            setReady(isReady: true);
            setResult('$workerName is ready. Click button to send.');
          } else if (data != null && data.isA<JSNumber>()) {
            setResult(
              '$workerName calculated: ${(data as JSNumber).toDartInt}',
            );
          } else if (data != null && data.isA<JSString>()) {
            setResult('$workerName responded: ${(data as JSString).toDart}');
          } else {
            setResult('$workerName received unknown data type.');
          }
        });
      }.toJS; // Convert the outer function to JS

  // Update the return type to the specific EventHandler type alias
  web.EventHandler _createErrorHandler(
    String workerName,
    void Function(String) setResult,
  ) =>
      (web.Event event) {
        debugPrint('Error from $workerName: $event');
        setState(() {
          setResult('Error communicating with $workerName.');
        });
      }.toJS; // Convert the outer function to JS

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: Text(widget.title),
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Dart Worker Section
            Text('Dart Worker Counter: $_dartCounter'),
            const SizedBox(height: 8),
            Text(
              _dartWorkerResult,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _sendToDartWorker,
              child: const Text('Send to Dart Worker'),
            ),

            const Divider(height: 40),

            // JS Worker Section
            Text('JS Worker Counter: $_jsCounter'),
            const SizedBox(height: 8),
            Text(
              _jsWorkerResult,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _sendToJsWorker,
              child: const Text('Send to JS Worker'),
            ),
          ],
        ),
      ),
    ),
  );
}
