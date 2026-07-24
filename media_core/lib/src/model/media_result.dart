/// Minimal result type so the package does not depend on a host Result util.
sealed class MediaResult<T> {
  const MediaResult();

  bool get isOk => this is MediaOk<T>;
  bool get isErr => this is MediaErr<T>;

  T? get valueOrNull => switch (this) {
    MediaOk(:final value) => value,
    MediaErr() => null,
  };

  Object? get errorOrNull => switch (this) {
    MediaOk() => null,
    MediaErr(:final error) => error,
  };
}

final class MediaOk<T> extends MediaResult<T> {
  const MediaOk(this.value);
  final T value;
}

final class MediaErr<T> extends MediaResult<T> {
  const MediaErr(this.error);
  final Object error;
}
