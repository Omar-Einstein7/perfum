import '../../imports/core_imports.dart';
import '../../imports/packages_imports.dart';

class ForbiddenPage extends StatelessWidget {
  const ForbiddenPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon styling matching rich aesthetics
                Container(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: cs.errorContainer.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    IconsaxPlusBold.security_safe,
                    size: 72.w,
                    color: cs.error,
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
                // Heading
                Text(
                  'Access Denied',
                  style:
                      tt.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.error,
                      ) ??
                      TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: cs.error,
                      ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.sm),
                // Message
                Text(
                  'You do not have the required permissions to view this resource.',
                  style:
                      tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant) ??
                      TextStyle(fontSize: 16, color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.xl),
                // Button
                AppButton(
                  label: 'Go to Dashboard',
                  onPressed: () => context.go(AppRoutes.home),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
