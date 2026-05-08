import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/auth_providers.dart';
import '../../theme/cine_theme.dart';
import '../../theme/motion_tokens.dart';
import '../../widgets/motion/fade_slide_in.dart';
import '../../widgets/motion/staggered_reveal.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    if (authState.user != null) {
      return _SignedInProfile(
        userEmail: authState.user?.email ?? 'User',
        joinedDate: authState.user?.createdAt.toString().substring(0, 10) ?? '',
        isLoading: authState.isLoading,
        onSignOut: () => ref.read(authStateProvider.notifier).signOut(),
      );
    }

    return Scaffold(
      body: CinematicBackdrop(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 980;

                return ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: isWide
                      ? Row(
                          children: [
                            Expanded(
                              child: StaggeredReveal(
                                index: 0,
                                child: _AuthIntro(isLogin: _isLogin),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: StaggeredReveal(
                                index: 1,
                                child: _AuthFormCard(
                                  emailController: _emailController,
                                  passwordController: _passwordController,
                                  isLogin: _isLogin,
                                  obscurePassword: _obscurePassword,
                                  isLoading: authState.isLoading,
                                  error: authState.error,
                                  onTogglePassword: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  onToggleMode: () =>
                                      setState(() => _isLogin = !_isLogin),
                                  onSubmit: _handleSubmit,
                                ),
                              ),
                            ),
                          ],
                        )
                      : FadeSlideIn(
                          child: _AuthFormCard(
                            emailController: _emailController,
                            passwordController: _passwordController,
                            isLogin: _isLogin,
                            obscurePassword: _obscurePassword,
                            isLoading: authState.isLoading,
                            error: authState.error,
                            onTogglePassword: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            onToggleMode: () =>
                                setState(() => _isLogin = !_isLogin),
                            onSubmit: _handleSubmit,
                            showIntro: true,
                          ),
                        ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in both email and password.'),
        ),
      );
      return;
    }

    try {
      if (_isLogin) {
        await ref
            .read(authStateProvider.notifier)
            .signIn(email: email, password: password);
      } else {
        await ref
            .read(authStateProvider.notifier)
            .signUp(email: email, password: password);
      }
    } catch (_) {
      // Errors are surfaced via authState.error.
    }
  }
}

class _SignedInProfile extends StatelessWidget {
  final String userEmail;
  final String joinedDate;
  final bool isLoading;
  final VoidCallback onSignOut;

  const _SignedInProfile({
    required this.userEmail,
    required this.joinedDate,
    required this.isLoading,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final initials = userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'U';

    return Scaffold(
      body: CinematicBackdrop(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            const StaggeredReveal(index: 0, child: _ProfileTitle()),
            const SizedBox(height: 10),
            StaggeredReveal(
              index: 1,
              child: CineGlassPanel(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            CinePalette.accent.withAlpha(240),
                            CinePalette.accentAlt.withAlpha(220),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Color(0xFF251900),
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userEmail,
                            style: const TextStyle(
                              color: CinePalette.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Member since $joinedDate',
                            style: const TextStyle(
                              color: CinePalette.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            StaggeredReveal(
              index: 2,
              child: CineGlassPanel(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    _ProfileActionTile(
                      icon: Icons.bookmark_rounded,
                      title: 'Open My Lists',
                      subtitle: 'View saved titles, favorites, and ratings.',
                      onTap: () => context.go('/watchlist'),
                    ),
                    const Divider(height: 14),
                    _ProfileActionTile(
                      icon: Icons.search_rounded,
                      title: 'Find Something New',
                      subtitle: 'Search by title, mood, or genre.',
                      onTap: () => context.go('/search'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            StaggeredReveal(
              index: 3,
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : onSignOut,
                icon: isLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout_rounded),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFFA8A8),
                  side: const BorderSide(color: Color(0xFFFF8D8D)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthIntro extends StatelessWidget {
  final bool isLogin;

  const _AuthIntro({required this.isLogin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'CineFlix',
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 62,
              color: CinePalette.accent,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isLogin
                ? 'Jump back in and continue your movie journey.'
                : 'Create your account and build your personal cinema.',
            style: const TextStyle(
              color: CinePalette.textMuted,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthFormCard extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLogin;
  final bool obscurePassword;
  final bool isLoading;
  final String? error;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleMode;
  final VoidCallback onSubmit;
  final bool showIntro;

  const _AuthFormCard({
    required this.emailController,
    required this.passwordController,
    required this.isLogin,
    required this.obscurePassword,
    required this.isLoading,
    required this.error,
    required this.onTogglePassword,
    required this.onToggleMode,
    required this.onSubmit,
    this.showIntro = false,
  });

  @override
  Widget build(BuildContext context) {
    return CineGlassPanel(
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showIntro) ...[
            Text(
              'CineFlix',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 44,
                color: CinePalette.accent,
              ),
            ),
            const SizedBox(height: 8),
          ],
          AnimatedSwitcher(
            duration: CineMotion.resolveDuration(context, CineMotion.normal),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Column(
              key: ValueKey('auth-mode-${isLogin ? 'login' : 'signup'}'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLogin ? 'Welcome back' : 'Create account',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  isLogin
                      ? 'Sign in to sync your lists and ratings.'
                      : 'Start building your personal watch universe.',
                  style: const TextStyle(color: CinePalette.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: passwordController,
            obscureText: obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: onTogglePassword,
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                ),
              ),
            ),
            onSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: isLoading ? null : onSubmit,
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isLogin ? 'Sign In' : 'Create Account'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: isLoading ? null : onToggleMode,
            child: Text(
              isLogin
                  ? 'Need an account? Sign Up'
                  : 'Already have an account? Sign In',
            ),
          ),
          AnimatedSwitcher(
            duration: CineMotion.resolveDuration(context, CineMotion.fast),
            child: (error != null && error!.trim().isNotEmpty)
                ? Padding(
                    key: ValueKey('auth-error-$error'),
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      error!,
                      style: const TextStyle(
                        color: Color(0xFFFFB0B0),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('auth-error-none')),
          ),
        ],
      ),
    );
  }
}

class _ProfileTitle extends StatelessWidget {
  const _ProfileTitle();

  @override
  Widget build(BuildContext context) {
    return Text('Profile', style: Theme.of(context).textTheme.headlineLarge);
  }
}

class _ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: CinePalette.accent.withAlpha(220),
              ),
              child: Icon(icon, color: const Color(0xFF271B02)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: CinePalette.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: CinePalette.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: CinePalette.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
