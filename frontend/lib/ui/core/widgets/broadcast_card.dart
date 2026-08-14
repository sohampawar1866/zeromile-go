// lib/ui/core/widgets/broadcast_card.dart

import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_spacing.dart';
import '../../../config/app_typography.dart';
import '../../../data/models/broadcast_message.dart';

class BroadcastCard extends StatelessWidget {
  final BroadcastMessage message;

  const BroadcastCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isCommand = message.senderRole == SenderRole.superAdmin;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: AppSpacing.edgeInsetsCard,
      decoration: BoxDecoration(
        color: isCommand ? AppColors.errorBg : AppColors.canvas,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
        border: Border.all(
          color: isCommand ? AppColors.errorBorder : AppColors.hairlineSoft,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isCommand ? Icons.campaign : Icons.chat_bubble_outline,
                    size: 15,
                    color: isCommand ? AppColors.sale : AppColors.ink,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    isCommand ? 'COMMAND ALERT' : 'TEAM NOTICE',
                    style: AppTypography.badge.copyWith(
                      color: isCommand ? AppColors.sale : AppColors.ink,
                    ),
                  ),
                ],
              ),
              Text(
                '${message.createdAt.hour}:${message.createdAt.minute.toString().padLeft(2, '0')}',
                style: AppTypography.captionXs,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message.messageText,
            style: AppTypography.bodyStrong.copyWith(
              color: isCommand ? AppColors.saleDeep : AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Origin: ${message.senderName ?? (isCommand ? "Command Control" : "Contingent Lead")}',
            style: AppTypography.captionXs,
          ),
        ],
      ),
    );
  }
}
