class WardrobeItemDef {
  final String id;
  final String name;
  final String slot; // 'head', 'face', 'neck', 'held', 'fx'
  final int price;
  final String iconEmoji;
  final String description;

  const WardrobeItemDef({
    required this.id,
    required this.name,
    required this.slot,
    required this.price,
    required this.iconEmoji,
    required this.description,
  });
}

class OutfitDef {
  final String id;
  final String name;
  final String iconEmoji;
  final String? head;
  final String? face;
  final String? neck;
  final String? held;
  final String? fx;

  const OutfitDef({
    required this.id,
    required this.name,
    required this.iconEmoji,
    this.head,
    this.face,
    this.neck,
    this.held,
    this.fx,
  });

  List<String> get allItems => [
        if (head != null) head!,
        if (face != null) face!,
        if (neck != null) neck!,
        if (held != null) held!,
        if (fx != null) fx!,
      ];
}

class MascotPoseDef {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final String? prop; // 'steam', 'hearts', 'lvl', 'gift', 'scribble', 'sadcloud', 'tears'
  final bool hasBlush;

  const MascotPoseDef({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    this.prop,
    this.hasBlush = false,
  });
}

class WardrobeCatalog {
  static const List<WardrobeItemDef> headItems = [
    WardrobeItemDef(id: 'beanie', name: 'Knit Beanie', slot: 'head', price: 160, iconEmoji: '🧶', description: 'Cozy hand-knitted beanie with a fluffy pompom'),
    WardrobeItemDef(id: 'santa', name: 'Santa Hat', slot: 'head', price: 180, iconEmoji: '🎅', description: 'Festive red holiday cap with snow-white trim'),
    WardrobeItemDef(id: 'straw', name: 'Straw Sunhat', slot: 'head', price: 150, iconEmoji: '👒', description: 'Woven organic sunhat with summer sunflower ribbon'),
    WardrobeItemDef(id: 'flowers', name: 'Flower Crown', slot: 'head', price: 140, iconEmoji: '🌸', description: 'Handcrafted circlet of vibrant spring blossoms'),
    WardrobeItemDef(id: 'acorn', name: 'Acorn Cap', slot: 'head', price: 130, iconEmoji: '🌰', description: 'Whimsical forest acorn cap with oak leaf accent'),
    WardrobeItemDef(id: 'rainhat', name: 'Rain Hat', slot: 'head', price: 150, iconEmoji: '🌧️', description: 'Waterproof sunny yellow hat for monsoon walks'),
    WardrobeItemDef(id: 'gujarati_paghdi', name: 'Royal Paghdi', slot: 'head', price: 250, iconEmoji: '👑', description: 'Traditional Gujarati paghdi for green energy champions'),
  ];

  static const List<WardrobeItemDef> faceItems = [
    WardrobeItemDef(id: 'sunnies', name: 'Sunglasses', slot: 'face', price: 90, iconEmoji: '🕶️', description: 'Cool dark sunglasses with solar glare reflection'),
    WardrobeItemDef(id: 'readers', name: 'Round Glasses', slot: 'face', price: 80, iconEmoji: '👓', description: 'Vintage circular readers for scholarly birds'),
  ];

  static const List<WardrobeItemDef> neckItems = [
    WardrobeItemDef(id: 'knit', name: 'Knit Scarf', slot: 'neck', price: 100, iconEmoji: '🧣', description: 'Red & cream striped warm wool scarf'),
    WardrobeItemDef(id: 'xmas', name: 'Holiday Scarf', slot: 'neck', price: 110, iconEmoji: '🎄', description: 'Green, cream & ruby seasonal festive scarf'),
    WardrobeItemDef(id: 'plaid', name: 'Plaid Scarf', slot: 'neck', price: 100, iconEmoji: '🟤', description: 'Warm autumn tartan patterned muffler'),
    WardrobeItemDef(id: 'lei', name: 'Flower Lei', slot: 'neck', price: 90, iconEmoji: '🌺', description: 'Vibrant garland of tropical flowers'),
    WardrobeItemDef(id: 'bow', name: 'Pink Bow', slot: 'neck', price: 70, iconEmoji: '🎀', description: 'Silky pink statement bow tie'),
    WardrobeItemDef(id: 'collar', name: 'Rain Collar', slot: 'neck', price: 80, iconEmoji: '🟡', description: 'Bright yellow waterproof cape collar'),
  ];

