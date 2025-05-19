import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellbotapp/components/background.dart';
import 'package:wellbotapp/screens/Welcome/welcome_screen.dart';
import 'package:wellbotapp/responsive.dart';

class GettingStartedScreen extends StatelessWidget {
  final VoidCallback onGetStarted;

  const GettingStartedScreen({Key? key, required this.onGetStarted})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Background(
      child: Responsive(
        mobile: _buildMobileContent(context),
        tablet: _buildTabletContent(context),
        desktop: _buildDesktopContent(context),
      ),
    );
  }

  // Mobile Layout with 3x3 Layout
  Widget _buildMobileContent(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 05), // Space at top of page
          Text(
            "Getting Started",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 50), // Space below title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Column(
              children: [
                _buildFeatureRow(context, [
                  _FeatureIcon(
                    icon: Icons.person,
                    title: "Profile Setup",
                    description: "Set up your profile.",
                  ),
                  _FeatureIcon(
                    icon: Icons.fitness_center,
                    title: "Health & Fitness",
                    description: "Track fitness goals.",
                  ),
                  _FeatureIcon(
                    icon: Icons.money,
                    title: "Financial Goals",
                    description: "Manage expenses.",
                  ),
                ]),
                const SizedBox(height: 8),
                _buildFeatureRow(context, [
                  _FeatureIcon(
                    icon: Icons.schedule,
                    title: "Task Scheduling",
                    description: "Plan tasks with reminders.",
                  ),
                  _FeatureIcon(
                    icon: Icons.track_changes,
                    title: "Progress Tracking",
                    description: "Monitor task progress.",
                  ),
                  _FeatureIcon(
                    icon: Icons.nature_people,
                    title: "Positive Mindset",
                    description: "Daily affirmations.",
                  ),
                ]),
                const SizedBox(height: 8),
                _buildFeatureRow(context, [
                  _FeatureIcon(
                    icon: Icons.group,
                    title: "Social Connections",
                    description: "Build relationships.",
                  ),
                  _FeatureIcon(
                    icon: Icons.public,
                    title: "Public Speaking",
                    description: "Improve skills.",
                  ),
                  _FeatureIcon(
                    icon: Icons.directions_run,
                    title: "Workout Tips",
                    description: "Stay active.",
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 80), // Space above button
          ElevatedButton(
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setBool('hasSeenGettingStarted', true);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => WelcomeScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlue,
              padding: const EdgeInsets.symmetric(
                  vertical: 10, horizontal: 20), // Shorter width
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            child: const Text(
              "Get Started",
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
          const SizedBox(height: 10), // Bottom padding
        ],
      ),
    );
  }

  // Build a row with three features
  Widget _buildFeatureRow(BuildContext context, List<Widget> features) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: features
          .map((feature) => Expanded(
                child: feature,
              ))
          .toList(),
    );
  }

  // Tablet Layout
  Widget _buildTabletContent(BuildContext context) {
    return _buildMobileContent(context);
  }

  // Desktop Layout
  Widget _buildDesktopContent(BuildContext context) {
    return Center(
      child: Container(
        width: 800, // Constrain width for desktop view
        child: _buildMobileContent(context),
      ),
    );
  }
}

class _FeatureIcon extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureIcon({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.white,
          child: Icon(
            icon,
            size: 30,
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(height: 3), // Reduced padding
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2), // Reduced padding
        Text(
          description,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
