import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @allowDevice.
  ///
  /// In en, this message translates to:
  /// **'Allow this device to join?'**
  String get allowDevice;

  /// No description provided for @peerType.
  ///
  /// In en, this message translates to:
  /// **'Type: {value0}'**
  String peerType(String value0);

  /// No description provided for @peerAddress.
  ///
  /// In en, this message translates to:
  /// **'Address: {value0}'**
  String peerAddress(String value0);

  /// No description provided for @joinPermissionDetail.
  ///
  /// In en, this message translates to:
  /// **'Once approved, this device can view history and exchange messages and files.'**
  String get joinPermissionDetail;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @allowJoin.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allowJoin;

  /// No description provided for @joinOptions.
  ///
  /// In en, this message translates to:
  /// **'How devices join'**
  String get joinOptions;

  /// No description provided for @joinDirectly.
  ///
  /// In en, this message translates to:
  /// **'Join directly'**
  String get joinDirectly;

  /// No description provided for @requireApproval.
  ///
  /// In en, this message translates to:
  /// **'Require my approval'**
  String get requireApproval;

  /// No description provided for @sessionStarted.
  ///
  /// In en, this message translates to:
  /// **'Session is running'**
  String get sessionStarted;

  /// No description provided for @scanToJoin.
  ///
  /// In en, this message translates to:
  /// **'Scan to join and start sharing'**
  String get scanToJoin;

  /// No description provided for @scanInstructions.
  ///
  /// In en, this message translates to:
  /// **'Scan with another device, or open the address in a browser'**
  String get scanInstructions;

  /// No description provided for @qrDescription.
  ///
  /// In en, this message translates to:
  /// **'QR code for web access: {value0}'**
  String qrDescription(String value0);

  /// No description provided for @otherAddresses.
  ///
  /// In en, this message translates to:
  /// **'Other network addresses'**
  String get otherAddresses;

  /// No description provided for @refreshAddresses.
  ///
  /// In en, this message translates to:
  /// **'Refresh addresses'**
  String get refreshAddresses;

  /// No description provided for @accessMode.
  ///
  /// In en, this message translates to:
  /// **'Joining options'**
  String get accessMode;

  /// No description provided for @directJoinDetail.
  ///
  /// In en, this message translates to:
  /// **'Devices on the same network can join directly'**
  String get directJoinDetail;

  /// No description provided for @approvalDetail.
  ///
  /// In en, this message translates to:
  /// **'You decide whether new devices can join'**
  String get approvalDetail;

  /// No description provided for @currentDirectJoin.
  ///
  /// In en, this message translates to:
  /// **'Current: join directly'**
  String get currentDirectJoin;

  /// No description provided for @currentApproval.
  ///
  /// In en, this message translates to:
  /// **'Current: require my approval'**
  String get currentApproval;

  /// No description provided for @copyAddress.
  ///
  /// In en, this message translates to:
  /// **'Copy address'**
  String get copyAddress;

  /// No description provided for @addressCopied.
  ///
  /// In en, this message translates to:
  /// **'Address copied'**
  String get addressCopied;

  /// No description provided for @noNetworkAddress.
  ///
  /// In en, this message translates to:
  /// **'No local network address found'**
  String get noNetworkAddress;

  /// No description provided for @networkHint.
  ///
  /// In en, this message translates to:
  /// **'Connect to Wi-Fi or enable a hotspot, then refresh the addresses.'**
  String get networkHint;

  /// No description provided for @fileAccessibility.
  ///
  /// In en, this message translates to:
  /// **'File {value0}, {value1}, click to open'**
  String fileAccessibility(String value0, String value1);

  /// No description provided for @fileOpenHint.
  ///
  /// In en, this message translates to:
  /// **'{value0} · Click to open'**
  String fileOpenHint(String value0);

  /// No description provided for @downloadProgress.
  ///
  /// In en, this message translates to:
  /// **'Downloading {value0}%'**
  String downloadProgress(String value0);

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @currentDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get currentDevice;

  /// No description provided for @phoneBrowser.
  ///
  /// In en, this message translates to:
  /// **'Phone / Browser'**
  String get phoneBrowser;

  /// No description provided for @connectionDiagram.
  ///
  /// In en, this message translates to:
  /// **'Connection example'**
  String get connectionDiagram;

  /// No description provided for @sameNetworkNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Same network · No account needed'**
  String get sameNetworkNoAccount;

  /// No description provided for @startFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to start: {value0}'**
  String startFailed(String value0);

  /// No description provided for @endSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'End this session?'**
  String get endSessionTitle;

  /// No description provided for @endSessionDetail.
  ///
  /// In en, this message translates to:
  /// **'All devices will disconnect and active transfers will stop. Chat history and files will be kept.'**
  String get endSessionDetail;

  /// No description provided for @continueSession.
  ///
  /// In en, this message translates to:
  /// **'Keep sharing'**
  String get continueSession;

  /// No description provided for @endSession.
  ///
  /// In en, this message translates to:
  /// **'End session'**
  String get endSession;

  /// No description provided for @invalidAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid address, such as 192.168.1.8:8686'**
  String get invalidAddress;

  /// No description provided for @deviceName.
  ///
  /// In en, this message translates to:
  /// **'Device name'**
  String get deviceName;

  /// No description provided for @deviceNameHint.
  ///
  /// In en, this message translates to:
  /// **'The name other devices see'**
  String get deviceNameHint;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @backHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get backHome;

  /// No description provided for @joinSession.
  ///
  /// In en, this message translates to:
  /// **'Join a session'**
  String get joinSession;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'LAN Chat'**
  String get appName;

  /// No description provided for @renameDevice.
  ///
  /// In en, this message translates to:
  /// **'Rename device'**
  String get renameDevice;

  /// No description provided for @homeHeadline.
  ///
  /// In en, this message translates to:
  /// **'Share files easily between devices'**
  String get homeHeadline;

  /// No description provided for @homeHeadlineCompact.
  ///
  /// In en, this message translates to:
  /// **'Share files easily\nbetween devices'**
  String get homeHeadlineCompact;

  /// No description provided for @sessionReady.
  ///
  /// In en, this message translates to:
  /// **'Your session is ready'**
  String get sessionReady;

  /// No description provided for @findDevicesDetail.
  ///
  /// In en, this message translates to:
  /// **'Connect to the same Wi-Fi and choose a nearby session.'**
  String get findDevicesDetail;

  /// No description provided for @homeDetail.
  ///
  /// In en, this message translates to:
  /// **'Same Wi-Fi, no account needed. Share messages and files instantly.'**
  String get homeDetail;

  /// No description provided for @inviteDetail.
  ///
  /// In en, this message translates to:
  /// **'Invite other devices. A computer browser works too.'**
  String get inviteDetail;

  /// No description provided for @allDevicesHint.
  ///
  /// In en, this message translates to:
  /// **'Connect easily from phones and computers'**
  String get allDevicesHint;

  /// No description provided for @createSession.
  ///
  /// In en, this message translates to:
  /// **'Create a session'**
  String get createSession;

  /// No description provided for @createSessionDetail.
  ///
  /// In en, this message translates to:
  /// **'Let other devices connect here to share messages, images and files.'**
  String get createSessionDetail;

  /// No description provided for @creatingSession.
  ///
  /// In en, this message translates to:
  /// **'Creating…'**
  String get creatingSession;

  /// No description provided for @enterSession.
  ///
  /// In en, this message translates to:
  /// **'Open session · {value0, plural, one{1 device online} other{{value0} devices online}}'**
  String enterSession(int value0);

  /// No description provided for @nearbySessions.
  ///
  /// In en, this message translates to:
  /// **'Nearby sessions'**
  String get nearbySessions;

  /// No description provided for @searchAgain.
  ///
  /// In en, this message translates to:
  /// **'Search again'**
  String get searchAgain;

  /// No description provided for @searchingDevices.
  ///
  /// In en, this message translates to:
  /// **'Looking for nearby sessions'**
  String get searchingDevices;

  /// No description provided for @discoveryFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to discover devices'**
  String get discoveryFailed;

  /// No description provided for @nearbyHint.
  ///
  /// In en, this message translates to:
  /// **'Make sure the other device has a session running on the same Wi-Fi.\nYou can also enter its address below.'**
  String get nearbyHint;

  /// No description provided for @enterAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter a session address'**
  String get enterAddress;

  /// No description provided for @manualAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Cannot find the device? Use the address shown on the host'**
  String get manualAddressHint;

  /// No description provided for @sessionAddress.
  ///
  /// In en, this message translates to:
  /// **'Session address'**
  String get sessionAddress;

  /// No description provided for @connectDevice.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connectDevice;

  /// No description provided for @sendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send: {value0}'**
  String sendFailed(String value0);

  /// No description provided for @chooseFiles.
  ///
  /// In en, this message translates to:
  /// **'Choose files to send'**
  String get chooseFiles;

  /// No description provided for @filePickerFailed.
  ///
  /// In en, this message translates to:
  /// **'Cannot open the file picker: {value0}'**
  String filePickerFailed(String value0);

  /// No description provided for @fileSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send “{value0}”'**
  String fileSendFailed(String value0);

  /// No description provided for @noAppForFile.
  ///
  /// In en, this message translates to:
  /// **'No app can open this file. Try sharing it instead.'**
  String get noAppForFile;

  /// No description provided for @openFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open: {value0}'**
  String openFailed(String value0);

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to share: {value0}'**
  String shareFailed(String value0);

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear chat history'**
  String get clearHistory;

  /// No description provided for @clearHistoryDetail.
  ///
  /// In en, this message translates to:
  /// **'All messages and files saved on the host will be permanently deleted. History will be cleared on every device.'**
  String get clearHistoryDetail;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @mySession.
  ///
  /// In en, this message translates to:
  /// **'My session'**
  String get mySession;

  /// No description provided for @sessionSettings.
  ///
  /// In en, this message translates to:
  /// **'Addresses and joining options'**
  String get sessionSettings;

  /// No description provided for @sessionInfo.
  ///
  /// In en, this message translates to:
  /// **'Session information'**
  String get sessionInfo;

  /// No description provided for @connectedDevices.
  ///
  /// In en, this message translates to:
  /// **'Connected · {value0, plural, one{1 device online} other{{value0} devices online}}'**
  String connectedDevices(int value0);

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connecting;

  /// No description provided for @awaitingApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting for host approval'**
  String get awaitingApproval;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @sessionEnded.
  ///
  /// In en, this message translates to:
  /// **'Session ended'**
  String get sessionEnded;

  /// No description provided for @approvalPendingDetail.
  ///
  /// In en, this message translates to:
  /// **'You can join once the host approves your request'**
  String get approvalPendingDetail;

  /// No description provided for @unableToJoin.
  ///
  /// In en, this message translates to:
  /// **'Unable to join the session'**
  String get unableToJoin;

  /// No description provided for @joinRejected.
  ///
  /// In en, this message translates to:
  /// **'The host rejected your request'**
  String get joinRejected;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @startSharing.
  ///
  /// In en, this message translates to:
  /// **'Connected. Start sharing!'**
  String get startSharing;

  /// No description provided for @preparingSession.
  ///
  /// In en, this message translates to:
  /// **'Preparing the session'**
  String get preparingSession;

  /// No description provided for @inviteFirstFile.
  ///
  /// In en, this message translates to:
  /// **'Invite another device, or send your first file.'**
  String get inviteFirstFile;

  /// No description provided for @sharingHint.
  ///
  /// In en, this message translates to:
  /// **'Send messages, images and files from here.'**
  String get sharingHint;

  /// No description provided for @inviteDevice.
  ///
  /// In en, this message translates to:
  /// **'Invite a device'**
  String get inviteDevice;

  /// No description provided for @connectingNow.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connectingNow;

  /// No description provided for @reconnecting.
  ///
  /// In en, this message translates to:
  /// **'Disconnected. Reconnecting…'**
  String get reconnecting;

  /// No description provided for @retryNow.
  ///
  /// In en, this message translates to:
  /// **'Retry now'**
  String get retryNow;

  /// No description provided for @sendFile.
  ///
  /// In en, this message translates to:
  /// **'Send files'**
  String get sendFile;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Write a message, or send a file…'**
  String get messageHint;

  /// No description provided for @connectBeforeSending.
  ///
  /// In en, this message translates to:
  /// **'Connect to start sending'**
  String get connectBeforeSending;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @hostAddress.
  ///
  /// In en, this message translates to:
  /// **'Host address {value0}'**
  String hostAddress(String value0);

  /// No description provided for @onlineDevicesCount.
  ///
  /// In en, this message translates to:
  /// **'Online devices ({value0})'**
  String onlineDevicesCount(int value0);

  /// No description provided for @peerIsMe.
  ///
  /// In en, this message translates to:
  /// **'{value0} (me)'**
  String peerIsMe(String value0);

  /// No description provided for @currentSession.
  ///
  /// In en, this message translates to:
  /// **'Current session'**
  String get currentSession;

  /// No description provided for @sessionDetails.
  ///
  /// In en, this message translates to:
  /// **'Session details'**
  String get sessionDetails;

  /// No description provided for @onlineDevices.
  ///
  /// In en, this message translates to:
  /// **'Online devices · {value0}'**
  String onlineDevices(int value0);

  /// No description provided for @myDevice.
  ///
  /// In en, this message translates to:
  /// **'My device'**
  String get myDevice;

  /// No description provided for @networkSharingHint.
  ///
  /// In en, this message translates to:
  /// **'Connect to the same Wi-Fi to share messages and files directly between devices.'**
  String get networkSharingHint;

  /// No description provided for @devicesConnected.
  ///
  /// In en, this message translates to:
  /// **'Your devices are connected'**
  String get devicesConnected;

  /// No description provided for @readyToShare.
  ///
  /// In en, this message translates to:
  /// **'{value0, plural, one{1 device online. Choose a file to start sharing.} other{{value0} devices online. Choose a file to start sharing.}}'**
  String readyToShare(int value0);

  /// No description provided for @sessionEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Your session is running. Invite another device, or add a file to the session.'**
  String get sessionEmptyHint;

  /// No description provided for @chooseFileToSend.
  ///
  /// In en, this message translates to:
  /// **'Choose files to send'**
  String get chooseFileToSend;

  /// No description provided for @inviteOtherDevices.
  ///
  /// In en, this message translates to:
  /// **'Invite other devices'**
  String get inviteOtherDevices;

  /// No description provided for @writeMessage.
  ///
  /// In en, this message translates to:
  /// **'Write a message'**
  String get writeMessage;

  /// No description provided for @documentsFiles.
  ///
  /// In en, this message translates to:
  /// **'Documents and files'**
  String get documentsFiles;

  /// No description provided for @imagesVideos.
  ///
  /// In en, this message translates to:
  /// **'Images and videos'**
  String get imagesVideos;

  /// No description provided for @textLinks.
  ///
  /// In en, this message translates to:
  /// **'Text and links'**
  String get textLinks;

  /// No description provided for @sessionFiles.
  ///
  /// In en, this message translates to:
  /// **'Session files'**
  String get sessionFiles;

  /// No description provided for @fileCountSize.
  ///
  /// In en, this message translates to:
  /// **'{value0, plural, one{1 file · {value1}} other{{value0} files · {value1}}}'**
  String fileCountSize(int value0, String value1);

  /// No description provided for @filesAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Files will appear here'**
  String get filesAppearHere;

  /// No description provided for @recentFilesHint.
  ///
  /// In en, this message translates to:
  /// **'Open recent files directly without searching through messages.'**
  String get recentFilesHint;

  /// No description provided for @recentFilesLimit.
  ///
  /// In en, this message translates to:
  /// **'Files from the current history are shown here, with up to 12 recent files.'**
  String get recentFilesLimit;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @me.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get me;

  /// No description provided for @host.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get host;

  /// No description provided for @web.
  ///
  /// In en, this message translates to:
  /// **'Browser'**
  String get web;

  /// No description provided for @app.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get app;

  /// No description provided for @unnamedDevice.
  ///
  /// In en, this message translates to:
  /// **'Unnamed device'**
  String get unnamedDevice;

  /// No description provided for @hostSuffix.
  ///
  /// In en, this message translates to:
  /// **' (host)'**
  String get hostSuffix;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
