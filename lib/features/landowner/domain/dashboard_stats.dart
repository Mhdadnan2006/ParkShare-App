class DashboardStats {
  final double totalRevenue;
  final int bookingsCount;
  final String peakMonth;
  final String mostBooked;

  DashboardStats({
    required this.totalRevenue,
    required this.bookingsCount,
    required this.peakMonth,
    required this.mostBooked,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalRevenue: double.tryParse(json['total_revenue']?.toString() ?? '0') ?? 0.0,
      bookingsCount: json['bookings_count'] ?? 0,
      peakMonth: json['peak_month'] ?? 'N/A',
      mostBooked: json['most_booked'] ?? 'N/A',
    );
  }
}
