import 'package:flutter/material.dart';
import '../../../core/design_system/crm_design_system.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  void _showDocumentList(String category, List<Map<String, String>> items) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: CRMColors.cardBgOf(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(CRMBorderRadius.m)),
        ),
        padding: const EdgeInsets.all(CRMSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  category,
                  style: CRMTypography.sectionTitle.copyWith(
                    color: CRMColors.textOf(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: CRMSpacing.s),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: CRMSpacing.s),
              child: Container(
                decoration: BoxDecoration(
                  color: CRMColors.backgroundOf(context),
                  borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                  border: Border.all(color: CRMColors.border),
                ),
                child: ListTile(
                  leading: Icon(
                    category.contains('Agent') ? Icons.person_outline_rounded : Icons.insert_drive_file_outlined,
                    color: CRMColors.primary,
                  ),
                  title: Text(item['name'] ?? '', style: CRMTypography.body.copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Text(item['subtitle'] ?? '', style: CRMTypography.caption),
                  trailing: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(category.contains('Agent') 
                              ? "Calling ${item['name']}..." 
                              : "Downloading ${item['name']}..."),
                          backgroundColor: CRMColors.success,
                        ),
                      );
                    },
                    child: Text(
                      category.contains('Agent') ? 'Call' : 'Download',
                      style: TextStyle(color: CRMColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            )),
            const SizedBox(height: CRMSpacing.m),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 700;

    final List<Map<String, dynamic>> categories = [
      {
        'title': 'Rental Document',
        'icon': Icons.folder_shared_rounded,
        'color': CRMColors.info,
        'description': 'Access lease agreements, tenant verification forms, rent receipts, and inventory checklists.',
        'items': [
          {'name': 'Residential Lease Agreement', 'subtitle': 'PDF • 1.2 MB'},
          {'name': 'Commercial Tenancy Contract', 'subtitle': 'Word • 540 KB'},
          {'name': 'Tenant Information Form', 'subtitle': 'PDF • 320 KB'},
          {'name': 'Rent Receipt Template', 'subtitle': 'Excel • 180 KB'},
        ]
      },
      {
        'title': 'Sale Document',
        'icon': Icons.gavel_rounded,
        'color': CRMColors.warning,
        'description': 'Access agreement to sell drafts, absolute sale deeds, allotment letters, and possession letters.',
        'items': [
          {'name': 'Agreement to Sell Draft', 'subtitle': 'Word • 850 KB'},
          {'name': 'Absolute Sale Deed Template', 'subtitle': 'PDF • 2.1 MB'},
          {'name': 'No-Objection Certificate (NOC) Form', 'subtitle': 'PDF • 430 KB'},
          {'name': 'Possession Letter Draft', 'subtitle': 'Word • 210 KB'},
        ]
      },
      {
        'title': 'Service Agents',
        'icon': Icons.handshake_rounded,
        'color': CRMColors.success,
        'description': 'Find local legal advisors, property inspectors, stamp duty agents, and valuation services.',
        'items': [
          {'name': 'Karan Patel (Legal Advisor)', 'subtitle': 'Legal Consultant • +91 98765 43210'},
          {'name': 'Valuations & Co', 'subtitle': 'Property Valuators • +91 98765 43211'},
          {'name': 'Pest Control Services', 'subtitle': 'Property Inspectors • +91 98765 43212'},
          {'name': 'HDFC Bank Home Loans', 'subtitle': 'Loan Agent • +91 98765 43213'},
        ]
      }
    ];

    return Scaffold(
      backgroundColor: CRMColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(CRMSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(CRMSpacing.s),
                  decoration: BoxDecoration(
                    color: CRMColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                  ),
                  child: Icon(Icons.library_books_rounded, color: CRMColors.primary, size: 28),
                ),
                const SizedBox(width: CRMSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Library',
                        style: CRMTypography.pageTitle.copyWith(color: CRMColors.text),
                      ),
                      Text(
                        'Access agency document templates, forms, and service directory',
                        style: CRMTypography.body.copyWith(color: CRMColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: CRMSpacing.xl),

            // Content Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isMobile ? 1 : 3,
                crossAxisSpacing: CRMSpacing.l,
                mainAxisSpacing: CRMSpacing.l,
                childAspectRatio: isMobile ? 1.4 : 0.85,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final IconData icon = cat['icon'];
                final Color color = cat['color'];
                final List<Map<String, String>> items = List<Map<String, String>>.from(cat['items']);

                return CRMCard(
                  padding: const EdgeInsets.all(CRMSpacing.l),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(CRMSpacing.m),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                        ),
                        child: Icon(icon, color: color, size: 32),
                      ),
                      const SizedBox(height: CRMSpacing.l),
                      Text(
                        cat['title'],
                        style: CRMTypography.cardTitle.copyWith(color: CRMColors.text, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: CRMSpacing.s),
                      Expanded(
                        child: Text(
                          cat['description'],
                          style: CRMTypography.body.copyWith(color: CRMColors.textSecondary),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: CRMSpacing.m),
                      SizedBox(
                        width: double.infinity,
                        child: CRMButton(
                          label: 'View Options',
                          variant: CRMButtonVariant.outline,
                          onPressed: () => _showDocumentList(cat['title'], items),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
