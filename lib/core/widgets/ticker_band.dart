import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../app/theme.dart';
import '../responsive.dart';

/// PRD section 5.4: "Red band with 'TRAIN HARD ✦ STAY FOCUSED ✦ BE STRONG ✦
/// BE FIT ✦ BE YOU', scrolling, tilted −1.5°." Web and tablet only
/// (PRD section 7.1).
class TickerBand extends StatefulWidget {
  const TickerBand({
    super.key,
    required this.text,
    this.height = 54,
    this.pixelsPerSecond = 58,
  });

  final String text;
  final double height;
  final double pixelsPerSecond;

  @override
  State<TickerBand> createState() => _TickerBandState();
}

class _TickerBandState extends State<TickerBand>
    with SingleTickerProviderStateMixin {
  /// Measures one repetition so the scroll can wrap seamlessly.
  final _segmentKey = GlobalKey();

  Ticker? _ticker;
  Duration _lastTick = Duration.zero;
  double _offset = 0;
  double _segmentWidth = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;

    final measured = _segmentKey.currentContext?.size?.width ?? 0;
    if (measured != _segmentWidth) _segmentWidth = measured;
    if (_segmentWidth <= 0) return;

    // Wrapping at exactly one repetition makes the seam invisible.
    final next = (_offset + widget.pixelsPerSecond * dt) % _segmentWidth;
    setState(() => _offset = next);
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = NHText.display(size: 21, color: Colors.white, height: 1);

    Widget segment(Key? key) => Padding(
      key: key,
      padding: const EdgeInsets.only(right: 34),
      child: Text(widget.text, style: style, maxLines: 1),
    );

    final reduceMotion = context.reduceMotion;
    if (reduceMotion && _ticker?.isActive == true) _ticker?.stop();

    return Transform.rotate(
      // −1.5° (PRD section 5.4).
      angle: -1.5 * math.pi / 180,
      child: Container(
        height: widget.height,
        color: NHColors.red,
        alignment: Alignment.centerLeft,
        child: ClipRect(
          child: ExcludeSemantics(
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              maxWidth: double.infinity,
              child: Transform.translate(
                offset: Offset(reduceMotion ? 0 : -_offset, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    segment(_segmentKey),
                    // A second copy covers the gap the first one leaves behind.
                    segment(null),
                    segment(null),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
