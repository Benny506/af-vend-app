import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import 'package:medusa_admin/src/core/constants/colors.dart';
import 'package:medusa_admin/src/core/extensions/context_extension.dart';
import 'package:medusa_admin/src/core/extensions/snack_bar_extension.dart';
import 'package:medusa_admin/src/core/extensions/string_extension.dart';
import 'package:medusa_admin/src/core/extensions/text_style_extension.dart';
import 'package:medusa_admin/src/core/utils/hide_keyboard.dart';
import 'package:medusa_admin/src/features/auth/presentation/cubits/reset_password/reset_password_cubit.dart';
import 'package:medusa_admin/src/features/auth/presentation/widgets/email_text_field.dart';
import 'components/sign_in_medusa_logo.dart';

@RoutePage()
class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({super.key});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final emailCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool rotate = false;
  void setLoading(bool value) => setState(() => rotate = value);

  @override
  Widget build(BuildContext context) {
    const manatee = ColorManager.manatee;
    final tr = context.tr;
    return BlocListener<ResetPasswordCubit, ResetPasswordState>(
      listener: (context, state) {
        state.mapOrNull(
          loading: (_) {
            setLoading(true);
            context.unfocus();
          },
          success: (_) {
            setLoading(false);
            context.showSnackBar('Password reset instructions sent to your email.');
            if (mounted) {
              context.maybePop();
            }
          },
          error: (error) {
            setLoading(false);
            context.showSignInErrorSnackBar(error.failure.toSnackBarString());
          },
        );
      },
      child: HideKeyboard(
        child: Scaffold(
          appBar: AppBar(
            systemOverlayStyle: context.defaultSystemUiOverlayStyle,
            leading: const CloseButton(),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: context.isDark ? 0.03 : 0.05,
                  child: Image.asset(
                    'assets/images/splash_login_background.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Hero(
                          tag: 'medusa',
                          child: SignInMedusaLogo(rotate: rotate),
                        ),
                        const Gap(16.0),
                        Text(
                          'Afriomarkets',
                          style: context.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF344F16),
                          ),
                        ),
                        Text(
                          'Password Recovery',
                          style: context.bodyLarge?.copyWith(
                            color: const Color(0xFFE48629),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Gap(24.0),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16.0),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                          decoration: BoxDecoration(
                            color: context.theme.cardColor,
                            borderRadius: const BorderRadius.all(Radius.circular(16.0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                            border: Border.all(
                              color: context.theme.dividerColor.withOpacity(0.6),
                              width: 1,
                            ),
                          ),
                          child: Form(
                            key: formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  tr.resetTokenCardResetYourPassword,
                                  style: context.bodyLargeW600?.copyWith(
                                    color: const Color(0xFF344F16),
                                  ),
                                ),
                                const Gap(8.0),
                                Text(
                                  tr.resetTokenCardPasswordResetDescription,
                                  style: context.bodyMedium?.copyWith(color: manatee),
                                  textAlign: TextAlign.center,
                                ),
                                const Gap(20.0),
                                Hero(
                                  tag: 'email',
                                  child: EmailTextField(
                                    controller: emailCtrl,
                                    enabled: !rotate,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (email) {
                                      if (formKey.currentState?.validate() == false) {
                                        return;
                                      }
                                      context
                                          .read<ResetPasswordCubit>()
                                          .resetPassword(email);
                                    },
                                    validator: (val) {
                                      if (val?.isEmpty == true) {
                                        return 'Field is required';
                                      }

                                      if (!emailCtrl.text.isEmail) {
                                        return 'Invalid email';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const Gap(24.0),
                                Hero(
                                  tag: 'continue',
                                  child: FilledButton(
                                    onPressed: rotate
                                        ? null
                                        : () {
                                            if (formKey.currentState?.validate() == false) {
                                              return;
                                            }
                                            context
                                                .read<ResetPasswordCubit>()
                                                .resetPassword(emailCtrl.text);
                                          },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF344F16),
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(double.infinity, 50.0),
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(10.0)),
                                      ),
                                    ),
                                    child: Text(
                                      tr.resetTokenCardSendResetInstructions,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
