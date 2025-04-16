import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart' as cp;
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/components/audio_manager.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/components/background_component.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/components/booster_manager.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/components/enemy_manager.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/components/player_component.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/components/trash_manager.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/data/providers/score_provider.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/game/overlay_widgets/env_message_overlay.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/game/overlay_widgets/game_header.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/game/overlay_widgets/pause_menu.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/helper/enums.dart';

class MyGame extends FlameGame {
  final BuildContext context;
  final WidgetRef ref;

  MyGame(this.context, this.ref);

  SpeedMode gameSpeed = SpeedMode.slow;

  final PlayerComponent player = PlayerComponent();

  late final MyParallaxComponent parallaxComponent = MyParallaxComponent();
  late final BackgroundComponent backgroundComponent = BackgroundComponent()
    ..size = size;
  final BoosterManager boosterManager = BoosterManager();
  final TrashManager trashManager = TrashManager();
  final EnemyManager enemyManager = EnemyManager();
  final AudioManager audioManager = AudioManager();

  late final Vector2 gameSize;

  int level = 0;
  GameState gameState = GameState.initial;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    await Flame.device.fullScreen();
    //await Flame.device.setLandscape();
    gameSize = size;
    add(backgroundComponent);
    add(parallaxComponent);
    add(audioManager);
  }

  @override
  pauseEngine() {
    super.pauseEngine();
    if (gameState == GameState.playing) {
      audioManager.stopBgmMusic();
      gameState = GameState.paused;
      overlays.remove(GameHeader.id);
      overlays.add(PauseMenu.id);
      boosterManager.timer.cancel();
      trashManager.timer.cancel();
      enemyManager.timer.cancel();
    }
  }

  @override
  resumeEngine() {
    super.resumeEngine();
    if (gameState == GameState.paused) {
      audioManager.playBgmMusic();
      gameState = GameState.playing;
      overlays.remove(PauseMenu.id);
      overlays.add(GameHeader.id);
      boosterManager.start();
      trashManager.start();
      enemyManager.start();
    }
  }

  void startGame() async {
    audioManager.playBgmMusic();
    gameState = GameState.playing;
    level = 1;
    add(player);
    overlays.add(GameHeader.id);
    player.startMovingUp();
    add(enemyManager);
    enemyManager.start();
    add(trashManager);
    trashManager.start();
    add(boosterManager);
    boosterManager.start();
    //ref.read(aiMessageNotifierProvider.notifier).getAiMessage();
  }

  levelUp() {
    level++;
    if (!player.hasShield) {
      updateSpeed();
    }
  }

  double get randomPositionX => Random().nextInt(gameSize.x.toInt()).toDouble();

  void updateSpeed() async {
    const speedValues = SpeedMode.values;
    gameSpeed =
        level < speedValues.length ? speedValues[level - 1] : speedValues.last;
    await parallaxComponent.updateSpeed(gameSpeed);
  }

  void sharkAttack(String componentId) async {
    final _enemies = enemyManager.enemyComponents;
    final index = _enemies.indexWhere((element) => element.id == componentId);
    if (index != -1) {
      audioManager.stopBgmMusic();
      audioManager.play('crash.wav');
      addEffect(
        effect: AnimationEffect.crash,
        position: crashPosition(_enemies[index].position),
        size: Vector2.all(250),
      );
      //player.isDead = true;
      final enemies = List.of(
          enemyManager.enemyComponents); // Tạo bản sao để tránh lỗi iterator

      Future.delayed(const Duration(milliseconds: 500), () {
        gameOver();
        for (var enemy in enemies) {
          enemy.removeFromParent(); // Xoá từng enemy khỏi game
        }

        enemyManager.enemyComponents.clear();
      });
    }
  }

  Vector2 crashPosition(Vector2 enemyPosition) {
    final playerPosition = player.position;
    final x = playerPosition.x + (enemyPosition.x - playerPosition.x) / 2;
    final y = playerPosition.y + (enemyPosition.y - playerPosition.y) / 2;
    return Vector2(x, y);
  }

  void gameOver() async {
    gameState = GameState.gameOver;
    pauseEngine();
    ref.read(scoreNotifierProvider.notifier).loadScores();
    overlays.remove(GameHeader.id);
    overlays.add(EnvMessageOverlay.id);
  }

  void reset() {
    gameState = GameState.initial;
    trashManager.reset();
    boosterManager.reset();
    enemyManager.reset();
    level = 0;
    gameSpeed = SpeedMode.slow;
    parallaxComponent.reset();
    player.isDead = false;
    player.setToInitialPosition();
    remove(player);
    ref.read(scoreNotifierProvider.notifier).resetScore();
  }

  void encreaseScore() {
    if (ref.read(scoreNotifierProvider.notifier).encreaseScore()) {
      levelUp();
    }
  }

  Future<void> addEffect(
      {required AnimationEffect effect,
      required Vector2 position,
      required Vector2 size}) async {
    final animationEffect = cp.SpriteAnimationComponent.fromFrameData(
      await images.load('${effect.name}.png'),
      cp.SpriteAnimationData.sequenced(
        amount: effect.amount,
        amountPerRow: effect.amountPerRow,
        textureSize: Vector2.all(effect.size),
        stepTime: effect.speed,
        loop: false,
      ),
      size: size,
      removeOnFinish: true,
      anchor: cp.Anchor.center,
    );

    animationEffect.position = position;
    add(animationEffect);
  }
}
