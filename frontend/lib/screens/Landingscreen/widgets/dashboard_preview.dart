import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'card_3d_effect.dart';

class DashboardPreview extends StatelessWidget {
  final Color primaryColor;
  final Color secondaryColor;
  
  const DashboardPreview({
    Key? key,
    required this.primaryColor,
    required this.secondaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card3DEffect(
      depth: 0.008,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(
                Colors.black.r.toInt(),
                Colors.black.g.toInt(),
                Colors.black.b.toInt(),
                0.1,
              ),
              blurRadius: 30,
              spreadRadius: -5,
              offset: const Offset(0, 15),
            ),
            BoxShadow(
              color: Color.fromRGBO(
                primaryColor.r.toInt(),
                primaryColor.g.toInt(),
                primaryColor.b.toInt(),
                0.08,
              ),
              blurRadius: 60,
              spreadRadius: -10,
              offset: const Offset(0, 25),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dashboard Header
              _buildDashboardHeader(),
              
              // Dashboard Content
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDashboardTitle(),
                    const SizedBox(height: 24),
                    _buildStatCards(),
                    const SizedBox(height: 32),
                    _buildTimeTrackingSection(),
                    const SizedBox(height: 32),
                    _buildRecentProjectsSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 800.ms, delay: 200.ms).scale(
      begin: const Offset(0.97, 0.97),
      end: const Offset(1, 1),
      duration: 800.ms,
      curve: Curves.easeOutQuint,
    );
  }

  Widget _buildDashboardHeader() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(
              Colors.black.r.toInt(),
              Colors.black.g.toInt(),
              Colors.black.b.toInt(),
              0.05,
            ),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(
            'Dashboard',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.fromRGBO(
                primaryColor.r.toInt(),
                primaryColor.g.toInt(),
                primaryColor.b.toInt(),
                0.1,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.notifications_none_rounded,
                color: primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEEEEEE),
            ),
            child: const Center(
              child: Icon(
                Icons.person_outline_rounded,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDashboardTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good morning, Alex',
          style: GoogleFonts.manrope(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Here\'s your activity summary',
          style: GoogleFonts.inter(
            color: Colors.black54,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatCards() {
    return Row(
      children: [
        _buildStatCard(
          title: 'Hours Tracked',
          value: '32h 40m',
          trend: '+12.6%',
          trendUp: true,
          icon: Icons.access_time,
          color: primaryColor,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          title: 'Billable Amount',
          value: '\$3,240', // Fixed: Escaped the dollar sign with backslash
          trend: '+8.1%',
          trendUp: true,
          icon: Icons.attach_money,
          color: Colors.green.shade700,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          title: 'Pending Tasks',
          value: '12',
          trend: '-2',
          trendUp: false,
          icon: Icons.check_circle_outline,
          color: secondaryColor,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String trend,
    required bool trendUp,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade100,
          ),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(
                color.r.toInt(),
                color.g.toInt(),
                color.b.toInt(),
                0.06,
              ),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(
                      color.r.toInt(),
                      color.g.toInt(),
                      color.b.toInt(),
                      0.1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      trendUp ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 12,
                      color: trendUp ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trend,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: trendUp ? Colors.green.shade700 : Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeTrackingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Today\'s Activity',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Start Timer',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTimeEntryCard(
          projectName: 'Website Redesign',
          clientName: 'Acme Corp',
          duration: '2h 15m',
          startTime: '9:30 AM',
          endTime: '11:45 AM',
          color: Colors.blue.shade700,
        ),
        const SizedBox(height: 12),
        _buildTimeEntryCard(
          projectName: 'Mobile App Development',
          clientName: 'TechStart Inc',
          duration: '3h 45m',
          startTime: '1:15 PM',
          endTime: '5:00 PM',
          color: Colors.purple.shade700,
        ),
      ],
    );
  }

  Widget _buildTimeEntryCard({
    required String projectName,
    required String clientName,
    required String duration,
    required String startTime,
    required String endTime,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(
              Colors.black.r.toInt(),
              Colors.black.g.toInt(),
              Colors.black.b.toInt(),
              0.03,
            ),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  projectName,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  clientName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                duration,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$startTime - $endTime',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentProjectsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Projects',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildProjectCard(
              name: 'Website Redesign',
              progress: 0.75,
              tasksCompleted: '15/20',
              daysLeft: 3,
              color: Colors.blue.shade700,
            ),
            const SizedBox(width: 16),
            _buildProjectCard(
              name: 'Mobile App Development',
              progress: 0.45,
              tasksCompleted: '9/20',
              daysLeft: 7,
              color: Colors.purple.shade700,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProjectCard({
    required String name,
    required double progress,
    required String tasksCompleted,
    required int daysLeft,
    required Color color,
  }) {
    return Builder(
      builder: (context) => Expanded( // Fixed: Added Builder to get access to context
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.shade100,
            ),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(
                  color.r.toInt(),
                  color.g.toInt(),
                  color.b.toInt(),
                  0.06,
                ),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Row(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.15 * progress,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  Text(
                    tasksCompleted,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.black54),
                  const SizedBox(width: 6),
                  Text(
                    '$daysLeft days left',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
