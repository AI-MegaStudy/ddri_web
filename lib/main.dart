// DDRI 웹 앱 진입점: Flutter 바인딩 초기화, 웹 Path URL 전략, App 실행
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:get_storage/get_storage.dart';

import 'app.dart';
import 'common/web/web_brand_sync.dart';

/// 앱 진입점.
/// 웹에서는 Path 기반 URL을 사용해 깔끔한 라우트(/user, /admin)를 제공한다.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  if (kIsWeb) {
    usePathUrlStrategy(); // /#/user → /user (path 기반 URL)
    syncWebBranding();
  }
  runApp(const App());
}
