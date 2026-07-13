import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:medusa_admin/src/core/extensions/context_extension.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:medusa_admin/src/core/extensions/snack_bar_extension.dart';
import 'package:medusa_admin/src/core/extensions/text_style_extension.dart';
import 'package:medusa_admin/src/core/routing/app_router.dart';
import 'package:medusa_admin/src/features/auth/presentation/bloc/authentication/authentication_bloc.dart';

@RoutePage()
class SplashView extends StatefulWidget {
  const SplashView({super.key, this.fromLogout = false});

  final bool fromLogout;

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  late Timer timer;
  bool takingTooLong = false;

  @override
  void initState() {
    if (widget.fromLogout) {
      timer = Timer(1.seconds, () {
        context.router.replace(SignInRoute());
      });
    }
    timer = Timer(15.seconds, () {
      setState(() => takingTooLong = true);
    });
    super.initState();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listener: (context, state) {
        state.whenOrNull(
          loggedIn: (loggedIn) async {
            context.router.replace(const DashboardRoute());
          },
          loggedOut: () {
            context.router.replace(SignInRoute());
          },
          error: (e) {
            context.showSignInErrorSnackBar(e.toSnackBarString());
            context.router.replace(SignInRoute());
          },
        );
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: context.systemUiOverlayNoAppBarStyle,
        child: Scaffold(
          body: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                height: context.height,
                width: context.width,
                color: context.theme.scaffoldBackgroundColor,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Hero(
                      tag: 'app_logo',
                      child: Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/square_logo.png',
                            height: 120,
                            width: 120,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const Gap(20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(
                        'Afriomarkets',
                        style: context.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF344F16),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(
                        'Vendor Portal',
                        style: context.bodyLarge?.copyWith(
                          color: const Color(0xFFE48629),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Gap(25),
                    LoadingAnimationWidget.staggeredDotsWave(
                        color: const Color(0xFF344F16), size: 40),
                    const Gap(15),
                  ],
                ),
              ),
              if (takingTooLong)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Taking too long to load?'),
                    const Gap(10),
                    OutlinedButton(
                        onPressed: () {
                          context.router.replaceAll([SignInRoute()]);
                          context
                              .read<AuthenticationBloc>()
                              .add(const AuthenticationEvent.cancel());
                        },
                        child: const Text('Go to login')),
                    Gap(context.bottomViewPadding != 0 ? context.bottomViewPadding : 10),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 200.ms)
                    .move(begin: const Offset(0, 10), curve: Curves.easeOutQuad)
            ],
          ),
        ),
      ),
    );
  }
}
