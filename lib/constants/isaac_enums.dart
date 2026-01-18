enum IsaacStage {
  basement, // 1
  cellar, // 1a
  burningBasement, // 1b
  downpour, // 1c
  dross, // 1d
  caves, // 3
  catacombs, // 3a
  floodedCaves, // 3b
  mines, // 3c
  ashpit, // 3d
  depths, // 5
  necropolis, // 5a
  dankDepths, // 5b
  mausoleum, // 5c
  gehenna, // 5d
  womb, // 7
  utero, // 7a
  scarredWomb, // 7b
  corpse, // 7c
  blueWomb, // 9
  sheol, // 10
  cathedral, // 10a
  darkRoom, // 11
  chest, // 11a
  theVoid, // 12
  homeDay, // 13
  homeNight, // 13a
}

extension IsaacStageExtension on IsaacStage {
  String toDisplayString() {
    switch (this) {
      case IsaacStage.basement:
        return 'Basement';
      case IsaacStage.cellar:
        return 'Cellar';
      case IsaacStage.burningBasement:
        return 'Burning Basement';
      case IsaacStage.downpour:
        return 'Downpour';
      case IsaacStage.dross:
        return 'Dross';
      case IsaacStage.caves:
        return 'Caves';
      case IsaacStage.catacombs:
        return 'Catacombs';
      case IsaacStage.floodedCaves:
        return 'Flooded Caves';
      case IsaacStage.mines:
        return 'Mines';
      case IsaacStage.ashpit:
        return 'Ashpit';
      case IsaacStage.depths:
        return 'Depths';
      case IsaacStage.necropolis:
        return 'Necropolis';
      case IsaacStage.dankDepths:
        return 'Dank Depths';
      case IsaacStage.mausoleum:
        return 'Mausoleum';
      case IsaacStage.gehenna:
        return 'Gehenna';
      case IsaacStage.womb:
        return 'Womb';
      case IsaacStage.utero:
        return 'Utero';
      case IsaacStage.scarredWomb:
        return 'Scarred Womb';
      case IsaacStage.corpse:
        return 'Corpse';
      case IsaacStage.blueWomb:
        return 'Blue Womb';
      case IsaacStage.sheol:
        return 'Sheol';
      case IsaacStage.cathedral:
        return 'Cathedral';
      case IsaacStage.darkRoom:
        return 'Dark Room';
      case IsaacStage.chest:
        return 'Chest';
      case IsaacStage.theVoid:
        return 'The Void';
      case IsaacStage.homeDay:
        return 'Home (Day)';
      case IsaacStage.homeNight:
        return 'Home (Night)';
    }
  }
}

enum IsaacRoomType {
  null_(0),
  defaultRoom(1),
  shop(2),
  error(3),
  treasure(4),
  boss(5),
  miniboss(6),
  secret(7),
  superSecret(8),
  arcade(9),
  curse(10),
  challenge(11),
  library(12),
  sacrifice(13),
  devil(14),
  angel(15),
  dungeon(16),
  bossRush(17),
  isaacs(18),
  barren(19),
  chest(20),
  dice(21),
  blackMarket(22),
  greedExit(23),
  planetarium(24),
  teleporter(25),
  teleporterExit(26),
  secretExit(27),
  blue(28),
  ultraSecret(29),
  deathMatch(30),
  hushBoss(1000),
  isaacBoss(1001),
  satanBoss(1002),
  blueBabyBoss(1003),
  theLambBoss(1004),
  megaSatanBoss(1005),
  deliriumBoss(1006),
  motherBoss(1007),
  dogmaBoss(1008),
  theBeastBoss(1009);

  final int value;
  const IsaacRoomType(this.value);

  static IsaacRoomType fromValue(int value) {
    return IsaacRoomType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => IsaacRoomType.null_,
    );
  }
}

