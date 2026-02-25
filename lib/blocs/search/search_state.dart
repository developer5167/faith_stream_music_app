import 'package:equatable/equatable.dart';
import '../../models/song.dart';
import '../../models/album.dart';
import '../../models/artist.dart';

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchLoaded extends SearchState {
  final List<Song> songs;
  final List<Album> albums;
  final List<Artist> artists;
  final String query;

  const SearchLoaded({
    required this.songs,
    required this.albums,
    required this.artists,
    required this.query,
  });

  @override
  List<Object?> get props => [songs, albums, artists, query];
}

class SearchError extends SearchState {
  final String message;

  const SearchError(this.message);

  @override
  List<Object?> get props => [message];
}
