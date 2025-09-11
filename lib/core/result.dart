import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cartridge/core/validation.dart';
part 'result.freezed.dart';

@freezed
sealed class Result<T> with _$Result<T> {
  const factory Result.ok({T? data, String? code, Map<String, Object?>? ctx}) = _Ok<T>;
  const factory Result.notFound({String? code, Map<String, Object?>? ctx}) = _NotFound<T>;
  const factory Result.invalid({required List<Violation> violations, String? code, Map<String, Object?>? ctx}) = _Invalid<T>;
  const factory Result.conflict({String? code, Map<String, Object?>? ctx}) = _Conflict<T>;
  const factory Result.failure({String? code, Object? error, Map<String, Object?>? ctx}) = _Failure<T>;
}
