import 'package:flutter/material.dart';

import '../services/api_service.dart';

class AuthGuard extends StatefulWidget {
  const AuthGuard({super.key, required this.builder, this.redirectRoute = '/'});

  final WidgetBuilder builder;
  final String redirectRoute;

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  @override
  void initState() {
    super.initState();
    _redirectIfUnauthenticated();
  }

  void _redirectIfUnauthenticated() {
    if (ApiService.authToken != null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil(widget.redirectRoute, (route) => false);
    });
  }

  @override
  void didUpdateWidget(covariant AuthGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _redirectIfUnauthenticated();
  }

  @override
  Widget build(BuildContext context) {
    if (ApiService.authToken == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return widget.builder(context);
  }
}
