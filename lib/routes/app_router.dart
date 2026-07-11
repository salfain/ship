import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/presentation/admin_dashboard_page.dart';
import '../features/auth/domain/user_session.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/dashboard/presentation/splash_page.dart';
import '../features/manager/presentation/manager_dashboard_page.dart';
import '../features/nahkoda/presentation/nahkoda_dashboard_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/nahkoda',
        builder: (context, state) => const NahkodaDashboardPage(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: '/manager',
        builder: (context, state) => const ManagerDashboardPage(),
      ),
    ],
    errorBuilder: (context, state) => const LoginPage(),
    redirect: (context, state) {
      final path = state.uri.path;
      final isPublic = path == '/login' || path == '/splash';

      if (authState.status == AuthStatus.checking) {
        return path == '/splash' ? null : '/splash';
      }

      if (!authState.isAuthenticated) {
        return path == '/login' ? null : '/login';
      }

      final session = authState.session!;
      if (isPublic) return session.role.homePath;

      final rolePath = _pathForRole(session.role);
      if (rolePath != null && !path.startsWith(rolePath)) {
        return session.role.homePath;
      }

      return null;
    },
  );
});

String? _pathForRole(UserRole role) {
  switch (role) {
    case UserRole.nahkoda:
      return '/nahkoda';
    case UserRole.admin:
      return '/admin';
    case UserRole.manager:
      return '/manager';
    case UserRole.unknown:
      return null;
  }
}
