// DDRI 사용자 컨트롤러: 위치/주소/반경/시간, 대여소·날씨 API, focusedStation
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../common/api/ddri_api_client.dart';
import '../common/api/models/station_models.dart';
import '../core/design_token.dart';

/// 사용자 페이지 상태·로직 (GetX).
/// permanent: true로 등록되어 페이지 전환 시에도 유지.
class UserPageController extends GetxController {
  UserPageController({DdriApiClient? apiClient})
    : _api = apiClient ?? DdriApiClient();

  final DdriApiClient _api;

  // ─── 검색 조건 ───────────────────────────
  final Rx<double?> lat = Rx<double?>(null);
  final Rx<double?> lng = Rx<double?>(null);
  final Rx<String> address = ''.obs;
  final Rx<DateTime> targetDatetime = DateTime.now().obs;
  final Rx<int> radiusM = DesignToken.radiusOptions[1].obs; // 500m 기본

  // ─── 결과 ───────────────────────────────
  final RxList<StationNearbyItem> items = <StationNearbyItem>[].obs;
  final Rx<StationNearbyItem?> focusedStation = Rx<StationNearbyItem?>(null);
  final RxList<WeatherDayItem> weeklyForecast = <WeatherDayItem>[].obs;
  final Rx<WeatherDayItem?> selectedForecast = Rx<WeatherDayItem?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isLoadingLocation = false.obs;
  final RxBool isLoadingWeather = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString weatherErrorMessage = ''.obs;
  final RxString serviceMode = 'beta'.obs;
  final RxString listMode = ''.obs;

  /// 위치가 선택되었는지 (위경도 존재)
  bool get hasLocation => lat.value != null && lng.value != null;
  bool get isBetaMode => serviceMode.value == 'beta';
  String get stationListTitle =>
      isBetaMode ? '베타 대여소 ${items.length}개' : '주변 대여소 ${items.length}개';

  @override
  void onInit() {
    super.onInit();
    // 페이지 진입 시 현 위치 자동 로드 (권한 거부/실패 시 검색 영역·플레이스홀더로 대체)
    if (!hasLocation) {
      fetchCurrentLocation();
    }
  }

  /// API용 ISO 8601 형식 (예: 2026-03-20T18:00:00+09:00)
  String get targetDatetimeIso =>
      '${targetDatetime.value.toIso8601String().substring(0, 19)}+09:00';

  void setRadius(int m) => radiusM.value = m;

  void setTargetDatetime(DateTime dt) => targetDatetime.value = dt;

  /// 현 위치로 검색
  Future<void> fetchCurrentLocation() async {
    try {
      errorMessage.value = '';
      isLoadingLocation.value = true;
      final pos = await Geolocator.getCurrentPosition();
      debugPrint('[DDRI] 현 위치 좌표: lat=${pos.latitude}, lng=${pos.longitude}');
      lat.value = pos.latitude;
      lng.value = pos.longitude;
      address.value = '현재 위치';
      await Future.wait([_fetchStations(), _fetchWeather()]);
    } catch (e) {
      errorMessage.value = '위치를 가져올 수 없습니다. 주소 검색을 이용해 주세요.';
    } finally {
      isLoadingLocation.value = false;
    }
  }

  /// 주소 검색 결과 적용 후 조회
  Future<void> applyAddressAndFetch(
    double newLat,
    double newLng,
    String addr,
  ) async {
    debugPrint('[DDRI] 주소 검색 좌표: lat=$newLat, lng=$newLng, addr=$addr');
    lat.value = newLat;
    lng.value = newLng;
    address.value = addr;
    await Future.wait([_fetchStations(), _fetchWeather()]);
  }

  /// 대여소 목록 조회
  Future<void> _fetchStations() async {
    final la = lat.value;
    final ln = lng.value;
    if (la == null || ln == null) return;

    try {
      errorMessage.value = '';
      isLoading.value = true;
      final res = await _api.getStationsNearby(
        lat: la,
        lng: ln,
        targetDatetime: targetDatetimeIso,
        limit: 20,
        radiusM: radiusM.value,
      );
      serviceMode.value = res.serviceMode;
      listMode.value = res.listMode;
      items.value = res.items;
      if (res.items.isNotEmpty && focusedStation.value == null) {
        focusedStation.value = res.items.first;
      }
    } catch (e, st) {
      debugPrint('[DDRI] 대여소 목록 조회 실패: $e');
      debugPrint('[DDRI] 스택: $st');
      final msg = e.toString().toLowerCase();
      if (msg.contains('connection') ||
          msg.contains('refused') ||
          msg.contains('failed host lookup') ||
          msg.contains('failed to fetch') ||
          msg.contains('socket')) {
        errorMessage.value = '서버에 연결할 수 없습니다. 잠시 후 다시 시도해 주세요.';
      } else {
        errorMessage.value = '대여소 목록을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
      }
      items.clear();
      serviceMode.value = 'beta';
      listMode.value = '';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchWeather() async {
    final la = lat.value;
    final ln = lng.value;
    if (la == null || ln == null) return;

    try {
      weatherErrorMessage.value = '';
      isLoadingWeather.value = true;
      final weekly = await _api.getWeeklyWeather(lat: la, lon: ln);
      weeklyForecast.value = weekly;
      selectedForecast.value = await _api.getSelectedWeather(
        lat: la,
        lon: ln,
        targetDatetime: targetDatetimeIso,
      );
    } catch (e, st) {
      debugPrint('[DDRI] 날씨 조회 실패: $e');
      debugPrint('[DDRI] 스택: $st');
      weeklyForecast.clear();
      selectedForecast.value = null;
      weatherErrorMessage.value = '현재 날씨를 받아오지 못했습니다.';
    } finally {
      isLoadingWeather.value = false;
    }
  }

  Future<void> retryWeather() => _fetchWeather();

  void focusStation(StationNearbyItem station) {
    focusedStation.value = station;
  }

  void clearFocusedStation() {
    focusedStation.value = null;
  }

  /// 반경 변경 시 재조회
  Future<void> onRadiusChanged(int m) async {
    setRadius(m);
    if (hasLocation) await _fetchStations();
  }

  /// 시간 변경 시 재조회
  Future<void> onDatetimeChanged(DateTime dt) async {
    setTargetDatetime(dt);
    if (hasLocation) {
      await Future.wait([_fetchStations(), _fetchWeather()]);
    }
  }
}
