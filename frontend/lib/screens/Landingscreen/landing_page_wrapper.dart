import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'LandingPage.dart';

/// Een wrapper component om ervoor te zorgen dat de landingspagina goed scrollt
class LandingPageWrapper extends StatelessWidget {
  const LandingPageWrapper({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Specifieke implementatie voor web om NaN transform fouten te voorkomen
      return Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: ClipRect(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    return notification is! OverscrollNotification;
                  },
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    primary: true,
                    child: RepaintBoundary(
                      child: LandingPageWidget(
                        disableAnimations: true,
                        useSimpleLayout: true,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    } else {
      // Voor niet-web platforms, gebruik een eenvoudigere implementatie
      return const Scaffold(
        body: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: LandingPageWidget(),
        ),
      );
    }
  }
}
