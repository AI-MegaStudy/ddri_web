import '../../app_config.dart';
import 'web_brand_sync_stub.dart'
    if (dart.library.html) 'web_brand_sync_web.dart' as web_brand_sync;

/// 웹 초기 HTML(title, splash 등)을 앱 상수와 동기화한다.
void syncWebBranding() {
  web_brand_sync.syncWebBranding(
    appTitle: AppConfig.appTitle,
    splashTitle: AppConfig.appTitle,
    splashSubtitle: '${AppConfig.appTitle}이 먼저 살펴보고 있어요.',
    splashAriaLabel: '${AppConfig.appTitle} 로딩 화면',
  );
}
