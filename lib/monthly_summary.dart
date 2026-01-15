import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MonthlySummaryScreen extends StatefulWidget {
  final String bikeId;
  final int monthlyLimit;

  const MonthlySummaryScreen({
    super.key,
    required this.bikeId,
    required this.monthlyLimit,
  });

  @override
  State<MonthlySummaryScreen> createState() => _MonthlySummaryScreenState();
}

class _MonthlySummaryScreenState extends State<MonthlySummaryScreen> {
  DateTime selectedMonth = DateTime.now();

  DateTime get monthStart =>
      DateTime(selectedMonth.year, selectedMonth.month, 1);

  DateTime get monthEnd =>
      DateTime(selectedMonth.year, selectedMonth.month + 1, 0, 23, 59, 59);

  void _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select any date in month',
    );

    if (picked != null) {
      setState(() {
        selectedMonth = DateTime(picked.year, picked.month);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthName = DateFormat('MMMM yyyy').format(selectedMonth);

    return Scaffold(
      // 🌞 AMBER APP BAR
      appBar: AppBar(
        title: const Text(
          'Monthly Summary',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📅 MONTH SELECTOR CARD
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.dividerColor),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.calendar_month_outlined,
                  color: Colors.amber,
                ),
                title: const Text(
                  'Selected Month',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(monthName),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_calendar),
                  onPressed: _pickMonth,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 📊 SUMMARY
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bikes')
                  .doc(widget.bikeId)
                  .collection('trips')
                  .where(
                    'date',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart),
                  )
                  .where(
                    'date',
                    isLessThanOrEqualTo: Timestamp.fromDate(monthEnd),
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                double totalKm = 0;
                for (var doc in snapshot.data!.docs) {
                  totalKm += (doc['distance'] as num).toDouble();
                }

                final remaining = widget.monthlyLimit - totalKm;

                final daysInMonth = DateUtils.getDaysInMonth(
                  selectedMonth.year,
                  selectedMonth.month,
                );

                final dailyAvg = daysInMonth > 0 ? totalKm / daysInMonth : 0;

                return Column(
                  children: [
                    // 🔢 STATS GRID
                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.6,
                          ),
                      children: [
                        _statCard(
                          title: 'Total Driven',
                          value: '${totalKm.toStringAsFixed(1)} km',
                          icon: Icons.speed,
                        ),
                        _statCard(
                          title: remaining >= 0 ? 'Remaining' : 'Exceeded',
                          value: '${remaining.abs().toStringAsFixed(1)} km',
                          icon: remaining >= 0
                              ? Icons.check_circle_outline
                              : Icons.warning_amber_outlined,
                          valueColor: remaining >= 0
                              ? Colors.green
                              : Colors.red,
                        ),
                        _statCard(
                          title: 'Daily Average',
                          value: '${dailyAvg.toStringAsFixed(1)} km/day',
                          icon: Icons.bar_chart_outlined,
                        ),
                        _statCard(
                          title: 'Monthly Limit',
                          value: '${widget.monthlyLimit} km',
                          icon: Icons.flag_outlined,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.amber),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
