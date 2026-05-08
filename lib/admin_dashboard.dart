import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _selectedSport = 'All';
  String _selectedStatus = 'All';
  List<QueryDocumentSnapshot> _allDocs = [];
  bool _loading = true;
  int _currentTab = 0;

  final List<String> _sports = [
    'All', 'Badminton', 'Table Tennis', 'Squash', 'Basketball'
  ];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _loading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .orderBy('bookedAt', descending: true)
          .get();
      setState(() {
        _allDocs = snapshot.docs;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _getSportIcon(String sport) {
    switch (sport) {
      case 'Badminton': return '🏸';
      case 'Table Tennis': return '🏓';
      case 'Squash': return '🎾';
      case 'Basketball': return '🏀';
      default: return '🏅';
    }
  }

  List<QueryDocumentSnapshot> get _filteredDocs {
    var docs = _allDocs;
    if (_selectedSport != 'All') {
      docs = docs.where((d) => (d.data() as Map)['sport'] == _selectedSport).toList();
    }
    if (_selectedStatus == 'Confirmed') {
      docs = docs.where((d) =>
      (d.data() as Map)['status'] == null ||
          (d.data() as Map)['status'] == 'confirmed').toList();
    } else if (_selectedStatus == 'Completed') {
      docs = docs.where((d) => (d.data() as Map)['status'] == 'completed').toList();
    }
    return docs;
  }

  int get _totalBookings => _allDocs.length;
  int get _confirmed => _allDocs.where((d) =>
  (d.data() as Map)['status'] == null ||
      (d.data() as Map)['status'] == 'confirmed').length;
  int get _completed => _allDocs.where((d) =>
  (d.data() as Map)['status'] == 'completed').length;
  int get _sportsCount => _allDocs
      .map((d) => (d.data() as Map)['sport'] as String?)
      .whereType<String>()
      .toSet()
      .length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: _currentTab == 0 ? _buildDashboard() : _buildBookingsList(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CourtBook', style: TextStyle(color: Colors.white,
              fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Admin Panel', style: TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadBookings,
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
                content: const Text('Are you sure you want to sign out?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Sign Out',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await FirebaseAuth.instance.signOut();
            }
          },
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentTab,
      onTap: (i) => setState(() => _currentTab = i),
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), label: 'Bookings'),
      ],
    );
  }

  Widget _buildDashboard() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.black));
    }
    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Overview',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildStatsGrid(),
            const SizedBox(height: 24),
            const Text('Recent Bookings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._allDocs.take(5).map((doc) =>
                _buildBookingCard(doc.data() as Map<String, dynamic>, doc.id)),
            if (_allDocs.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text('No bookings yet', style: TextStyle(color: Colors.grey)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard('Total Bookings', '$_totalBookings',
            Icons.calendar_today, Colors.black),
        _buildStatCard('Confirmed', '$_confirmed',
            Icons.check_circle_outline, Colors.green),
        _buildStatCard('Completed', '$_completed',
            Icons.done_all, Colors.blue),
        _buildStatCard('Sports Active', '$_sportsCount',
            Icons.sports, Colors.orange),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.black));
    }
    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadBookings,
            child: _filteredDocs.isEmpty
                ? const Center(child: Text('No bookings found',
                style: TextStyle(color: Colors.grey)))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredDocs.length,
              itemBuilder: (context, i) {
                final doc = _filteredDocs[i];
                return _buildBookingCard(
                    doc.data() as Map<String, dynamic>, doc.id);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filter by sport',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _sports.length,
              itemBuilder: (context, i) {
                final selected = _sports[i] == _selectedSport;
                return GestureDetector(
                  onTap: () => setState(() => _selectedSport = _sports[i]),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? Colors.black : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_sports[i],
                        style: TextStyle(
                            fontSize: 12,
                            color: selected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w500)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: ['All', 'Confirmed', 'Completed'].map((s) {
              final selected = s == _selectedStatus;
              return GestureDetector(
                onTap: () => setState(() => _selectedStatus = s),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? Colors.black : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(s,
                      style: TextStyle(
                          fontSize: 12,
                          color: selected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w500)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> data, String docId) {
    final status = data['status'] ?? 'confirmed';
    final isCompleted = status == 'completed';
    final sport = data['sport'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(_getSportIcon(sport), style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(data['userName'] ?? 'Unknown',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.blue[50] : Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isCompleted ? 'Completed' : 'Confirmed',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isCompleted ? Colors.blue[700] : Colors.green[700]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(Icons.sports_tennis, data['courtName'] ?? ''),
                const SizedBox(width: 8),
                _buildInfoChip(Icons.calendar_today, data['date'] ?? ''),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _buildInfoChip(Icons.access_time, data['time'] ?? ''),
                const SizedBox(width: 8),
                _buildInfoChip(Icons.timer_outlined,
                    '${data['duration'] ?? 1} hr${(data['duration'] ?? 1) > 1 ? 's' : ''}'),
                const SizedBox(width: 8),
                _buildInfoChip(Icons.attach_money, data['price'] ?? ''),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!isCompleted) ...[
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        await FirebaseFirestore.instance
                            .collection('bookings')
                            .doc(docId)
                            .update({'status': 'completed'});
                        _loadBookings();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text('Mark Complete',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          title: const Text('Delete Booking',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          content: const Text('Are you sure?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel',
                                  style: TextStyle(color: Colors.grey)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete',
                                  style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await FirebaseFirestore.instance
                            .collection('bookings')
                            .doc(docId)
                            .delete();
                        _loadBookings();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text('Delete',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.red[700],
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
