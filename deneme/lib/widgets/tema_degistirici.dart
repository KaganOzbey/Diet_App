import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../servisler/tema_servisi.dart';

class TemaDegistirici extends StatelessWidget {
  final bool showLabel;
  final double iconSize;
  
  const TemaDegistirici({
    Key? key,
    this.showLabel = true,
    this.iconSize = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TemaServisi>(
      builder: (context, temaServisi, child) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          child: showLabel
              ? ListTile(
                  leading: Icon(
                    temaServisi.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    size: iconSize,
                  ),
                  title: Text(
                    temaServisi.isDarkMode ? 'Karanlık Mod' : 'Aydınlık Mod',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  trailing: Switch.adaptive(
                    value: temaServisi.isDarkMode,
                    onChanged: (value) {
                      temaServisi.toggleTheme();
                    },
                    activeColor: Colors.green,
                  ),
                  onTap: () {
                    temaServisi.toggleTheme();
                  },
                )
              : IconButton(
                  icon: AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    child: Icon(
                      temaServisi.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      key: ValueKey(temaServisi.isDarkMode),
                      size: iconSize,
                    ),
                  ),
                  onPressed: () {
                    temaServisi.toggleTheme();
                  },
                  tooltip: temaServisi.isDarkMode ? 'Aydınlık Moda Geç' : 'Karanlık Moda Geç',
                ),
        );
      },
    );
  }
} 