import 'package:flutter/material.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/models/ai_model.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/models/ai_tier.dart';

class ModelSelectionTile extends StatelessWidget {
  final AIModel model;
  final bool isSelected;
  final VoidCallback onTap;

  const ModelSelectionTile({
    super.key,
    required this.model,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokensStr = model.contextTokens != null 
        ? (model.contextTokens! >= 1000000 
            ? '${(model.contextTokens! / 1000000).toStringAsFixed(1)}M' 
            : (model.contextTokens! >= 1000 
                ? '${(model.contextTokens! / 1000).toStringAsFixed(0)}K' 
                : '${model.contextTokens}'))
        : '---';

    final inputPrice = model.inputPrice != null ? '\$${model.inputPrice!.toStringAsFixed(2)}' : '0.00';
    final outputPrice = model.outputPrice != null ? '\$${model.outputPrice!.toStringAsFixed(2)}' : '0.00';
    final costStr = model.tier == AITier.free ? 'Free' : 'In: $inputPrice | Out: $outputPrice / 1M';

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withValues(alpha: 0.05) : null,
          border: Border(left: BorderSide(color: isSelected ? Colors.blue : Colors.transparent, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    model.name, 
                    style: TextStyle(
                      fontSize: 14, 
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.blue.shade800 : Colors.black87,
                    )
                  ),
                ),
                if (isSelected) const Icon(Icons.check_circle, size: 14, color: Colors.blue),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  costStr, 
                  style: TextStyle(
                    fontSize: 10, 
                    color: model.tier == AITier.free ? Colors.green : Colors.orange.shade800,
                    fontWeight: FontWeight.w600,
                  )
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$tokensStr ctx',
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 6),
                _CapabilityIcon(icon: Icons.visibility_outlined, active: model.hasVision),
                _CapabilityIcon(icon: Icons.build_outlined, active: model.hasTools),
                _CapabilityIcon(icon: Icons.psychology_outlined, active: model.hasReasoning),
                const SizedBox(width: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CapabilityIcon extends StatelessWidget {
  final IconData icon;
  final bool active;

  const _CapabilityIcon({required this.icon, required this.active});

  @override
  Widget build(BuildContext context) {
    if (!active) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, size: 12, color: Colors.blue),
    );
  }
}
