import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/data_table.dart';
import '../models/property_model.dart';
import '../services/properties_service.dart';

class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
  final PropertiesService _propertiesService = PropertiesService();
  bool _isLoading = true;
  List<PropertyModel> _binProperties = [];

  @override
  void initState() {
    super.initState();
    _fetchBinProperties();
  }

  Future<void> _fetchBinProperties() async {
    setState(() => _isLoading = true);
    try {
      final res = await _propertiesService.getBinProperties();
      final data = res['data'] as Map<String, dynamic>? ?? {};
      final list = data['properties'] as List? ?? [];
      setState(() {
        _binProperties = list.map((p) => PropertyModel.fromJson(p)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load bin properties: $e'), backgroundColor: CRMColors.danger),
        );
      }
    }
  }

  Future<void> _restoreProperty(String id) async {
    try {
      await _propertiesService.restoreProperty(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property restored successfully'), backgroundColor: CRMColors.success),
      );
      _fetchBinProperties();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to restore property: $e'), backgroundColor: CRMColors.danger),
      );
    }
  }

  Future<void> _permanentDelete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permanently Delete Property'),
        content: const Text('Are you sure? This action cannot be undone and will erase this property forever.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete Permanently', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _propertiesService.permanentDeleteProperty(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property permanently deleted'), backgroundColor: CRMColors.success),
      );
      _fetchBinProperties();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete property: $e'), backgroundColor: CRMColors.danger),
      );
    }
  }

  Future<void> _emptyBin() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Empty Recycle Bin'),
        content: const Text('Are you sure you want to permanently erase ALL deleted properties in the bin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Empty Bin', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _propertiesService.emptyBin();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recycle bin emptied'), backgroundColor: CRMColors.success),
      );
      _fetchBinProperties();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to empty bin: $e'), backgroundColor: CRMColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(CRMSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recycle Bin', style: CRMTypography.body.copyWith(color: CRMColors.textSecondary)),
                    Text(
                      'Deleted Properties',
                      style: CRMTypography.pageTitle.copyWith(
                        color: CRMColors.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (_binProperties.isNotEmpty)
                  CRMButton(
                    label: 'Empty Bin',
                    variant: CRMButtonVariant.danger,
                    prefixIcon: Icons.delete_forever_rounded,
                    onPressed: _emptyBin,
                  ),
              ],
            ),
            const SizedBox(height: CRMSpacing.l),
            CRMCard(
              child: _isLoading
                  ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                  : _binProperties.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(48.0),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.delete_sweep_outlined, size: 64, color: CRMColors.textSecondaryOf(context)),
                                const SizedBox(height: CRMSpacing.m),
                                Text(
                                  'Recycle Bin is Empty',
                                  style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context)),
                                ),
                                const SizedBox(height: CRMSpacing.xs),
                                Text(
                                  'Properties deleted from active listings will appear here before permanent deletion.',
                                  style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context)),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : CRMDataTable(
                          isLoading: false,
                          columns: const [
                            DataColumn(label: Text('Code')),
                            DataColumn(label: Text('Property Name')),
                            DataColumn(label: Text('Owner')),
                            DataColumn(label: Text('Area')),
                            DataColumn(label: Text('Price')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: _binProperties.map((p) {
                            return DataRow(
                              cells: [
                                DataCell(Text(p.propertyCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(Text(p.title)),
                                DataCell(Text(p.ownerName)),
                                DataCell(Text(p.areaName)),
                                DataCell(Text('₹${p.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600))),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.restore_rounded, color: CRMColors.success, size: 20),
                                        tooltip: 'Restore Property',
                                        onPressed: () => _restoreProperty(p.id),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: Icon(Icons.delete_forever_rounded, color: CRMColors.danger, size: 20),
                                        tooltip: 'Permanently Delete',
                                        onPressed: () => _permanentDelete(p.id),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
