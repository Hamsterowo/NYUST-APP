import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../api_client.dart';
import 'report_service.dart';

/// 以 App 自己的 Cloudflare 後端（`cf-api.nyust-plus.com`）為後端的
/// [ReportService] 實作。
class CfReportService implements ReportService {
  final ApiClient _client;

  CfReportService(this._client);

  Dio get _dio => _client.dio;

  @override
  Future<Map<String, dynamic>> getTermsOfService({String? lang}) async {
    await _client.ensureInit();
    try {
      final response = await _dio.get(
        '/api/policy/terms',
        queryParameters: lang != null ? {'lang': lang} : null,
      );
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return {'status': 'error', 'message': '連線逾時，請稍後再試'};
      }
      if (e.type == DioExceptionType.connectionError) {
        return {'status': 'error', 'message': '無法連線至伺服器，請檢查網路連線'};
      }
      return {'status': 'error', 'message': 'API 呼叫失敗: ${e.message}'};
    } catch (e) {
      return {'status': 'error', 'message': 'API call failed: $e'};
    }
  }

  @override
  Future<Map<String, dynamic>> submitBugReport({
    required String description,
    String? contact,
    required String deviceInfo,
    XFile? imageFile,
  }) async {
    await _client.ensureInit();
    try {
      final Map<String, dynamic> data = {
        'description': description,
        'contact': contact ?? '',
        'deviceInfo': deviceInfo,
      };

      if (imageFile != null) {
        if (kIsWeb) {
          final bytes = await imageFile.readAsBytes();
          data['file'] = MultipartFile.fromBytes(
            bytes,
            filename: imageFile.name,
          );
        } else {
          data['file'] = await MultipartFile.fromFile(
            imageFile.path,
            filename: imageFile.name,
          );
        }
      }

      final formData = FormData.fromMap(data);
      final response = await _dio.post('/api/report', data: formData);

      if (response.statusCode != 200) {
        return {
          'status': 'error',
          'code': 'server_error',
          'statusCode': response.statusCode,
          'message': '伺服器回應錯誤 (${response.statusCode})',
        };
      }

      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      } else if (response.data is String) {
        try {
          final decoded = jsonDecode(response.data as String);
          if (decoded is Map<String, dynamic>) {
            return decoded;
          }
        } catch (_) {}
      }

      return {
        'status': 'error',
        'code': 'format_error',
        'message': '伺服器回應格式錯誤',
      };
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return {'status': 'error', 'code': 'timeout', 'message': '連線逾時，請稍後再試'};
      }
      if (e.type == DioExceptionType.connectionError) {
        return {
          'status': 'error',
          'code': 'connection_error',
          'message': '無法連線至伺服器，請檢查網路連線',
        };
      }
      return {
        'status': 'error',
        'code': 'api_failed',
        'error': e.message ?? e.toString(),
        'message': 'API 呼叫失敗: ${e.message}',
      };
    } catch (e) {
      return {
        'status': 'error',
        'code': 'api_failed',
        'error': e.toString(),
        'message': 'API call failed: $e',
      };
    }
  }
}