extension IsaacRoomExtension on IsaacRoomType {
  String toDisplayString() {
    switch (this) {
      case IsaacRoomType.null_:
        return 'Null';
      case IsaacRoomType.defaultRoom:
        return 'Default';
      case IsaacRoomType.shop:
        return 'Shop';
      case IsaacRoomType.error:
        return 'Error';
      case IsaacRoomType.treasure:
        return 'Treasure';
      case IsaacRoomType.boss:
        return 'Boss';
      case IsaacRoomType.miniboss:
        return 'Miniboss';
      case IsaacRoomType.secret:
        return 'Secret';
      case IsaacRoomType.superSecret:
        return 'Super Secret';
      case IsaacRoomType.arcade:
        return 'Arcade';
      case IsaacRoomType.curse:
        return 'Curse';
      case IsaacRoomType.challenge:
        return 'Challenge';
      case IsaacRoomType.library:
        return 'Library';
      case IsaacRoomType.sacrifice:
        return 'Sacrifice';
      case IsaacRoomType.devil:
        return 'Devil';
      case IsaacRoomType.angel:
        return 'Angel';
      case IsaacRoomType.dungeon:
        return 'Dungeon';
      case IsaacRoomType.bossRush:
        return 'Boss Rush';
      case IsaacRoomType.isaacs:
        return "Isaac's Room";
      case IsaacRoomType.barren:
        return 'Barren';
      case IsaacRoomType.chest:
        return 'Chest';
      case IsaacRoomType.dice:
        return 'Dice';
      case IsaacRoomType.blackMarket:
        return 'Black Market';
      case IsaacRoomType.greedExit:
        return 'Greed Exit';
      case IsaacRoomType.planetarium:
        return 'Planetarium';
      case IsaacRoomType.teleporter:
        return 'Teleporter';
      case IsaacRoomType.teleporterExit:
        return 'Teleporter Exit';
      case IsaacRoomType.secretExit:
        return 'Secret Exit';
      case IsaacRoomType.blue:
        return 'Blue';
      case IsaacRoomType.ultraSecret:
        return 'Ultra Secret';
      case IsaacRoomType.deathMatch:
        return 'Death Match';
      case IsaacRoomType.hushBoss:
        return 'Hush Boss';
      case IsaacRoomType.isaacBoss:
        return 'Isaac Boss';
      case IsaacRoomType.satanBoss:
        return 'Satan Boss';
      case IsaacRoomType.blueBabyBoss:
        return 'Blue Baby Boss';
      case IsaacRoomType.theLambBoss:
        return 'The Lamb Boss';
      case IsaacRoomType.megaSatanBoss:
        return 'Mega Satan Boss';
      case IsaacRoomType.deliriumBoss:
        return 'Delirium Boss';
      case IsaacRoomType.motherBoss:
        return 'Mother Boss';
      case IsaacRoomType.dogmaBoss:
        return 'Dogma Boss';
      case IsaacRoomType.theBeastBoss:
        return 'The Beast Boss';
    }
  }
}

enum IsaacBossType {
  blueBaby,
  theLamb,
  megaSatan,
  mother,
  theBeast,
  delirium,
}

extension IsaacBossExtension on IsaacBossType {
  static const List<IsaacBossType> sortedValues = [
    IsaacBossType.blueBaby,
    IsaacBossType.theLamb,
    IsaacBossType.megaSatan,
    IsaacBossType.delirium,
    IsaacBossType.mother,
    IsaacBossType.theBeast,
  ];

  String toDisplayString() {
    switch (this) {
      case IsaacBossType.blueBaby:
        return 'Blue Baby';
      case IsaacBossType.theLamb:
        return 'The Lamb';
      case IsaacBossType.megaSatan:
        return 'Mega Satan';
      case IsaacBossType.mother:
        return 'Mother';
      case IsaacBossType.theBeast:
        return 'The Beast';
      case IsaacBossType.delirium:
        return 'Delirium';
    }
  }
}
