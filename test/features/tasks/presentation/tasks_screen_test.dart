import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/app.dart';
import 'package:todo_app/features/tasks/data/repositories/task_local_repository.dart';
import 'package:todo_app/features/tasks/presentation/widgets/task_tile.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<void> pumpApp(WidgetTester tester) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(TodoApp(taskRepository: TaskLocalRepository(preferences)));
    await tester.pumpAndSettle();
  }

  Future<void> addTask(WidgetTester tester, String title) async {
    await tester.tap(find.text('New task'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('task-title-field')), title);
    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();
  }

  testWidgets('adds a task from the editor sheet', (WidgetTester tester) async {
    await pumpApp(tester);
    expect(find.text('No tasks yet'), findsOneWidget);

    await addTask(tester, 'Buy milk');

    expect(find.text('Buy milk'), findsOneWidget);
    expect(find.text('0 of 1 done'), findsOneWidget);
  });

  testWidgets('rejects an empty title', (WidgetTester tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('New task'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();

    expect(find.text('Give the task a title.'), findsOneWidget);
    expect(find.text('No tasks yet'), findsOneWidget);
  });

  testWidgets('toggles a task and filters the list', (WidgetTester tester) async {
    await pumpApp(tester);
    await addTask(tester, 'Buy milk');
    await addTask(tester, 'Call mum');

    final Finder buyMilkTile = find.ancestor(
      of: find.text('Buy milk'),
      matching: find.byType(TaskTile),
    );
    await tester.tap(find.descendant(of: buyMilkTile, matching: find.byType(Checkbox)));
    await tester.pumpAndSettle();
    expect(find.text('1 of 2 done'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('Buy milk'), findsOneWidget);
    expect(find.text('Call mum'), findsNothing);
  });

  testWidgets('swipe deletes a task and undo restores it', (WidgetTester tester) async {
    await pumpApp(tester);
    await addTask(tester, 'Buy milk');

    await tester.drag(find.text('Buy milk'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Buy milk'), findsNothing);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(find.text('Buy milk'), findsOneWidget);
  });
}
