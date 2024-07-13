import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:overlaystack/overlaystack.dart';

final navigator = GlobalKey<NavigatorState>();

void main() {
  test('adds one to input values', () {
    runApp(MaterialApp(
      navigatorKey: navigator,
      home: const Main(),
    ));
    // final calculator = Calculator();
    // expect(calculator.addOne(2), 3);
    // expect(calculator.addOne(-7), -6);
    // expect(calculator.addOne(0), 1);
  });
}

class Main extends StatefulWidget {
  const Main({super.key});

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> {
  @override
  void initState() {
    super.initState();
    OverlayStack.create(navigator);
  }

  @override
  void dispose() {
    OverlayStack.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      color: Colors.red,
      child: GestureDetector(
        onTap: () => OverlayStack.add((context) {
          return Container(
            width: 200,
            height: 200,
            color: Colors.blue.withOpacity(0.1),
          );
        }),
        child: Text('Add an overlay'),
      ),
    );
  }
}
