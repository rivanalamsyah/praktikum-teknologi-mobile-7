import 'package:animations/animations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reply/custom_transition_page.dart';
import 'package:reply/home.dart';
import 'package:reply/search_page.dart';

import 'model/router_provider.dart';

const String _homePageLocation = '/reply/home';
const String _searchPageLocation = '/reply/search';

class ReplyRouterDelegate extends RouterDelegate<ReplyRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<ReplyRoutePath> {
  ReplyRouterDelegate({required this.replyState})
      : navigatorKey = GlobalObjectKey<NavigatorState>(replyState) {
    replyState.addListener(notifyListeners);
  }

  @override
  final GlobalKey<NavigatorState> navigatorKey;

  final RouterProvider replyState;

  @override
  void dispose() {
    replyState.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  ReplyRoutePath get currentConfiguration => replyState.routePath!;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<RouterProvider>.value(value: replyState),
      ],
      child: Selector<RouterProvider, ReplyRoutePath?>(
        selector: (context, routerProvider) => routerProvider.routePath,
        builder: (context, routePath, child) {
          return Navigator(
            key: navigatorKey,
            onPopPage: _handlePopPage,
            pages: [
              const SharedAxisTransitionPageWrapper(
                transitionKey: ValueKey('home'),
                screen: HomePage(),
              ),
              if (routePath is ReplySearchPath)
                const SharedAxisTransitionPageWrapper(
                  transitionKey: ValueKey('search'),
                  screen: SearchPage(),
                ),
            ],
          );
        },
      ),
    );
  }

  bool _handlePopPage(Route<dynamic> route, dynamic result) {
    final bool didPop = route.didPop(result);
    if (didPop && replyState.routePath is ReplySearchPath) {
      replyState.routePath = const ReplyHomePath();
    }
    return didPop;
  }

  @override
  Future<void> setNewRoutePath(ReplyRoutePath configuration) {
    replyState.routePath = configuration;
    return SynchronousFuture<void>(null);
  }
}

@immutable
abstract class ReplyRoutePath {
  const ReplyRoutePath();
}

class ReplyHomePath extends ReplyRoutePath {
  const ReplyHomePath();
}

class ReplySearchPath extends ReplyRoutePath {
  const ReplySearchPath();
}

class SharedAxisTransitionPageWrapper extends Page {
  const SharedAxisTransitionPageWrapper({
    required this.screen,
    required this.transitionKey,
  }) : super(key: transitionKey);

  final Widget screen;
  final ValueKey transitionKey;

  @override
  Route createRoute(BuildContext context) {
    return PageRouteBuilder(
      settings: this,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          fillColor: Theme.of(context).cardColor,
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.scaled,
          child: child,
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return screen;
      },
    );
  }
}

class ReplyRouteInformationParser
    extends RouteInformationParser<ReplyRoutePath> {
  @override
  Future<ReplyRoutePath> parseRouteInformation(
      RouteInformation routeInformation) async {
    final url = Uri.parse(routeInformation.location!);

    if (url.path == _searchPageLocation) {
      return const ReplySearchPath();
    }

    return const ReplyHomePath();
  }

  @override
  RouteInformation? restoreRouteInformation(ReplyRoutePath configuration) {
    if (configuration is ReplyHomePath) {
      return const RouteInformation(location: _homePageLocation);
    }
    if (configuration is ReplySearchPath) {
      return const RouteInformation(location: _searchPageLocation);
    }
    return null;
  }
}
