import 'package:flutter/material.dart';

class MyCarousel extends StatelessWidget {
  const MyCarousel({super.key});

  final List<String> imageUrls = const [
    'https://images.pexels.com/photos/9629696/pexels-photo-9629696.jpeg', 
    'https://images.pexels.com/photos/7230917/pexels-photo-7230917.jpeg',
    'https://images.pexels.com/photos/5428257/pexels-photo-5428257.jpeg',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: PageView.builder(
        itemCount: imageUrls.length, 
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(imageUrls[index]), 
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}