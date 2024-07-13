library overlaystack;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef OverlayWidgetBuilder = Widget Function(BuildContext);

class _Notifier<T> extends ChangeNotifier implements ValueListenable<T> {
  T _value;

  _Notifier(this._value) {
    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
    }
  }

  notify() => notifyListeners();

  @override
  T get value => _value;

  set value(T newValue) {
    if (_value == newValue) return;

    _value = newValue;
    notify();
  }

  set force(T newValue) {
    _value = newValue;
    notify();
  }

  set ignore(T newValue) {
    _value = newValue;
  }

  @override
  String toString() => '${describeIdentity(this)}($value)';
}

class _NotifierBuilder<T> extends StatefulWidget {
  final _Notifier<T> notifier;
  final ValueWidgetBuilder<T> builder;
  final Widget? child;

  const _NotifierBuilder({
    super.key,
    required this.notifier,
    required this.builder,
    this.child,
  });

  @override
  State<_NotifierBuilder<T>> createState() => _NotifierBuilderState<T>();
}

class _NotifierBuilderState<T> extends State<_NotifierBuilder<T>> {
  late T value;

  @override
  void initState() {
    super.initState();
    value = widget.notifier.value;
    widget.notifier.addListener(_update);
  }

  @override
  void didUpdateWidget(_NotifierBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notifier != widget.notifier) {
      oldWidget.notifier.removeListener(_update);
      value = widget.notifier.value;
      widget.notifier.addListener(_update);
    }
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_update);
    super.dispose();
  }

  void _update() => setState(() => value = widget.notifier.value);

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, value, widget.child);
  }
}

/// A `Stack` that simplifies global overlays by using indexing rather than
/// nesting. Example usage:
/// ```dart
/// @override
/// void initState() {
///   super.initState();
///   OverlayStack.create(navigatorKey);
/// }
///
/// @override
/// void dispose() {
///   OverlayStack.destroy();
///   super.dispose();
/// }
///
/// @override
/// Widget build(BuildContext context) {
///   return Container(
///     alignment: Alignment.center,
///     color: Colors.red,
///     child: GestureDetector(
///       onTap: () => OverlayStack.add((context) {
///         return Container(
///           width: 200,
///           height: 200,
///           color: Colors.blue.withOpacity(0.1),
///         );
///       }),
///       child: Text('Add an overlay'),
///     ),
///   );
/// }
/// ```
class OverlayStack extends StatefulWidget {
  const OverlayStack({super.key});

  static final _Notifier<List<_Notifier<OverlayWidgetBuilder>>> _layers = _Notifier([]);
  static OverlayEntry? _overlay;

  /// Attempts to insert `OverlayStack` into the `Navigator`'s currentState
  /// overlay. Returns `true` if `OverlayStack` was successfully added, and
  /// `false` otherwise.
  static bool create(
    GlobalKey<NavigatorState> key, {
    Widget Function(Widget child)? builder,
    GlobalKey? stackKey,
    ThemeData? theme,
  }) {
    destroy();

    final stack = OverlayStack(key: stackKey);
    _overlay = OverlayEntry(
      builder: (_) => builder != null ? builder(stack) : stack,
    );

    bool success = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (key.currentState?.overlay == null) {
        _overlay = null;
        return;
      }

      key.currentState!.overlay!.insert(_overlay!);
      success = true;
    });

    return success;
  }

  /// Attempts to remove `OverlayStack`. This function is a noop if
  /// `OverlayStack` isn't inserted.
  static void destroy() {
    if (_overlay == null) return;

    _overlay!.remove();
    _overlay!.dispose();
    _overlay = null;
  }

  /// Returns a read-only copy of the current layers. This method is relatively
  /// expensive (O(n)). To find the number of layers, it's more efficient to
  /// use `layerCount`.
  static List<OverlayWidgetBuilder> get layers => List.unmodifiable(_layers.value);

  /// Returns the current number of layers.
  static int get layerCount => _layers.value.length;

  /// Returns the index of the layer whose builder matches
  /// `OverlayWidgetBuilder`, or `-1` if no such `OverlayWidgetBuilder` is
  /// found (or none was provided).
  static int find(OverlayWidgetBuilder? builder) {
    if (builder == null) return -1;
    return _layers.value.indexWhere((_Notifier<OverlayWidgetBuilder> w) => w.value == builder);
  }

  /// Returns `true` if a layer matching `OverlayWidgetBuilder` is present in
  /// `OverlayStack`, `false` otherwise.
  static bool exists(OverlayWidgetBuilder? builder) {
    return find(builder) != -1;
  }

  /// Appends a layer whose builder is given by `OverlayWidgetBuilder` to
  /// `OverlayStack` and returns its index.
  static int add(OverlayWidgetBuilder builder) {
    _layers.value.add(_Notifier(builder));
    _layers.notify();

    return _layers.value.length - 1;
  }

  /// Inserts a layer whose builder is given by `OverlayWidgetBuilder` into
  /// `OverlayStack` at the given index.
  static void insert(int index, OverlayWidgetBuilder? builder) {
    if (builder == null) return;

    _layers.value.insert(index, _Notifier(builder));
    _layers.notify();
  }

  /// Removes the layer whose builder is given by `OverlayWidgetBuilder` from
  /// `OverlayStack`, if it exists.
  static void remove(OverlayWidgetBuilder? builder) {
    if (builder == null) return;

    final index = find(builder);
    if (index != -1) removeAt(index);
  }

  /// Removes and returns the `OverlayWidgetBuilder` of the layer at the given
  /// index.
  static OverlayWidgetBuilder removeAt(int index) {
    final removed = _layers.value.removeAt(index);
    _layers.notify();
    final value = removed.value;
    removed.dispose();
    return value;
  }

  /// Removes and returns the `OverlayWidgetBuilder` of the last layer.
  static OverlayWidgetBuilder removeLast() {
    return removeAt(_layers.value.length - 1);
  }

  /// Triggers a redraw of the layer whose builder is given by
  /// `OverlayWidgetBuilder`.
  static void refresh(OverlayWidgetBuilder? builder) {
    if (builder == null) return;

    final index = find(builder);
    if (index != -1) refreshAt(index);
  }

  /// Triggers a redraw of the layer at the given index.
  static void refreshAt(int index) {
    _layers.value[index].notify();
  }

  /// Removes all layers from `OverlayStack`.
  static void clear() {
    while (_layers.value.isNotEmpty) {
      final removed = _layers.value.removeLast();
      removed.dispose();
    }
    _layers.notify();
  }

  @override
  State<OverlayStack> createState() => _OverlayStackState();
}

class _OverlayStackState extends State<OverlayStack> {
  void _update() {
    // Post-frame callback prevents dual setState errors if user sets state.
    // Equivalent to how OverlayEntry uses markNeedsBuild.

    WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {}));
    WidgetsBinding.instance.scheduleFrame();
  }

  @override
  void initState() {
    super.initState();
    OverlayStack._layers.addListener(_update);
  }

  @override
  void dispose() {
    OverlayStack._layers.removeListener(_update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> list = [];

    for (_Notifier<OverlayWidgetBuilder> notifier in OverlayStack._layers.value) {
      list.add(_NotifierBuilder(
        notifier: notifier,
        builder: (BuildContext context, _, __) => notifier.value(context),
      ));
    }

    return Stack(
      alignment: Alignment.center,
      children: list,
    );
  }
}
