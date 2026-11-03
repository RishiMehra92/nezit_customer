
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hyper_local/bloc/theme_bloc/theme_event.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeMode> {
  ThemeBloc() : super(_getInitialTheme()) {
    on<ThemeChanged>((event, emit) {
      _saveTheme(event.themeMode);
      emit(event.themeMode);
    });
  }
  static ThemeMode _getInitialTheme() {
    final box = Hive.box('themebox');
    final themeIndex = box.get('themeMode', defaultValue: ThemeMode.light.index);
    return ThemeMode.values[themeIndex];
  }
  void _saveTheme(ThemeMode theme) {
    final box = Hive.box('themebox');
    box.put('themeMode', theme.index);
  }
}