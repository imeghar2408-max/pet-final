import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petcare_core/petcare_core.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/petcare_card.dart';
import '../../widgets/status_badge.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  List<Complaint> _reports = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await UserApiService().getMyComplaints();
      if (mounted) {
        setState(() {
          _reports = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(PetColors.primary),
        ),
      );
    }

    if (_error != null) {
      return EmptyStateView(
        icon: Icons.error_outline_rounded,
        iconColor: PetColors.error,
        title: 'Could not load reports',
        description: _error!,
        buttonLabel: 'Try Again',
        onButtonPressed: _loadReports,
      );
    }

    if (_reports.isEmpty) {
      return const EmptyStateView(
        icon: Icons.verified_user_outlined,
        title: 'No reports filed',
        description: 'You have not submitted any complaints or issue tickets. Everything looks calm!',
      );
    }

    return RefreshIndicator(
      color: PetColors.primary,
      onRefresh: _loadReports,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: _reports.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final r = _reports[i];
          return PetCareCard(
            hasShadow: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        r.subject,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: PetColors.dark,
                        ),
                      ),
                    ),
                    StatusBadge.complaint(r.status),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      r.category.label,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: PetColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•  ${DateFormat('MMM d, yyyy • h:mm a').format(r.createdAt)}',
                      style: const TextStyle(fontSize: 11.5, color: PetColors.darkLight),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  r.description,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: PetColors.darkMuted,
                    height: 1.4,
                  ),
                ),
                if (r.adminNote != null && r.adminNote!.isNotEmpty) ...[
                  const Divider(height: 22),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: PetColors.sageLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: PetColors.sage.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.support_agent_rounded, size: 16, color: PetColors.sage),
                            SizedBox(width: 6),
                            Text(
                              'Operations Support Response',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: PetColors.sage,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          r.adminNote!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: PetColors.dark,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
