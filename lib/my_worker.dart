import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart';

@JS()
external JSObject get globalThis;

void main() {
  final DedicatedWorkerGlobalScope globalScope =
      globalThis as DedicatedWorkerGlobalScope;

  globalScope.onmessage =
      (MessageEvent event) {
        final JSAny? data = event.data;
        console.log('Worker received: $data'.toJS);

        if (data != null && data.isA<JSNumber>()) {
          final int receivedNum = (data as JSNumber).toDartInt;
          console.log('Worker starting calculation...'.toJS);

          unawaited(
            Future.delayed(const Duration(seconds: 3)).then((_) {
              final int result = receivedNum * 2;
              console.log('Worker finished calculation, sending: $result'.toJS);

              globalScope.postMessage(result.toJS);
            }),
          );
        } else {
          console.log('Worker received invalid data type.'.toJS);
          globalScope.postMessage('Invalid data type received'.toJS);
        }
      }.toJS;

  console.log('Worker initialized'.toJS);
  globalScope.postMessage('Worker Ready'.toJS);
}
