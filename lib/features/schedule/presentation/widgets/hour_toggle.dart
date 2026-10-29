import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';

/// The hour switch.
///
/// The track is red when the hour is off (empty or done) and green when the
/// item is in place. The knob is yellow and sits above the track with a shadow.
///
/// Both shadows are neutral black: the knob's lift is depth, not light, so the
/// switch never tints the card around it.
class HourToggle extends StatelessWidget {
  const HourToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  /// True means on: the item is in place.
  final bool value;
  final VoidCallback onChanged;
  final String? semanticLabel;

  static const double _trackWidth = 52;
  static const double _trackHeight = 30;
  static const double _knob = 24;

  @override
  Widget build(BuildContext context) {
    final StatusPalette palette = StatusPalette.of(context);

    return Semantics(
      toggled: value,
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          onChanged();
        },
        child: SizedBox(
          width: 56,
          height: Insets.touch,
          child: Center(
            child: AnimatedContainer(
              duration: Motion.fast,
              curve: Motion.state,
              width: _trackWidth,
              height: _trackHeight,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: value ? palette.active : palette.completed,
                borderRadius: BorderRadius.circular(_trackHeight),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: AnimatedAlign(
                duration: Motion.fast,
                curve: Motion.state,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: _knob,
                  height: _knob,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[Color(0xFFFFE082), Color(0xFFF2B705)],
                    ),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x59000000),
                        blurRadius: 6,
                        spreadRadius: 0.5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
