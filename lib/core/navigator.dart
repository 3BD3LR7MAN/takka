import 'package:flutter/material.dart';

/// Global navigator key — يتيح للخدمات (الإشعارات) التنقل بدون BuildContext.
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
