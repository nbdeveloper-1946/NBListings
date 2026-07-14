import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'skeletons.dart';
import 'empty_state.dart';

class CRMDataTable extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final bool isLoading;
  final String emptyTitle;
  final String emptyDescription;
  final IconData emptyIcon;

  const CRMDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.isLoading = false,
    this.emptyTitle = 'No entries found',
    this.emptyDescription = 'Try adjusting your search filters or add a new record.',
    this.emptyIcon = Icons.folder_open_rounded,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.all(CRMSpacing.m),
        child: Column(
          children: List.generate(5, (index) => const Padding(
            padding: EdgeInsets.only(bottom: CRMSpacing.s),
            child: CRMSkeleton(height: 48),
          )),
        ),
      );
    }

    if (rows.isEmpty) {
      return CRMEmptyState(
        title: emptyTitle,
        description: emptyDescription,
        icon: emptyIcon,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: CRMColors.cardBg,
        borderRadius: BorderRadius.circular(CRMBorderRadius.m),
        border: Border.all(color: CRMColors.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(CRMColors.sidebarBg),
          headingTextStyle: CRMTypography.captionBold.copyWith(color: CRMColors.textSecondary),
          dataTextStyle: CRMTypography.body.copyWith(color: CRMColors.text),
          dividerThickness: 1.0,
          horizontalMargin: CRMSpacing.m,
          columnSpacing: CRMSpacing.l,
          columns: columns,
          rows: rows,
        ),
      ),
    );
  }
}
