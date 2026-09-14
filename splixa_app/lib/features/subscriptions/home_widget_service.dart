import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

class SplixaHomeWidgetService {
  const SplixaHomeWidgetService._();

  static const appGroupId = 'group.net.splixa.app';
  static const androidProviderName = 'SplixaQuickAddWidgetProvider';
  static const iOSWidgetName = 'SplixaQuickAddWidget';

  static Future<void> update({required bool isPro}) async {
    if (kIsWeb) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await HomeWidget.setAppGroupId(appGroupId);
      }
      await HomeWidget.saveWidgetData<bool>('is_pro', isPro);
      await HomeWidget.saveWidgetData<String>(
        'widget_status',
        isPro ? 'Quick Add' : 'Splixa Pro',
      );
      await HomeWidget.updateWidget(
        name: androidProviderName,
        iOSName: iOSWidgetName,
      );
    } catch (error) {
      debugPrint('Home widget update deferred: $error');
    }
  }

  static Stream<Uri?> get clicks => HomeWidget.widgetClicked;

  static Future<Uri?> initiallyLaunched() {
    return HomeWidget.initiallyLaunchedFromHomeWidget();
  }
}
