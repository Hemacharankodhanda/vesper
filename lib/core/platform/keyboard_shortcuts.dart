import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../audio/audio_providers.dart';
import '../../data/repositories/library_repository.dart';
import '../../features/queue/queue_sheet.dart';

class PlayPauseIntent extends Intent {
  const PlayPauseIntent();
}

class NextTrackIntent extends Intent {
  const NextTrackIntent();
}

class PreviousTrackIntent extends Intent {
  const PreviousTrackIntent();
}

class LikeTrackIntent extends Intent {
  const LikeTrackIntent();
}

class OpenQueueIntent extends Intent {
  const OpenQueueIntent();
}

class VesperKeyboardShortcuts extends ConsumerWidget {
  const VesperKeyboardShortcuts({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioServiceProvider);
    final currentTrack = ref.watch(currentTrackProvider).value;

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.space): const PlayPauseIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowRight): const NextTrackIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): const PreviousTrackIntent(),
        const SingleActivator(LogicalKeyboardKey.keyL): const LikeTrackIntent(),
        const SingleActivator(LogicalKeyboardKey.keyQ): const OpenQueueIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          PlayPauseIntent: CallbackAction<PlayPauseIntent>(
            onInvoke: (_) {
              // Avoid intercepting space if a text field is currently focused
              final focusNode = FocusManager.instance.primaryFocus;
              if (focusNode != null && focusNode.context?.widget is EditableText) {
                return null;
              }
              audio.toggle();
              return null;
            },
          ),
          NextTrackIntent: CallbackAction<NextTrackIntent>(
            onInvoke: (_) {
              final focusNode = FocusManager.instance.primaryFocus;
              if (focusNode != null && focusNode.context?.widget is EditableText) {
                return null;
              }
              audio.next();
              return null;
            },
          ),
          PreviousTrackIntent: CallbackAction<PreviousTrackIntent>(
            onInvoke: (_) {
              final focusNode = FocusManager.instance.primaryFocus;
              if (focusNode != null && focusNode.context?.widget is EditableText) {
                return null;
              }
              audio.previous();
              return null;
            },
          ),
          LikeTrackIntent: CallbackAction<LikeTrackIntent>(
            onInvoke: (_) {
              final focusNode = FocusManager.instance.primaryFocus;
              if (focusNode != null && focusNode.context?.widget is EditableText) {
                return null;
              }
              if (currentTrack != null) {
                ref.read(likedTracksProvider.notifier).toggle(currentTrack.id);
                ref.read(libraryRepositoryProvider).toggleLike(currentTrack.id);
              }
              return null;
            },
          ),
          OpenQueueIntent: CallbackAction<OpenQueueIntent>(
            onInvoke: (_) {
              final focusNode = FocusManager.instance.primaryFocus;
              if (focusNode != null && focusNode.context?.widget is EditableText) {
                return null;
              }
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                constraints: const BoxConstraints(maxWidth: 560),
                builder: (_) => const QueueSheet(),
              );
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: child,
        ),
      ),
    );
  }
}
