// DDRI 관리자 컨트롤러: 기준 시각, 긴급만, 행정동, 정렬, /v1/admin/stations/risk
import 'package:get/get.dart';

import '../common/api/ddri_api_client.dart';
import '../common/api/models/station_models.dart';
import '../utils/ddri_debug.dart';

/// 관리자 페이지 상태·로직 (GetX).
/// onReady에서 fetchRiskStations 자동 호출.
class AdminPageController extends GetxController {
  AdminPageController({DdriApiClient? apiClient})
    : _api = apiClient ?? DdriApiClient();

  final DdriApiClient _api;

  // ─── 제어 ───────────────────────────────
  final Rx<DateTime> baseDatetime = DateTime.now().obs;
  final Rx<bool?> urgentOnly = Rx<bool?>(null);
  final Rx<String?> districtName = Rx<String?>(null);
  final Rx<String> sortBy = 'risk_score'.obs;
  final Rx<String> sortOrder = 'desc'.obs;

  // ─── 결과 ───────────────────────────────
  final RxList<StationRiskItem> items = <StationRiskItem>[].obs;
  final RxList<ExceptionItem> exceptions = <ExceptionItem>[].obs;
  final RxList<WeatherDayItem> weeklyForecast = <WeatherDayItem>[].obs;
  final Rx<WeatherDayItem?> selectedForecast = Rx<WeatherDayItem?>(null);
  final Rx<StationRiskItem?> focusedStation = Rx<StationRiskItem?>(null);
  final Rx<RiskSummary?> summary = Rx<RiskSummary?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isSupplementReady = false.obs;
  final RxBool isMapReady = false.obs;
  final RxBool weatherExpanded = true.obs;
  final RxString errorMessage = ''.obs;
  final RxBool exceptionsExpanded = false.obs;
  final RxString serviceMode = 'beta'.obs;
  final RxString listMode = ''.obs;
  int _mapRenderTicket = 0;

  /// API용 ISO 8601 형식
  String get baseDatetimeIso =>
      '${baseDatetime.value.toIso8601String().substring(0, 19)}+09:00';

  static const List<String> sortByOptions = [
    'risk_score',
    'reallocation_priority',
    'stock_gap',
  ];
  static const List<String> sortOrderOptions = ['asc', 'desc'];
  bool get isBetaMode => serviceMode.value == 'beta';
  String get dashboardSubtitle => isBetaMode
      ? '베타 기간에는 선별된 6개 대여소만 노출하는 재배치 우선순위 대시보드'
      : '강남구 따릉이 실시간 수요 예측 및 재배치 우선순위 대시보드';

  /// 강남구 행정동 (필터용)
  static const List<String> districtOptions = [
    '전체',
    '도곡동',
    '삼성동',
    '압구정동',
    '자곡동',
    '수서동',
  ];

  @override
  void onReady() {
    fetchRiskStations();
  }

  void setBaseDatetime(DateTime dt) {
    baseDatetime.value = dt;
    fetchRiskStations();
  }

  void setUrgentOnly(bool? value) {
    urgentOnly.value = value;
    fetchRiskStations();
  }

  void setDistrictName(String? value) {
    districtName.value = value == '전체' || value == null ? null : value;
    fetchRiskStations();
  }

  void setSortBy(String value) {
    sortBy.value = value;
    fetchRiskStations();
  }

  void setSortOrder(String value) {
    sortOrder.value = value;
    fetchRiskStations();
  }

  void toggleExceptionsExpanded() {
    exceptionsExpanded.value = !exceptionsExpanded.value;
  }

  void toggleWeatherExpanded() {
    weatherExpanded.value = !weatherExpanded.value;
  }

  Future<void> fetchRiskStations() async {
    final requestTicket = ++_mapRenderTicket;
    try {
      errorMessage.value = '';
      isLoading.value = true;
      isSupplementReady.value = false;
      isMapReady.value = false;
      final res = await _api.getStationsRisk(
        baseDatetime: baseDatetimeIso,
        urgentOnly: urgentOnly.value,
        districtName: districtName.value,
        sortBy: sortBy.value,
        sortOrder: sortOrder.value,
      );
      for (final item in res.items) {
        ddriDebugPrint(
          '[DDRI][admin] stationId=${item.stationId} '
          'stationName="${item.stationName}" '
          'current=${item.currentBikeStock} '
          'predictedDemand=${item.predictedDemand} '
          'predictedRemaining=${item.predictedRemainingBikes} '
          'shortage=${item.shortageBikes} '
          'risk=${item.riskScore}',
        );
      }
      serviceMode.value = res.serviceMode;
      listMode.value = res.listMode;
      items.assignAll(res.items);
      exceptions.assignAll(res.exceptions);
      weeklyForecast.assignAll(res.weather.weeklyForecast);
      selectedForecast.value = res.weather.selectedForecast;
      summary.value = res.summary;
      if (res.items.isEmpty) {
        focusedStation.value = null;
      } else {
        final currentFocusedId = focusedStation.value?.stationId;
        focusedStation.value =
            res.items.firstWhereOrNull(
              (item) => item.stationId == currentFocusedId,
            ) ??
            res.items.first;
      }
      ddriDebugPrint(
        '[DDRI] 관리자 목록: total=${res.summary.totalCount}, risk=${res.summary.riskCount}',
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!isClosed && requestTicket == _mapRenderTicket) {
        isSupplementReady.value = true;
      }
      if (res.items.isNotEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 160));
        if (!isClosed && requestTicket == _mapRenderTicket) {
          isMapReady.value = true;
        }
      }
    } on ApiException catch (e) {
      ddriDebugPrint('[DDRI] 관리자 목록 조회 실패(ApiException): ${e.message}');
      errorMessage.value = e.message;
      items.clear();
      exceptions.clear();
      weeklyForecast.clear();
      selectedForecast.value = null;
      focusedStation.value = null;
      summary.value = null;
      serviceMode.value = 'beta';
      listMode.value = '';
      isSupplementReady.value = false;
      isMapReady.value = false;
    } catch (e) {
      ddriDebugPrint('[DDRI] 관리자 목록 조회 실패: $e');
      errorMessage.value = '재배치 목록을 불러오지 못했습니다.';
      items.clear();
      exceptions.clear();
      weeklyForecast.clear();
      selectedForecast.value = null;
      focusedStation.value = null;
      summary.value = null;
      serviceMode.value = 'beta';
      listMode.value = '';
      isSupplementReady.value = false;
      isMapReady.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  void focusStation(StationRiskItem station) {
    focusedStation.value = station;
  }
}
