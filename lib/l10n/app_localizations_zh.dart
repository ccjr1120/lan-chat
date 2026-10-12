// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get allowDevice => '允许这台设备加入？';

  @override
  String peerType(String value0) {
    return '类型：$value0';
  }

  @override
  String peerAddress(String value0) {
    return '地址：$value0';
  }

  @override
  String get joinPermissionDetail => '同意后该设备可以查看聊天记录、收发消息和文件。';

  @override
  String get reject => '拒绝';

  @override
  String get allowJoin => '允许加入';

  @override
  String get joinOptions => '设备如何加入';

  @override
  String get joinDirectly => '直接加入';

  @override
  String get requireApproval => '需要我确认';

  @override
  String get sessionStarted => '会话已开启';

  @override
  String get scanToJoin => '扫码加入，开始互传';

  @override
  String get scanInstructions => '用另一台设备扫描，或在浏览器打开地址';

  @override
  String qrDescription(String value0) {
    return '网页访问二维码：$value0';
  }

  @override
  String get otherAddresses => '其他网络地址';

  @override
  String get refreshAddresses => '刷新地址';

  @override
  String get accessMode => '加入方式';

  @override
  String get directJoinDetail => '同一网络中的设备可直接加入';

  @override
  String get approvalDetail => '新设备加入时，由你决定是否允许';

  @override
  String get currentDirectJoin => '当前：直接加入';

  @override
  String get currentApproval => '当前：需要我确认';

  @override
  String get copyAddress => '复制地址';

  @override
  String get addressCopied => '地址已复制';

  @override
  String get noNetworkAddress => '未获取到局域网地址';

  @override
  String get networkHint => '连接 Wi-Fi 或开启个人热点后，刷新地址。';

  @override
  String fileAccessibility(String value0, String value1) {
    return '文件 $value0，$value1，点击打开';
  }

  @override
  String fileOpenHint(String value0) {
    return '$value0 · 点击打开';
  }

  @override
  String downloadProgress(String value0) {
    return '下载中 $value0%';
  }

  @override
  String get share => '分享';

  @override
  String get remove => '移除';

  @override
  String get currentDevice => '当前设备';

  @override
  String get phoneBrowser => '手机 / 浏览器';

  @override
  String get connectionDiagram => '连接方式示意';

  @override
  String get sameNetworkNoAccount => '通过同一网络连接 · 无需账号';

  @override
  String startFailed(String value0) {
    return '启动失败：$value0';
  }

  @override
  String get endSessionTitle => '结束会话？';

  @override
  String get endSessionDetail => '所有设备将断开连接，正在进行的传输会中断。聊天记录和文件会保留。';

  @override
  String get continueSession => '继续会话';

  @override
  String get endSession => '结束会话';

  @override
  String get invalidAddress => '请输入有效地址，例如 192.168.1.8:8686';

  @override
  String get deviceName => '设备名称';

  @override
  String get deviceNameHint => '其他设备看到的名称';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get nameNextSession => '新名称将在下次开启服务时生效';

  @override
  String get backHome => '返回首页';

  @override
  String get joinSession => '加入会话';

  @override
  String get appName => '局域网互传';

  @override
  String get renameDevice => '修改设备名称';

  @override
  String get findDevices => '找到设备，开始互传';

  @override
  String get homeHeadline => '在设备之间，轻松传文件';

  @override
  String get homeHeadlineCompact => '在设备之间，\n轻松传文件';

  @override
  String get sessionReady => '你的会话已准备好';

  @override
  String get findDevicesDetail => '连接同一个 Wi-Fi，选择附近的会话。';

  @override
  String get homeDetail => '同一个 Wi-Fi，无需账号。文字和文件即刻互传。';

  @override
  String get inviteDetail => '邀请其他设备加入，电脑浏览器也能使用。';

  @override
  String get joinNearbyDetail => '连接附近已开启的设备';

  @override
  String get allDevicesHint => '手机、电脑，都能轻松连接';

  @override
  String get sessionStillRunning => '你的会话仍在运行';

  @override
  String get returnToSession => '返回首页可以进入或结束会话';

  @override
  String get myDeviceRename => '我的设备 · 点击修改名称';

  @override
  String get createSession => '创建会话';

  @override
  String get createSessionDetail => '让其他设备连接到这里，发送文字、图片和文件。';

  @override
  String get creatingSession => '正在创建…';

  @override
  String enterSession(int value0) {
    return '进入会话 · $value0 台设备在线';
  }

  @override
  String get joinAnotherSession => '加入其他会话';

  @override
  String get nearbySessions => '附近的会话';

  @override
  String get searchAgain => '重新搜索';

  @override
  String get searchingDevices => '正在寻找附近的会话';

  @override
  String get discoveryFailed => '暂时无法发现设备';

  @override
  String get nearbyHint => '确认设备已创建会话，并连接同一个 Wi-Fi。\n也可以在下方输入地址加入。';

  @override
  String get enterAddress => '输入会话地址';

  @override
  String get manualAddressHint => '找不到设备？使用主机显示的地址';

  @override
  String get sessionAddress => '会话地址';

  @override
  String get connectDevice => '连接设备';

  @override
  String sendFailed(String value0) {
    return '发送失败：$value0';
  }

  @override
  String get chooseFiles => '选择要发送的文件';

  @override
  String filePickerFailed(String value0) {
    return '无法打开文件选择器：$value0';
  }

  @override
  String fileSendFailed(String value0) {
    return '“$value0”发送失败';
  }

  @override
  String get noAppForFile => '没有可以打开该文件的应用，可尝试分享';

  @override
  String openFailed(String value0) {
    return '打开失败：$value0';
  }

  @override
  String shareFailed(String value0) {
    return '分享失败：$value0';
  }

  @override
  String get copied => '已复制';

  @override
  String get clearHistory => '清空聊天记录';

  @override
  String get clearHistoryDetail => '将删除所有消息与主机保存的文件，所有设备的聊天记录同步清空，无法恢复。';

  @override
  String get clear => '清空';

  @override
  String get mySession => '我的会话';

  @override
  String get sessionSettings => '访问地址与设置';

  @override
  String get sessionInfo => '会话信息';

  @override
  String connectedDevices(int value0) {
    return '已连接 · $value0 台设备在线';
  }

  @override
  String get connecting => '连接中…';

  @override
  String get awaitingApproval => '等待主机确认';

  @override
  String get rejected => '已被拒绝';

  @override
  String get disconnected => '已断开';

  @override
  String get sessionEnded => '会话已结束';

  @override
  String get approvalPendingDetail => '主机同意后即可进入会话';

  @override
  String get unableToJoin => '无法加入会话';

  @override
  String get joinRejected => '主机拒绝了你的加入请求';

  @override
  String get back => '返回';

  @override
  String get startSharing => '连接好了，开始互传吧';

  @override
  String get preparingSession => '正在准备会话';

  @override
  String get inviteFirstFile => '邀请其他设备，或发送第一个文件。';

  @override
  String get sharingHint => '文字、图片和文件，都可以从这里发送。';

  @override
  String get inviteDevice => '邀请设备';

  @override
  String get connectingNow => '正在连接…';

  @override
  String get reconnecting => '连接已断开，正在重连';

  @override
  String get retryNow => '立即重试';

  @override
  String get sendFile => '发送文件';

  @override
  String get messageHint => '输入文字，或发送文件…';

  @override
  String get connectBeforeSending => '连接后即可发送';

  @override
  String get send => '发送';

  @override
  String hostAddress(String value0) {
    return '主机地址 $value0';
  }

  @override
  String onlineDevicesCount(int value0) {
    return '在线设备（$value0）';
  }

  @override
  String peerIsMe(String value0) {
    return '$value0（我）';
  }

  @override
  String get currentSession => '当前会话';

  @override
  String get sessionDetails => '会话详情';

  @override
  String onlineDevices(int value0) {
    return '在线设备 · $value0';
  }

  @override
  String get myDevice => '我的设备';

  @override
  String get networkSharingHint => '连接同一个 Wi-Fi，文字和文件直接在设备之间传输。';

  @override
  String get devicesConnected => '你的设备，已经连在一起';

  @override
  String readyToShare(int value0) {
    return '$value0 台设备在线。选择一个文件，开始这次互传。';
  }

  @override
  String get sessionEmptyHint => '会话已开启。邀请另一台设备，或先把文件放进会话。';

  @override
  String get chooseFileToSend => '选择文件发送';

  @override
  String get inviteOtherDevices => '邀请其他设备';

  @override
  String get writeMessage => '发送一条文字';

  @override
  String get documentsFiles => '文档与文件';

  @override
  String get imagesVideos => '图片与视频';

  @override
  String get textLinks => '文字与链接';

  @override
  String get sessionFiles => '会话文件';

  @override
  String fileCountSize(int value0, String value1) {
    return '$value0 个文件 · $value1';
  }

  @override
  String get filesAppearHere => '文件会出现在这里';

  @override
  String get recentFilesHint => '会话中的最近文件可直接打开，无需在消息中翻找。';

  @override
  String get recentFilesLimit => '这里显示当前同步记录中的文件，最多展示最近 12 个。';

  @override
  String get theme => '主题';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get me => '我';

  @override
  String get host => '主机';

  @override
  String get web => '网页';

  @override
  String get app => 'App';

  @override
  String get unnamedDevice => '未命名设备';

  @override
  String get hostSuffix => '（主机）';
}
