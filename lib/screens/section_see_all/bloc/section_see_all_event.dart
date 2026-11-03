import 'package:equatable/equatable.dart';

abstract class SectionSeeAllEvent extends Equatable {
  const SectionSeeAllEvent();

  @override
  List<Object?> get props => [];
}

/// Fetch the first page of a section's items. [type] selects the model the
/// bloc parses each item into ('categories' / 'brands').
class FetchSectionItems extends SectionSeeAllEvent {
  final int sectionId;
  final String type;

  const FetchSectionItems({required this.sectionId, required this.type});

  @override
  List<Object?> get props => [sectionId, type];
}

/// Fetch the next page and append. Uses the section id / page cursor held by
/// the bloc.
class FetchMoreSectionItems extends SectionSeeAllEvent {
  const FetchMoreSectionItems();
}
