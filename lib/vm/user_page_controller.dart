// DDRI 사용자 컨트롤러: 위치/주소/반경/시간, 대여소·날씨 API, focusedStation
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../common/api/ddri_api_client.dart';
import '../common/api/models/station_models.dart';
import '../utils/ddri_debug.dart';

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
  final RxnInt selectedRadiusM = RxnInt(); // null = 전체보기

  // ─── 결과 ───────────────────────────────
  final RxList<StationNearbyItem> items = <StationNearbyItem>[].obs;
  final Rx<StationNearbyItem?> focusedStation = Rx<StationNearbyItem?>(null);
  final RxList<WeatherDayItem> weeklyForecast = <WeatherDayItem>[].obs;
  final Rx<WeatherDayItem?> selectedForecast = Rx<WeatherDayItem?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isLoadingLocation = false.obs;
  final RxBool isLoadingWeather = false.obs;
  final RxBool weatherExpanded = true.obs;
  final RxString errorMessage = ''.obs;
  final RxString weatherErrorMessage = ''.obs;
  final RxString serviceMode = 'beta'.obs;
  final RxString listMode = ''.obs;
  bool _shouldRefocusOnNextResult = false;

  /// 위치가 선택되었는지 (위경도 존재)
  bool get hasLocation => lat.value != null && lng.value != null;
  bool get isBetaMode => serviceMode.value == 'beta';
  String get stationListTitle => '대여소 ${items.length}개';

  @override
  void onInit() {
    super.onInit();
    // 페이지 진입 시 현 위치 자동 로드 (실패 시 검색 영역·플레이스홀더로 대체)
    if (!hasLocation) {
      fetchCurrentLocation();
    }
  }

  /// API용 ISO 8601 형식 (예: 2026-03-20T18:00:00+09:00)
  String get targetDatetimeIso =>
      '${targetDatetime.value.toIso8601String().substring(0, 19)}+09:00';

  void setSelectedRadius(int? m) => selectedRadiusM.value = m;

  void setTargetDatetime(DateTime dt) => targetDatetime.value = dt;

  /// 현 위치로 검색
  Future<void> fetchCurrentLocation() async {
    try {
      errorMessage.value = '';
      isLoadingLocation.value = true;
      _shouldRefocusOnNextResult = true;
      if (kIsWeb) {
        await _fetchCurrentLocationForWeb();
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        errorMessage.value = '기기 위치 서비스가 꺼져 있습니다. 위치 서비스를 켠 뒤 다시 시도해 주세요.';
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        errorMessage.value = '위치 권한이 필요합니다. 브라우저에서 위치 접근을 허용한 뒤 다시 시도해 주세요.';
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        errorMessage.value =
            '브라우저에서 위치 접근이 차단되어 있습니다. 사이트 권한에서 위치를 허용한 뒤 다시 시도해 주세요.';
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      ddriDebugPrint(
        '[DDRI] 현 위치 좌표: lat=${pos.latitude}, lng=${pos.longitude}',
      );
      lat.value = pos.latitude;
      lng.value = pos.longitude;
      address.value = '현재 위치';
      await Future.wait([_fetchStations(), _fetchWeather()]);
    } on PermissionDeniedException catch (e) {
      ddriDebugPrint('[DDRI] 현 위치 권한 거부: $e');
      errorMessage.value =
          '위치 권한이 필요합니다. 브라우저에서 위치 접근을 허용한 뒤 다시 시도해 주세요.';
    } on PositionUpdateException catch (e) {
      ddriDebugPrint('[DDRI] 현 위치 조회 실패: $e');
      errorMessage.value =
          '브라우저가 현재 위치를 확인하지 못했습니다. 잠시 후 다시 시도하거나 주소 검색을 이용해 주세요.';
    } on TimeoutException catch (e) {
      ddriDebugPrint('[DDRI] 현 위치 조회 시간 초과: $e');
      errorMessage.value =
          '현재 위치 확인 시간이 초과되었습니다. 잠시 후 다시 시도하거나 주소 검색을 이용해 주세요.';
    } catch (e) {
      ddriDebugPrint('[DDRI] 현 위치 조회 실패: $e');
      errorMessage.value =
          '현재 위치를 가져오지 못했습니다. 브라우저 위치 권한을 확인하거나 주소 검색을 이용해 주세요.';
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
    ddriDebugPrint('[DDRI] 주소 검색 좌표: lat=$newLat, lng=$newLng, addr=$addr');
    lat.value = newLat;
    lng.value = newLng;
    address.value = addr;
    _shouldRefocusOnNextResult = true;
    await Future.wait([_fetchStations(), _fetchWeather()]);
  }

  Future<void> _fetchCurrentLocationForWeb() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      errorMessage.value = '브라우저 또는 macOS 위치 서비스가 꺼져 있습니다. 위치 서비스를 켠 뒤 다시 시도해 주세요.';
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      errorMessage.value = '위치 권한이 필요합니다. 브라우저에서 위치 접근을 허용한 뒤 다시 시도해 주세요.';
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: WebSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
          maximumAge: Duration(minutes: 5),
        ),
      );
      await _applyCurrentPosition(pos, sourceLabel: 'web');
    } on PermissionDeniedException catch (e) {
      ddriDebugPrint('[DDRI] 웹 현 위치 권한 거부: $e (permission=$permission)');
      errorMessage.value =
          '브라우저 위치 권한이 실제로 적용되지 않았습니다. 주소창 왼쪽 사이트 권한과 macOS 위치 서비스에서 Chrome 허용 상태를 다시 확인해 주세요.';
    } on PositionUpdateException catch (e) {
      ddriDebugPrint('[DDRI] 웹 현 위치 실시간 조회 실패: $e');
      errorMessage.value =
          '브라우저가 현재 위치를 아직 확인하지 못했습니다. 잠시 후 다시 시도하거나 주소 검색을 이용해 주세요.';
    }
  }

  Future<void> _applyCurrentPosition(
    Position pos, {
    required String sourceLabel,
  }) async {
    ddriDebugPrint(
      '[DDRI] 현 위치 좌표($sourceLabel): lat=${pos.latitude}, lng=${pos.longitude}',
    );
    lat.value = pos.latitude;
    lng.value = pos.longitude;
    address.value = '현재 위치';
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
        radiusM: selectedRadiusM.value,
      );
      for (final item in res.items) {
        ddriDebugPrint(
          '[DDRI][user] stationId=${item.stationId} '
          'stationName="${item.stationName}" '
          'current=${item.currentBikeStock} '
          'predictedRental=${item.predictedRentalCount} '
          'predictedRemaining=${item.predictedRemainingBikes} '
          'availability=${item.availabilityLevel}',
        );
      }
      serviceMode.value = res.serviceMode;
      listMode.value = res.listMode;
      items.value = res.items;
      if (res.items.isEmpty) {
        focusedStation.value = null;
      } else if (_shouldRefocusOnNextResult) {
        focusedStation.value = res.items.first;
      } else {
        final currentFocusedId = focusedStation.value?.stationId;
        focusedStation.value =
            res.items.firstWhereOrNull(
              (item) => item.stationId == currentFocusedId,
            ) ??
            res.items.first;
      }
    } on ApiException catch (e, st) {
      ddriDebugPrint('[DDRI] 대여소 목록 조회 실패: $e');
      ddriDebugPrint('[DDRI] 스택: $st');
      errorMessage.value = e.message;
      items.clear();
      focusedStation.value = null;
      serviceMode.value = 'beta';
      listMode.value = '';
    } catch (e, st) {
      ddriDebugPrint('[DDRI] 대여소 목록 조회 실패: $e');
      ddriDebugPrint('[DDRI] 스택: $st');
      errorMessage.value = '대여소 목록을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
      items.clear();
      focusedStation.value = null;
      serviceMode.value = 'beta';
      listMode.value = '';
    } finally {
      _shouldRefocusOnNextResult = false;
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
    } on ApiException catch (e, st) {
      ddriDebugPrint('[DDRI] 날씨 조회 실패: $e');
      ddriDebugPrint('[DDRI] 스택: $st');
      weeklyForecast.clear();
      selectedForecast.value = null;
      weatherErrorMessage.value = e.message;
    } catch (e, st) {
      ddriDebugPrint('[DDRI] 날씨 조회 실패: $e');
      ddriDebugPrint('[DDRI] 스택: $st');
      weeklyForecast.clear();
      selectedForecast.value = null;
      weatherErrorMessage.value = '현재 날씨를 받아오지 못했습니다.';
    } finally {
      isLoadingWeather.value = false;
    }
  }

  Future<void> retryWeather() => _fetchWeather();

  void toggleWeatherExpanded() {
    weatherExpanded.value = !weatherExpanded.value;
  }

  void focusStation(StationNearbyItem station) {
    focusedStation.value = station;
  }

  void clearFocusedStation() {
    focusedStation.value = null;
  }

  /// 전체보기/반경 필터 변경 시 재조회
  Future<void> onRadiusFilterChanged(int? radiusM) async {
    setSelectedRadius(radiusM);
    _shouldRefocusOnNextResult = true;
    if (hasLocation) await _fetchStations();
  }

  /// 시간 변경 시 재조회
  Future<void> onDatetimeChanged(DateTime dt) async {
    setTargetDatetime(dt);
    _shouldRefocusOnNextResult = true;
    if (hasLocation) {
      await Future.wait([_fetchStations(), _fetchWeather()]);
    }
  }
}
