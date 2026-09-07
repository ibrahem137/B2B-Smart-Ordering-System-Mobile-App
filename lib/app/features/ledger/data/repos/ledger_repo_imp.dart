import 'package:B2B/app/core/cache/cache_keyes.dart';
import 'package:B2B/app/core/networking/api_error_handler.dart';
import 'package:B2B/app/core/networking/api_result.dart';
import 'package:B2B/app/features/ledger/data/data_sources/ledger_local_data_source.dart';
import 'package:B2B/app/features/ledger/data/data_sources/ledger_remote_data_source.dart';
import 'package:B2B/app/features/ledger/data/models/ledger_cache_model.dart';
import 'package:B2B/app/features/ledger/data/models/ledger_response.dart';
import 'package:B2B/app/features/ledger/data/repos/ledger_repo.dart';

class LedgerRepoImpl implements LedgerRepo {
  final LedgerLocalDataSource _local;
  final LedgerRemoteDataSource _remote;

  final Set<String> _activeRequests = {};

  LedgerRepoImpl(this._local, this._remote);

  @override
  Future<void> clearLedger({required int page}) async {
    await _local.clear(page: page);
  }

  @override
  Future<LedgerResponse?> getCachedLedger({
    required int page,
  }) async {
    final cached = await _local.read(page: page);
    return cached?.toResponse();
  }

  @override
  Future<DateTime?> getCachedLedgerAt({
    required int page,
  }) async {
    final cached = await _local.read(page: page);
    return cached?.cachedAt;
  }

  @override
  Future<ApiResult<LedgerResponse>> getLedger({
    required int page,
    bool forceRefresh = false,
  }) async {
    final requestKey = 'ledger_p$page';

    try {
      if (!forceRefresh) {
        final cached = await getCachedLedger(page: page);

        if (cached != null) {
          return ApiResult.success(cached);
        }
      }

      if (_activeRequests.contains(requestKey)) {
        final cached = await getCachedLedger(page: page);

        if (cached != null) {
          return ApiResult.success(cached);
        }
      }

      _activeRequests.add(requestKey);

      final response = await _remote.getLedger(page: page);

      final cacheModel =
          LedgerCacheModel.fromResponse(response);
      await _local.save(cacheModel, page: page);

      return ApiResult.success(response);
    } catch (error) {
      final cached = await getCachedLedger(page: page);

      if (cached != null) {
        return ApiResult.success(cached);
      }

      return ApiResult.failure(ErrorHandler.handle(error));
    } finally {
      _activeRequests.remove(requestKey);
    }
  }

  @override
  bool shouldRefreshLedger(DateTime? cachedAt) {
    if (cachedAt == null) return true;

    return DateTime.now().difference(cachedAt) >=
        CacheKeys.ledgerTtl;
  }
}
