import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';

/// 返回 JSON 响应。
Response jsonResponse(Object? body, {int status = 200}) => Response(
      status,
      body: jsonEncode(body),
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
        HttpHeaders.cacheControlHeader: 'no-store',
      },
    );

Response jsonError(int status, String message) =>
    jsonResponse({'error': message}, status: status);

/// 从查询参数 `token` 或 `Authorization: Bearer <token>` 读取访问令牌。
/// 浏览器 `<a href>` 下载只能带查询参数，因此两种方式都支持。
String? readToken(Request request) {
  final query = request.url.queryParameters['token'];
  if (query != null && query.isNotEmpty) return query;
  final auth = request.headers[HttpHeaders.authorizationHeader];
  if (auth != null && auth.startsWith('Bearer ')) {
    return auth.substring(7).trim();
  }
  return null;
}

/// 解析 multipart 请求的 boundary。
String? multipartBoundary(Request request) {
  final type = request.headers[HttpHeaders.contentTypeHeader];
  if (type == null || !type.toLowerCase().startsWith('multipart/form-data')) {
    return null;
  }
  final match = RegExp(r'boundary=(?:"([^"]+)"|([^;\s]+))', caseSensitive: false)
      .firstMatch(type);
  return match?.group(1) ?? match?.group(2);
}

/// 解析 multipart 分段的 `Content-Disposition`，返回 `name` 与 `filename`。
({String? name, String? filename}) parseContentDisposition(String? header) {
  if (header == null) return (name: null, filename: null);
  String? name;
  String? filename;
  String? filenameStar;
  for (final match
      in RegExp(r'''(\w+\*?)\s*=\s*(?:"((?:[^"\\]|\\.)*)"|([^;]*))''').allMatches(header)) {
    final key = match.group(1)!.toLowerCase();
    final value = (match.group(2) ?? match.group(3) ?? '').trim();
    switch (key) {
      case 'name':
        name = value;
      case 'filename':
        filename = value.replaceAll(r'\"', '"');
      case 'filename*':
        final idx = value.indexOf("''");
        final encoded = idx >= 0 ? value.substring(idx + 2) : value;
        try {
          filenameStar = Uri.decodeComponent(encoded);
        } on ArgumentError {
          filenameStar = null;
        }
    }
  }
  return (name: name, filename: filenameStar ?? filename);
}

/// 生成下载用 `Content-Disposition`：ASCII 回退名 + RFC 5987 UTF-8 文件名。
String contentDisposition(String fileName, {required bool inline}) {
  final ascii = fileName.replaceAll(RegExp(r'[^\x20-\x7E]|["\\]'), '_');
  final type = inline ? 'inline' : 'attachment';
  return '$type; filename="$ascii"; filename*=UTF-8\'\'${Uri.encodeComponent(fileName)}';
}

/// 单段 Range 请求的解析结果（闭区间）。
class ByteRange {
  const ByteRange(this.start, this.end);

  final int start;
  final int end;

  int get length => end - start + 1;
}

/// 解析 `Range: bytes=start-end` / `bytes=start-` / `bytes=-suffix`。
///
/// 返回 null 表示不是有效的单段 Range（按完整文件返回）；
/// 抛出 [RangeError] 表示范围不可满足（应返回 416）。
ByteRange? parseRange(String? header, int fileSize) {
  if (header == null) return null;
  final match = RegExp(r'^bytes=(\d*)-(\d*)$').firstMatch(header.trim());
  if (match == null) return null;
  final startText = match.group(1)!;
  final endText = match.group(2)!;
  if (startText.isEmpty && endText.isEmpty) return null;
  int start;
  int end;
  if (startText.isEmpty) {
    final suffix = int.parse(endText);
    if (suffix == 0) throw RangeError('empty suffix range');
    start = fileSize - suffix < 0 ? 0 : fileSize - suffix;
    end = fileSize - 1;
  } else {
    start = int.parse(startText);
    end = endText.isEmpty ? fileSize - 1 : int.parse(endText);
    if (end >= fileSize) end = fileSize - 1;
  }
  if (fileSize == 0 || start > end || start >= fileSize) {
    throw RangeError('unsatisfiable range');
  }
  return ByteRange(start, end);
}
