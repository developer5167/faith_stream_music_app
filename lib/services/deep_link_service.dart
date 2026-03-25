import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DeepLinkService {
  final GoRouter _router;
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  DeepLinkService(this._router);

  void init() {
    _handleInitialLink();
    _listenToIncomingLinks();
  }

  Future<void> _handleInitialLink() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } catch (e) {
      debugPrint('[DeepLinkService] Error handling initial link: $e');
    }
  }

  void _listenToIncomingLinks() {
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleUri(uri);
      },
      onError: (err) {
        debugPrint('[DeepLinkService] Error listening to links: $err');
      },
    );
  }

  void _handleUri(Uri uri) {
    debugPrint('[DeepLinkService] Handling URI: $uri');
    String path = uri.path;
    final host = uri.host;

    // Handle case where entity type is in the host (e.g., faithstream://song/123)
    if (host == 'song' || host == 'album' || host == 'artist') {
      path = '/$host$path';
    } else if (host == 'subscription' || host == 'premium') {
      path = '/premium';
    }

    // Check if the link follows our expected patterns
    if (path.startsWith('/song/') ||
        path.startsWith('/album/') ||
        path.startsWith('/artist/') ||
        path == '/premium') {
      debugPrint('[DeepLinkService] Navigating to: $path');
      
      // Attempt to establish a background stack if we are currenty at the root.
      final currentLoc = _router.routerDelegate.currentConfiguration.uri.toString();
      if (currentLoc == '/' || currentLoc == '/splash') {
        _router.go('/home');
      }
      
      _router.push(path);
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
