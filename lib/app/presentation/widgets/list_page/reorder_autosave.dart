import 'dart:async';

/// 재정렬 모드일 때 무입력(Idle) 상태가 지속되면 저장을 수행.
/// - 각 페이지는 isEnabled/isDirty/getIds/commit/reset 콜백만 넘겨주면 됨.
class ReorderAutosave {
  final Duration duration;
  final bool Function() isEnabled;
  final bool Function() isDirty;
  final List<String> Function() getIds;
  final Future<void> Function(List<String> ids) commit;
  final void Function() resetAfterSave;

  Timer? _timer;

  ReorderAutosave({
    required this.duration,
    required this.isEnabled,
    required this.isDirty,
    required this.getIds,
    required this.commit,
    required this.resetAfterSave,
  });

  void start() {
    _timer?.cancel();
    _timer = Timer(duration, _tick);
  }

  void bump() {
    if (isEnabled()) start();
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _tick() async {
    if (!isEnabled()) return;
    if (isDirty()) {
      await commit(getIds());
    }
    resetAfterSave();
    cancel();
  }
}
