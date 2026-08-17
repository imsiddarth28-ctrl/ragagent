import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../../models/message_model.dart';

class SourceCard extends StatelessWidget {
  final Source source;

  const SourceCard({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(AppRadius.s),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.s),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.description_outlined, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '${source.documentName} • p.${source.page}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
