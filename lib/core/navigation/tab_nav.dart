// Responsável: Cainã Coutinho
import 'package:flutter/foundation.dart';

/// Aba atual da barra inferior. Qualquer tela pode trocar de aba:
///   currentTab.value = TabIndex.tasks;
final ValueNotifier<int> currentTab = ValueNotifier<int>(0);

class TabIndex {
  static const home = 0;
  static const disciplines = 1;
  static const calendar = 2;
  static const tasks = 3;
  static const profile = 4;
}
