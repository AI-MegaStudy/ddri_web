// DDRI 앱 설정: API URL, 카카오 키, 저장소 키, 라우트 경로
import 'app_config_platform_stub.dart'
    if (dart.library.io) 'app_config_platform_io.dart'
    as platform_config;

/// 앱 전반에서 사용하는 상수 모음.
/// private 생성자(_)로 인스턴스 생성을 막고, static 상수만 제공한다.
class AppConfig {
  AppConfig._();

  static const String appTitle = '따릉이랑';
  static const String userPageTitle = '$appTitle 대여소 조회';
  static const String adminPageTitle = '$appTitle 재배치 관리';

  static const String adminFooterCopy =
      '© 2023 $appTitle Reallocation Support System. Gangnam-gu Smart Mobility Division.';

  /// 카카오 JavaScript API 키 (주소 검색→위경도 변환용, 웹에서 필요)
  static const String kakaoJsKey = '945bd56201340c858e34dda4bea79688';

  /// FastAPI 서버 기본 URL (커스텀 오버라이드)
  /// null/빈값이면 플랫폼 자동 선택 (웹·iOS: 127.0.0.1, Android 에뮬: 10.0.2.2)
  static const String? customApiBaseUrl = null;

  // static const String? customApiBaseUrl = 'http://192.168.90.7:8000';
  // static const String? customApiBaseUrl =
  //     'http://cheng80.myqnapcloud.com:18000';
}

/// FastAPI 서버 베이스 URL 반환.
/// [AppConfig.customApiBaseUrl]이 있으면 사용, 없으면 플랫폼 기본값(웹: 127.0.0.1:8000).
String getApiBaseUrl() {
  if (AppConfig.customApiBaseUrl?.trim().isNotEmpty ?? false) {
    return AppConfig.customApiBaseUrl?.trim() ?? '';
  }
  return platform_config.getPlatformDefaultApiUrl();
}

/// 로컬 저장소(GetStorage) 키 상수.
/// 사용자 저장 주소·좌표 등에 사용.
class StorageKeys {
  StorageKeys._();

  static const String apiBaseUrl = 'api_base_url';
  static const String savedAddress = 'saved_address';
  static const String savedLat = 'saved_lat';
  static const String savedLng = 'saved_lng';
  static const String betaNoticeHiddenDate = 'beta_notice_hidden_date';
}

/// DDRI 앱 라우트 경로 상수.
/// GetX 라우팅에서 사용.
class RoutePaths {
  RoutePaths._();

  static const String root = '/';
  static const String user = '/user';
  static const String admin = '/admin';
}
