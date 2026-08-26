import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:newsreader/core/utils/window_size_class.dart';

void main() {
  Widget buildAt(double width, ValueChanged<WindowSizeClass> onBuild) {
    return MediaQuery(
      data: MediaQueryData(size: Size(width, 800)),
      child: Builder(
        builder: (context) {
          onBuild(context.windowSizeClass);
          return const SizedBox.shrink();
        },
      ),
    );
  }

  testWidgets('ancho menor a 840dp es compact', (tester) async {
    WindowSizeClass? result;
    await tester.pumpWidget(buildAt(839, (value) => result = value));
    expect(result, WindowSizeClass.compact);
  });

  testWidgets('ancho de exactamente 840dp es expanded', (tester) async {
    WindowSizeClass? result;
    await tester.pumpWidget(buildAt(840, (value) => result = value));
    expect(result, WindowSizeClass.expanded);
  });

  testWidgets('ancho mayor a 840dp es expanded', (tester) async {
    WindowSizeClass? result;
    await tester.pumpWidget(buildAt(1200, (value) => result = value));
    expect(result, WindowSizeClass.expanded);
  });
}
