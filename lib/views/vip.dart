import 'package:flairtips/screens/payment_screen.dart';
import 'package:flairtips/utils/user_provider.dart';
import 'package:flairtips/views/tips_screen.dart';
import 'package:flairtips/widgets/filled_button.dart';
import 'package:flairtips/widgets/outlined_button.dart';
import 'package:flairtips/widgets/plan_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Item {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  Item({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class Vip extends StatefulWidget {
  const Vip({super.key});

  @override
  State<Vip> createState() => _VipState();
}

class _VipState extends State<Vip> with SingleTickerProviderStateMixin {
  final List<Item> items = [
    Item(
      title: "Exclusive Premium Tips",
      description: "Get expert predictions with higher win rates",
      icon: Icons.auto_awesome,
      color: Colors.blue,
    ),
    Item(
      title: "Higher Accuracy Rates",
      description: "Enjoy precise predictions and better outcomes",
      icon: Icons.trending_up,
      color: Colors.green,
    ),
    Item(
      title: "Value Bets & Enhanced Odds",
      description: "Access exclusive high-value betting opportunities",
      icon: Icons.attach_money,
      color: Colors.amber,
    ),
    Item(
      title: "Priority Support",
      description: "Get dedicated assistance whenever you need it",
      icon: Icons.headset_mic,
      color: Colors.purple,
    ),
  ];

  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<Color?> _backgroundColorAnimation;
  double _currentPage = 0;
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    
    _pageController = PageController(viewportFraction: 0.85);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
    
    _backgroundColorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.black.withOpacity(0.02),
    ).animate(_animationController);
    
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0;
      });
    });
    
    // Start animations after build
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _animationController.forward();
        setState(() {
          _showContent = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToPayment(BuildContext context, int planId) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => PaymentScreen(planId: planId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Widget _buildFeatureCard(Item item, int index, BuildContext context) {
    final page = _currentPage;
    final offset = (index - page).abs();
    final scale = 1 - (offset * 0.2).clamp(0.0, 0.2);
    final opacity = 1 - (offset * 0.5).clamp(0.0, 0.5);
    
    return Transform(
      transform: Matrix4.identity()
        ..scale(scale, scale)
        ..rotateY((index - page) * 0.1),
      alignment: Alignment.center,
      child: Opacity(
        opacity: opacity,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                item.color.withOpacity(0.1),
                item.color.withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: item.color.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: item.color.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 1,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -20,
                right: -20,
                child: Icon(
                  item.icon,
                  size: 80,
                  color: item.color.withOpacity(0.1),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: Icon(
                          item.icon,
                          color: item.color,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        height: 1.4,
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

  Widget _buildIndicator(int index, BuildContext context) {
    final isActive = (_currentPage - index).abs() < 0.5;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: isActive ? 24 : 8,
      height: 4,
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                colors: [
                  items[index % items.length].color,
                  items[index % items.length].color.withOpacity(0.7),
                ],
              )
            : null,
        color: isActive ? null : Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: true);
    final user = userProvider.user;
    final isUserPremium = user?.isPremium ?? false;
    
    if (isUserPremium) {
      return TipsScreen(premium: true);
    }
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.background,
                Theme.of(context).colorScheme.background.withOpacity(0.95),
              ],
            ),
          ),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              /*SliverAppBar(
                expandedHeight: 50,
                floating: true,
                pinned: false,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          Colors.transparent, 
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60, left: 24, right: 24),
                      child: AnimatedOpacity(
                        opacity: _fadeAnimation.value,
                        duration: const Duration(milliseconds: 500),
                        child: Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Unlock exclusive features for better winning chances',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),*/
              
              SliverToBoxAdapter(
                child: AnimatedOpacity(
                  opacity: _fadeAnimation.value,
                  duration: const Duration(milliseconds: 500),
                  child: Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 260,
                          child: PageView.builder(
                            controller: _pageController,
                            scrollDirection: Axis.horizontal,
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              return _buildFeatureCard(items[index], index, context);
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            items.length,
                            (index) => _buildIndicator(index, context),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
              

              if (user != null)
              SliverToBoxAdapter(
                child: AnimatedOpacity(
                  opacity: _fadeAnimation.value,
                  duration: const Duration(milliseconds: 700),
                  child: Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose Your Plan',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Select the plan that works best for you',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              
              
              if (user != null)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final planIndex = index;
                    final plans = [
                      {
                        'charge': 50.00,
                        'billing': 'Daily',
                        'planId': 0,
                        'color': Colors.blue,
                      },
                      {
                        'charge': 300.00,
                        'billing': 'Weekly',
                        'planId': 1,
                        'color': Colors.green,
                      },
                      {
                        'charge': 1000.00,
                        'billing': 'Monthly',
                        'planId': 2,
                        'color': Colors.amber,
                      },
                    ];
                    
                    if (planIndex < plans.length) {
                      final plan = plans[planIndex];
                      return AnimatedOpacity(
                        opacity: _fadeAnimation.value,
                        duration: Duration(milliseconds: 500 + (planIndex * 100)),
                        child: Transform.translate(
                          offset: Offset(0, _slideAnimation.value * (1 - (planIndex * 0.2))),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              24,
                              planIndex == 0 ? 0 : 8,
                              24,
                              planIndex == plans.length - 1 ? 40 : 8,
                            ),
                            child: PlanCard(
                              charge: plan['charge'] as double,
                              billing: plan['billing'] as String,
                              planId: plan['planId'] as int,
                              onSelect: () => _navigateToPayment(context, plan['planId'] as int),
                            ),
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                  childCount: 3,
                ),
              ),
              
              if (user == null)
                SliverToBoxAdapter(
                  child: AnimatedOpacity(
                    opacity: _fadeAnimation.value,
                    duration: const Duration(milliseconds: 1000),
                    child: Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                  ],
                                ),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Ready to get started?',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Sign in or create an account to access premium features',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  Column(
                                    children: [
                                      AppFilledButton(
                                        text: "Sign In",
                                        onPressed: () {
                                          Navigator.pushNamed(context, "/login");
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      AppOutlinedButton(
                                        text: 'Create Account',
                                        onPressed: () {
                                          Navigator.pushNamed(context, "/register");
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}