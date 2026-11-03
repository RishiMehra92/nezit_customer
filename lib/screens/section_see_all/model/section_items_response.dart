import '../../../config/helper.dart';

/// Parsed wrapper for GET /api/home-layout/sections/{section}. Holds the
/// pagination meta plus the raw item maps; the bloc turns [items] into the
/// right typed model (CategoryData / BrandData) based on the section type.
class SectionItemsResponse {
  final bool success;
  final String message;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final List<Map<String, dynamic>> items;

  SectionItemsResponse({
    required this.success,
    required this.message,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.items,
  });

  factory SectionItemsResponse.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map?)?.cast<String, dynamic>() ?? const {};
    final rawItems = (data['data'] as List?) ?? const [];
    final currentPage = parseInt(data['current_page']) ?? 1;
    final lastPage = parseInt(data['last_page']) ?? 1;
    return SectionItemsResponse(
      success: json['success'] == true,
      message: parseString(json['message']) ?? '',
      // Pagination is 1-based; guard against a missing/0 value so the bloc's
      // hasReachedMax (currentPage >= lastPage) behaves sanely.
      currentPage: currentPage == 0 ? 1 : currentPage,
      lastPage: lastPage == 0 ? 1 : lastPage,
      perPage: parseInt(data['per_page']) ?? 0,
      total: parseInt(data['total']) ?? 0,
      items: rawItems
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList(),
    );
  }
}
