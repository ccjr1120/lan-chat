import 'package:dio/dio.dart';

import '../core/models/chat_message.dart';
import '../core/session/chat_session.dart';

/// 基于 dio 的 HTTP 传输：带进度的上传与下载。
class TransferClient {
  TransferClient(this.baseUrl)
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 8),
          // 大文件传输不限制收发超时。
          receiveTimeout: null,
          sendTimeout: null,
        ));

  final String baseUrl;
  final Dio _dio;

  /// 访问令牌，加入会话（welcome）后设置。
  String? token;

  Options get _auth => Options(headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      });

  /// 校验地址是否为局域网互传主机，返回主机信息。
  Future<Map<String, dynamic>> info() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/info');
    final data = response.data;
    if (data == null || data['app'] != 'lanchat') {
      throw const FormatException('该地址不是局域网互传主机');
    }
    return data;
  }

  Future<ChatMessage> upload(
    LocalFileSource file, {
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromStream(file.openRead, file.size, filename: file.name),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/upload',
      data: form,
      // 文件名通过查询参数传递，避免 multipart 分段头中非 ASCII 字符的编码差异。
      queryParameters: {'name': file.name},
      options: _auth,
      onSendProgress: onProgress,
      cancelToken: cancelToken,
    );
    return ChatMessage.fromJson(response.data ?? const {});
  }

  Future<void> download(
    FileMeta file,
    String savePath, {
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    await _dio.download(
      '/api/files/${Uri.encodeComponent(file.id)}',
      savePath,
      queryParameters: {'download': '1'},
      options: _auth,
      onReceiveProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  void close() => _dio.close(force: true);

  /// 将 dio 异常转换为可读提示。
  static String describe(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      final data = error.response?.data;
      if (data is Map && data['error'] is String) return data['error'] as String;
      if (status == 401) return '未授权，请重新加入会话';
      if (status != null) return '请求失败（HTTP $status）';
      return switch (error.type) {
        DioExceptionType.connectionTimeout => '连接超时',
        DioExceptionType.connectionError => '无法连接到主机',
        DioExceptionType.cancel => '已取消',
        _ => error.message ?? '网络错误',
      };
    }
    return error.toString();
  }
}
