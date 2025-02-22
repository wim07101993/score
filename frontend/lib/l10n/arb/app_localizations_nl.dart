// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get couldNotFetchDiscoveryDocumentErrorMessage => 'Failed to connect to authentication server. Are you connected to the internet?';

  @override
  String get userInfoScreenTitle => 'Gebruikers info';

  @override
  String get loginButtonText => 'LOG IN';

  @override
  String get logoutButtonText => 'LOG OUT';

  @override
  String get unknownErrorDialogTitle => 'Er liep iets mis';

  @override
  String get unknownErrorDialogMessage => 'Als dit blijft gebeuren, contacteer de ontwikelaars van de app.';
}
