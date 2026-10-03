import 'package:flutter/material.dart';

/// Writes the score this device is holding back out to the device.
///
/// The score file comes out the way it was written — the file the editor
/// uploaded, byte for byte — because that is the one that can be opened in
/// other music software, corrected and uploaded here again. Once something
/// has been transposed or taken off the screen, the way it is on screen can be
/// had as well, but as a second thing, saying so in the menu and in the name
/// of the file: a copy in the band's key with the piano taken out, replaced
/// over the real score after a typo was fixed in it, is the real score gone.
class DownloadScoreButton extends StatelessWidget {
  const DownloadScoreButton({
    super.key,
    required this.onDownloadAsWritten,
    this.onDownloadAsOnScreen,
  });

  /// Writes out the score as it was uploaded.
  final VoidCallback? onDownloadAsWritten;

  /// Writes out the score the way it is on screen, or null while that is the
  /// way it was written — there is only the one file to offer then, and a menu
  /// claiming otherwise would be asking the player to choose between two of
  /// the same.
  final VoidCallback? onDownloadAsOnScreen;

  @override
  Widget build(BuildContext context) {
    final asOnScreen = onDownloadAsOnScreen;
    if (asOnScreen == null) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.download),
        label: const Text('Download'),
        onPressed: onDownloadAsWritten,
      );
    }

    return MenuAnchor(
      builder: (context, menu, _) => OutlinedButton.icon(
        icon: const Icon(Icons.download),
        label: const Text('Download'),
        onPressed: onDownloadAsWritten == null
            ? null
            : () => menu.isOpen ? menu.close() : menu.open(),
      ),
      menuChildren: [
        // As written first: it is the one that is the score, and the one an
        // editor who means to correct it and put it back wants.
        _Choice(
          onPressed: onDownloadAsWritten,
          icon: Icons.description_outlined,
          title: 'Score file, as written (.musicxml)',
          subtitle: 'The score itself, as it was uploaded. It opens in other'
              ' music software and can be uploaded here again.',
        ),
        _Choice(
          onPressed: asOnScreen,
          icon: Icons.visibility_outlined,
          title: 'Score file, as on screen (.musicxml)',
          subtitle: 'In the key you are reading it in, without the parts you'
              ' have hidden. Not the original: do not upload it over this'
              ' score.',
        ),
      ],
    );
  }
}

/// One of the two files the menu offers.
class _Choice extends StatelessWidget {
  const _Choice({
    required this.onPressed,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return MenuItemButton(
      onPressed: onPressed,
      leadingIcon: Icon(icon),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
