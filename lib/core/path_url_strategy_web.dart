import 'package:flutter_web_plugins/url_strategy.dart';

/// Serves `/plans` instead of `/#/plans`.
///
/// This is why `web/.htaccess` exists (PRD section 12 step 2) — the hosting
/// has to send every unknown path back to `index.html`.
void configurePathUrlStrategy() => usePathUrlStrategy();
