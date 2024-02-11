import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const double _kThumbWidth = 100;

class CustomSwitch extends StatefulWidget {
  const CustomSwitch({
    required this.initialValue,
    required this.activeText,
    required this.inactiveText,
    super.key,
    this.onChanged,
    this.thumbWidth,
    this.backgroundColor,
    this.activeColor,
    this.inactiveColor,
    this.focusNode,
    this.autofocus = false,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.fastOutSlowIn,
  });

  final bool? initialValue;
  final String activeText;
  final String inactiveText;
  final ValueChanged<bool>? onChanged;

  final double? thumbWidth;
  final Color? backgroundColor;
  final Color? activeColor;
  final Color? inactiveColor;
  final FocusNode? focusNode;
  final bool autofocus;

  final Duration duration;
  final Curve curve;

  @override
  State<CustomSwitch> createState() => _CustomSwitchState();
}

class _CustomSwitchState extends State<CustomSwitch>
    with TickerProviderStateMixin {
  final _painter = _SwitchPainter();

  late final _actionMap = <Type, Action<Intent>>{
    ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
      onInvoke: (_) => _handleEnterAction(),
    ),
  };

  late final AnimationController _positionController;

  late final CurvedAnimation _position;

  late final MaterialStateProperty<MouseCursor> _effectiveMouseCursor;

  late final FocusNode _effectiveFocusNode;

  late bool? _value;

  late Size _trackSize;

  late Size _thumbSize;

  bool get _isInteractive => widget.onChanged != null;

  Set<MaterialState> get states => <MaterialState>{
        if (!_isInteractive) MaterialState.disabled,
        if (_effectiveFocusNode.hasFocus) MaterialState.focused,
        if (_value ?? false) MaterialState.selected,
      };

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
    _positionController = AnimationController(
      duration: widget.duration,
      value: (widget.initialValue ?? false) ? 1.0 : 0.0,
      vsync: this,
    );
    _position = CurvedAnimation(
      parent: _positionController,
      curve: widget.curve,
      reverseCurve: widget.curve.flipped,
    );
    _effectiveMouseCursor = MaterialStateProperty.resolveWith(
      (states) => MaterialStateProperty.resolveAs(
        MaterialStateMouseCursor.clickable,
        states,
      ),
    );
    _effectiveFocusNode = widget.focusNode ?? FocusNode();
    final thumbWidth = widget.thumbWidth ?? _kThumbWidth;
    _trackSize = Size(
      thumbWidth * 2,
      kMinInteractiveDimension,
    );
    _thumbSize = Size(
      thumbWidth,
      kMinInteractiveDimension,
    );
  }

  @override
  void dispose() {
    _positionController.dispose();
    _painter.dispose();
    super.dispose();
  }

  void _jumpTo(bool value) {
    if (value) {
      if (_positionController.value != 1.0) {
        _positionController.value = 1.0;
      }
    } else {
      if (_positionController.value != 0.0) {
        _positionController.value = 0.0;
      }
    }
  }

  void _animateTo(bool value) {
    if (value) {
      if (_positionController.value != 1.0) {
        _positionController.forward();
      }
    } else {
      if (_positionController.value != 0.0) {
        _positionController.reverse();
      }
    }
  }

  void _requestFocus() {
    if (!_effectiveFocusNode.hasFocus) {
      _effectiveFocusNode.requestFocus();
    }
  }

  void _handleChanged(bool value) {
    widget.onChanged?.call(value);

    _requestFocus();

    setState(() => _value = value);
  }

  void _selectValue(bool value) {
    if (value == _value) {
      return;
    }

    _position
      ..curve = widget.curve
      ..reverseCurve = widget.curve.flipped;

    if (_value == null) {
      _jumpTo(value);
    }

    _handleChanged(value);
  }

  void _handleEnterAction() {
    if (_value == null) {
      _selectValue(false);
    } else {
      _selectValue(!_value!);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    final newValue = details.localPosition.dx >= _trackSize.width / 2;

    _selectValue(newValue);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_value == null) {
      return;
    }

    _requestFocus();

    _position
      ..curve = Curves.linear
      ..reverseCurve = null;

    _positionController.value += details.primaryDelta! / _thumbSize.width;
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_value == null) {
      return;
    }

    _position
      ..curve = widget.curve
      ..reverseCurve = widget.curve.flipped;

    final newValue = _position.value >= 0.5;

    if (newValue != _value) {
      _handleChanged(newValue);
    } else {
      _animateTo(_value!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_value != null) {
      _animateTo(_value!);
    }

    return FocusableActionDetector(
      actions: _actionMap,
      focusNode: _effectiveFocusNode,
      autofocus: widget.autofocus,
      enabled: _isInteractive,
      mouseCursor: _effectiveMouseCursor.resolve(states),
      child: GestureDetector(
        excludeFromSemantics: true,
        onTapUp: _isInteractive ? _handleTapUp : null,
        onHorizontalDragUpdate: _isInteractive ? _handleDragUpdate : null,
        onHorizontalDragEnd: _isInteractive ? _handleDragEnd : null,
        child: CustomPaint(
          size: _trackSize,
          painter: _painter
            ..hasValue = _value != null
            ..isFocused = _effectiveFocusNode.hasFocus
            ..positionController = _positionController
            ..position = _position
            ..thumbSize = _thumbSize
            ..activeText = widget.activeText
            ..inactiveText = widget.inactiveText
            ..trackColor =
                widget.backgroundColor ?? Theme.of(context).colorScheme.surface
            ..activeColor =
                widget.activeColor ?? Theme.of(context).colorScheme.primary
            ..inactiveColor =
                widget.inactiveColor ?? Theme.of(context).colorScheme.secondary
            ..textColor = Theme.of(context).colorScheme.onSurface
            ..activeTextColor = Theme.of(context).colorScheme.onPrimary
            ..inactiveTextColor = Theme.of(context).colorScheme.onSecondary,
        ),
      ),
    );
  }
}

