import 'package:flutter/material.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/features/budget/presentation/widgets/budget_format.dart';
import 'package:falimy/features/assets/presentation/screens/assets_home_screen.dart';

/// Home prompt / entry card for family assets.
class AddAssetInsightCard extends StatelessWidget {
  const AddAssetInsightCard({
    super.key,
    required this.itemCount,
    required this.totalValue,
  });

  final int itemCount;
  final double totalValue;

  void _open(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AssetsHomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final hasAssets = itemCount > 0;
    final title = hasAssets ? 'Family assets' : 'Add Asset';
    final buttonLabel = hasAssets ? 'View assets' : 'Add Asset';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: FalimyTheme.ink.withValues(alpha: 0.06),
                blurRadius: 14,
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
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF5B8DEF), Color(0xFFD6E4FF)],
                      ),
                    ),
                    child: const Icon(
                      Icons.account_balance_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: FalimyTheme.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: hasAssets
                    ? Text.rich(
                        TextSpan(
                          style: TextStyle(
                            color: FalimyTheme.muted.withValues(alpha: 0.95),
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            TextSpan(
                              text: BudgetFormat.money(totalValue),
                              style: const TextStyle(
                                color: FalimyTheme.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text:
                                  ' across $itemCount ${itemCount == 1 ? 'item' : 'items'}.',
                            ),
                          ],
                        ),
                      )
                    : Text.rich(
                        TextSpan(
                          style: TextStyle(
                            color: FalimyTheme.muted.withValues(alpha: 0.95),
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                          children: const [
                            TextSpan(text: 'Track '),
                            TextSpan(
                              text: 'vehicles, property, gold and deposits',
                              style: TextStyle(
                                color: FalimyTheme.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(text: ' for the whole family.'),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 36,
                child: FilledButton(
                  onPressed: () => _open(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(buttonLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
