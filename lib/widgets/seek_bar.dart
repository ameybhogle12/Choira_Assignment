import 'package:flutter/material.dart';

class SeekBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  const SeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  // While the user is dragging, show the drag value instead of the live
  // position stream - otherwise the thumb fights the player every frame.
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final durationMs = widget.duration.inMilliseconds;
    final maxMs = durationMs > 0 ? durationMs.toDouble() : 1.0;
    final positionMs =
        widget.position.inMilliseconds.clamp(0, maxMs.toInt()).toDouble();

    return Column(
      children: [
        Slider(
          value: _dragValue ?? positionMs,
          max: maxMs,
          onChanged: durationMs > 0
              ? (value) => setState(() => _dragValue = value)
              : null,
          onChangeEnd: durationMs > 0
              ? (value) {
                  widget.onSeek(Duration(milliseconds: value.toInt()));
                  setState(() => _dragValue = null);
                }
              : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_format(widget.position)),
              Text(_format(widget.duration)),
            ],
          ),
        ),
      ],
    );
  }

  String _format(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
