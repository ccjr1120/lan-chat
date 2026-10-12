import 'package:flutter/widgets.dart';

import '../core/models/access_mode.dart';
import '../core/models/peer.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

extension LocalizedContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension UiStrings on AppLocalizations {
  String platformLabel(PeerPlatform platform) => switch (platform) {
    PeerPlatform.host => host,
    PeerPlatform.app => app,
    PeerPlatform.web => web,
  };

  String accessDescription(AccessMode mode) => switch (mode) {
    AccessMode.open => directJoinDetail,
    AccessMode.approval => approvalDetail,
  };

  /// Translate legacy local/protocol diagnostics at the presentation boundary.
  /// User names, file names and message bodies are never passed through this.
  String diagnostic(String value) {
    if (localeName.startsWith('zh')) return value;
    var result = value;
    const translations = {
      '设备发现广播失败，其他设备可通过 IP 地址访问':
          'Device discovery broadcast failed. Other devices can use the IP address.',
      '尚未连接到主机，无法下载': 'Not connected to the host. Cannot download.',
      '未授权，请重新加入会话': 'Not authorized. Please rejoin the session.',
      '该地址不是局域网互传主机': 'This address is not a LAN Chat host.',
      '主机拒绝了你的加入请求': 'The host rejected your request.',
      '主机拒绝了加入请求': 'The host rejected your request.',
      '主机已结束会话': 'The host ended the session',
      '设备发现启动失败：': 'Unable to start device discovery: ',
      '服务器内部错误': 'Internal server error',
      '尚未连接到主机': 'Not connected to the host',
      '无法连接到主机': 'Cannot connect to the host',
      '等待主机确认': 'Waiting for host approval',
      '未找到文件分段': 'No file found in the upload',
      '需要 multipart/form-data': 'Expected multipart/form-data',
      '文件已被删除': 'The file has been deleted',
      '文件不存在': 'The file does not exist',
      '连接已断开': 'Disconnected',
      '正在连接 ': 'Connecting to ',
      '请求失败（HTTP ': 'Request failed (HTTP ',
      '保存失败：': 'Failed to save: ',
      '上传失败：': 'Upload failed: ',
      '上传失败': 'Upload failed',
      '消息过长': 'Message is too long',
      '连接超时': 'Connection timed out',
      '网络错误': 'Network error',
      '已取消': 'Cancelled',
      '未授权': 'Not authorized',
    };
    for (final entry in translations.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    result = result.replaceAllMapped(
      RegExp(r'，(\d+) 秒后重试'),
      (match) => ', retrying in ${match[1]} s',
    );
    return result.replaceAll('）', ')');
  }
}
