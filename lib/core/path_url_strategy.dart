/// PRD section 3: `go_router` with path URLs (no `#`).
///
/// `flutter_web_plugins` only compiles for the web, so the real call lives in
/// the `_web` file and a no-op stands in everywhere else.
library;

export 'path_url_strategy_stub.dart'
    if (dart.library.js_interop) 'path_url_strategy_web.dart';
