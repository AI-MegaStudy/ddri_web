// DDRI 관리자 컨트롤러: 기준 시각, 긴급만, 행정동, 정렬, /v1/admin/stations/risk
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../common/api/ddri_api_client.dart';
import '../common/api/models/station_models.dart';

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
  final Rx<RiskSummary?> summary = Rx<RiskSummary?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool exceptionsExpanded = false.obs;
  final RxString serviceMode = 'beta'.obs;
  final RxString listMode = ''.obs;

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
    '역삼동',
    '청담동',
    '삼성동',
    '대치동',
    '논현동',
    '압구정동',
    '세곡동',
    '자곡동',
    '율현동',
    '일원동',
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

  Future<void> fetchRiskStations() async {
    try {
      errorMessage.value = '';
      isLoading.value = true;
      final res = await _api.getStationsRisk(
        baseDatetime: baseDatetimeIso,
        urgentOnly: urgentOnly.value,
        districtName: districtName.value,
        sortBy: sortBy.value,
        sortOrder: sortOrder.value,
      );
      serviceMode.value = res.serviceMode;
      listMode.value = res.listMode;
      items.value = res.items;
      exceptions.value = res.exceptions;
      summary.value = res.summary;
      debugPrint(
        '[DDRI] 관리자 목록: total=${res.summary.totalCount}, risk=${res.summary.riskCount}',
      );
    } catch (e) {
      errorMessage.value = '재배치 목록을 불러오지 못했습니다.';
      items.clear();
      exceptions.clear();
      summary.value = null;
      serviceMode.value = 'beta';
      listMode.value = '';
    } finally {
      isLoading.value = false;
    }
  }
}
