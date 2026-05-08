import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> court;
  final String sportIcon;

  const BookingScreen({
    super.key,
    required this.court,
    required this.sportIcon,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  DateTime _selectedDate = DateTime.now();
  int _selectedSlot = -1;
  int _selectedDuration = 1;

  final List<Map<String, dynamic>> _timeSlots = [
    {'time': '6:00 AM', 'period': 'Morning', 'available': true},
    {'time': '7:00 AM', 'period': 'Morning', 'available': true},
    {'time': '8:00 AM', 'period': 'Morning', 'available': false},
    {'time': '9:00 AM', 'period': 'Morning', 'available': true},
    {'time': '10:00 AM', 'period': 'Morning', 'available': true},
    {'time': '12:00 PM', 'period': 'Afternoon', 'available': true},
    {'time': '1:00 PM', 'period': 'Afternoon', 'available': false},
    {'time': '2:00 PM', 'period': 'Afternoon', 'available': true},
    {'time': '3:00 PM', 'period': 'Afternoon', 'available': true},
    {'time': '4:00 PM', 'period': 'Afternoon', 'available': false},
    {'time': '5:00 PM', 'period': 'Evening', 'available': true},
    {'time': '6:00 PM', 'period': 'Evening', 'available': true},
    {'time': '7:00 PM', 'period': 'Evening', 'available': true},
    {'time': '8:00 PM', 'period': 'Evening', 'available': false},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<DateTime> _getNext7Days() {
    return List.generate(7, (i) => DateTime.now().add(Duration(days: i)));
  }

  String _formatDay(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  String _formatMonth(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[date.month - 1];
  }

  List<Map<String, dynamic>> _getSlotsByPeriod(String period) {
    return _timeSlots.where((s) => s['period'] == period).toList();
  }

  int _getPricePerHour() {
    final priceStr = widget.court['price'] as String;
    final cleaned = priceStr
        .replaceAll('LKR ', '')
        .replaceAll('/hr', '')
        .replaceAll(',', '');
    return int.tryParse(cleaned) ?? 0;
  }

  int _getTotalPrice() {
    return _getPricePerHour() * _selectedDuration;
  }

  String _formatPrice(int price) {
    return 'LKR ${price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
    )}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
          ),
        ),
        title: const Text('Book Court',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildCourtCard(),
                const SizedBox(height: 28),
                _buildDatePicker(),
                const SizedBox(height: 28),
                _buildTimeSlotsSection('Morning', '🌅'),
                const SizedBox(height: 20),
                _buildTimeSlotsSection('Afternoon', '☀️'),
                const SizedBox(height: 20),
                _buildTimeSlotsSection('Evening', '🌙'),
                const SizedBox(height: 28),
                if (_selectedSlot != -1) ...[
                  _buildDurationPicker(),
                  const SizedBox(height: 28),
                ],
                _buildConfirmButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourtCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(widget.sportIcon,
                  style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.court['name'],
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17)),
                const SizedBox(height: 4),
                Text(widget.court['sport'],
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(widget.court['price'],
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              const SizedBox(height: 4),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('per hour',
                    style: TextStyle(color: Colors.white, fontSize: 10)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    final days = _getNext7Days();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Date',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 72,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            itemBuilder: (context, i) {
              final day = days[i];
              final selected = day.day == _selectedDate.day &&
                  day.month == _selectedDate.month;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedDate = day;
                  _selectedSlot = -1;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(right: 10),
                  width: 52,
                  decoration: BoxDecoration(
                    color: selected ? Colors.black : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_formatDay(day),
                          style: TextStyle(
                              fontSize: 11,
                              color: selected
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.grey,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text('${day.day}',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color:
                              selected ? Colors.white : Colors.black)),
                      const SizedBox(height: 2),
                      Text(_formatMonth(day),
                          style: TextStyle(
                              fontSize: 10,
                              color: selected
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.grey)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotsSection(String period, String emoji) {
    final slots = _getSlotsByPeriod(period);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(period,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: slots.length,
          itemBuilder: (context, i) {
            final globalIndex = _timeSlots.indexOf(slots[i]);
            final available = slots[i]['available'] as bool;
            final selected = globalIndex == _selectedSlot;
            return GestureDetector(
              onTap: available
                  ? () => setState(() {
                _selectedSlot = globalIndex;
                _selectedDuration = 1;
              })
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: !available
                      ? const Color(0xFFF5F5F5)
                      : selected
                      ? Colors.black
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? Colors.black : Colors.transparent,
                  ),
                ),
                child: Center(
                  child: Text(
                    slots[i]['time'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: !available
                          ? Colors.grey[400]
                          : selected
                          ? Colors.white
                          : Colors.black,
                      decoration: !available
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDurationPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Duration',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [1, 2, 3].map((hrs) {
            final selected = _selectedDuration == hrs;
            return GestureDetector(
              onTap: () => setState(() => _selectedDuration = hrs),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? Colors.black : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$hrs hr${hrs > 1 ? 's' : ''}',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: selected ? Colors.white : Colors.black),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_getPricePerHour()} × $_selectedDuration hr${_selectedDuration > 1 ? 's' : ''}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
              Text(_formatPrice(_getTotalPrice()),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    final canBook = _selectedSlot != -1;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: canBook
            ? () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (context) => _buildConfirmSheet(),
          );
        }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          disabledBackgroundColor: const Color(0xFFF5F5F5),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.grey,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              canBook ? 'Confirm Booking' : 'Select a time slot',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (canBook) ...[
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 18),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmSheet() {
    final slot = _timeSlots[_selectedSlot];
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Confirm Booking',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildConfirmRow('Court', widget.court['name']),
          _buildConfirmRow('Date',
              '${_selectedDate.day} ${_formatMonth(_selectedDate)} ${_selectedDate.year}'),
          _buildConfirmRow('Time', slot['time']),
          _buildConfirmRow('Duration',
              '$_selectedDuration hr${_selectedDuration > 1 ? 's' : ''}'),
          _buildConfirmRow('Total', _formatPrice(_getTotalPrice())),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () async {
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  await FirebaseFirestore.instance
                      .collection('bookings')
                      .add({
                    'userId': user?.uid,
                    'userName': user?.displayName,
                    'courtName': widget.court['name'],
                    'sport': widget.court['sport'],
                    'price': _formatPrice(_getTotalPrice()),
                    'pricePerHour': widget.court['price'],
                    'duration': _selectedDuration,
                    'date':
                    '${_selectedDate.day} ${_formatMonth(_selectedDate)} ${_selectedDate.year}',
                    'time': slot['time'],
                    'bookedAt': FieldValue.serverTimestamp(),
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 10),
                            Text('Booking confirmed!'),
                          ],
                        ),
                        backgroundColor: Colors.black,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Confirm',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}

