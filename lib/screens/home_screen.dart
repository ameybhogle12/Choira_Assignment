import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/player_provider.dart';
import '../providers/track_list_provider.dart';
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
    // Deferred to after the first frame: calling loadInitial() synchronously
    // here would run TrackListProvider's notifyListeners() while this widget
    // tree is still being built, which Flutter rejects.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrackListProvider>().loadInitial();
    });
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
      context.read<TrackListProvider>().loadMore();
    }
  }

  void _onSearchChanged(String value) {
    setState(() {}); // refresh the clear (x) button's visibility immediately
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final provider = context.read<TrackListProvider>();
      if (value.trim().isEmpty) {
        provider.clearSearch();
      } else {
        provider.search(value);
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
                          context.read<TrackListProvider>().clearSearch();
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
    return Consumer<TrackListProvider>(
      builder: (context, listProvider, _) {
        final tracks = listProvider.tracks;
        final paginationError = listProvider.paginationError;

        if (paginationError != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;

            final messenger = ScaffoldMessenger.of(context);
            messenger.clearSnackBars();
            final controller = messenger.showSnackBar(
              SnackBar(
                content: Text(paginationError),
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Retry',
                  onPressed: () {
                    listProvider.clearPaginationError();
                    listProvider.retryAfterError();
                  },
                ),
              ),
            );
            // Dismiss it ourselves rather than trusting SnackBar's own
            // duration timer, which was observed to not reliably auto-hide.
            Future.delayed(const Duration(seconds: 4), controller.close);

            listProvider.clearPaginationError();
          });
        }

        if (listProvider.status == TrackListStatus.loading && tracks.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (listProvider.status == TrackListStatus.error && tracks.isEmpty) {
          return _ErrorState(
            message: listProvider.errorMessage ?? 'Something went wrong.',
            onRetry: () => listProvider.isSearching
                ? listProvider.search(_searchController.text)
                : listProvider.loadInitial(),
          );
        }

        if (tracks.isEmpty) {
          return Center(
            child: Text(
              listProvider.isSearching
                  ? 'No tracks match your search.'
                  : 'No tracks available.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        return Consumer<PlayerProvider>(
          builder: (context, player, _) {
            return ListView.builder(
              controller: _scrollController,
              itemCount: tracks.length + (listProvider.hasMore ? 1 : 0),
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
                  isPlaying: player.currentTrack?.id == track.id,
                  onTap: () => player.playQueue(tracks, index),
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
