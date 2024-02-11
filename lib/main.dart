import 'package:flutter/material.dart';
import 'package:flutter_sample_custom_switch/color_schemes.g.dart';
import 'package:flutter_sample_custom_switch/custom_switch.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        theme: ThemeData(
          colorScheme: lightColorScheme,
          textTheme: GoogleFonts.ralewayTextTheme(),
        ),
        darkTheme: ThemeData(
          colorScheme: darkColorScheme,
          textTheme: GoogleFonts.ralewayTextTheme(),
        ),
        color: Colors.deepPurple,
        builder: (context, child) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Custom Switch'),
                CustomSwitch(
                  initialValue: false,
                  activeText: 'ON',
                  inactiveText: 'OFF',
                  onChanged: (value) => debugPrint('Value: $value'),
                ),
              ],
            ),
          ),
        ),
      );
}
