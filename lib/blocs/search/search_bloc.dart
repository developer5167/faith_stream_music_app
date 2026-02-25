import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';
import 'search_event.dart';
import 'search_state.dart';
import '../../services/search_service.dart';

// Helper to debounce search events so we don't query DB on every keystroke
EventTransformer<Event> debounce<Event>(Duration duration) {
  return (events, mapper) => events.debounce(duration).switchMap(mapper);
}

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchService _searchService;

  SearchBloc(this._searchService) : super(SearchInitial()) {
    on<SearchQueryChanged>(
      _onSearchQueryChanged,
      transformer: debounce(const Duration(milliseconds: 500)),
    );

    on<SearchClear>((event, emit) {
      emit(SearchInitial());
    });
  }

  Future<void> _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    final query = event.query.trim();

    if (query.isEmpty) {
      emit(SearchInitial());
      return;
    }

    emit(SearchLoading());

    try {
      final results = await _searchService.search(query);

      emit(
        SearchLoaded(
          query: query,
          songs: results['songs'] ?? [],
          albums: results['albums'] ?? [],
          artists: results['artists'] ?? [],
        ),
      );
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }
}
