// DDRI API 클라이언트: 사용자/관리자/날씨 API, baseUrl 플랫폼별
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../utils/custom_common_util.dart';
import 'package:http/http.dart' as http;

import 'models/station_models.dart';

/// DDRI API 클라이언트.
/// 모든 API 호출은 이 클라이언트를 통해 수행.
class DdriApiClient {
  DdriApiClient({String? baseUrl})
    : _baseUrl = baseUrl ?? CustomCommonUtil.getApiBaseUrlSync();

  final String _baseUrl;

  /// v1 API 베이스 경로
  String get _v1 => '$_baseUrl/v1';

  /// GET 요청. 4xx/5xx 시 [ApiException] 발생.
  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse('$_v1$path').replace(queryParameters: queryParams);
    final response = await http.get(uri);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, response.body);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// 근처 대여소 조회
  Future<NearbyStationsResponse> getStationsNearby({
    required double lat,
    required double lng,
    required String targetDatetime,
    int limit = 20,
    int? radiusM,
  }) async {
    debugPrint('[DDRI] 좌표 수신: lat=$lat, lng=$lng');
    final params = <String, String>{
      'lat': lat.toString(),
      'lng': lng.toString(),
      'target_datetime': targetDatetime,
      'limit': limit.toString(),
    };
    if (radiusM != null) {
      params['radius_m'] = radiusM.toString();
    }

    final json = await _get('/user/stations/nearby', queryParams: params);
    final res = NearbyStationsResponse.fromJson(json);
    debugPrint(
      '[DDRI] API 응답 user_location: lat=${res.userLocation.lat}, lng=${res.userLocation.lng}',
    );
    return res;
  }

  /// 재배치 판단 목록 조회
  Future<RiskStationsResponse> getStationsRisk({
    required String baseDatetime,
    bool? urgentOnly,
    String? districtName,
    String sortBy = 'risk_score',
    String sortOrder = 'desc',
  }) async {
    final params = <String, String>{
      'base_datetime': baseDatetime,
      'sort_by': sortBy,
      'sort_order': sortOrder,
    };
    if (urgentOnly != null) {
      params['urgent_only'] = urgentOnly.toString();
    }
    if (districtName != null && districtName.isNotEmpty) {
      params['district_name'] = districtName;
    }

    final json = await _get('/admin/stations/risk', queryParams: params);
    return RiskStationsResponse.fromJson(json);
  }

  /// 스테이션 마스터 조회
  Future<StationsListResponse> getStations({String? districtName}) async {
    final params = <String, String>{};
    if (districtName != null && districtName.isNotEmpty) {
      params['district_name'] = districtName;
    }

    final json = await _get(
      '/stations',
      queryParams: params.isNotEmpty ? params : null,
    );
    return StationsListResponse.fromJson(json);
  }

  /// 주간 날씨 조회
  Future<List<WeatherDayItem>> getWeeklyWeather({
    required double lat,
    required double lon,
  }) async {
    final json = await _get(
      '/weather/direct',
      queryParams: {'lat': lat.toString(), 'lon': lon.toString()},
    );
    return (json['results'] as List<dynamic>?)
            ?.map((e) => WeatherDayItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
  }

  /// 선택 날짜 날씨 조회
  Future<WeatherDayItem?> getSelectedWeather({
    required double lat,
    required double lon,
    required String targetDatetime,
  }) async {
    final json = await _get(
      '/weather/direct/single',
      queryParams: {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'target_datetime': targetDatetime,
      },
    );
    final result = json['result'];
    if (result is Map<String, dynamic>) {
      return WeatherDayItem.fromJson(result);
    }
    return null;
  }
}

/// API 예외. HTTP 4xx/5xx 응답 시 발생.
class ApiException implements Exception {
  ApiException(this.statusCode, this.body);
  final int statusCode;
  final String body;
  @override
  String toString() => 'ApiException($statusCode): $body';
}

/// 근처 대여소 응답 (GET /v1/user/stations/nearby)
class NearbyStationsResponse {
  const NearbyStationsResponse({
    required this.targetDatetime,
    required this.serviceMode,
    required this.listMode,
    required this.userLocation,
    required this.items,
    required this.exceptions,
  });

