import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '/flutter_flow/flutter_flow_animations.dart';

/// إعدادات الأداء المشتركة — تقليل العمل غير الضروري على الشاشات الثقيلة.
abstract final class TouryPerf {
  TouryPerf._();

  /// تعطيل حركات الدخول الثقيلة لتحسين زمن الاستجابة الأول.
  static const skipHeavyAnimations = true;

  /// قوائم داخل ScrollView واحد — لا تتنافس مع التمرير الرئيسي.
  static const nestedListPhysics = NeverScrollableScrollPhysics();

  /// فك التركيز فقط عند وجود لوحة مفاتيح مفتوحة — لا يبطّئ كل ضغطة.
  static void unfocusIfNeeded(BuildContext context) {
    final primary = FocusManager.instance.primaryFocus;
    if (primary == null || !primary.hasFocus) return;
    primary.unfocus();
  }
}

extension TouryPerfAnimateX on Widget {
  Widget touryPageAnim(AnimationInfo? info) {
    if (TouryPerf.skipHeavyAnimations || info == null) return this;
    return animateOnPageLoad(info);
  }
}
