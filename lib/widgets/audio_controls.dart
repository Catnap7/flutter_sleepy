import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_sleepy/constants/constants.dart';
import 'package:flutter_sleepy/widgets/showSliderDialog.dart';
import 'package:just_audio/just_audio.dart';

class AudioControls extends StatelessWidget {
  final AudioPlayer player;
  final ValueChanged<bool>? onPlayPauseChanged;

  const AudioControls(this.player, {super.key, this.onPlayPauseChanged});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildVolumeControl(context),
                const SizedBox(width: 24.0),
                // 재생/일시정지 버튼
                StreamBuilder<PlayerState>(
                  stream: player.playerStateStream,
                  builder: (context, snapshot) {
                    final playerState = snapshot.data;
                    final processingState = playerState?.processingState;
                    final playing = playerState?.playing;

                    if (processingState == ProcessingState.loading ||
                        processingState == ProcessingState.buffering) {
                      return SizedBox(
                        width: 64.0,
                        height: 64.0,
                        child: const CircularProgressIndicator(),
                      );
                    }

                    final isPlaying = playing ?? false;
                    return Semantics(
                      button: true,
                      label: isPlaying ? 'Pause playback' : 'Play sound',
                      child: IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause_circle : Icons.play_circle,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        iconSize: 64.0,
                        onPressed: () {
                          if (isPlaying) {
                            player.pause();
                            onPlayPauseChanged?.call(false);
                          } else {
                            player.play();
                            onPlayPauseChanged?.call(true);
                          }
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(width: 24),
                _buildSpeedControl(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVolumeControl(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.volume_up),
      onPressed: () => _showVolumeDialog(context),
    );
  }

  Widget _buildSpeedControl(BuildContext context) {
    return StreamBuilder<double>(
      stream: player.speedStream,
      builder: (context, snapshot) {
        final speed = snapshot.data?.toStringAsFixed(1) ?? '1.0';
        return IconButton(
          icon: Text(
            "${speed}x",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary
            ),
          ),
          onPressed: () => _showSpeedDialog(context),
        );
      },
    );
  }

  void _showVolumeDialog(BuildContext context) {
    showSliderDialog(
      context: context,
      title: "볼륨 조절",
      divisions: 10,
      min: 0.0,
      max: AppConstants.maxVolume,
      value: player.volume,
      stream: player.volumeStream,
      onChanged: player.setVolume,
    );
  }

  void _showSpeedDialog(BuildContext context) {
    showSliderDialog(
      context: context,
      title: "재생 속도 조절",
      divisions: 10,
      min: AppConstants.minSpeed,
      max: AppConstants.maxSpeed,
      value: player.speed,
      stream: player.speedStream,
      onChanged: player.setSpeed,
    );
  }
}