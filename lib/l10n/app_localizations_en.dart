// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get allowDevice => 'Allow this device to join?';

  @override
  String peerType(String value0) {
    return 'Type: $value0';
  }

  @override
  String peerAddress(String value0) {
    return 'Address: $value0';
  }

  @override
  String get joinPermissionDetail =>
      'Once approved, this device can view history and exchange messages and files.';

  @override
  String get reject => 'Reject';

  @override
  String get allowJoin => 'Allow';

  @override
  String get joinOptions => 'How devices join';

  @override
  String get joinDirectly => 'Join directly';

  @override
  String get requireApproval => 'Require my approval';

  @override
  String get sessionStarted => 'Session is running';

  @override
  String get scanToJoin => 'Scan to join and start sharing';

  @override
  String get scanInstructions =>
      'Scan with another device, or open the address in a browser';

  @override
  String qrDescription(String value0) {
    return 'QR code for web access: $value0';
  }

  @override
  String get otherAddresses => 'Other network addresses';

  @override
  String get refreshAddresses => 'Refresh addresses';

  @override
  String get accessMode => 'Joining options';

  @override
  String get directJoinDetail =>
      'Devices on the same network can join directly';

  @override
  String get approvalDetail => 'You decide whether new devices can join';

  @override
  String get currentDirectJoin => 'Current: join directly';

  @override
  String get currentApproval => 'Current: require my approval';

  @override
  String get copyAddress => 'Copy address';

  @override
  String get addressCopied => 'Address copied';

  @override
  String get noNetworkAddress => 'No local network address found';

  @override
  String get networkHint =>
      'Connect to Wi-Fi or enable a hotspot, then refresh the addresses.';

  @override
  String fileAccessibility(String value0, String value1) {
    return 'File $value0, $value1, click to open';
  }

  @override
  String fileOpenHint(String value0) {
    return '$value0 · Click to open';
  }

  @override
  String downloadProgress(String value0) {
    return 'Downloading $value0%';
  }

  @override
  String get share => 'Share';

  @override
  String get remove => 'Remove';

  @override
  String get currentDevice => 'This device';

  @override
  String get phoneBrowser => 'Phone / Browser';

  @override
  String get connectionDiagram => 'Connection example';

  @override
  String get sameNetworkNoAccount => 'Same network · No account needed';

  @override
  String startFailed(String value0) {
    return 'Failed to start: $value0';
  }

  @override
  String get endSessionTitle => 'End this session?';

  @override
  String get endSessionDetail =>
      'All devices will disconnect and active transfers will stop. Chat history and files will be kept.';

  @override
  String get continueSession => 'Keep sharing';

  @override
  String get endSession => 'End session';

  @override
  String get invalidAddress =>
      'Enter a valid address, such as 192.168.1.8:8686';

  @override
  String get deviceName => 'Device name';

  @override
  String get deviceNameHint => 'The name other devices see';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get backHome => 'Back to home';

  @override
  String get joinSession => 'Join a session';

  @override
  String get appName => 'LAN Chat';

  @override
  String get renameDevice => 'Rename device';

  @override
  String get homeHeadline => 'Share files easily between devices';

  @override
  String get homeHeadlineCompact => 'Share files easily\nbetween devices';

  @override
  String get sessionReady => 'Your session is ready';

  @override
  String get findDevicesDetail =>
      'Connect to the same Wi-Fi and choose a nearby session.';

  @override
  String get homeDetail =>
      'Same Wi-Fi, no account needed. Share messages and files instantly.';

  @override
  String get inviteDetail =>
      'Invite other devices. A computer browser works too.';

  @override
  String get allDevicesHint => 'Connect easily from phones and computers';

  @override
  String get createSession => 'Create a session';

  @override
  String get createSessionDetail =>
      'Let other devices connect here to share messages, images and files.';

  @override
  String get creatingSession => 'Creating…';

  @override
  String enterSession(int value0) {
    String _temp0 = intl.Intl.pluralLogic(
      value0,
      locale: localeName,
      other: '$value0 devices online',
      one: '1 device online',
    );
    return 'Open session · $_temp0';
  }

  @override
  String get nearbySessions => 'Nearby sessions';

  @override
  String get searchAgain => 'Search again';

  @override
  String get searchingDevices => 'Looking for nearby sessions';

  @override
  String get discoveryFailed => 'Unable to discover devices';

  @override
  String get nearbyHint =>
      'Make sure the other device has a session running on the same Wi-Fi.\nYou can also enter its address below.';

  @override
  String get enterAddress => 'Enter a session address';

  @override
  String get manualAddressHint =>
      'Cannot find the device? Use the address shown on the host';

  @override
  String get sessionAddress => 'Session address';

  @override
  String get connectDevice => 'Connect';

  @override
  String sendFailed(String value0) {
    return 'Failed to send: $value0';
  }

  @override
  String get chooseFiles => 'Choose files to send';

  @override
  String filePickerFailed(String value0) {
    return 'Cannot open the file picker: $value0';
  }

  @override
  String fileSendFailed(String value0) {
    return 'Failed to send “$value0”';
  }

  @override
  String get noAppForFile =>
      'No app can open this file. Try sharing it instead.';

  @override
  String openFailed(String value0) {
    return 'Failed to open: $value0';
  }

  @override
  String shareFailed(String value0) {
    return 'Failed to share: $value0';
  }

  @override
  String get copied => 'Copied';

  @override
  String get clearHistory => 'Clear chat history';

  @override
  String get clearHistoryDetail =>
      'All messages and files saved on the host will be permanently deleted. History will be cleared on every device.';

  @override
  String get clear => 'Clear';

  @override
  String get mySession => 'My session';

  @override
  String get sessionSettings => 'Addresses and joining options';

  @override
  String get sessionInfo => 'Session information';

  @override
  String connectedDevices(int value0) {
    String _temp0 = intl.Intl.pluralLogic(
      value0,
      locale: localeName,
      other: '$value0 devices online',
      one: '1 device online',
    );
    return 'Connected · $_temp0';
  }

  @override
  String get connecting => 'Connecting…';

  @override
  String get awaitingApproval => 'Waiting for host approval';

  @override
  String get rejected => 'Rejected';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get sessionEnded => 'Session ended';

  @override
  String get approvalPendingDetail =>
      'You can join once the host approves your request';

  @override
  String get unableToJoin => 'Unable to join the session';

  @override
  String get joinRejected => 'The host rejected your request';

  @override
  String get back => 'Back';

  @override
  String get startSharing => 'Connected. Start sharing!';

  @override
  String get preparingSession => 'Preparing the session';

  @override
  String get inviteFirstFile =>
      'Invite another device, or send your first file.';

  @override
  String get sharingHint => 'Send messages, images and files from here.';

  @override
  String get inviteDevice => 'Invite a device';

  @override
  String get connectingNow => 'Connecting…';

  @override
  String get reconnecting => 'Disconnected. Reconnecting…';

  @override
  String get retryNow => 'Retry now';

  @override
  String get sendFile => 'Send files';

  @override
  String get messageHint => 'Write a message, or send a file…';

  @override
  String get connectBeforeSending => 'Connect to start sending';

  @override
  String get send => 'Send';

  @override
  String hostAddress(String value0) {
    return 'Host address $value0';
  }

  @override
  String onlineDevicesCount(int value0) {
    return 'Online devices ($value0)';
  }

  @override
  String peerIsMe(String value0) {
    return '$value0 (me)';
  }

  @override
  String get currentSession => 'Current session';

  @override
  String get sessionDetails => 'Session details';

  @override
  String onlineDevices(int value0) {
    return 'Online devices · $value0';
  }

  @override
  String get myDevice => 'My device';

  @override
  String get networkSharingHint =>
      'Connect to the same Wi-Fi to share messages and files directly between devices.';

  @override
  String get devicesConnected => 'Your devices are connected';

  @override
  String readyToShare(int value0) {
    String _temp0 = intl.Intl.pluralLogic(
      value0,
      locale: localeName,
      other: '$value0 devices online. Choose a file to start sharing.',
      one: '1 device online. Choose a file to start sharing.',
    );
    return '$_temp0';
  }

  @override
  String get sessionEmptyHint =>
      'Your session is running. Invite another device, or add a file to the session.';

  @override
  String get chooseFileToSend => 'Choose files to send';

  @override
  String get inviteOtherDevices => 'Invite other devices';

  @override
  String get writeMessage => 'Write a message';

  @override
  String get documentsFiles => 'Documents and files';

  @override
  String get imagesVideos => 'Images and videos';

  @override
  String get textLinks => 'Text and links';

  @override
  String get sessionFiles => 'Session files';

  @override
  String fileCountSize(int value0, String value1) {
    String _temp0 = intl.Intl.pluralLogic(
      value0,
      locale: localeName,
      other: '$value0 files · $value1',
      one: '1 file · $value1',
    );
    return '$_temp0';
  }

  @override
  String get filesAppearHere => 'Files will appear here';

  @override
  String get recentFilesHint =>
      'Open recent files directly without searching through messages.';

  @override
  String get recentFilesLimit =>
      'Files from the current history are shown here, with up to 12 recent files.';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get me => 'Me';

  @override
  String get host => 'Host';

  @override
  String get web => 'Browser';

  @override
  String get app => 'App';

  @override
  String get unnamedDevice => 'Unnamed device';

  @override
  String get hostSuffix => ' (host)';

  @override
  String get orDivider => 'or';
}
