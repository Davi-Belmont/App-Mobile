// Responsável: Alisson Batista (Tela de Calendário e integração de datas)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_planner/core/theme/app_colors.dart';
import 'package:study_planner/core/utils/date_utils.dart';
import 'package:study_planner/core/widgets/activity_tile.dart';
import 'package:study_planner/core/widgets/common_widgets.dart';
import 'package:study_planner/data/models/activity.dart';
import 'package:study_planner/data/models/activity_query.dart';
import 'package:study_planner/features/disciplines/disciplines_provider.dart';
import 'package:study_planner/features/tasks/activities_provider.dart';
import 'package:study_planner/features/tasks/activities_query_builder.dart';
import 'package:study_planner/features/tasks/task_form_sheet.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();

  /// Só o mês visível é pedido à API: GET /activities?from=...&to=...
  ActivityQuery get _monthQuery => ActivityQuery(
        from: DateTime(_focused.year, _focused.month, 1),
        to: DateTime(_focused.year, _focused.month + 1, 1).subtract(const Duration(milliseconds: 1)),
      );

  void _onPageChanged(DateTime focused) {
    final now = DateTime.now();
    final isCurrentMonth = focused.year == now.year && focused.month == now.month;
    setState(() {
      _focused = focused;
      _selected = isCurrentMonth ? now : DateTime(focused.year, focused.month, 1);
    });
  }

  Widget _content(BuildContext context, ActivitiesResult r) {
    final discs = context.watch<DisciplinesProvider>();
    final acts = context.read<ActivitiesProvider>();

    // Agrupa as atividades do mês pela data de entrega (dueDate).
    final events = <DateTime, List<Activity>>{};
    for (final a in r.items) {
      events.putIfAbsent(DateHelpers.utcDay(a.dueDate), () => []).add(a);
    }
    List<Activity> eventsFor(DateTime d) => events[DateHelpers.utcDay(d)] ?? const [];

    final dayList = [...eventsFor(_selected)]..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return RefreshIndicator(
      onRefresh: () => Future.wait([acts.load(silent: true), r.reload()]),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          if (r.loading) const LinearProgressIndicator(minHeight: 2),
          AppCard(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            child: TableCalendar<Activity>(
              locale: 'pt_BR',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2035, 12, 31),
              focusedDay: _focused,
              selectedDayPredicate: (d) => isSameDay(_selected, d),
              startingDayOfWeek: StartingDayOfWeek.sunday,
              availableCalendarFormats: const {CalendarFormat.month: 'Mês'},
              eventLoader: eventsFor,
              onDaySelected: (selected, focused) => setState(() {
                _selected = selected;
                _focused = focused;
              }),
              onPageChanged: _onPageChanged,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: false,
                todayDecoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                todayTextStyle: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                selectedDecoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              ),
              calendarBuilders: CalendarBuilders<Activity>(
                markerBuilder: (context, day, evs) {
                  if (evs.isEmpty) return null;
                  return Positioned(
                    bottom: 4,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final e in evs.take(3))
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: e.isCompleted ? const Color(0xFF9CA3AF) : e.type.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [for (final t in ActivityType.values) _LegendDot(t)],
          ),
          SectionTitle(DateHelpers.longDate(_selected)),
          if (dayList.isEmpty)
            const AppCard(
              child: Row(
                children: [
                  Icon(Icons.event_available_rounded, color: AppColors.textMuted),
                  SizedBox(width: 10),
                  Expanded(child: Text('Nenhuma atividade neste dia.', style: TextStyle(color: AppColors.textMuted))),
                ],
              ),
            )
          else
            for (final a in dayList)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ActivityTile(
                  activity: a,
                  discipline: discs.byId(a.disciplineId),
                  onTap: () => TaskFormSheet.show(context, activity: a),
                  onToggle: (done) => context.read<ActivitiesProvider>().toggle(a, done),
                ),
              ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => TaskFormSheet.show(context, initialDate: _selected),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Atividade'),
      ),
      body: Column(
        children: [
          ScreenHeader(
            title: 'Calendário',
            subtitle: 'Prazos e provas do semestre',
            trailing: TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.white, backgroundColor: const Color(0x33FFFFFF)),
              onPressed: () => setState(() {
                _focused = DateTime.now();
                _selected = DateTime.now();
              }),
              icon: const Icon(Icons.today_rounded, size: 18),
              label: const Text('Hoje'),
            ),
          ),
          Expanded(
            child: ActivitiesQueryBuilder(
              query: _monthQuery,
              builder: _content,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot(this.type);
  final ActivityType type;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: type.color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(type.label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      );
}