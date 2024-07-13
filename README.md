<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

OverlayStack provides an easier way to manage global layers.

## Usage

Simply provide a key (usually a `GlobalKey<NavigatorState>`) to OverlayStack.create(key). This will add OverlayStack as an OverlayEntry at the location provided.

```dart
final navigatorKey = GlobalKey<NavigatorState>();
OverlayStack.create(navigatorKey);
OverlayStack.add((context) => Text('This is appearing from OverlayStack!'));
OverlayStack.destroy();
```