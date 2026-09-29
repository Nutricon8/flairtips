import 'package:flairtips/models/tip.dart';
import 'package:flairtips/utils/api_service.dart';
import 'package:flairtips/utils/predictions_utils.dart';
import 'package:flairtips/utils/user_provider.dart';
import 'package:flairtips/widgets/ScrollDate.dart';
import 'package:flairtips/widgets/league_card.dart';
import 'package:flairtips/widgets/match_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TipsScreen extends StatefulWidget {
  final bool premium;
  const TipsScreen({required this.premium, super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  String selectedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
  final GlobalKey _dateScrollWidgetKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  final List<Tip> _tips = [];
  final Map<String, List<Tip>> _groupedTips = {};
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMoreData = true;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _fetchInitialTips();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          !isLoadingMore &&
          hasMoreData) {
        _loadMoreTips();
      }
    });
  }

  Future<void> _fetchInitialTips() async {
    setState(() {
      isLoading = true;
      _tips.clear();
      _groupedTips.clear();
      _currentPage = 1;
    });

    try {
      final tips = await getTips(widget.premium, selectedDate, _currentPage);
      _addUniqueTips(tips);
      setState(() {
        isLoading = false;
        hasMoreData = tips.isNotEmpty;
      });
    } catch (error) {
      _handleError(error);
    }
  }

  Future<void> _loadMoreTips() async {
    setState(() {
      _currentPage++;
      isLoadingMore = true;
    });

    try {
      final moreTips = await getTips(
        widget.premium,
        selectedDate,
        _currentPage,
      );
      _addUniqueTips(moreTips);
      setState(() {
        isLoadingMore = false;
        hasMoreData = moreTips.isNotEmpty;
      });
    } catch (error) {
      setState(() => isLoadingMore = false);
      _handleError(error);
    }
  }

  void _addUniqueTips(List<Tip> newTips) {
    final existingIds = _tips.map((t) => t.id).toSet();
    final uniqueTips =
        newTips.where((t) => !existingIds.contains(t.id)).toList();
    _tips.addAll(uniqueTips);

    for (var tip in uniqueTips) {
      // FIXED: Create a COMPOSITE key with country + league name
      // This ensures "England|Premier League" and "Bahrain|Premier League" are separate
      final compositeKey = '${tip.country}|${tip.leagueName}';
      _groupedTips.putIfAbsent(compositeKey, () => []).add(tip);
    }
  }

  void _handleError(Object error) async {
    setState(() => isLoading = false);
    if (error is UnauthorizedException && widget.premium && hasMoreData) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.logout();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Group tips properly
    final groupedTips = groupTipsByLeague(_tips);
    final groupedTipsKeys = groupedTips.keys.toList();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: _getAppBarSize(),
        child: AppBar(
          bottom: PreferredSize(
            preferredSize: _getAppBarSize(),
            child: ScrollDate(
              key: _dateScrollWidgetKey,
              onDateSelected: (date) {
                final parsed = DateFormat('yyyy-MM-dd').parse(date);
                selectedDate = DateFormat('dd-MM-yyyy').format(parsed);
                hasMoreData = true;
                _fetchInitialTips();
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
              : ListView.builder(
                controller: _scrollController,
                itemCount: groupedTipsKeys.length + (isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= groupedTipsKeys.length) {
                    return const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final compositeKey = groupedTipsKeys[index];
                  final tipsInLeague = groupedTips[compositeKey]!;
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
                },
              ),
    );
  }

  Size _getAppBarSize() {
    final renderBox =
        _dateScrollWidgetKey.currentContext?.findRenderObject() as RenderBox?;
    return renderBox?.size ?? const Size.fromHeight(52);
  }
}
