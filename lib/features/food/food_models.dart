/// A local traditional dish or delicacy.
class LocalDish {
  const LocalDish({
    required this.name,
    required this.localName,
    required this.description,
    required this.category, // e.g. 'Piatto forte', 'Street food', 'Dolce tipico', 'Bevanda'
    required this.dietaryTag, // e.g. 'Carne', 'Pesce', 'Vegetariano', 'Dolce'
    required this.mustTryPlace,
  });

  final String name;
  final String localName;
  final String description;
  final String category;
  final String dietaryTag;
  final String mustTryPlace;
}

/// A recommended authentic restaurant, historic café or food market.
class RecommendedVenue {
  const RecommendedVenue({
    required this.name,
    required this.type, // e.g. 'Trattoria tipica', 'Mercato coperto', 'Caffè storico', 'Bistrot'
    required this.specialty,
    required this.priceTier, // '€', '€€', '€€€'
    required this.address,
    required this.whyIterRecommends,
    required this.mapsQuery,
  });

  final String name;
  final String type;
  final String specialty;
  final String priceTier;
  final String address;
  final String whyIterRecommends;
  final String mapsQuery;
}

/// Complete local food guide for a destination.
class DestinationFoodGuide {
  const DestinationFoodGuide({
    required this.destination,
    required this.culinaryIdentity,
    required this.dishes,
    required this.venues,
    required this.orderingPhrases,
  });

  final String destination;
  final String culinaryIdentity;
  final List<LocalDish> dishes;
  final List<RecommendedVenue> venues;
  final Map<String, String>
  orderingPhrases; // e.g. 'Un tavolo per due per favore' -> 'Egy asztalt két főre, kérem'
}
