/// Asset paths for the 3D images (mascot, subject icons, rewards, background).
abstract final class AppImages {
  static const chipMain = 'assets/images/chip-main.png';
  static const chipJoy = 'assets/images/chip-joy.png';
  static const chipThumb = 'assets/images/chip-thumb.png';
  static const chipSurprise = 'assets/images/chip-surprise.png';
  static const chipEncourage = 'assets/images/chip-encourage.png';
  static const chipSleep = 'assets/images/chip-sleep.png';
  static const chipWrite = 'assets/images/chip-write.png';
  static const icViet = 'assets/images/ic-viet.png';
  static const icTiengViet = 'assets/images/ic-tieng-viet.png';
  static const icToan = 'assets/images/ic-toan.png';
  static const icTiengAnh = 'assets/images/ic-tieng-anh.png';
  static const icKhamPha = 'assets/images/ic-kham-pha.png';
  static const icStar = 'assets/images/ic-star.png';
  static const icFlame = 'assets/images/ic-flame.png';
  static const icCrown = 'assets/images/ic-crown.png';
  static const logo = 'assets/images/logo.png';
  static const bgSky = 'assets/images/bg-sky.jpg';

  // Animal avatars under assets/images/avatars/.
  static const avatarFox = 'assets/images/avatars/fox.png';
  static const avatarPanda = 'assets/images/avatars/panda.png';
  static const avatarBunny = 'assets/images/avatars/bunny.png';
  static const avatarTiger = 'assets/images/avatars/tiger.png';
  static const avatarCat = 'assets/images/avatars/cat.png';
  static const avatarDog = 'assets/images/avatars/dog.png';
  static const avatarElephant = 'assets/images/avatars/elephant.png';
  static const avatarDino = 'assets/images/avatars/dino.png';
  static const avatarOwl = 'assets/images/avatars/owl.png';
  static const avatarPenguin = 'assets/images/avatars/penguin.png';
  static const avatarBear = 'assets/images/avatars/bear.png';
  static const avatarUnicorn = 'assets/images/avatars/unicorn.png';

  // Game art (rocket race), under assets/images/game/.
  static const rocketOrange = 'assets/images/game/rocket-orange.png';
  static const rocketBlue = 'assets/images/game/rocket-blue.png';
  static const rocketGreen = 'assets/images/game/rocket-green.png';
  static const rocketPurple = 'assets/images/game/rocket-purple.png';
  static const rocketChip = 'assets/images/game/rocket-chip.png';
  static const planet = 'assets/images/game/planet.png';
  static const comet = 'assets/images/game/comet.png';
  static const finsBolt = 'assets/images/game/fins-bolt.png';
  static const noseStar = 'assets/images/game/nose-star.png';
  static const trailRainbow = 'assets/images/game/trail-rainbow.png';
  static const badgeSpeedKing = 'assets/images/game/badge-speed-king.png';
  static const badgeScholar = 'assets/images/game/badge-scholar.png';
  static const badgeCometHunter = 'assets/images/game/badge-comet-hunter.png';
  static const badgeNeverGiveUp = 'assets/images/game/badge-never-give-up.png';
  static const badgeChipBuddy = 'assets/images/game/badge-chip-buddy.png';
  static const badgeMathWhiz = 'assets/images/game/badge-math-whiz.png';
  static const badgeLetterMaster = 'assets/images/game/badge-letter-master.png';
  static const badgePilot = 'assets/images/game/badge-pilot.png';
  static const badgeFriendRacer = 'assets/images/game/badge-friend-racer.png';
  static const badgeFriendChampion = 'assets/images/game/badge-friend-champion.png';
  static const badgeBigRace = 'assets/images/game/badge-big-race.png';
  static const badgeCheerleader = 'assets/images/game/badge-cheerleader.png';
  static const stickerClap = 'assets/images/game/sticker-clap.png';
  static const stickerLaugh = 'assets/images/game/sticker-laugh.png';
  static const stickerPilotGoggles = 'assets/images/game/sticker-pilot-goggles.png';
  static const stickerGradCap = 'assets/images/game/sticker-grad-cap.png';
  static const stickerHugStar = 'assets/images/game/sticker-hug-star.png';
  static const stickerFist = 'assets/images/game/sticker-fist.png';
  static const stickerHugHeart = 'assets/images/game/sticker-hug-heart.png';
  static const stickerAbacus = 'assets/images/game/sticker-abacus.png';
  static const stickerCrayon = 'assets/images/game/sticker-crayon.png';
  static const stickerWaveRocket = 'assets/images/game/sticker-wave-rocket.png';
  static const stickerRareChipSleep = 'assets/images/game/sticker-rare-chip-sleep.png';
  static const stickerRareChipWrite = 'assets/images/game/sticker-rare-chip-write.png';
  static const stickerRareRocketChip = 'assets/images/game/sticker-rare-rocket-chip.png';
  static const stickerRareCrown = 'assets/images/game/sticker-rare-crown.png';
  static const stickerRareComet = 'assets/images/game/sticker-rare-comet.png';
  static const stickerRarePlanet = 'assets/images/game/sticker-rare-planet.png';