class _SwitchPainter extends ChangeNotifier implements CustomPainter {
  bool get hasValue => _hasValue!;
  bool? _hasValue;

  set hasValue(bool value) {
    if (value == _hasValue) {
      return;
    }
    _hasValue = value;
    notifyListeners();
  }

  bool get isFocused => _isFocused!;
  bool? _isFocused;

  set isFocused(bool value) {
    if (value == _isFocused) {
      return;
    }
    _isFocused = value;
    notifyListeners();
  }

  AnimationController get positionController => _positionController!;
  AnimationController? _positionController;

  set positionController(AnimationController? value) {
    assert(value != null, 'AnimationController must not be null.');
    if (value == _positionController) {
      return;
    }
    _positionController = value;
    notifyListeners();
  }

  CurvedAnimation get position => _position!;
  CurvedAnimation? _position;

  set position(CurvedAnimation value) {
    if (value == _position) {
      return;
    }
    _position?.removeListener(notifyListeners);
    value.addListener(notifyListeners);
    _position = value;
    notifyListeners();
  }

  String get activeText => _activeText!;
  String? _activeText;

  set activeText(String value) {
    if (value == _activeText) {
      return;
    }
    _activeText = value;
    notifyListeners();
  }

  String get inactiveText => _inactiveText!;
  String? _inactiveText;

  set inactiveText(String value) {
    if (value == _inactiveText) {
      return;
    }
    _inactiveText = value;
    notifyListeners();
  }

  Size get thumbSize => _thumbSize!;
  Size? _thumbSize;

  set thumbSize(Size value) {
    if (value == _thumbSize) {
      return;
    }
    _thumbSize = value;
    notifyListeners();
  }

  Color get trackColor => _trackColor!;
  Color? _trackColor;

  set trackColor(Color value) {
    if (value == _trackColor) {
      return;
    }
    _trackColor = value;
    notifyListeners();
  }

  Color get activeColor => _activeColor!;
  Color? _activeColor;

  set activeColor(Color value) {
    if (value == _activeColor) {
      return;
    }
    _activeColor = value;
    notifyListeners();
  }

  Color get inactiveColor => _inactiveColor!;
  Color? _inactiveColor;

  set inactiveColor(Color value) {
    if (value == _inactiveColor) {
      return;
    }
    _inactiveColor = value;
    notifyListeners();
  }

  Color get textColor => _textColor!;
  Color? _textColor;

  set textColor(Color value) {
    if (value == _textColor) {
      return;
    }
    _textColor = value;
    notifyListeners();
  }

  Color get activeTextColor => _activeTextColor!;
  Color? _activeTextColor;

  set activeTextColor(Color value) {
    if (value == _activeTextColor) {
      return;
    }
    _activeTextColor = value;
    notifyListeners();
  }

  Color get inactiveTextColor => _inactiveTextColor!;
  Color? _inactiveTextColor;

  set inactiveTextColor(Color value) {
    if (value == _inactiveTextColor) {
      return;
    }
    _inactiveTextColor = value;
    notifyListeners();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final currentValue = CurvedAnimation(
      parent: positionController,
      curve: position.curve,
      reverseCurve: position.curve.flipped,
    ).value;

    _paintTrack(canvas, size, trackColor);

    final foregroundColor =
        Color.lerp(inactiveColor, activeColor, currentValue)!;
    if (hasValue) {
      _paintThumb(
        canvas,
        Offset(size.width / 2 * position.value, 0),
        Size(size.width / 2, size.height),
        foregroundColor,
      );
    }

    _paintBorder(canvas, size, foregroundColor);

    final effectiveInactiveTextColor = !hasValue
        ? textColor
        : Color.lerp(inactiveTextColor, textColor, currentValue)!;
    _paintText(
      canvas,
      inactiveText,
      Rect.fromLTWH(0, 0, size.width / 2, size.height),
      effectiveInactiveTextColor,
    );

    final effectiveActiveTextColor = !hasValue
        ? textColor
        : Color.lerp(textColor, activeTextColor, currentValue)!;
    _paintText(
      canvas,
      activeText,
      Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height),
      effectiveActiveTextColor,
    );
  }

  void _paintTrack(Canvas canvas, Size size, Color color) {
    final paint = Paint()..color = color;
    final rect = Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height,
    );
    final rRect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(8),
    );
    canvas.drawRRect(rRect, paint);
  }

  void _paintBorder(Canvas canvas, Size size, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rRect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(8),
    );
    canvas.drawRRect(rRect, paint);
  }

  void _paintThumb(Canvas canvas, Offset offset, Size size, Color color) {
    final paint = Paint()..color = color;
    final rect = Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);
    final rRect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(8),
    );
    canvas.drawRRect(rRect, paint);
  }

  void _paintText(Canvas canvas, String text, Rect rect, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: rect.width, maxWidth: rect.width);
    textPainter.paint(
      canvas,
      Offset(
        rect.center.dx - textPainter.width / 2,
        rect.center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  void dispose() {
    _position?.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  @override
  bool? hitTest(Offset position) => null;

  @override
  SemanticsBuilderCallback? get semanticsBuilder => null;

  @override
  bool shouldRebuildSemantics(covariant CustomPainter oldDelegate) => false;

  @override
  String toString() => describeIdentity(this);
}
