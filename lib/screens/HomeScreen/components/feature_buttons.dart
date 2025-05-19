import 'package:flutter/material.dart';
import 'package:wellbotapp/screens/DietFitness/diet_fitness_screen.dart';
import 'package:wellbotapp/screens/MoneyManagement/money_management_screen.dart';
import 'package:wellbotapp/screens/social_helper_screen.dart';
import 'package:wellbotapp/screens/time_management/time_management_screen.dart';

class FeatureButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.0),
      margin: EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.lightBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Features',
              style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.bold),
            ),
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 12.0,
            padding: EdgeInsets.all(10.0),
            children: [
              _buildFeatureButton(context, 'Time Management', Icons.access_time,
                  TimeManagementScreen()),
              _buildFeatureButton(
                  context, 'Diet & Fitness', Icons.fitness_center,
                  DietFitnessScreen()),
              _buildFeatureButton(
                  context, 'Money Management', Icons.attach_money,
                  MoneyManagementScreen()),
              _buildFeatureButton(
                  context, 'Social Helper', Icons.people, SocialHelperScreen()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureButton(BuildContext context, String title, IconData icon,
      Widget screen) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => screen));
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade700,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: EdgeInsets.symmetric(vertical: 12.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50.0, color: Colors.white),
          SizedBox(height: 8.0),
          Text(
            title,
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}