  // Tease and party stickers (under assets/images/game/).
  static const stickerTeaseBubble = 'assets/images/game/sticker-tease-bubble.png';
  static const stickerTeaseTongue = 'assets/images/game/sticker-tease-tongue.png';
  static const stickerTeaseByebye = 'assets/images/game/sticker-tease-byebye.png';
  static const stickerTeaseRain = 'assets/images/game/sticker-tease-rain.png';
  static const stickerTeaseSleepy = 'assets/images/game/sticker-tease-sleepy.png';
  static const stickerTeaseTurtle = 'assets/images/game/sticker-tease-turtle.png';
  static const stickerTeaseSmoke = 'assets/images/game/sticker-tease-smoke.png';
  static const stickerParty = 'assets/images/game/sticker-party.png';

  /// Tease sticker path by id: bubble, tongue, byebye, rain, sleepy, turtle, smoke.
  static String stickerTease(String id) => 'assets/images/game/sticker-tease-$id.png';

  /// Album sticker art by sticker id (Chíp poses, cut from green).
  static const stickers = <String, String>{
    'sticker_clap': stickerClap,
    'sticker_laugh': stickerLaugh,
    'sticker_pilot_goggles': stickerPilotGoggles,
    'sticker_grad_cap': stickerGradCap,
    'sticker_hug_star': stickerHugStar,
    'sticker_fist': stickerFist,
    'sticker_hug_heart': stickerHugHeart,
    'sticker_abacus': stickerAbacus,
    'sticker_crayon': stickerCrayon,
    'sticker_wave_rocket': stickerWaveRocket,
    // Online-room badge stickers: Chíp's poses.
    'sticker_thumb': chipThumb,
    'sticker_joy': chipJoy,
    'sticker_surprise': chipSurprise,
    'sticker_encourage': chipEncourage,
    // Rare stickers (gold frame), dropped after races with friends.
    'rare_chip_sleep': stickerRareChipSleep,
    'rare_chip_write': stickerRareChipWrite,
    'rare_rocket_chip': stickerRareRocketChip,
    'rare_crown': stickerRareCrown,
    'rare_comet': stickerRareComet,
    'rare_planet': stickerRarePlanet,
    // Party and tease stickers
    'sticker_party': stickerParty,
    'party': stickerParty,
    'bubble': stickerTeaseBubble,
    'tongue': stickerTeaseTongue,
    'byebye': stickerTeaseByebye,
    'rain': stickerTeaseRain,
    'sleepy': stickerTeaseSleepy,
    'turtle': stickerTeaseTurtle,
    'smoke': stickerTeaseSmoke,
  };

  static const all = [
    chipMain,
    chipJoy,
    chipThumb,
    chipSurprise,
    chipEncourage,
    chipSleep,
    chipWrite,
    icViet,
    icTiengViet,
    icToan,
    icTiengAnh,
    icKhamPha,
    icStar,
    icFlame,
    icCrown,
    bgSky,
    avatarFox,
    avatarPanda,
    avatarBunny,
    avatarTiger,
    avatarCat,
    avatarDog,
    avatarElephant,
    avatarDino,
    avatarOwl,
    avatarPenguin,
    avatarBear,
    avatarUnicorn,
    rocketOrange,
    rocketBlue,
    rocketGreen,
    rocketPurple,
    rocketChip,
    planet,
    comet,
    finsBolt,
    noseStar,
    trailRainbow,
    badgeSpeedKing,
    badgeScholar,
    badgeCometHunter,
    badgeNeverGiveUp,
    badgeChipBuddy,
    badgeMathWhiz,
    badgeLetterMaster,
    badgePilot,
    badgeFriendRacer,
    badgeFriendChampion,
    badgeBigRace,
    badgeCheerleader,
    stickerClap,
    stickerLaugh,
    stickerPilotGoggles,
    stickerGradCap,
    stickerHugStar,
    stickerFist,
    stickerHugHeart,
    stickerAbacus,
    stickerCrayon,
    stickerWaveRocket,
    stickerRareChipSleep,
    stickerRareChipWrite,
    stickerRareRocketChip,
    stickerRareCrown,
    stickerRareComet,
    stickerRarePlanet,
    stickerTeaseBubble,
    stickerTeaseTongue,
    stickerTeaseByebye,
    stickerTeaseRain,
    stickerTeaseSleepy,
    stickerTeaseTurtle,
    stickerTeaseSmoke,
    stickerParty,
  ];

