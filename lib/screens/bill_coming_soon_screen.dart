import 'package:flutter/material.dart';

class BillComingSoonScreen extends StatelessWidget {
  const BillComingSoonScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 448),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Clock icon — mirrors <Clock className="w-16 h-16 text-blue-600" />
                const Icon(
                  Icons.access_time_rounded,
                  size: 64,
                  color: Color(0xFF2563EB),
                ),
                const SizedBox(height: 24),

                // Title
                const Text(
                  'Coming Soon',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  "We're working hard to bring you a seamless bill payment experience. Stay tuned for updates!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),

                // Notification banner — mirrors the bg-blue-50 div
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_outlined,
                              size: 20, color: Color(0xFF2563EB)),
                          SizedBox(width: 6),
                          Text(
                            'Get Notified',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "We'll notify you when the bill payment feature is ready",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Progress bar — mirrors h-2 bg-gray-200 with w-3/4 blue fill
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Stack(
                        children: [
                          Container(
                            height: 8,
                            width: double.infinity,
                            color: const Color(0xFFE5E7EB),
                          ),
                          FractionallySizedBox(
                            widthFactor: 0.75, // mirrors w-3/4
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Development in progress',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}