  final String targetDatetime;
  final String serviceMode;
  final String listMode;
  final UserLocation userLocation;
  final List<StationNearbyItem> items;
  final List<ExceptionItem> exceptions;

  factory NearbyStationsResponse.fromJson(Map<String, dynamic> json) {
    return NearbyStationsResponse(
      targetDatetime: json['target_datetime'] as String? ?? '',
      serviceMode: json['service_mode'] as String? ?? 'beta',
      listMode: json['list_mode'] as String? ?? '',
      userLocation: UserLocation.fromJson(
        json['user_location'] as Map<String, dynamic>? ?? {},
      ),
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (e) => StationNearbyItem.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      exceptions:
          (json['exceptions'] as List<dynamic>?)
              ?.map((e) => ExceptionItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// 사용자 위치 (위경도)
class UserLocation {
  const UserLocation({required this.lat, required this.lng});
  final double lat;
  final double lng;
  factory UserLocation.fromJson(Map<String, dynamic> json) => UserLocation(
    lat: (json['lat'] as num?)?.toDouble() ?? 0,
    lng: (json['lng'] as num?)?.toDouble() ?? 0,
  );
}

/// 예외 스테이션 (실시간 비노출 등)
class ExceptionItem {
  const ExceptionItem({required this.stationId, required this.reason});
  final int stationId;
  final String reason;
  factory ExceptionItem.fromJson(Map<String, dynamic> json) => ExceptionItem(
    stationId: json['station_id'] as int? ?? 0,
    reason: json['reason'] as String? ?? '',
  );
}

/// 위험 대여소 응답 (GET /v1/admin/stations/risk)
class RiskStationsResponse {
  const RiskStationsResponse({
    required this.baseDatetime,
    required this.serviceMode,
    required this.listMode,
    required this.summary,
    required this.items,
    required this.exceptions,
  });

  final String baseDatetime;
  final String serviceMode;
  final String listMode;
  final RiskSummary summary;
  final List<StationRiskItem> items;
  final List<ExceptionItem> exceptions;

  factory RiskStationsResponse.fromJson(Map<String, dynamic> json) {
    return RiskStationsResponse(
      baseDatetime: json['base_datetime'] as String? ?? '',
      serviceMode: json['service_mode'] as String? ?? 'beta',
      listMode: json['list_mode'] as String? ?? '',
      summary: RiskSummary.fromJson(
        json['summary'] as Map<String, dynamic>? ?? {},
      ),
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => StationRiskItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      exceptions:
          (json['exceptions'] as List<dynamic>?)
              ?.map((e) => ExceptionItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// 위험 대여소 요약 (전체/위험/예외 개수, 평균 위험도)
class RiskSummary {
  const RiskSummary({
    required this.totalCount,
    required this.riskCount,
    required this.exceptionCount,
    required this.avgRiskScore,
  });
  final int totalCount;
  final int riskCount;
  final int exceptionCount;
  final double avgRiskScore;
  factory RiskSummary.fromJson(Map<String, dynamic> json) => RiskSummary(
    totalCount: json['total_count'] as int? ?? 0,
    riskCount: json['risk_count'] as int? ?? 0,
    exceptionCount: json['exception_count'] as int? ?? 0,
    avgRiskScore: (json['avg_risk_score'] as num?)?.toDouble() ?? 0,
  );
}

/// 스테이션 마스터 목록 응답 (GET /v1/stations)
class StationsListResponse {
  const StationsListResponse({
    required this.serviceMode,
    required this.listMode,
    required this.items,
    required this.totalCount,
  });
  final String serviceMode;
  final String listMode;
  final List<StationMasterItem> items;
  final int totalCount;
  factory StationsListResponse.fromJson(Map<String, dynamic> json) =>
      StationsListResponse(
        serviceMode: json['service_mode'] as String? ?? 'beta',
        listMode: json['list_mode'] as String? ?? '',
        items:
            (json['items'] as List<dynamic>?)
                ?.map(
                  (e) => StationMasterItem.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            [],
        totalCount: json['total_count'] as int? ?? 0,
      );
}