  // Explore island art, under assets/images/explore/. Kept out of [all] so
  // the splash does not decode ~50 images; screens precache what they show.
  static const islandDiaLy = 'assets/images/explore/island-dia-ly.png';
  static const islandSinhHoc = 'assets/images/explore/island-sinh-hoc.png';
  static const islandLichSu = 'assets/images/explore/island-lich-su.png';

  /// Geography item art by item id.
  static const Map<String, String> geography = {
    'nui': 'assets/images/explore/geo-nui.png',
    'song': 'assets/images/explore/geo-song.png',
    'bien': 'assets/images/explore/geo-bien.png',
    'rung': 'assets/images/explore/geo-rung.png',
    'dong-lua': 'assets/images/explore/geo-dong-lua.png',
    'hang-dong': 'assets/images/explore/geo-hang-dong.png',
    'nang': 'assets/images/explore/geo-nang.png',
    'mua': 'assets/images/explore/geo-mua.png',
    'gio': 'assets/images/explore/geo-gio.png',
    'may': 'assets/images/explore/geo-may.png',
    'cau-vong': 'assets/images/explore/geo-cau-vong.png',
    'sam-set': 'assets/images/explore/geo-sam-set.png',
    'co-viet-nam': 'assets/images/explore/geo-co-viet-nam.png',
    'ban-do-chu-s': 'assets/images/explore/geo-ban-do-chu-s.png',
    'non-la': 'assets/images/explore/geo-non-la.png',
    'ao-dai': 'assets/images/explore/geo-ao-dai.png',
    'hoa-sen': 'assets/images/explore/geo-hoa-sen.png',
    'ho-guom': 'assets/images/explore/geo-ho-guom.png',
    'vinh-ha-long': 'assets/images/explore/geo-vinh-ha-long.png',
    'van-mieu': 'assets/images/explore/geo-van-mieu.png',
    'chua-mot-cot': 'assets/images/explore/geo-chua-mot-cot.png',
    'ruong-bac-thang': 'assets/images/explore/geo-ruong-bac-thang.png',
    'co-do-hue': 'assets/images/explore/geo-co-do-hue.png',
    'chua-cau': 'assets/images/explore/geo-chua-cau.png',
    'cau-rong': 'assets/images/explore/geo-cau-rong.png',
    'dong-phong-nha': 'assets/images/explore/geo-dong-phong-nha.png',
    'cau-vang': 'assets/images/explore/geo-cau-vang.png',
    'cho-ben-thanh': 'assets/images/explore/geo-cho-ben-thanh.png',
    'cho-noi-cai-rang': 'assets/images/explore/geo-cho-noi-cai-rang.png',
    'nha-tho-duc-ba': 'assets/images/explore/geo-nha-tho-duc-ba.png',
    'buu-dien-sai-gon': 'assets/images/explore/geo-buu-dien-sai-gon.png',
    'mui-ca-mau': 'assets/images/explore/geo-mui-ca-mau.png',
    'van-ly-truong-thanh': 'assets/images/explore/geo-van-ly-truong-thanh.png',
    'nui-phu-si': 'assets/images/explore/geo-nui-phu-si.png',
    'taj-mahal': 'assets/images/explore/geo-taj-mahal.png',
    'angkor-wat': 'assets/images/explore/geo-angkor-wat.png',
    'thap-petronas': 'assets/images/explore/geo-thap-petronas.png',
    'thap-eiffel': 'assets/images/explore/geo-thap-eiffel.png',
    'kim-tu-thap': 'assets/images/explore/geo-kim-tu-thap.png',
    'thap-pisa': 'assets/images/explore/geo-thap-pisa.png',
    'big-ben': 'assets/images/explore/geo-big-ben.png',
    'dau-truong-la-ma': 'assets/images/explore/geo-dau-truong-la-ma.png',
    'tuong-nu-than-tu-do': 'assets/images/explore/geo-tuong-nu-than-tu-do.png',
    'nha-hat-opera-sydney': 'assets/images/explore/geo-nha-hat-opera-sydney.png',
    'machu-picchu': 'assets/images/explore/geo-machu-picchu.png',
    'tuong-chua-cuu-the': 'assets/images/explore/geo-tuong-chua-cuu-the.png',
    'thac-niagara': 'assets/images/explore/geo-thac-niagara.png',
  };

  /// Every explore item picture by `<prefix>-<id>` (geo-, bio-).
  static final Map<String, String> exploreArt = {
    for (final e in geography.entries) 'geo-${e.key}': e.value,
  };

  static final explore = [
    islandDiaLy,
    islandSinhHoc,
    islandLichSu,
    ...geography.values,
  ];
}
