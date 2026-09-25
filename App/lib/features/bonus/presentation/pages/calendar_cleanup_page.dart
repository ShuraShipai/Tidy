import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tidy_spacing.dart';
import '../../../../core/widgets/tidy_action_button.dart';
import '../../models/bonus_records.dart';
import '../../services/group_eight_service.dart';
import '../../widgets/bonus_page_frame.dart';

class CalendarCleanupPage extends ConsumerStatefulWidget {
  const CalendarCleanupPage({super.key});

  @override
  ConsumerState<CalendarCleanupPage> createState() =>
      _CalendarCleanupPageState();
}

class _CalendarCleanupPageState extends ConsumerState<CalendarCleanupPage>
    with WidgetsBindingObserver {
  String _status = 'loading';
  String _filter = 'old';
  String? _error;
  List<CalendarEventRecord> _events = [];
  final Set<String> _selected = {};
  List<CalendarEventRecord> _reviewed = [];
  bool _busy = false;
  bool _review = false;
  String? _completed;

  GroupEightService get _service => ref.read(groupEightServiceProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    try {
      final status = await _service.calendarStatus();
      if (!mounted) return;
      setState(() => _status = status);
      if (status == 'authorized') await _loadEvents();
    } catch (error) {
      if (mounted) {
        setState(() {
          _status = 'error';
          _error = '$error';
        });
      }
    }
  }

  Future<void> _requestAccess() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final response = await _service.requestCalendar();
      final status = response['status'] as String? ?? 'unknown';
      if (!mounted) return;
      setState(() => _status = status);
      if (status == 'authorized') await _loadEvents();
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loadEvents() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final rows = await _service.calendarEvents();
      if (mounted) {
        setState(() {
          _events = rows.map(CalendarEventRecord.fromMap).toList()
            ..sort((a, b) => b.start.compareTo(a.start));
          _status = 'authorized';
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDelete() async {
    final reviewed = List<CalendarEventRecord>.unmodifiable(_reviewed);
    if (reviewed.isEmpty || _busy) return;
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CalendarConfirmation(count: reviewed.length),
    );
    if (confirm != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final response = await _service.deleteCalendarEvents(
        reviewed.map((event) => event.toMap()).toList(growable: false),
      );
      final deleted = (response['deleted'] as num?)?.toInt() ?? 0;
      final failedRows = response['failed'] as List? ?? const [];
      final failedKeys = failedRows
          .whereType<Map>()
          .map((row) {
            final id = row['id'] as String?;
            final start = (row['start'] as num?)?.round();
            return id == null || start == null ? null : '$id:$start';
          })
          .whereType<String>()
          .toSet();
      if (!mounted) return;
      setState(() {
        final succeeded = reviewed
            .map(_key)
            .where((key) => !failedKeys.contains(key))
            .toSet();
        _events.removeWhere((event) => succeeded.contains(_key(event)));
        _selected.removeAll(succeeded);
        _review = false;
        _reviewed = [];
        _completed =
            '$deleted ${deleted == 1 ? 'event occurrence' : 'event occurrences'} removed';
        if (failedKeys.isNotEmpty) {
          _error =
              '${failedKeys.length} event occurrence(s) could not be removed. They remain available for review.';
        }
      });
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shown = _events.where((event) => event.kind == _filter).toList();
    if (_status != 'authorized') return _accessPage();
    if (_review) return _reviewPage();
    return BonusPageFrame(
      title: 'Calendar Cleanup',
      subtitle: 'Old and repeated events from about the past four years.',
      backLabel: 'Optional Features',
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('${_selected.length} selected'),
              const Spacer(),
              const Text('No storage estimate'),
            ],
          ),
          const SizedBox(height: TidySpacing.sm),
          TidyActionButton(
            label: 'Review Events',
            onPressed: _selected.isEmpty || _busy
                ? null
                : () => setState(() {
                    _reviewed = List.unmodifiable(
                      _events.where((event) => _selected.contains(_key(event))),
                    );
                    _review = true;
                  }),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'old', label: Text('Old Events')),
              ButtonSegment(value: 'repeated', label: Text('Repeated Events')),
            ],
            selected: {_filter},
            onSelectionChanged: (value) =>
                setState(() => _filter = value.first),
          ),
          const SizedBox(height: TidySpacing.md),
          if (_error != null) _message(_error!, isError: true),
          if (_completed != null) _message(_completed!),
          if (_busy && _events.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (shown.isEmpty)
            _emptyState()
          else
            for (final event in shown) ...[
              _CalendarEventTile(
                event: event,
                selected: _selected.contains(_key(event)),
                onTap: () => setState(() {
                  final key = _key(event);
                  if (!_selected.add(key)) _selected.remove(key);
                }),
              ),
              const SizedBox(height: TidySpacing.sm),
            ],
          const SizedBox(height: TidySpacing.sm),
          const Text(
            'Only the reviewed occurrence is removed. Recurring series are not removed as a whole.',
          ),
        ],
      ),
    );
  }

  Widget _accessPage() => BonusPageFrame(
    title: _status == 'denied' || _status == 'restricted'
        ? 'Calendar Access Is Off'
        : 'A lighter calendar.',
    subtitle: _status == 'denied' || _status == 'restricted'
        ? 'Allow full Calendar access in Settings to review event occurrences.'
        : 'Allow Calendar access to review old or repeated events. Access is requested only when you choose to continue.',
    backLabel: 'Optional Features',
    footer: TextButton(
      onPressed: () => Navigator.of(context).maybePop(),
      child: const Text('Not Now'),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.calendar_month_outlined, size: 76),
        if (_error != null) _message(_error!, isError: true),
        const Text(
          'You review every event before removal. Other Tidy features remain available.',
        ),
        const SizedBox(height: TidySpacing.md),
        if (_status == 'loading' || _busy)
          const Center(child: CircularProgressIndicator())
        else if (_status == 'denied' || _status == 'restricted')
          TidyActionButton(
            label: 'Open Settings',
            onPressed: () async {
              final opened = await _service.openCalendarSettings();
              if (!opened && mounted) {
                setState(() => _error = 'Settings could not be opened.');
              }
            },
          )
        else
          TidyActionButton(
            label: 'Allow Calendar Access',
            onPressed: _requestAccess,
          ),
      ],
    ),
  );

  Widget _reviewPage() => BonusPageFrame(
    title: 'Review Events',
    subtitle:
        '${_reviewed.length} event${_reviewed.length == 1 ? '' : 's'} selected. Check each one before continuing.',
    backLabel: 'Calendar',
    onBack: () => setState(() {
      _review = false;
      _reviewed = [];
    }),
    footer: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TidyActionButton(
          label: 'Continue to Confirmation',
          onPressed: _busy ? null : _confirmDelete,
          style: TidyActionStyle.destructive,
        ),
        TextButton(
          onPressed: () => setState(() {
            _review = false;
            _reviewed = [];
          }),
          child: const Text('Cancel'),
        ),
      ],
    ),
    child: Column(
      children: [
        for (final event in _reviewed) ...[
          _CalendarEventTile(
            event: event,
            selected: false,
            onTap: null,
            review: true,
          ),
          const SizedBox(height: TidySpacing.sm),
        ],
        const SizedBox(height: TidySpacing.md),
        const Text('Removing events cannot be undone in Tidy.'),
        if (_error != null) _message(_error!, isError: true),
      ],
    ),
  );

  Widget _emptyState() => Padding(
    padding: const EdgeInsets.symmetric(vertical: TidySpacing.xl),
    child: Column(
      children: [
        const Icon(Icons.event_available_outlined, size: 52),
        const SizedBox(height: TidySpacing.sm),
        Text(
          _filter == 'old'
              ? 'No old event occurrences'
              : 'No repeated event occurrences',
        ),
        const SizedBox(height: TidySpacing.xs),
        const Text(
          'No matching events from about the last four years were found in the calendars you can access.',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _message(String text, {bool isError = false}) => Padding(
    padding: const EdgeInsets.only(bottom: TidySpacing.md),
    child: Text(
      text,
      style: TextStyle(
        color: isError ? Theme.of(context).colorScheme.error : null,
      ),
    ),
  );

  String _key(CalendarEventRecord event) =>
      '${event.id}:${event.start.millisecondsSinceEpoch}';
}

class _CalendarEventTile extends StatelessWidget {
  const _CalendarEventTile({
    required this.event,
    required this.selected,
    required this.onTap,
    this.review = false,
  });

  final CalendarEventRecord event;
  final bool selected;
  final VoidCallback? onTap;
  final bool review;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      leading: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: SizedBox(
          width: 48,
          height: 58,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_month(event.start)),
              Text(
                '${event.start.day}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
      title: Text(event.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${_date(event.start)} · ${event.calendar}${review ? '\nOnly this occurrence' : ''}',
      ),
      isThreeLine: review,
      trailing: review
          ? null
          : Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked),
    ),
  );

  static String _month(DateTime date) => const [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ][date.month - 1];
  static String _date(DateTime date) =>
      '${_month(date)} ${date.day}, ${date.year}';
}

class _CalendarConfirmation extends StatelessWidget {
  const _CalendarConfirmation({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(TidySpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.delete_outline, size: 44),
          const SizedBox(height: TidySpacing.md),
          Text(
            'Delete selected events?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: TidySpacing.sm),
          Text(
            '$count selected ${count == 1 ? 'event occurrence will' : 'event occurrences will'} be removed. Only the reviewed occurrences are affected.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TidySpacing.lg),
          TidyActionButton(
            label: 'Delete $count ${count == 1 ? 'Event' : 'Events'}',
            style: TidyActionStyle.destructive,
            onPressed: () => Navigator.pop(context, true),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    ),
  );
}
