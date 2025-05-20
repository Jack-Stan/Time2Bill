import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// A widget that prevents overflow issues in UI - performance optimized version
class OverflowSafeWidget extends StatelessWidget {
  final Widget child;
  final bool handleFontErrors;

  const OverflowSafeWidget({
    Key? key,
    required this.child,
    this.handleFontErrors = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // On web, minimize extra wrappers for better performance
    if (kIsWeb && !handleFontErrors) {
      return child;
    }

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        // Replace deprecated textScaleFactor with textScaler
        textScaler: const TextScaler.linear(1.0),
      ),
      child: handleFontErrors
          ? _FontErrorHandler(child: child)
          : child,
    );
  }
}

/// A widget that handles font loading errors
class _FontErrorHandler extends StatelessWidget {
  final Widget child;

  const _FontErrorHandler({required this.child});

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: DefaultTextStyle.of(context).style.copyWith(
        fontFamily: _getFallbackFontFamily(context),
        fontFamilyFallback: const [
          'Arial', 
          'Roboto', 
          'Helvetica',
        ],
      ),
      child: child,
    );
  }

  String? _getFallbackFontFamily(BuildContext context) {
    // Use system fonts that are likely to be available
    if (Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.macOS) {
      return 'SF Pro Text';
    } else {
      return 'Roboto';
    }
  }
}

/// A basic row that uses minimal wrappers
class BasicRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  
  const BasicRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children,
    );
  }
}

/// A basic column that uses minimal wrappers
class BasicColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  
  const BasicColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children,
    );
  }
}

/// Special web-safe container - performance optimized
class WebSafeContainer extends StatelessWidget {
  final Widget child;
  final bool enableHitTesting;
  
  const WebSafeContainer({
    Key? key,
    required this.child,
    this.enableHitTesting = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Skip unnecessary wrappers on non-web platforms for better performance
    if (!kIsWeb) {
      return child;
    }
    
    // Use simpler structure for web
    if (!enableHitTesting) {
      return MouseRegion(
        opaque: false,
        hitTestBehavior: HitTestBehavior.deferToChild,
        child: child,
      );
    }
    
    return child;
  }
}

/// Extension methods - performance optimized
extension WebSafetyExtension on Widget {
  /// Makes this widget safe for web rendering - optimized version
  Widget makeWebSafe({bool enableHitTesting = true}) {
    if (!kIsWeb) return this;
    
    return WebSafeContainer(
      enableHitTesting: enableHitTesting,
      child: this,
    );
  }
  
  /// Makes this widget scrollable with web safety - optimized version
  Widget makeScrollableAndWebSafe({
    Axis direction = Axis.vertical,
    bool alwaysScrollable = false,
  }) {
    // Only add scrolling when really needed
    return SingleChildScrollView(
      scrollDirection: direction,
      physics: const ClampingScrollPhysics(),
      // Use less complex widget tree
      child: this,
    );
  }
}

// Performance optimized versions of SafeRow and SafeColumn
class SafeRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final TextDirection? textDirection;
  final VerticalDirection verticalDirection;
  final TextBaseline? textBaseline;
  final bool addScrolling;

  const SafeRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.textBaseline,
    this.addScrolling = false,
  });

  @override
  Widget build(BuildContext context) {
    // Simple direct implementation for better performance
    if (!addScrolling) {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        textDirection: textDirection,
        verticalDirection: verticalDirection,
        textBaseline: textBaseline,
        children: children,
      );
    }
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      child: Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        textDirection: textDirection,
        verticalDirection: verticalDirection,
        textBaseline: textBaseline,
        children: children,
      ),
    );
  }
}

class SafeColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final TextDirection? textDirection;
  final VerticalDirection verticalDirection;
  final TextBaseline? textBaseline;
  final bool addScrolling;

  const SafeColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.textBaseline,
    this.addScrolling = false,
  });

  @override
  Widget build(BuildContext context) {
    // Simple direct implementation for better performance
    if (!addScrolling) {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        textDirection: textDirection,
        verticalDirection: verticalDirection,
        textBaseline: textBaseline,
        children: children,
      );
    }
    
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        textDirection: textDirection,
        verticalDirection: verticalDirection,
        textBaseline: textBaseline,
        children: children,
      ),
    );
  }
}
