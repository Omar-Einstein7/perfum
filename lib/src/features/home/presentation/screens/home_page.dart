import 'package:perfum_ahmed_gaper/src/imports/core_imports.dart';
import 'package:perfum_ahmed_gaper/src/imports/packages_imports.dart';

import 'package:perfum_ahmed_gaper/src/features/auth/presentation/providers/auth_bloc.dart';

class HomePage extends HookWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final authState = context.watch<AuthBloc>().state;
    final employee = authState.employee;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppTopBar(
        title: 'home.home_title'.tr(),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppIcon(
                icon: IconsaxPlusLinear.home,
                size: 60.sp,
                color: colorScheme.primary,
              ),
              SizedBox(height: AppSpacing.lg.h),
              Text(
                employee?.fullName ?? ('home.welcome_home'.tr()),
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                  fontSize: 28.sp,
                ),
              ),
              SizedBox(height: AppSpacing.md.h),
              Text(
                employee != null ? 'فرع رقم ${employee.branchId}' : ('home.home_subtitle'.tr()),
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
