import 'package:construculator/app/check_gate/check_gate_bloc.dart';
import 'package:construculator/libraries/extensions/build_context_extensions.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Covers [child] with a loading screen until the sign-in check has finished.
///
/// [child] stays built underneath, so the router can still move to the sign-in
/// screen while the check runs, but while the screen is covered it takes no
/// taps and is left out of the screen reader's tree.
class CheckGate extends StatelessWidget {
  /// The app's screens.
  final Widget? child;

  /// A gate over [child].
  const CheckGate({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckGateBloc, CheckGateState>(
      builder: (context, state) => Stack(
        children: [
          ExcludeSemantics(
            excluding: state is CheckGateHolding,
            child: IgnorePointer(
              ignoring: state is CheckGateHolding,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
          if (state is CheckGateHolding)
            Positioned.fill(
              key: const Key('check_gate_loading_screen'),
              child: ColoredBox(
                color: context.colorTheme.pageBackground,
                child: const CoreLoadingIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
