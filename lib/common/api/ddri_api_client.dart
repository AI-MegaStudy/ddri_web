// DDRI API 클라이언트: 사용자/관리자/날씨 API, baseUrl 플랫폼별
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../utils/custom_common_util.dart';
import '../../utils/ddri_debug.dart';
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
    late final http.Response response;
    try {
      response = await http.get(uri);
    } catch (_) {
      throw ApiException.network();
    }
    if (response.statusCode >= 400) {
      throw ApiException.fromHttpResponse(
        statusCode: response.statusCode,
        body: response.body,
      );
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    _throwIfLogicalError(json);
    return json;
  }

  void _throwIfLogicalError(Map<String, dynamic> json) {
    final result = json['result'];
    final errorMsg = json['errorMsg'];

    final hasErrorResult =
        result is String && result.trim().toLowerCase() == 'error';
    final hasErrorMessage = errorMsg is String && errorMsg.trim().isNotEmpty;

    if (hasErrorResult || hasErrorMessage) {
      throw ApiException(
        200,
        hasErrorMessage
            ? errorMsg.trim()
            : '요청을 처리하지 못했습니다. 잠시 후 다시 시도해 주세요.',
      );
    }
  }

  /// 근처 대여소 조회
  Future<NearbyStationsResponse> getStationsNearby({
    required double lat,
    required double lng,
    required String targetDatetime,
    int limit = 20,
    int? radiusM,
  }) async {
    ddriDebugPrint('[DDRI] 좌표 수신: lat=$lat, lng=$lng');
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
    ddriDebugPrint(
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
    ddriDebugPrint(
      '[DDRI] 관리자 API 응답 수신: items=${(json['items'] as List<dynamic>?)?.length ?? 0}, '
      'weather=${json['weather'] != null}, summary=${json['summary'] != null}',
    );
    final res = RiskStationsResponse.fromJson(json);
    ddriDebugPrint(
      '[DDRI] 관리자 API 파싱 완료: items=${res.items.length}, '
      'weekly=${res.weather.weeklyForecast.length}, focused-ready=${res.items.isNotEmpty}',
    );
    return res;
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
    ddriDebugPrint('[DDRI] 날씨 주간 요청: lat=$lat, lon=$lon');
    final json = await _get(
      '/weather/direct',
      queryParams: {'lat': lat.toString(), 'lon': lon.toString()},
    );
    final results =
        (json['results'] as List<dynamic>?)
            ?.map((e) => WeatherDayItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    ddriDebugPrint('[DDRI] 날씨 주간 응답: items=${results.length}');
    return results;
  }

  /// 선택 날짜 날씨 조회
  Future<WeatherDayItem?> getSelectedWeather({
    required double lat,
    required double lon,
    required String targetDatetime,
  }) async {
    ddriDebugPrint(
      '[DDRI] 날씨 선택시각 요청: lat=$lat, lon=$lon, targetDatetime=$targetDatetime',
    );
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
      final item = WeatherDayItem.fromJson(result);
      ddriDebugPrint(
        '[DDRI] 날씨 선택시각 응답: type=${item.weatherType}, low=${item.weatherLow}, high=${item.weatherHigh}',
      );
      return item;
    }
    ddriDebugPrint('[DDRI] 날씨 선택시각 응답: result=null');
    return null;
  }
}

/// API 예외. HTTP 4xx/5xx 응답 시 발생.
class ApiException implements Exception {
  ApiException(this.statusCode, this.message, {this.isNetworkError = false});

  factory ApiException.network() {
    return ApiException(
      0,
      '서버에 연결할 수 없습니다. 잠시 후 다시 시도해 주세요.',
      isNetworkError: true,
    );
  }

  factory ApiException.fromHttpResponse({
    required int statusCode,
    required String body,
  }) {
    String message = '요청을 처리하지 못했습니다. 잠시 후 다시 시도해 주세요.';

    try {
      final json = jsonDecode(body);
      if (json is Map<String, dynamic>) {
        final detail = json['detail'];
        if (detail is String && detail.trim().isNotEmpty) {
          message = detail.trim();
        } else {
          final errorMsg = json['errorMsg'];
          if (errorMsg is String && errorMsg.trim().isNotEmpty) {
            message = errorMsg.trim();
          }
        }
      }
    } catch (_) {
      // Keep the generic safe message when the body is not valid JSON.
    }

    return ApiException(statusCode, message);
  }

  final int statusCode;
  final String message;
  final bool isNetworkError;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// 근처 대여소 응답 (GET /v1/user/stations/nearby)
class NearbyStationsResponse {
  const NearbyStationsResponse({
    required this.targetDatetime,
    required this.serviceMode,
    required this.listMode,
    required this.userLocation,
    required this.weather,
    required this.items,
    required this.exceptions,
  });

  final String targetDatetime;
  final String serviceMode;
  final String listMode;
  final UserLocation userLocation;
  final WeatherBundle weather;
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
      weather: WeatherBundle.fromJson(
        json['weather'] as Map<String, dynamic>? ?? {},
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
  const ExceptionItem({required this.reason, required this.count});
  final String reason;
  final int count;
  factory ExceptionItem.fromJson(Map<String, dynamic> json) => ExceptionItem(
    reason: json['reason'] as String? ?? '',
    count: json['count'] as int? ?? 1,
  );
}

/// 위험 대여소 응답 (GET /v1/admin/stations/risk)
class RiskStationsResponse {
  const RiskStationsResponse({
    required this.baseDatetime,
    required this.serviceMode,
    required this.listMode,
    required this.weather,
    required this.summary,
    required this.items,
    required this.exceptions,
  });

  final String baseDatetime;
  final String serviceMode;
  final String listMode;
  final WeatherBundle weather;
  final RiskSummary summary;
  final List<StationRiskItem> items;
  final List<ExceptionItem> exceptions;

  factory RiskStationsResponse.fromJson(Map<String, dynamic> json) {
    return RiskStationsResponse(
      baseDatetime: json['base_datetime'] as String? ?? '',
      serviceMode: json['service_mode'] as String? ?? 'beta',
      listMode: json['list_mode'] as String? ?? '',
      weather: WeatherBundle.fromJson(
        json['weather'] as Map<String, dynamic>? ?? {},
      ),
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

class WeatherBundle {
  const WeatherBundle({
    required this.weeklyForecast,
    required this.selectedForecast,
  });

  final List<WeatherDayItem> weeklyForecast;
  final WeatherDayItem? selectedForecast;

  factory WeatherBundle.fromJson(Map<String, dynamic> json) {
    final selected = json['selected_forecast'];
    return WeatherBundle(
      weeklyForecast:
          (json['weekly_forecast'] as List<dynamic>?)
              ?.map((e) => WeatherDayItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      selectedForecast: selected is Map<String, dynamic>
          ? WeatherDayItem.fromJson(selected)
          : null,
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
    required this.avgPredictedRemainingBikes,
  });
  final int totalCount;
  final int riskCount;
  final int exceptionCount;
  final double avgRiskScore;
  final double avgPredictedRemainingBikes;
  factory RiskSummary.fromJson(Map<String, dynamic> json) => RiskSummary(
    totalCount: json['total_count'] as int? ?? 0,
    riskCount: json['risk_count'] as int? ?? 0,
    exceptionCount: json['exception_count'] as int? ?? 0,
    avgRiskScore: (json['avg_risk_score'] as num?)?.toDouble() ?? 0,
    avgPredictedRemainingBikes:
        (json['avg_predicted_remaining_bikes'] as num?)?.toDouble() ?? 0,
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
