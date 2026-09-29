import 'package:flairtips/models/tip.dart';
import 'package:flairtips/utils/api_service.dart';
import 'package:flairtips/utils/user_provider.dart';
import 'package:flairtips/widgets/ScrollDate.dart';
import 'package:flairtips/widgets/league_card.dart';
import 'package:flairtips/widgets/match_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class VipTips extends StatefulWidget {
  const VipTips({super.key});

  @override
  State<VipTips> createState() => _VipTipsState();
}

class _VipTipsState extends State<VipTips> {
  String selectedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _scrollDateKey = GlobalKey();

  final List<Tip> _tips = [];
  bool _isFetchingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTips();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 300 &&
          !_isFetchingMore &&
          _hasMore) {
        _loadMoreTips();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _fetchTips({bool reset = true}) async {
    if (reset) {
      setState(() {
        _tips.clear();
        _currentPage = 1;
        _hasMore = true;
        isLoading = true;
      });
    }

    getTips(true, selectedDate, _currentPage)
        .then((newTips) {
          setState(() {
            isLoading = false;
            _tips.addAll(newTips);
            _hasMore = newTips.isNotEmpty;
            _isFetchingMore = false;
          });
        })
        .catchError((error) async {
          setState(() {
            isLoading = false;
            _isFetchingMore = false;
          });

          // Optionally show an error
          if (error is UnauthorizedException) {
            final userProvider = Provider.of<UserProvider>(
              context,
              listen: false,
            );
            await userProvider.logout();
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          } else {
            // Handle other errors if needed
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(error.toString())));
          }
        });
  }

  void _loadMoreTips() {
    if (_isFetchingMore || !_hasMore) return;

    setState(() => _isFetchingMore = true);
    _currentPage++;
    _fetchTips(reset: false);
  }

  @override
  Widget build(BuildContext context) {
    // Group tips properly
    final groupedTips = _groupTipsByLeagueName(_tips);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: _getAppBarSize(),
        child: AppBar(
          bottom: PreferredSize(
            preferredSize: _getAppBarSize(),
            child: ScrollDate(
              key: _scrollDateKey,
              onDateSelected: (date) {
                final parsed = DateFormat('yyyy-MM-dd').parse(date);
                setState(() {
                  selectedDate = DateFormat('dd-MM-yyyy').format(parsed);
                });
                _fetchTips();
              },
            ),
          ),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : _tips.isEmpty
              ? const Center(child: Text('No tips available for this date'))
              : ListView(
                controller: _scrollController,
                children: [
                  ...groupedTips.entries.map((entry) {
                    final compositeKey = entry.key;
                    final tipsInLeague = entry.value;
                    final logoTip = tipsInLeague.firstWhere(
                      (tip) => tip.leagueLogo.isNotEmpty,
                      orElse: () => tipsInLeague.first,
                    );

                    // Split the composite key
                    final parts = compositeKey.split('|');
                    final countryName = parts[0];
                    final leagueName = parts[1];

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4.0,
                        horizontal: 12.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LeagueCard(
                            countryName: countryName,
                            leagueName: leagueName,
                            leagueLogo: logoTip.leagueLogo,
                          ),
                          ...tipsInLeague.map((tip) => MatchCard(tip: tip)),
                        ],
                      ),
                    );
                  }),
                  if (_isFetchingMore)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
    );
  }

  // Utility function to properly group tips while preserving API order
  Map<String, List<Tip>> groupTipsByLeague(List<Tip> tips) {
    final Map<String, List<Tip>> grouped = {};
    final Map<String, int> firstAppearanceIndex =
        {}; // Track first appearance index

    for (int i = 0; i < tips.length; i++) {
      final tip = tips[i];

      // Create a UNIQUE key with country ID, country name, and league name
      final uniqueKey = '${tip.countryId}_${tip.country}_${tip.leagueName}';

      // Also ensure all fields are properly filled
      final actualCountry = tip.country.isNotEmpty ? tip.country : 'Unknown';
      final actualLeague =
          tip.leagueName.isNotEmpty ? tip.leagueName : 'Unknown League';

      final displayKey = '$actualCountry|$actualLeague';

      // Track when this league first appeared
      if (!firstAppearanceIndex.containsKey(displayKey)) {
        firstAppearanceIndex[displayKey] = i;
      }

      grouped.putIfAbsent(displayKey, () => []).add(tip);
    }

    // Sort keys by their first appearance index (preserve API order)
    final sortedKeys =
        grouped.keys.toList()..sort((a, b) {
          return firstAppearanceIndex[a]!.compareTo(firstAppearanceIndex[b]!);
        });

    // Return sorted map
    return Map.fromEntries(
      sortedKeys.map((key) => MapEntry(key, grouped[key]!)),
    );
  }

  Map<String, List<Tip>> _groupTipsByLeagueName(List<Tip> tips) {
    return groupTipsByLeague(tips);
  }

  Size _getAppBarSize() {
    final RenderBox? renderBox =
        _scrollDateKey.currentContext?.findRenderObject() as RenderBox?;
    return renderBox?.size ?? const Size.fromHeight(52);
  }
}
