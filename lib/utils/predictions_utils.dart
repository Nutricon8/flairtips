import 'package:flairtips/models/tip.dart';

Map<String, List<Tip>> _groupTipsByLeagueNamee(List<Tip> tips) {
  final Map<String, List<Tip>> grouped = {};

  for (var tip in tips) {
    final uniqueKey = '${tip.country}|${tip.leagueName}';
    grouped.putIfAbsent(uniqueKey, () => []).add(tip);
  }

  // Sort the groups
  final sortedKeys =
      grouped.keys.toList()..sort((a, b) {
        final aParts = a.split('|');
        final bParts = b.split('|');

        // Sort by country first, then league
        final countryCompare = aParts[0].compareTo(bParts[0]);
        if (countryCompare != 0) return countryCompare;
        return aParts[1].compareTo(bParts[1]);
      });

  // Create a new sorted map
  final sortedGroups = <String, List<Tip>>{};
  for (var key in sortedKeys) {
    sortedGroups[key] = grouped[key]!;
  }

  return sortedGroups;
}

List<Tip> _deduplicateTipsByID(List<Tip> tips) {
  final Map<String, Tip> uniqueTips = {};

  for (final tip in tips) {
    if (!uniqueTips.containsKey(tip.id)) {
      // First time seeing this ID
      uniqueTips[tip.id] = tip;
    } else {
      // Duplicate ID found - decide which one to keep
      final existingTip = uniqueTips[tip.id]!;

      // Prefer tips with league logo
      if (tip.leagueLogo.isNotEmpty && existingTip.leagueLogo.isEmpty) {
        uniqueTips[tip.id] = tip;
      }
      // Prefer tips with valid league name
      else if (tip.leagueName.isNotEmpty && existingTip.leagueName.isEmpty) {
        uniqueTips[tip.id] = tip;
      }
      // Prefer the one with more complete data
      else if (_getTipCompletenessScore(tip) >
          _getTipCompletenessScore(existingTip)) {
        uniqueTips[tip.id] = tip;
      }
    }
  }

  return uniqueTips.values.toList();
}

// Helper method to score how complete a tip is
int _getTipCompletenessScore(Tip tip) {
  int score = 0;
  if (tip.leagueName.isNotEmpty) score += 10;
  if (tip.leagueLogo.isNotEmpty) score += 5;
  if (tip.country.isNotEmpty) score += 3;
  if (tip.homeImage != null && tip.homeImage!.isNotEmpty) score += 2;
  if (tip.awayImage != null && tip.awayImage!.isNotEmpty) score += 2;
  return score;
}

// Utility function to properly group tips
/*Map<String, List<Tip>> groupTipsByLeague(List<Tip> tips) {
  final Map<String, List<Tip>> grouped = {};

  for (var tip in tips) {
    // Create a UNIQUE key with country ID, country name, and league name
    // This is the MOST reliable way to separate same-named leagues in different countries
    final uniqueKey = '${tip.countryId}_${tip.country}_${tip.leagueName}';

    // Also ensure all fields are properly filled
    final actualCountry = tip.country.isNotEmpty ? tip.country : 'Unknown';
    final actualLeague =
        tip.leagueName.isNotEmpty ? tip.leagueName : 'Unknown League';

    final displayKey = '$actualCountry|$actualLeague';

    grouped.putIfAbsent(displayKey, () => []).add(tip);
  }

  // Sort by country, then league
  final sortedKeys =
      grouped.keys.toList()..sort((a, b) {
        final aParts = a.split('|');
        final bParts = b.split('|');

        if (aParts[0] != bParts[0]) {
          return aParts[0].compareTo(bParts[0]); // Sort by country
        }
        return aParts[1].compareTo(bParts[1]); // Then by league
      });

  // Return sorted map
  return Map.fromEntries(sortedKeys.map((key) => MapEntry(key, grouped[key]!)));
}*/
// Utility function to properly group tips WITHOUT alphabetical sorting
Map<String, List<Tip>> groupTipsByLeague(List<Tip> tips) {
  final Map<String, List<Tip>> grouped = {};
  final List<String> insertionOrder = []; // To preserve insertion order

  for (var tip in tips) {
    // Create a UNIQUE key with country ID, country name, and league name
    final uniqueKey = '${tip.countryId}_${tip.country}_${tip.leagueName}';

    // Also ensure all fields are properly filled
    final actualCountry = tip.country.isNotEmpty ? tip.country : 'Unknown';
    final actualLeague =
        tip.leagueName.isNotEmpty ? tip.leagueName : 'Unknown League';

    final displayKey = '$actualCountry|$actualLeague';

    if (!grouped.containsKey(displayKey)) {
      insertionOrder.add(displayKey); // Track the order of first appearance
    }

    grouped.putIfAbsent(displayKey, () => []).add(tip);
  }

  // Return map in the order that leagues first appeared (API order)
  return Map.fromEntries(
    insertionOrder.map((key) => MapEntry(key, grouped[key]!)),
  );
}

Map<String, List<Tip>> _groupTipsByLeagueName(List<Tip> tips) {
  return groupTipsByLeague(tips);
}
