import 'package:flairtips/utils/format_date_time.dart';
import 'package:flairtips/widgets/custom_image.dart';
import 'package:flutter/material.dart';
import 'package:flairtips/models/tip.dart';
import 'package:flairtips/screens/tip_detail.dart';
import 'package:flairtips/utils/theme_provider.dart';
import 'package:flairtips/widgets/faded_divider.dart';
import 'package:provider/provider.dart';

class MatchCard extends StatelessWidget {
  final Tip tip;

  const MatchCard({required this.tip, super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Determine what to show for scores
    final String homeScoreDisplay;
    final String awayScoreDisplay;

    if (tip.playing == "Finished" || tip.isPlayed) {
      // Match has finished - show actual scores
      homeScoreDisplay = tip.homeScore.isNotEmpty ? tip.homeScore : "-";
      awayScoreDisplay = tip.awayScore.isNotEmpty ? tip.awayScore : "-";
    } else if (tip.playing == "Upcoming" || !tip.isPlayed) {
      // Match hasn't started yet - show ""
      homeScoreDisplay = "";
      awayScoreDisplay = "";
    } else {
      // Fallback or ongoing match - check if we have scores
      homeScoreDisplay = tip.homeScore.isNotEmpty ? tip.homeScore : "";
      awayScoreDisplay = tip.awayScore.isNotEmpty ? tip.awayScore : "";
    }
    return Card(
      margin: EdgeInsets.all(4),
      // Remove spacing between cards
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Theme.of(context).colorScheme.primary.withAlpha(52),
              themeProvider.isDarkMode
                  ? Colors.transparent
                  : Colors.white.withAlpha(52),
              Theme.of(context).colorScheme.primary.withAlpha(52),
            ],
          ),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TipDetail(tip: tip)),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Padding(
                padding: EdgeInsets.only(right: 4.0), // Adjust padding
                child: Row(
                  children: [
                    // Leading: Time Card
                    Container(
                      constraints: const BoxConstraints(minHeight: 60),
                      // Ensure a reasonable height
                      alignment: Alignment.center,
                      // Center time text vertically
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      // Adjust padding
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Theme.of(context).colorScheme.primary.withAlpha(52),
                            //Colors.transparent,
                            Theme.of(
                              context,
                            ).colorScheme.secondary.withAlpha(52),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(
                            4,
                          ), // Adjust the radius as needed
                          bottomLeft: Radius.circular(4),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Conditionally show confidence or an expanded SizedBox
                          tip.confidence.isNotEmpty
                              ? Text(
                                tip.confidence,
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14.0,
                                ),
                              )
                              : Expanded(
                                // ← This expands to take available space when no confidence
                                child: SizedBox.shrink(),
                              ),

                          SizedBox(
                            width: 60,
                            height: 40,
                            child: Card(
                              margin: EdgeInsets.all(4.0),
                              clipBehavior: Clip.hardEdge,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4.0),
                                side: BorderSide(color: Colors.grey, width: .5),
                              ),
                              child: Center(
                                child: Text(
                                  formatTime(tip.fixtureDate),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8), // Spacing

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  CustomImage(
                                    imageString: tip.homeImage ?? "",
                                    height: 12,
                                    width: 12,
                                  ),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      tip.home,
                                      overflow:
                                          TextOverflow
                                              .ellipsis, // Prevents overflow
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                homeScoreDisplay,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 4),
                          FadedDivider(fadeWidth: 60),
                          SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  CustomImage(
                                    imageString: tip.awayImage ?? "",
                                    height: 12,
                                    width: 12,
                                  ),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      tip.away,
                                      overflow:
                                          TextOverflow
                                              .ellipsis, // Prevents overflow
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                awayScoreDisplay,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 12),
                    SizedBox(
                      width: 80,
                      height: 35,
                      child: Card(
                        margin: EdgeInsets.all(4.0),
                        clipBehavior: Clip.hardEdge,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                          side: BorderSide(color: Colors.grey, width: .5),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                tip.bestTip.isNotEmpty && tip.bestTip != '-'
                                    ? tip.bestTip
                                    : tip.tip,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              SizedBox(width: 4),
                              /*tip.premium
                                  ? Text("👑")
                                  : */
                              Icon(Icons.arrow_forward_ios_rounded, size: 12),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
