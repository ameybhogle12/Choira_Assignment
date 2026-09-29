import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/playback/playback_bloc.dart';
import '../blocs/playback/playback_event.dart';
import '../blocs/playback/playback_state.dart';
import '../blocs/track_list/track_list_bloc.dart';
import '../blocs/track_list/track_list_event.dart';
import '../blocs/track_list/track_list_state.dart';
import '../widgets/mini_player.dart';
import '../widgets/track_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Fire the next page once the user is ~80% down the list, not at the
  // exact bottom - keeps scrolling feeling continuous.
  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent * 0.8) {
      context.read<TrackListBloc>().add(const TrackListLoadMoreRequested());
    }
  }

  void _onSearchChanged(String value) {
    setState(() {}); // refresh the clear (x) button's visibility immediately
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final bloc = context.read<TrackListBloc>();
      if (value.trim().isEmpty) {
        bloc.add(const TrackListLoadInitialRequested());
      } else {
        bloc.add(TrackListSearchRequested(value));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choira Music')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search tracks or artists',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _debounce?.cancel();
                          context.read<TrackListBloc>().add(
                            const TrackListLoadInitialRequested(),
                          );
                          setState(() {});
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(child: _buildList()),
        ],
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }

  Widget _buildList() {
    // BlocConsumer = BlocListener (side effects, runs once per change) +
    // BlocBuilder (draws UI). The listener replaces the Provider version's
    // addPostFrameCallback + clearPaginationError() workaround.
    return BlocConsumer<TrackListBloc, TrackListState>(
      listenWhen: (previous, current) =>
          current.paginationError != null &&
          previous.paginationError != current.paginationError,
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        final controller = messenger.showSnackBar(
          SnackBar(
            content: Text(state.paginationError!),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => context.read<TrackListBloc>().add(
                const TrackListRetryRequested(),
              ),
            ),
          ),
        );
        // Dismiss it ourselves rather than trusting SnackBar's own
        // duration timer, which was observed to not reliably auto-hide.
        Future.delayed(const Duration(seconds: 4), controller.close);
      },
      builder: (context, listState) {
        final tracks = listState.tracks;

        if (listState.status == TrackListStatus.loading && tracks.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (listState.status == TrackListStatus.error && tracks.isEmpty) {
          return _ErrorState(
            message: listState.errorMessage ?? 'Something went wrong.',
            onRetry: () => context.read<TrackListBloc>().add(
              listState.isSearching
                  ? TrackListSearchRequested(_searchController.text)
                  : const TrackListLoadInitialRequested(),
            ),
          );
        }

        if (tracks.isEmpty) {
          return Center(
            child: Text(
              listState.isSearching
                  ? 'No tracks match your search.'
                  : 'No tracks available.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        // buildWhen: only rebuild the list when the playing track changes -
        // not on every position tick while a song plays.
        return BlocBuilder<PlaybackBloc, PlaybackState>(
          buildWhen: (previous, current) =>
              previous.currentTrack?.id != current.currentTrack?.id,
          builder: (context, playback) {
            return ListView.builder(
              controller: _scrollController,
              itemCount: tracks.length + (listState.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= tracks.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final track = tracks[index];
                return TrackTile(
                  track: track,
                  isPlaying: playback.currentTrack?.id == track.id,
                  onTap: () => context.read<PlaybackBloc>().add(
                    PlaybackQueueStarted(tracks, index),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
