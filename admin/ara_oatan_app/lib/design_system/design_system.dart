/// Tory Taxi Design System — single import for Phase 2 UI migration.
///
/// Usage (when applying theme later):
/// ```dart
/// MaterialApp(
///   theme: DsTheme.light(),
///   darkTheme: DsTheme.dark(),
/// )
/// ```
library;

// Tokens
export 'colors/ds_color_scales.dart';
export 'colors/ds_colors.dart';
export 'typography/ds_typography.dart';
export 'spacing/ds_spacing.dart';
export 'radius/ds_radius.dart';
export 'shadows/ds_shadows.dart';
export 'constants/ds_constants.dart';

// Motion
export 'animations/ds_animations.dart';
export 'animations/ds_page_transitions.dart';

// Theme
export 'theme/ds_theme.dart';
export 'extensions/ds_context_extensions.dart';
export 'extensions/ds_theme_extension.dart';

// Widgets — buttons
export 'widgets/buttons/ds_button.dart';
export 'widgets/buttons/ds_icon_button.dart';

// Widgets — inputs
export 'widgets/inputs/ds_text_field.dart';
export 'widgets/inputs/ds_otp_field.dart';

// Widgets — cards
export 'widgets/cards/ds_card.dart';

// Widgets — feedback
export 'widgets/feedback/ds_feedback.dart';

// Widgets — navigation
export 'widgets/navigation/ds_navigation.dart';
export 'widgets/navigation/ds_screen_shell.dart';

// Widgets — display
export 'widgets/display/ds_display.dart';

// Widgets — icons
export 'widgets/icons/ds_icons.dart';
