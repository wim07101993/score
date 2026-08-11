import 'package:flutter/material.dart';

import '../app.dart';
import '../data/settings.dart';
import '../notation/score_sheet.dart';

/// What this device prefers.
///
/// More than a preference about chrome: the page a score is read off is set
/// here. A rehearsal room with the lights down and a laptop on a stand is the
/// case all of this exists for — the machine's own theme is often not what the
/// room is, and how dim a page wants to be is a question about the room.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      // Listening to the settings rather than to the app: these are the things
      // that change without anything else about the app having changed, and a
      // control that did not move until something else happened to redraw the
      // page would be the app disagreeing with what it had just been told.
      body: ListenableBuilder(
        listenable: app.settings,
        builder: (context, _) {
          final brightness = Theme.of(context).brightness;
          return Appearance(
            mode: app.settings.themeMode,
            onModeChanged: app.settings.setThemeMode,
            brightness: brightness,
            look: app.settings.pageLook(brightness),
            onLookChanged: (look) =>
                app.settings.setPageLook(brightness, look),
            onLookReset: app.settings.isPageLookDefault(brightness)
                ? null
                : () => app.settings.resetPageLook(brightness),
          );
        },
      ),
    );
  }
}

/// Choosing between light and dark, and lighting the page.
///
/// It is handed the answers and a way to change them rather than reaching for
/// the app itself, which is what lets it be looked at on its own.
class Appearance extends StatelessWidget {
  const Appearance({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.brightness,
    required this.look,
    required this.onLookChanged,
    this.onLookReset,
  });

  /// Light, dark, or the machine's own choice.
  final ThemeMode mode;
  final ValueChanged<ThemeMode> onModeChanged;

  /// Which page is being lit — the one in force, since that is the one on
  /// screen to judge it by.
  final Brightness brightness;

  final PageLook look;
  final ValueChanged<PageLook> onLookChanged;