  static const List<WardrobeItemDef> heldItems = [
    WardrobeItemDef(id: 'umbrella', name: 'Red Umbrella', slot: 'held', price: 140, iconEmoji: '☂️', description: 'Classic red & white striped umbrella'),
    WardrobeItemDef(id: 'leafbrella', name: 'Leaf Umbrella', slot: 'held', price: 170, iconEmoji: '🍃', description: 'Eco-friendly broad lotus leaf parasol'),
  ];

  static const List<WardrobeItemDef> fxItems = [
    WardrobeItemDef(id: 'petals', name: 'Spring Petals', slot: 'fx', price: 50, iconEmoji: '🌸', description: 'Gentle pink cherry blossom petals drifting by'),
    WardrobeItemDef(id: 'butterflies', name: 'Butterflies', slot: 'fx', price: 80, iconEmoji: '🦋', description: 'Colorful fluttering butterflies and sunny warmth'),
    WardrobeItemDef(id: 'leaves', name: 'Autumn Leaves', slot: 'fx', price: 50, iconEmoji: '🍂', description: 'Golden amber oak leaves swirling in the breeze'),
    WardrobeItemDef(id: 'snow', name: 'Gentle Snow', slot: 'fx', price: 60, iconEmoji: '❄️', description: 'Soft crystal snowflakes descending gracefully'),
    WardrobeItemDef(id: 'rain', name: 'Monsoon Rain', slot: 'fx', price: 60, iconEmoji: '🌧️', description: 'Refreshing monsoon rain shower'),
    WardrobeItemDef(id: 'sparks', name: 'Golden Sparks', slot: 'fx', price: 50, iconEmoji: '✨', description: 'Aura of glowing clean energy sparks'),
  ];

  static const List<OutfitDef> outfits = [
    OutfitDef(id: 'none', name: 'Plain Sparrow', iconEmoji: '🐦'),
    OutfitDef(id: 'spring', name: 'Spring Blossom', iconEmoji: '🌸', head: 'flowers', neck: 'bow', fx: 'petals'),
    OutfitDef(id: 'summer', name: 'Summer Vibes', iconEmoji: '☀️', head: 'straw', face: 'sunnies', neck: 'lei', fx: 'butterflies'),
    OutfitDef(id: 'autumn', name: 'Autumn Breeze', iconEmoji: '🍂', head: 'acorn', face: 'readers', neck: 'plaid', fx: 'leaves'),
    OutfitDef(id: 'winter', name: 'Winter Warmth', iconEmoji: '❄️', head: 'beanie', neck: 'knit', fx: 'snow'),
    OutfitDef(id: 'rainy', name: 'Monsoon Walk', iconEmoji: '🌧️', head: 'rainhat', neck: 'collar', held: 'leafbrella', fx: 'rain'),
    OutfitDef(id: 'festive', name: 'Festive Cheer', iconEmoji: '🎄', head: 'santa', neck: 'xmas', fx: 'snow'),
  ];

  static const List<MascotPoseDef> poses = [
    MascotPoseDef(id: 'happy', name: 'Happy', emoji: '😊', description: 'Cheerful companion smiling warmly'),
    MascotPoseDef(id: 'cheering', name: 'Cheering', emoji: '🥳', description: 'Spread wings celebration'),
    MascotPoseDef(id: 'petted', name: 'Petted', emoji: '💖', description: 'Affectionate blush and floating hearts', prop: 'hearts', hasBlush: true),
    MascotPoseDef(id: 'levelup', name: 'Level Up', emoji: '🌟', description: 'Ascending golden aura & badge', prop: 'lvl'),
    MascotPoseDef(id: 'angry', name: 'Angry', emoji: '😤', description: 'Ruffled feathers and steam puffs', prop: 'steam'),
    MascotPoseDef(id: 'announce', name: 'Gift Box', emoji: '🎁', description: 'Shows an exciting eco gift box', prop: 'gift'),
    MascotPoseDef(id: 'frustrated', name: 'Frustrated', emoji: '🌀', description: 'Wings on head with scribble cloud', prop: 'scribble'),
    MascotPoseDef(id: 'sad', name: 'Sad', emoji: '🌧️', description: 'Gloomy mood with personal raincloud', prop: 'sadcloud'),
    MascotPoseDef(id: 'crying', name: 'Crying', emoji: '😭', description: 'Tears streaming down into a puddle', prop: 'tears'),
  ];

  static WardrobeItemDef? findItem(String id) {
    for (final it in [...headItems, ...faceItems, ...neckItems, ...heldItems, ...fxItems]) {
      if (it.id == id) return it;
    }
    return null;
  }
}
