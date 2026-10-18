import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fun_edu/di/locator.dart';
import 'package:fun_edu/features/shop_game/data/datasources/shop_game_levels_data.dart';
import 'package:fun_edu/features/shop_game/presentation/cubit/shop_game_cubit.dart';
import 'package:fun_edu/features/shop_game/presentation/cubit/shop_game_state.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/layers/ambient_particles_layer.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/layers/background_scenery_layer.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/layers/countertop_layer.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/layers/customer_character_layer.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/layers/fruit_shelf_draggable_layer.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/layers/game_hud_overlay.dart';

class ShopGameScreen extends StatefulWidget {
  final String levelId;
  final ShopGameCubit? cubit;

  const ShopGameScreen({
    super.key,
    required this.levelId,
    this.cubit,
  });

  @override
  State<ShopGameScreen> createState() => _ShopGameScreenState();
}

class _ShopGameScreenState extends State<ShopGameScreen> {
  late final ShopGameCubit _cubit;
  final bool _isExternalCubit;

  _ShopGameScreenState() : _isExternalCubit = false;

  @override
  void initState() {
    super.initState();
    // 1. Force landscape orientation for shop game
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // 2. Resolve cubit
    _cubit = widget.cubit ?? locator<ShopGameCubit>();
    _cubit.startGame(widget.levelId);
  }

  @override
  void dispose() {
    // 1. Restore portrait orientation for legacy app
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    if (widget.cubit == null) {
      _cubit.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<ShopGameCubit, ShopGameState>(
        listener: (context, state) {
          if (state.phase == GamePhase.levelComplete) {
            // Level summary will be triggered here
          }
        },
        builder: (context, state) {
          if (state.phase == GamePhase.loading) {
            return const Scaffold(
              backgroundColor: Color(0xFFFFF7ED),
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFFFF9800),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Bác Ba đang dọn tiệm...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5D4037),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final levelNumber = int.tryParse(state.levelId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;

          return Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                // Layer 1: Scenery
                const BackgroundSceneryLayer(),

                // Layer 2: Ambient
                const AmbientParticlesLayer(),

                // Layer 3: Customer Character
                CustomerCharacterLayer(
                  phase: state.phase,
                  currentOrder: state.currentOrder,
                ),

                // Layer 4: Countertop & Props
                CountertopLayer(
                  basketItems: state.basketItems,
                  onItemDropped: (item) => _cubit.onItemDroppedToBasket(item),
                  totalCoins: state.starCount * 5,
                ),

                // Layer 5: Fruit Shelf Draggable Items
                FruitShelfDraggableLayer(
                  availableItems: ShopGameLevelsData.shelfEntities,
                  isEnabled: state.phase == GamePhase.collectingItems,
                ),

                // Layer 6: Game HUD Overlay
                GameHudOverlay(
                  phase: state.phase,
                  levelNumber: levelNumber,
                  totalCoins: state.starCount * 5,
                  isMuted: false,
                  onExitPressed: () => Navigator.of(context).maybePop(),
                  onSoundToggled: () => _cubit.toggleMute(),
                  countingText: state.floatingText,
                  showTutor: state.isHandTutorVisible,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
