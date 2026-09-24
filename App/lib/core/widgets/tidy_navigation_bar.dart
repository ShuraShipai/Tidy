import 'package:flutter/material.dart';

class TidyNavigationBar extends StatelessWidget {
  const TidyNavigationBar({
    required this.currentIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: const <NavigationDestination>[
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.photo_outlined),
          selectedIcon: Icon(Icons.photo_rounded),
          label: 'Photos',
        ),
        NavigationDestination(
          icon: Icon(Icons.video_library_outlined),
          selectedIcon: Icon(Icons.video_library_rounded),
          label: 'Videos',
        ),
        NavigationDestination(
          icon: Icon(Icons.contacts_outlined),
          selectedIcon: Icon(Icons.contacts_rounded),
          label: 'Contacts',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings_rounded),
          label: 'Settings',
        ),
      ],
    );
  }
}
