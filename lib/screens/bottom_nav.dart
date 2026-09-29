import 'dart:io';
import 'package:flairtips/utils/user_provider.dart';
import 'package:flairtips/views/tips_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flairtips/views/settings.dart';
import 'package:flairtips/views/vip.dart';
import 'package:provider/provider.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  BottomNavScreenState createState() => BottomNavScreenState();
}

class BottomNavScreenState extends State<BottomNavScreen> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [TipsScreen(premium: false), Vip(), Settings()];
  }

  void _onItemTapped(int index) async {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevents the default pop behavior
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          bool exitApp = await showExitConfirmationDialog(context);
          if (exitApp) {
            if (Platform.isAndroid) {
              SystemNavigator.pop(); // Exit on Android
            } else if (Platform.isIOS) {
              exit(0); // Force exit on iOS (Not recommended)
            }
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              showExitConfirmationDialog(context);
            },
          ),
          title: Text(returnTitle(context, _selectedIndex), style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700
          ),),
          centerTitle: true,
          actions: [
            _selectedIndex == 1
                ? Container(
                  width: 32,
                  height: 32,
                  margin: EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ColorScheme.of(context).primary,
                    borderRadius: BorderRadius.circular(100),
                  ),

                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.workspace_premium_rounded, size: 24),
                )
                : SizedBox.shrink(),
          ],
        ),
        body: AnimatedSwitcher(
          duration: Duration(milliseconds: 500),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                ),
                child: child,
              ),
            );
          },
          child: _pages[_selectedIndex],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8),
              child: Stack(
                children: [
                  // Shadow behind the nav bar
                  Container(
                    height:
                        60, // adjust based on your BottomNavigationBar height
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: ColorScheme.of(context).primary.withAlpha(128),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BottomNavigationBar(
                      type: BottomNavigationBarType.fixed,
                      backgroundColor: ColorScheme.of(context).surface,
                      elevation: 0,
                      currentIndex: _selectedIndex,
                      onTap: _onItemTapped,
                      selectedFontSize: 12,
                      unselectedFontSize: 11,
                      items: const [
                        BottomNavigationBarItem(
                          icon: Icon(Icons.tips_and_updates_outlined, size: 24),
                          activeIcon: Icon(
                            Icons.tips_and_updates_rounded,
                            size: 26,
                          ),
                          label: 'Tips',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(
                            Icons.workspace_premium_outlined,
                            size: 24,
                          ),
                          activeIcon: Icon(
                            Icons.workspace_premium_rounded,
                            size: 26,
                          ),
                          label: 'Premium',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.settings_outlined, size: 24),
                          activeIcon: Icon(Icons.settings, size: 26),
                          label: 'Settings',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String returnTitle(BuildContext context, int index) {
  String title;
  final userProvider = Provider.of<UserProvider>(context);
  final user = userProvider.user;
  final isPremium = user?.isPremium ?? false;

  switch (index) {
    case 1:
      title = isPremium ? "VIP Tips" : "Go Premium";
      break;
    case 2:
      title = "Settings";
      break;
    default:
      title = "Tips";
  }

  return title;
}

/// Function to show exit confirmation dialog
Future<bool> showExitConfirmationDialog(BuildContext context) async {
  return await showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              title: Text("Exit App"),
              content: Text("Are you sure you want to exit?"),
              actions: [
                TextButton(
                  onPressed: () => {Navigator.of(context).pop(false)},
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text("Exit"),
                ),
              ],
            ),
      ) ??
      false;
}
