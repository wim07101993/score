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
      return IconButton(
        tooltip: 'Download the score file',
        icon: const Icon(Icons.download),
        onPressed: onDownloadAsWritten,
      );
    }

    return PopupMenuButton<VoidCallback>(
      tooltip: 'Download the score file',
      icon: const Icon(Icons.download),
      enabled: onDownloadAsWritten != null,
      onSelected: (download) => download(),
      itemBuilder: (context) => [
        // As written first: it is the one that is the score, and the one an
        // editor who means to correct it and put it back wants.
        PopupMenuItem(
          value: onDownloadAsWritten,
          child: const ListTile(
            leading: Icon(Icons.description_outlined),
            title: Text('Score file, as written (.musicxml)'),
            subtitle: Text(
              'The score itself, as it was uploaded. It opens in other music'
              ' software and can be uploaded here again.',
            ),
          ),
        ),
        PopupMenuItem(
          value: asOnScreen,
          child: const ListTile(
            leading: Icon(Icons.visibility_outlined),
            title: Text('Score file, as on screen (.musicxml)'),
            subtitle: Text(
              'In the key you are reading it in, without the parts you have'
              ' hidden. Not the original: do not upload it over this score.',
            ),
          ),
        ),
      ],
    );
  }
}