  /// Null when there is nothing to put back.
  final VoidCallback? onLookReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = SheetPalette.lamp(
      brightness: look.brightness,
      warmth: look.warmth,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text('Appearance', style: theme.textTheme.titleMedium),
                ),
                RadioGroup<ThemeMode>(
                  groupValue: mode,
                  onChanged: (chosen) {
                    if (chosen != null) {
                      onModeChanged(chosen);
                    }
                  },
                  child: Column(
                    children: [
                      for (final choice in _ThemeChoice.all)
                        RadioListTile<ThemeMode>(
                          value: choice.mode,
                          title: Text(choice.title),
                          subtitle: Text(choice.explanation),
                          secondary: Icon(choice.icon),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Text(
                    'This is remembered on this device and nowhere else. A'
                    ' tablet on a stand and a laptop at home can be set'
                    ' differently while being the same account.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        brightness == Brightness.dark
                            ? 'The page, in the dark'
                            : 'The page, in the light',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: onLookReset,
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'A score is ink on paper however dark the room is. What'
                  ' changes at night is how much light the paper is throwing at'
                  ' you — so this turns the lamp down rather than turning the'
                  ' score inside out.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                _Page(palette: palette),
                const SizedBox(height: 8),
                _Dial(
                  label: 'Brightness',
                  // What the page gives off against what a white one does,
                  // which is the number an eye actually reckons by.
                  value: look.brightness,
                  min: SheetPalette.dimmest,
                  max: SheetPalette.full,
                  readout: '${(look.brightness * 100).round()}%',
                  low: Icons.brightness_low_outlined,
                  high: Icons.brightness_high_outlined,
                  onChanged: (value) =>
                      onLookChanged((brightness: value, warmth: look.warmth)),
                ),
                _Dial(
                  label: 'Warmth',
                  value: look.warmth,
                  min: 0,
                  max: 1,
                  readout: look.warmth < 0.02
                      ? 'none'
                      : '${(look.warmth * 100).round()}%',
                  low: Icons.ac_unit_outlined,
                  high: Icons.local_fire_department_outlined,
                  onChanged: (value) => onLookChanged(
                      (brightness: look.brightness, warmth: value)),
                ),
                const SizedBox(height: 4),
                Text(
                  brightness == Brightness.dark
                      ? 'The light page is set separately — switch to Light'
                          ' above to set it.'
                      : 'The dark page is set separately — switch to Dark above'
                          ' to set it.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// One of the three answers, and what it means to a player rather than to a
/// framework.
class _ThemeChoice {
  const _ThemeChoice(this.mode, this.title, this.explanation, this.icon);

  final ThemeMode mode;
  final String title;
  final String explanation;
  final IconData icon;

  static const all = [
    _ThemeChoice(
      ThemeMode.system,
      'Follow the system',
      'Whatever this machine is set to.',
      Icons.brightness_auto_outlined,
    ),
    _ThemeChoice(
      ThemeMode.light,
      'Light',
      'Black on white, the way a score is printed.',
      Icons.light_mode_outlined,
    ),
    _ThemeChoice(
      ThemeMode.dark,
      'Dark',
      'The same page with the lamp turned down.',
      Icons.dark_mode_outlined,
    ),
  ];
}

/// Which slider is which, for anything that has to find one by name.
Key dialKey(String label) => Key('dial-$label');

/// A slider with what it is worth written beside it.
class _Dial extends StatelessWidget {
  const _Dial({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.readout,
    required this.low,
    required this.high,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String readout;
  final IconData low;
  final IconData high;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.labelLarge)),
            Text(
              readout,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        Row(
          children: [
            Icon(low, size: 18, color: theme.colorScheme.onSurfaceVariant),
            Expanded(
              // Named, so that a reader who cannot see the page hears which
              // dial this is rather than a number on its own.
              child: Semantics(
                label: label,
                child: Slider(
                  key: dialKey(label),
                  value: value.clamp(min, max),
                  min: min,
                  max: max,
                  label: readout,
                  onChanged: onChanged,
                ),
              ),
            ),
            Icon(high, size: 18, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ],
    );
  }
}

/// A scrap of staff in the palette being set, so the lamp can be seen rather
/// than read about.
class _Page extends StatelessWidget {
  const _Page({required this.palette});

  final SheetPalette palette;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ColoredBox(
        color: palette.paper,
        child: SizedBox(
          height: 96,
          width: double.infinity,
          child: CustomPaint(painter: _StaffSample(palette)),
        ),
      ),
    );
  }
}

/// Five lines and a note, at about the weight the real thing is drawn at.
///
/// Not the engine: a sample that had to lay out a document would be a document
/// this page had to carry, and what is being shown is a page and the ink on it.
class _StaffSample extends CustomPainter {
  const _StaffSample(this.palette);

  final SheetPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    const space = 7.5;
    final top = (size.height - space * 4) / 2;

    // Whole rows, the way the real thing is drawn. A sample showing the smeared
    // staff lines the engine no longer produces would be showing the wrong
    // thing. See `ScorePainter`.
    for (var i = 0; i < 5; i++) {
      final y = (top + i * space).roundToDouble();
      canvas.drawRect(
        Rect.fromLTRB(16, y, size.width - 16, y + 1),
        Paint()..color = palette.ink,
      );
    }

    // A notehead on the middle line, and a stem — the two things whose weight
    // tells you whether the ink is right.
    final head = Offset(size.width / 2, top + space * 2);
    canvas.save();
    canvas.translate(head.dx, head.dy);
    canvas.rotate(-0.35);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: space * 1.5, height: space),
      Paint()..color = palette.ink,
    );
    canvas.restore();
    canvas.drawRect(
      Rect.fromLTRB(
        (head.dx + space * 0.65).roundToDouble(),
        (head.dy - space * 3.5).roundToDouble(),
        (head.dx + space * 0.65).roundToDouble() + 1,
        head.dy.roundToDouble(),
      ),
      Paint()..color = palette.ink,
    );

    // A grace note, which is the thing that goes first when a page is dimmed
    // too far.
    canvas.save();
    canvas.translate(head.dx - space * 3, head.dy + space);
    canvas.rotate(-0.35);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: space, height: space * 0.7),
      Paint()..color = palette.fadedInk,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StaffSample old) => old.palette != palette;
}
