import 'package:perfum_ahmed_gaper/src/imports/core_imports.dart';
import 'package:perfum_ahmed_gaper/src/imports/packages_imports.dart';

import 'package:perfum_ahmed_gaper/src/features/auth/presentation/providers/auth_bloc.dart';

class LoginScreen extends HookWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final usernameController = useTextEditingController();
    final passwordController = useTextEditingController();
    final obscurePassword = useState(true);

    final authState = context.watch<AuthBloc>().state;
    final isLoading = authState.isLoading;
    final error = authState.error;

    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    useEffect(() {
      if (authState.isAuthenticated) {
        context.go(AppRoutes.dashboard);
      }
      return null;
    }, [authState.isAuthenticated]);

    Future<void> handleLogin() async {
      if (!(formKey.currentState?.validate() ?? false)) return;

      context.read<AuthBloc>().add(
        LoginSubmitted(username: usernameController.text, password: passwordController.text),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: AppSpacing.xl.h),
                Text(
                  'تسجيل الدخول',
                  style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: AppSpacing.sm.h),
                Text(
                  'أدخل اسم المستخدم وكلمة المرور',
                  textAlign: TextAlign.center,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                SizedBox(height: AppSpacing.xxxl.h),
                if (error != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md.h),
                    child: Text(
                      error,
                      style: tt.bodyMedium?.copyWith(color: cs.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Form(
                  key: formKey,
                  child: Column(
                    children: [
                      AppTextField(
                        controller: usernameController,
                        enabled: !isLoading,
                        label: 'اسم المستخدم',
                        prefixIcon: const Icon(IconsaxPlusBold.profile),
                        validator: (v) {
                          if (AppUtils.isBlank(v)) {
                            return 'اسم المستخدم مطلوب';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: AppSpacing.md.h),
                      AppTextField(
                        controller: passwordController,
                        enabled: !isLoading,
                        label: 'كلمة المرور',
                        obscureText: obscurePassword.value,
                        prefixIcon: const Icon(IconsaxPlusBold.lock),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword.value ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => obscurePassword.value = !obscurePassword.value,
                        ),
                        validator: (v) {
                          if (AppUtils.isBlank(v)) {
                            return 'كلمة المرور مطلوبة';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => handleLogin(),
                      ),
                      SizedBox(height: AppSpacing.lg.h),
                      AppButton(
                        label: 'دخول',
                        isLoading: isLoading,
                        onPressed: isLoading ? null : handleLogin,
                        width: ButtonSize.large,
                        isFullWidth: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
