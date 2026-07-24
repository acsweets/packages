/// Cross-project media cache and playback core.
///
/// Contract: given URL / local path / [MediaRef], provides disk cache,
/// selection helpers, and mutex / visibility-aware playback.
///
/// Network layer is **host-owned**: fetch URLs with any HTTP/RPC/repository,
/// then pass them in. This package never depends on a specific API client.
library;

export 'src/bootstrap/media_core_config.dart';
export 'src/bootstrap/media_core_logger.dart';

export 'src/model/media_kind.dart';
export 'src/model/media_meta.dart';
export 'src/model/media_playback_state.dart';
export 'src/model/media_ref.dart';
export 'src/model/media_result.dart';

export 'src/cache/media_cache.dart';
export 'src/cache/media_image_provider.dart';

export 'src/selection/media_selector.dart';

export 'src/player/media_player_controller.dart';
export 'src/player/media_session.dart';

export 'src/widgets/media_player_view.dart';
export 'src/widgets/media_view.dart';
