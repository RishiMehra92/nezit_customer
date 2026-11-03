import 'package:flutter_cache_manager/flutter_cache_manager.dart';

final customCacheManager = CacheManager(
  Config(
    'appImagesCacheKey',
    maxNrOfCacheObjects: 1000,
  ),
);
