import 'package:flutter/material.dart';

class LoyaltyCard extends StatelessWidget {
  const LoyaltyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MOTIONIX',
                style: TextStyle(
                  color: Colors.black45.withValues(alpha: 0.75),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.black45.withValues(alpha: 0.10),
                ),
                child: Text(
                  'PLATINUM',
                  style: TextStyle(
                    color: Colors.black45.withValues(alpha: 0.75),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '12 450 pts',
            style: TextStyle(
              color: Colors.black45.withValues(alpha: 0.70),
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Loyalty Points',
            style: TextStyle(
              color: Colors.black45.withValues(alpha: 0.4),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.person_outline,
                color: Colors.black45.withValues(alpha: 0.50),
                size: 13,
              ),
              const SizedBox(width: 5),
              Text(
                'Alex Adopnex',
                style: TextStyle(
                  color: Colors.black45.withValues(alpha: 0.65),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
