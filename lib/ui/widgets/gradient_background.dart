import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/app_theme.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/profile/profile_state.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      buildWhen: (previous, current) => current is ProfileLoaded,
      builder: (context, state) {
        final bool isPremium =
            state is ProfileLoaded &&
            state.subscription != null &&
            state.subscription!.isActive;

        final gradient = isPremium
            ? AppTheme.premiumDarkGradient
            : AppTheme.freeDarkGradient;

        return Container(
          decoration: BoxDecoration(gradient: gradient),
          child: child,
        );
      },
    );
  }
}
