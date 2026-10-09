import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/notation/widgets/score_sheet.dart';
import 'package:score/features/observability/widgets/logs_button.dart';
import 'package:score/features/settings/behaviours/set_page_look.dart';
import 'package:score/features/settings/behaviours/set_theme_mode.dart';
import 'package:score/features/settings/models.dart';
import 'package:score/features/settings/notifiers/settings_notifier.dart';
import 'package:score/features/settings/widgets/look_slider.dart';
import 'package:score/features/settings/widgets/reset_look_button.dart';

/// What this device prefers.
///
/// More than a preference about chrome: the page a score is read off is set
/// here. A rehearsal room with the lights down and a laptop on a stand is the
/// case all of this exists for — the machine's own theme is often not what the
/// room is, and how dim a page wants to be is a question about the room.
@RoutePage()
class const SettingsPage({
  super.key,
}) extends StatefulWidget {
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settings = GetIt.I<SettingsNotifier>();

  /// Where a drag on the lamp has got to, for the page it is lighting, while
  /// it has not let go. Shown rather than stored: see [SetPageLook].
  final Map<Brightness, PageLook> _dragging = {};

  void _drag(Brightness brightness, PageLook look) =>
      setState(() => _dragging[brightness] = readable(look));

  Future<void> _keep(Brightness brightness, PageLook? look) async {
    await GetIt.I<SetPageLook>()(
      SetPageLookParams(brightness: brightness, look: look),
    );
    // The store has it by now, and the page follows the store again.
    if (mounted) setState(() => _dragging.remove(brightness));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: const [LogsButton()],
      ),
      // Listening to the settings rather than to the app: these are the things
      // that change without anything else about the app having changed, and a
      // control that did not move until something else happened to redraw the
      // page would be the app disagreeing with what it had just been told.
      body: ListenableBuilder(
        listenable: _settings,
        builder: (context, _) {
          final brightness = Theme.of(context).brightness;
          return Appearance(
            mode: _settings.themeMode,
            onModeChanged: (mode) => GetIt.I<SetThemeMode>()(mode),
            brightness: brightness,
            look: _dragging[brightness] ?? _settings.pageLook(brightness),
            onLookChanged: (look) => _drag(brightness, look),
            onLookCommitted: (look) => _keep(brightness, look),
            onLookReset:
                _settings.isPageLookDefault(brightness) &&
                    !_dragging.containsKey(brightness)
                ? null
                : () => _keep(brightness, null),
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
class const Appearance({
  super.key,

  /// Light, dark, or the machine's own choice.
  required final ThemeMode mode,
  required final ValueChanged<ThemeMode> onModeChanged,

  /// Which page is being lit — the one in force, since that is the one on
  /// screen to judge it by.
  required final Brightness brightness,
  required final PageLook look,

  /// Called for every step of a drag: what the page should look like now.
  required final ValueChanged<PageLook> onLookChanged,

  /// Called once a drag lets go, with where it was left: what is worth
  /// keeping. Null when nothing is kept beyond what [onLookChanged] was told.
  final ValueChanged<PageLook>? onLookCommitted,

  /// Null when there is nothing to put back.
  final VoidCallback? onLookReset,
}) extends StatelessWidget {
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
                    ResetLookButton(onPressed: onLookReset),
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
                  onChangeEnd: onLookCommitted == null
                      ? null
                      : (value) => onLookCommitted!((
                          brightness: value,
                          warmth: look.warmth,
                        )),
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
                  onChanged: (value) => onLookChanged((
                    brightness: look.brightness,
                    warmth: value,
                  )),
                  onChangeEnd: onLookCommitted == null
                      ? null
                      : (value) => onLookCommitted!((
                          brightness: look.brightness,
                          warmth: value,
                        )),
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
class const _ThemeChoice({
  required final ThemeMode mode,
  required final String title,
  required final String explanation,
  required final IconData icon,
}) {
  static const all = [
    _ThemeChoice(
      mode: ThemeMode.system,
      title: 'Follow the system',
      explanation: 'Whatever this machine is set to.',
      icon: Icons.brightness_auto_outlined,
    ),
    _ThemeChoice(
      mode: ThemeMode.light,
      title: 'Light',
      explanation: 'Black on white, the way a score is printed.',
      icon: Icons.light_mode_outlined,
    ),
    _ThemeChoice(
      mode: ThemeMode.dark,
      title: 'Dark',
      explanation: 'The same page with the lamp turned down.',
      icon: Icons.dark_mode_outlined,
    ),
  ];
}

/// A slider with what it is worth written beside it.
class const _Dial({
  required final String label,
  required final double value,
  required final double min,
  required final double max,
  required final String readout,
  required final IconData low,
  required final IconData high,
  required final ValueChanged<double> onChanged,
  final ValueChanged<double>? onChangeEnd,
}) extends StatelessWidget {
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
              child: LookSlider(
                label: label,
                value: value,
                min: min,
                max: max,
                readout: readout,
                onChanged: onChanged,
                onChangeEnd: onChangeEnd,
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
class const _Page({
  required final SheetPalette palette,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ColoredBox(
        color: palette.paper,
        child: SizedBox(
          height: 96,
          width: double.infinity,
          child: CustomPaint(painter: _StaffSample(palette: palette)),
        ),
      ),
    );
  }
}

/// Five lines and a note, at about the weight the real thing is drawn at.
///
/// Not the engine: a sample that had to lay out a document would be a document
/// this page had to carry, and what is being shown is a page and the ink on it.
class const _StaffSample({
  required final SheetPalette palette,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const space = 7.5;
    final top = (size.height - space * 4) / 2;

    // Whole rows, so that the sample shows the ink rather than a staff line
    // smeared across two rows of pixels at half cover — which on a dimmed page
    // is half way to the page, and would be judging the lamp by the wrong
    // thing.
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
