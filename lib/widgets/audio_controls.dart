import 'package:flutter/material.dart';
import 'package:flutter_sleepy/constants/constants.dart';
import 'package:flutter_sleepy/widgets/showSliderDialog.dart';
import 'package:just_audio/just_audio.dart';

class AudioControls extends StatelessWidget {
  final AudioPlayer player;

  const AudioControls(this.player, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildVolumeControl(context),
        const SizedBox(width: 40.0),
        // 재생/일시정지 버튼
        StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final playing = playerState?.playing;

            if (processingState == ProcessingState.loading ||
                processingState == ProcessingState.buffering) {
              return Container(
                margin: const EdgeInsets.all(8.0),
                width: 64.0,
                height: 64.0,
                child: const CircularProgressIndicator(),
              );
            }

            return IconButton(
              icon: Icon(
                playing ?? false ? Icons.pause_circle : Icons.play_circle,
                color: Colors.tealAccent,
              ),
              iconSize: 64.0,
              onPressed: () {
                if (playing ?? false) {
                  player.pause();
                } else {
                  player.play();
                }
              },
            );
          },
        ),
        const SizedBox(width: 40),
        _buildSpeedControl(context),
      ],
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
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.tealAccent
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