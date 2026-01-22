import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Custom kalendar widget s bojama dostupnosti
/// - Zeleno: svi termini dostupni
/// - Zuto: djelomicno popunjeno (1-3 termina zauzeto)
/// - Crveno/roza: potpuno popunjeno
/// - Sivo: zatvoreno
class AvailabilityCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const AvailabilityCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<AvailabilityCalendar> createState() => _AvailabilityCalendarState();
}

class _AvailabilityCalendarState extends State<AvailabilityCalendar> {
  DateTime _currentMonth = DateTime.now();
  Map<String, DayStatus> _dayStatuses = {};
  bool _isLoading = true;

  // Hrvatski nazivi dana
  final List<String> _dayNames = ['Pon', 'Uto', 'Sri', 'Cet', 'Pet', 'Sub', 'Ned'];

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month, 1);
    _loadCalendarStatus();
  }

  Future<void> _loadCalendarStatus() async {
    setState(() => _isLoading = true);

    // Ucitaj status za trenutni mjesec + 7 dana unaprijed
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).add(const Duration(days: 7));

    final startStr =
        '${firstDay.year}-${firstDay.month.toString().padLeft(2, '0')}-${firstDay.day.toString().padLeft(2, '0')}';
    final endStr =
        '${lastDay.year}-${lastDay.month.toString().padLeft(2, '0')}-${lastDay.day.toString().padLeft(2, '0')}';

    final response = await ApiService.getCalendarStatus(startStr, endStr);

    if (response.success && response.data != null) {
      final List<dynamic> data = response.data as List<dynamic>;
      final Map<String, DayStatus> statuses = {};

      for (var item in data) {
        final date = item['date'] as String;
        final status = item['status'] as String;
        final available = item['availableSlots'] as int;
        final total = item['totalSlots'] as int;

        statuses[date] = DayStatus(
          status: status,
          availableSlots: available,
          totalSlots: total,
        );
      }

      setState(() {
        _dayStatuses = statuses;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
    _loadCalendarStatus();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
    _loadCalendarStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header s mjesecom i navigacijom
          _buildHeader(),
          const SizedBox(height: 16),

          // Nazivi dana
          _buildDayHeaders(),
          const SizedBox(height: 8),

          // Kalendar grid
          _isLoading ? _buildLoadingGrid() : _buildCalendarGrid(),

          const SizedBox(height: 16),

          // Legenda
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final canGoPrevious = _currentMonth.isAfter(DateTime(DateTime.now().year, DateTime.now().month, 1));
    // Ograniči navigaciju do prosinca 2026.
    final canGoNext = _currentMonth.isBefore(DateTime(2026, 12, 1));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: canGoPrevious ? _previousMonth : null,
          icon: Icon(
            Icons.chevron_left,
            color: canGoPrevious ? const Color(0xFF1C1917) : Colors.grey[300],
          ),
        ),
        Text(
          '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        IconButton(
          onPressed: canGoNext ? _nextMonth : null,
          icon: Icon(
            Icons.chevron_right,
            color: canGoNext ? const Color(0xFF1C1917) : Colors.grey[300],
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const names = [
      '',
      'Sijecanj',
      'Veljaca',
      'Ozujak',
      'Travanj',
      'Svibanj',
      'Lipanj',
      'Srpanj',
      'Kolovoz',
      'Rujan',
      'Listopad',
      'Studeni',
      'Prosinac'
    ];
    return names[month];
  }

  Widget _buildDayHeaders() {
    return Row(
      children: _dayNames.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLoadingGrid() {
    return SizedBox(
      height: 240,
      child: Center(
        child: CircularProgressIndicator(
          color: Colors.grey[400],
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

    // Ponedjeljak = 1, Nedjelja = 7
    int startWeekday = firstDayOfMonth.weekday;
    // Prilagodi za grid (ponedjeljak = 0)
    int leadingEmptyDays = startWeekday - 1;

    final totalDays = lastDayOfMonth.day;
    final totalCells = leadingEmptyDays + totalDays;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (rowIndex) {
        return Row(
          children: List.generate(7, (colIndex) {
            final cellIndex = rowIndex * 7 + colIndex;
            final dayNumber = cellIndex - leadingEmptyDays + 1;

            if (cellIndex < leadingEmptyDays || dayNumber > totalDays) {
              return Expanded(child: Container(height: 44));
            }

            final date = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
            return Expanded(child: _buildDayCell(date, dayNumber));
          }),
        );
      }),
    );
  }

  Widget _buildDayCell(DateTime date, int dayNumber) {
    final today = DateTime.now();
    final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
    final isPast = date.isBefore(DateTime(today.year, today.month, today.day));
    final isSelected =
        date.year == widget.selectedDate.year &&
        date.month == widget.selectedDate.month &&
        date.day == widget.selectedDate.day;

    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final status = _dayStatuses[dateStr];

    // Boje prema statusu - UVIJEK prikazuj boju dostupnosti
    Color bgColor;
    Color textColor;
    Color borderColor = Colors.transparent;
    double borderWidth = 2;

    // Provjeri je li datum izvan dozvoljenog raspona (nakon 2026)
    final isBeyond2026 = date.year > 2026;

    if (isPast) {
      bgColor = Colors.grey[100]!;
      textColor = Colors.grey[400]!;
    } else if (isBeyond2026) {
      bgColor = Colors.grey[100]!;
      textColor = Colors.grey[400]!;
    } else if (status == null) {
      // Ako nema statusa ali je u 2026, pretpostavi da je dostupno
      bgColor = const Color(0xFFD1FAE5); // Zeleno - pretpostavi dostupno
      textColor = const Color(0xFF065F46);
    } else {
      // Postavi boju prema statusu
      switch (status.status) {
        case 'available':
          bgColor = const Color(0xFFD1FAE5); // Zeleno - sve slobodno
          textColor = const Color(0xFF065F46);
          break;
        case 'limited':
          bgColor = const Color(0xFFFEF3C7); // Zuto - ograniceno
          textColor = const Color(0xFF92400E);
          break;
        case 'full':
          bgColor = const Color(0xFFFEE2E2); // Crveno - popunjeno
          textColor = const Color(0xFF991B1B);
          break;
        case 'closed':
          bgColor = Colors.grey[200]!;
          textColor = Colors.grey[500]!;
          break;
        default:
          bgColor = Colors.grey[100]!;
          textColor = Colors.grey[600]!;
      }
    }

    // Odabrani datum ima CRNU POZADINU s bijelim tekstom
    if (isSelected) {
      bgColor = const Color(0xFF1C1917);
      textColor = Colors.white;
    }

    // Danas UVIJEK ima crni obrub (čak i ako je odabran)
    if (isToday) {
      borderColor = const Color(0xFF1C1917);
      borderWidth = 3; // Deblji obrub za bolju vidljivost
    }

    // Zatvoreni dani imaju precrtani tekst
    final isClosed = status?.status == 'closed';

    // Dozvoli odabir za buduće datume u 2026 (čak i bez statusa pretpostavi dostupno)
    final canSelect = !isPast && !isBeyond2026 &&
        (status == null || (status.status != 'closed' && status.status != 'full'));

    return GestureDetector(
      onTap: canSelect ? () => widget.onDateSelected(date) : null,
      child: Container(
        height: 44,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Center(
          child: Text(
            '$dayNumber',
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
              color: textColor,
              decoration: isClosed ? TextDecoration.lineThrough : null,
              decorationColor: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(const Color(0xFFD1FAE5), 'Dostupno'),
        const SizedBox(width: 12),
        _buildLegendItem(const Color(0xFFFEF3C7), 'Ograniceno'),
        const SizedBox(width: 12),
        _buildLegendItem(const Color(0xFFFEE2E2), 'Popunjeno'),
        const SizedBox(width: 12),
        _buildLegendItem(Colors.grey[200]!, 'Zatvoreno'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class DayStatus {
  final String status;
  final int availableSlots;
  final int totalSlots;

  DayStatus({
    required this.status,
    required this.availableSlots,
    required this.totalSlots,
  });
}
