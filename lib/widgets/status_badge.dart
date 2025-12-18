import 'package:flutter/material.dart';
import '../utils/constants.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final Color? color;
  final bool withIcon;

  const StatusBadge({
    Key? key,
    required this.status,
    this.color,
    this.withIcon = true,
  }) : super(key: key);

  Color _getStatusColor() {
    if (color != null) return color!;

    String statusLower = status.toLowerCase();
    
    if (statusLower.contains('normal') || 
        statusLower.contains('optimal') || 
        statusLower.contains('bon')) {
      return AppColors.success;
    } else if (statusLower.contains('attention') || 
               statusLower.contains('élevé') || 
               statusLower.contains('moyen')) {
      return AppColors.warning;
    } else {
      return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor = _getStatusColor();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (withIcon) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}