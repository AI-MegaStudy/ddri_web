// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

void syncWebBranding({
  required String appTitle,
  required String splashTitle,
  required String splashSubtitle,
  required String splashAriaLabel,
}) {
  html.document.title = appTitle;
  html.document
      .querySelector('meta[name="apple-mobile-web-app-title"]')
      ?.setAttribute('content', appTitle);
  html.document.getElementById('ddri-splash')?.setAttribute(
    'aria-label',
    splashAriaLabel,
  );
  html.document.getElementById('ddri-brand-title')?.text = splashTitle;
  html.document.getElementById('ddri-brand-subtitle-copy')?.text =
      splashSubtitle;
}
