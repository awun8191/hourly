import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';

/// The hour switch, Moss on bark.
///
/// Flat fills only, no gradient, no glow. The off track is bark with a 1.5px
/// border; the on track is moss with no border. The knob is a solid 24 circle
/// on a 52x30 pill.
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
  static const double _offBorderWidth = 1.5;

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
                color: value ? palette.switchOn : palette.switchOff,
                borderRadius: BorderRadius.circular(_trackHeight),
                border: value
                    ? null
                    : Border.all(
                        color: palette.switchBorderOff,
                        width: _offBorderWidth,
                      ),
              ),
              child: AnimatedAlign(
                duration: Motion.fast,
                curve: Motion.state,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: _knob,
                  height: _knob,
                  decoration: BoxDecoration(
                    color: value
                        ? palette.switchKnobOn
                        : palette.switchKnobOff,
                    shape: BoxShape.circle,
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
