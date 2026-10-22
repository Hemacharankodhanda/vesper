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

class VolumeUpIntent extends Intent {
  const VolumeUpIntent();
}

class VolumeDownIntent extends Intent {
  const VolumeDownIntent();
}

class ToggleMuteIntent extends Intent {
  const ToggleMuteIntent();
}

class VesperKeyboardShortcuts extends ConsumerStatefulWidget {
  const VesperKeyboardShortcuts({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<VesperKeyboardShortcuts> createState() =>
      _VesperKeyboardShortcutsState();
}

class _VesperKeyboardShortcutsState
    extends ConsumerState<VesperKeyboardShortcuts> {
  double _lastVolume = 1.0;

  @override
  Widget build(BuildContext context) {
    final audio = ref.watch(audioServiceProvider);
    final currentTrack = ref.watch(currentTrackProvider).value;

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.space):
            const PlayPauseIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowRight):
            const NextTrackIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowLeft):
            const PreviousTrackIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowUp):
            const VolumeUpIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowDown):
            const VolumeDownIntent(),
        const SingleActivator(LogicalKeyboardKey.keyM):
            const ToggleMuteIntent(),
        const SingleActivator(LogicalKeyboardKey.keyL): const LikeTrackIntent(),
        const SingleActivator(LogicalKeyboardKey.keyQ): const OpenQueueIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          PlayPauseIntent: CallbackAction<PlayPauseIntent>(
            onInvoke: (_) {
              // Avoid intercepting space if a text field is currently focused
              final focusNode = FocusManager.instance.primaryFocus;
              if (focusNode != null &&
                  focusNode.context?.widget is EditableText) {
                return null;
              }
              audio.toggle();
              return null;
            },
          ),
          NextTrackIntent: CallbackAction<NextTrackIntent>(
            onInvoke: (_) {
              final focusNode = FocusManager.instance.primaryFocus;
              if (focusNode != null &&
                  focusNode.context?.widget is EditableText) {
                return null;
              }
              audio.next();
              return null;
            },
          ),
          PreviousTrackIntent: CallbackAction<PreviousTrackIntent>(
            onInvoke: (_) {
              final focusNode = FocusManager.instance.primaryFocus;
              if (focusNode != null &&
                  focusNode.context?.widget is EditableText) {
                return null;
              }
              audio.previous();
              return null;
            },
          ),
          LikeTrackIntent: CallbackAction<LikeTrackIntent>(
            onInvoke: (_) {
              final focusNode = FocusManager.instance.primaryFocus;
              if (focusNode != null &&
                  focusNode.context?.widget is EditableText) {
                return null;
              }
              if (currentTrack != null) {
                ref.read(likedTracksProvider.notifier).toggle(currentTrack.id);
                ref.read(libraryRepositoryProvider).toggleLike(currentTrack.id);
              }
              return null;
            },
          ),
          VolumeUpIntent: CallbackAction<VolumeUpIntent>(
            onInvoke: (_) {
              final focusNode = FocusManager.instance.primaryFocus;
              if (focusNode != null &&
                  focusNode.context?.widget is EditableText) {
                return null;
              }
              final nextVol = (audio.volume + 0.05).clamp(0.0, 1.0);
              audio.setVolume(nextVol);
              return null;
            },
          ),
          VolumeDownIntent: CallbackAction<VolumeDownIntent>(
            onInvoke: (_) {
              final focusNode = FocusManager.instance.primaryFocus;
              if (focusNode != null &&
                  focusNode.context?.widget is EditableText) {
                return null;
              }
              final nextVol = (audio.volume - 0.05).clamp(0.0, 1.0);
              audio.setVolume(nextVol);
              return null;
            },
          ),
          ToggleMuteIntent: CallbackAction<ToggleMuteIntent>(
            onInvoke: (_) {
              final focusNode = FocusManager.instance.primaryFocus;
              if (focusNode != null &&
                  focusNode.context?.widget is EditableText) {
                return null;
              }
              if (audio.volume > 0.01) {
                _lastVolume = audio.volume;
                audio.setVolume(0.0);
              } else {
                audio.setVolume(_lastVolume > 0.01 ? _lastVolume : 1.0);
              }
              return null;
            },
          ),
          OpenQueueIntent: CallbackAction<OpenQueueIntent>(
            onInvoke: (_) {
              final focusNode = FocusManager.instance.primaryFocus;
              if (focusNode != null &&
                  focusNode.context?.widget is EditableText) {
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
        child: Focus(autofocus: true, child: widget.child),
      ),
    );
  }
}
