import 'package:flutter/material.dart';

class ReferralCodeExplanationSheet extends StatelessWidget {
  const ReferralCodeExplanationSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 20),
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFE8C7B6), Color(0xFFCC471B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.card_giftcard,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Text(
                    'How Referral Codes Work',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 25),
          _buildStep(
            icon: Icons.person_add,
            title: 'Share Your Code',
            description: 'Every user gets a unique referral code when they sign up. Share yours with friends!',
            color: Color(0xFFCC471B),
          ),
          SizedBox(height: 15),
          _buildStep(
            icon: Icons.login,
            title: 'Friends Sign Up',
            description: 'When your friends use your code during sign-up, they get special rewards.',
            color: Color(0xFF8715C9),
          ),
          SizedBox(height: 15),
          _buildStep(
            icon: Icons.emoji_events,
            title: 'Earn Rewards',
            description: 'You earn points and exclusive rewards for each successful referral!',
            color: Color(0xFF009688),
          ),
          SizedBox(height: 25),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 30),
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Color(0xFFE0E0E0)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Color(0xFFCC471B),
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Codes are unique and can be used multiple times!',
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Montserrat',
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 25),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFCC471B),
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                'Got It!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStep({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 30),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat',
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'Montserrat',
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ReferralCodeExplanationSheet(),
    );
  }
}
