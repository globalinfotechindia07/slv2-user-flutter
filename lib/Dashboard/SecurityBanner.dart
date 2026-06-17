import 'package:flutter/material.dart';

class SecurityBanner extends StatelessWidget {
  const SecurityBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 24),
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 16, right: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFA7F3D0), 
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Text section
          const Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 14, color: Colors.black),
                children: [
                  TextSpan(text: 'Do not share '),
                  TextSpan(
                    text: 'MPIN',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ' with others | '),
                  TextSpan(
                    text: 'Your safety is our top priority',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Lock icon with red dots
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Yellow rounded box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFACC15), // yellow-400
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.lock, color: Colors.black, size: 24),
              ),

              // Top-right red dot
              const Positioned(
                top: -6,
                right: -6,
                child: _RedDot(),
              ),

              // Bottom-right red dot
              const Positioned(
                bottom: -6,
                right: -6,
                child: _RedDot(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RedDot extends StatelessWidget {
  const _RedDot({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: const BoxDecoration(
        color: Color(0xFFEF4444), // red-500
        shape: BoxShape.circle,
      ),
    );
  }
}