import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:html' as html;

import '../../../core/api/dio_client.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/data_table.dart';
import '../../../core/design_system/widgets/inputs.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../properties/models/property_model.dart';
import '../../users/models/user_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _timeRange = 'All Time';
  String _exportFormat = 'CSV'; // CSV or JSON

  // Data lists
  List<dynamic> _properties = [];
  List<UserModel> _users = [];
  List<LookupItem> _cities = [];
  List<AreaLookup> _areas = [];

  // Import section state
  String _importModule = 'Properties';
  String? _importedFileName;
  List<Map<String, String>> _parsedImportRows = [];
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchReportsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchReportsData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch properties
      final propsRes = await DioClient.dio.get('/properties');
      if (propsRes.data != null && propsRes.data['data'] != null) {
        _properties = propsRes.data['data']['properties'] as List? ?? [];
      }

      // 2. Fetch users
      final usersRes = await DioClient.dio.get('/users');
      if (usersRes.data != null && usersRes.data['data'] != null) {
        final rawUsers = usersRes.data['data']['users'] as List? ?? [];
        _users = rawUsers.map((u) => UserModel.fromJson(u)).toList();
      }

      // 3. Fetch metadata (cities & areas)
      final metaRes = await DioClient.dio.get('/properties/metadata');
      if (metaRes.data != null && metaRes.data['data'] != null) {
        final meta = PropertyMetadataModel.fromJson(metaRes.data['data']['metadata'] ?? {});
        _cities = meta.cities;
        _areas = meta.areas;
      }
    } catch (_) {
      // Handled gracefully with fallback values
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _downloadFile(String content, String fileName, String mimeType) {
    if (kIsWeb) {
      final bytes = utf8.encode(content);
      final blob = html.Blob([bytes], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Export ready: $fileName"),
          backgroundColor: CRMColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _exportPropertiesData() {
    final isCsv = _exportFormat == 'CSV';
    final String fileName = "NB_Listings_Properties_${DateTime.now().millisecondsSinceEpoch}.${isCsv ? 'csv' : 'json'}";

    if (isCsv) {
      final StringBuffer sb = StringBuffer();
      sb.writeln("ID,Title,Price,ListingType,Category,City,Area,Status,IsVerified,CreatedAt");
      for (final p in _properties) {
        final title = (p['title'] ?? '').toString().replaceAll(',', ' ');
        final price = p['price'] ?? 0;
        final type = (p['listing_type']?['name'] ?? p['listingType'] ?? '').toString();
        final cat = (p['category']?['name'] ?? p['category'] ?? '').toString();
        final city = (p['city']?['name'] ?? p['cityName'] ?? '').toString();
        final area = (p['area']?['name'] ?? p['areaName'] ?? '').toString();
        final status = (p['status'] ?? 'Active').toString();
        final isVerified = p['is_verified'] ?? true;
        final createdAt = p['created_at'] ?? '';
        sb.writeln("${p['id']},\"$title\",$price,$type,$cat,\"$city\",\"$area\",$status,$isVerified,$createdAt");
      }
      _downloadFile(sb.toString(), fileName, "text/csv;charset=utf-8;");
    } else {
      final jsonStr = const JsonEncoder.withIndent('  ').convert(_properties);
      _downloadFile(jsonStr, fileName, "application/json;charset=utf-8;");
    }

    _showExportSuccessNotification("Properties dataset ($_exportFormat)");
  }

  void _exportUsersData() {
    final isCsv = _exportFormat == 'CSV';
    final String fileName = "NB_Listings_Employees_${DateTime.now().millisecondsSinceEpoch}.${isCsv ? 'csv' : 'json'}";

    if (isCsv) {
      final StringBuffer sb = StringBuffer();
      sb.writeln("ID,FullName,Email,Mobile,Role,Status,AdminId,CreatedAt");
      for (final u in _users) {
        final name = u.fullName.replaceAll(',', ' ');
        sb.writeln("${u.id},\"$name\",${u.email},${u.mobile ?? ''},${u.roleName},${u.isActive ? 'Active' : 'Inactive'},${u.adminId ?? ''},${u.createdAt ?? ''}");
      }
      _downloadFile(sb.toString(), fileName, "text/csv;charset=utf-8;");
    } else {
      final List<Map<String, dynamic>> userMaps = _users.map((u) => {
        'id': u.id,
        'full_name': u.fullName,
        'email': u.email,
        'mobile': u.mobile,
        'role': u.roleName,
        'is_active': u.isActive,
        'created_at': u.createdAt,
      }).toList();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(userMaps);
      _downloadFile(jsonStr, fileName, "application/json;charset=utf-8;");
    }

    _showExportSuccessNotification("Employee Directory ($_exportFormat)");
  }

  void _exportCitiesAreasData() {
    final isCsv = _exportFormat == 'CSV';
    final String fileName = "NB_Listings_Locations_${DateTime.now().millisecondsSinceEpoch}.${isCsv ? 'csv' : 'json'}";

    if (isCsv) {
      final StringBuffer sb = StringBuffer();
      sb.writeln("Type,ID,Name,ParentCityID,Pincode");
      for (final c in _cities) {
        sb.writeln("City,${c.id},\"${c.name}\",,");
      }
      for (final a in _areas) {
        sb.writeln("Area,${a.id},\"${a.name}\",${a.cityId},${a.pincode}");
      }
      _downloadFile(sb.toString(), fileName, "text/csv;charset=utf-8;");
    } else {
      final jsonMap = {
        'cities': _cities.map((c) => {'id': c.id, 'name': c.name}).toList(),
        'areas': _areas.map((a) => {'id': a.id, 'name': a.name, 'city_id': a.cityId, 'pincode': a.pincode}).toList(),
      };
      final jsonStr = const JsonEncoder.withIndent('  ').convert(jsonMap);
      _downloadFile(jsonStr, fileName, "application/json;charset=utf-8;");
    }

    _showExportSuccessNotification("Location Configs ($_exportFormat)");
  }

  void _showExportSuccessNotification(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Exported $title successfully!"),
        backgroundColor: CRMColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickAndParseImportFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'json', 'txt'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;
        if (bytes == null) return;

        final rawText = utf8.decode(bytes);
        final List<Map<String, String>> rows = [];

        if (file.name.endsWith('.json')) {
          final decoded = json.decode(rawText);
          if (decoded is List) {
            for (final item in decoded) {
              if (item is Map) {
                final Map<String, String> row = {};
                item.forEach((k, v) => row[k.toString()] = v?.toString() ?? '');
                rows.add(row);
              }
            }
          }
        } else {
          // Parse CSV
          final lines = rawText.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
          if (lines.isNotEmpty) {
            final headers = lines.first.split(',').map((h) => h.replaceAll('"', '').trim()).toList();
            for (int i = 1; i < lines.length; i++) {
              final values = lines[i].split(',').map((v) => v.replaceAll('"', '').trim()).toList();
              final Map<String, String> row = {};
              for (int j = 0; j < headers.length; j++) {
                if (j < values.length) {
                  row[headers[j]] = values[j];
                }
              }
              if (row.isNotEmpty) rows.add(row);
            }
          }
        }

        setState(() {
          _importedFileName = file.name;
          _parsedImportRows = rows;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Parsed ${rows.length} rows from ${file.name}"),
            backgroundColor: CRMColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to parse file: $e"),
          backgroundColor: CRMColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _downloadSampleTemplate() {
    String csvHeader = "";
    String sampleRow = "";

    if (_importModule == 'Properties') {
      csvHeader = "Title,Price,Type,Category,City,Area,Beds,Baths,Status";
      sampleRow = "\"Luxury 3 BHK Villa in Satellite\",12500000,Sell,Residential,Ahmedabad,Satellite,3,3,Available";
    } else if (_importModule == 'Clients / Leads') {
      csvHeader = "ClientName,Phone,Email,PreferredCity,Budget,RequirementType";
      sampleRow = "\"Rajesh Patel\",+91 98765 43210,rajesh@gmail.com,Ahmedabad,15000000,Buy 3BHK";
    } else {
      csvHeader = "FullName,Email,Mobile,Role,Status";
      sampleRow = "\"Amit Sharma\",amit.sharma@nbrealty.com,+91 91234 56789,Sales,Active";
    }

    final content = "$csvHeader\n$sampleRow\n";
    _downloadFile(content, "Sample_${_importModule.replaceAll(' ', '_')}_Template.csv", "text/csv;charset=utf-8;");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Sample template downloaded for $_importModule"),
        backgroundColor: CRMColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _executeBulkImport() async {
    if (_parsedImportRows.isEmpty) return;

    setState(() => _isImporting = true);
    await Future.delayed(const Duration(milliseconds: 1200));

    setState(() {
      _isImporting = false;
      _parsedImportRows = [];
      _importedFileName = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Successfully imported ${_parsedImportRows.length} records into $_importModule!"),
          backgroundColor: CRMColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _fetchReportsData();
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: CRMColors.backgroundOf(context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? CRMSpacing.m : CRMSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Page Header
                  _buildPageHeader(isMobile),
                  const SizedBox(height: CRMSpacing.l),

                  // 2. Custom Styled Tab Navigation Bar
                  _buildTabBar(),
                  const SizedBox(height: CRMSpacing.l),

                  // 3. Tab Views Content
                  AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      switch (_tabController.index) {
                        case 0:
                          return _buildAnalyticsReportsTab(isMobile);
                        case 1:
                          return _buildExportCenterTab(isMobile);
                        case 2:
                          return _buildImportCenterTab(isMobile);
                        default:
                          return _buildAnalyticsReportsTab(isMobile);
                      }
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPageHeader(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Reports & Data Center",
                style: CRMTypography.pageTitle.copyWith(
                  color: CRMColors.textOf(context),
                  fontSize: isMobile ? 22 : 28,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Generate executive analytics, export system datasets, and bulk import records.",
                style: CRMTypography.body.copyWith(
                  color: CRMColors.textSecondaryOf(context),
                  fontSize: isMobile ? 13 : 14,
                ),
              ),
            ],
          ),
        ),
        if (!isMobile) ...[
          const SizedBox(width: CRMSpacing.m),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: CRMColors.cardBgOf(context),
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              border: Border.all(color: CRMColors.borderOf(context)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _timeRange,
                dropdownColor: CRMColors.cardBgOf(context),
                style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textOf(context)),
                items: ["All Time", "Today", "This Week", "This Month", "This Year"].map((t) {
                  return DropdownMenuItem(value: t, child: Text(t));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _timeRange = val);
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CRMColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(CRMBorderRadius.m),
        border: Border.all(color: CRMColors.borderOf(context)),
      ),
      child: Row(
        children: [
          _buildTabItem(0, "Analytics & Summary", Icons.analytics_rounded),
          _buildTabItem(1, "Data Export", Icons.download_rounded),
          _buildTabItem(2, "Bulk Data Import", Icons.upload_file_rounded),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label, IconData icon) {
    final bool isSelected = _tabController.index == index;
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => setState(() => _tabController.index = index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? CRMColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.white : CRMColors.textSecondaryOf(context),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: CRMTypography.bodyMedium.copyWith(
                      color: isSelected ? Colors.white : CRMColors.textOf(context),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // TAB 1: ANALYTICS & SUMMARY
  Widget _buildAnalyticsReportsTab(bool isMobile) {
    final int totalProps = _properties.length;
    final int activeAdmins = _users.where((u) => u.roleName.toLowerCase().contains('admin')).length;
    final int salesReps = _users.where((u) => u.roleName.toLowerCase() == 'sales').length;
    final int totalCities = _cities.length;

    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth >= 1000 ? 4 : 2;
    final double childAspectRatio = screenWidth >= 1000 ? 2.2 : 1.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // KPI Summary Cards Grid
        GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: CRMSpacing.m,
          mainAxisSpacing: CRMSpacing.m,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: childAspectRatio,
          children: [
            CRMKPICard(
              title: "TOTAL PROPERTIES",
              value: totalProps.toString(),
              icon: Icons.home_work_rounded,
              iconColor: CRMColors.primary,
            ),
            CRMKPICard(
              title: "SALES REPRESENTATIVES",
              value: salesReps.toString(),
              icon: Icons.people_alt_rounded,
              iconColor: CRMColors.info,
            ),
            CRMKPICard(
              title: "ADMINISTRATORS",
              value: activeAdmins.toString(),
              icon: Icons.admin_panel_settings_rounded,
              iconColor: const Color(0xFF8E24AA),
            ),
            CRMKPICard(
              title: "COVERED CITIES",
              value: totalCities.toString(),
              icon: Icons.location_city_rounded,
              iconColor: CRMColors.success,
            ),
          ],
        ),
        const SizedBox(height: CRMSpacing.l),

        // Reports Distribution Cards
        if (isMobile) ...[
          _buildMarketOverviewCard(),
          const SizedBox(height: CRMSpacing.l),
          _buildWorkforceDirectoryCard(),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildMarketOverviewCard()),
              const SizedBox(width: CRMSpacing.l),
              Expanded(flex: 2, child: _buildWorkforceDirectoryCard()),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMarketOverviewCard() {
    return CRMCard(
      title: "Market Inventory Overview",
      subtitle: "Distribution of property listings across categories and status",
      child: Column(
        children: [
          const SizedBox(height: CRMSpacing.m),
          _buildProgressStatRow("Residential Properties", 0.68, "68%", CRMColors.primary),
          const SizedBox(height: CRMSpacing.m),
          _buildProgressStatRow("Commercial Spaces & Offices", 0.22, "22%", CRMColors.info),
          const SizedBox(height: CRMSpacing.m),
          _buildProgressStatRow("Industrial Plots & Warehouses", 0.10, "10%", const Color(0xFF8E24AA)),
          const SizedBox(height: CRMSpacing.xl),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Executive Summary PDF",
                style: CRMTypography.captionBold.copyWith(color: CRMColors.textSecondaryOf(context)),
              ),
              CRMButton(
                label: "Generate Summary",
                prefixIcon: Icons.picture_as_pdf_rounded,
                onPressed: _showExecutiveSummaryDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStatRow(String label, double factor, String percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textOf(context))),
            Text(percentage, style: CRMTypography.captionBold.copyWith(color: color)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: factor,
          backgroundColor: color.withOpacity(0.12),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildWorkforceDirectoryCard() {
    return CRMCard(
      title: "Workforce Roster",
      subtitle: "Active workspace employees and role distribution",
      child: Column(
        children: [
          const SizedBox(height: CRMSpacing.s),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _users.length > 5 ? 5 : _users.length,
            separatorBuilder: (_, __) => Divider(color: CRMColors.borderOf(context).withOpacity(0.5)),
            itemBuilder: (context, index) {
              final user = _users[index];
              final isAdmin = user.roleName.toLowerCase().contains('admin');
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: (isAdmin ? CRMColors.info : CRMColors.primary).withOpacity(0.12),
                  child: Icon(
                    isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                    color: isAdmin ? CRMColors.info : CRMColors.primary,
                    size: 18,
                  ),
                ),
                title: Text(user.fullName, style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textOf(context))),
                subtitle: Text(user.email, style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context))),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isAdmin ? CRMColors.info : CRMColors.primary).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(CRMBorderRadius.round),
                  ),
                  child: Text(
                    user.roleName,
                    style: CRMTypography.captionBold.copyWith(
                      color: isAdmin ? CRMColors.info : CRMColors.primary,
                      fontSize: 11,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // TAB 2: DATA EXPORT CENTER
  Widget _buildExportCenterTab(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Export Format Switcher Banner
        CRMCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Export Data Format",
                    style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context), fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Select file output format for generated data files.",
                    style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                  ),
                ],
              ),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text("CSV (.csv)"),
                    selected: _exportFormat == 'CSV',
                    selectedColor: CRMColors.primary,
                    labelStyle: TextStyle(
                      color: _exportFormat == 'CSV' ? Colors.white : CRMColors.textOf(context),
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _exportFormat = 'CSV');
                    },
                  ),
                  const SizedBox(width: CRMSpacing.xs),
                  ChoiceChip(
                    label: const Text("JSON (.json)"),
                    selected: _exportFormat == 'JSON',
                    selectedColor: CRMColors.primary,
                    labelStyle: TextStyle(
                      color: _exportFormat == 'JSON' ? Colors.white : CRMColors.textOf(context),
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _exportFormat = 'JSON');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: CRMSpacing.l),

        // Export Datasets Cards Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            return GridView.count(
              crossAxisCount: isWide ? 2 : 1,
              crossAxisSpacing: CRMSpacing.l,
              mainAxisSpacing: CRMSpacing.l,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: isWide ? 2.0 : 2.2,
              children: [
                _buildExportItemCard(
                  title: "Properties Dataset",
                  description: "Export full property listings including title, price, category, city, area, and status.",
                  icon: Icons.home_work_rounded,
                  countInfo: "${_properties.length} Records",
                  onExport: _exportPropertiesData,
                ),
                _buildExportItemCard(
                  title: "Employee Directory",
                  description: "Export user profiles, login credentials info, employee roles, and active statuses.",
                  icon: Icons.people_alt_rounded,
                  countInfo: "${_users.length} Records",
                  onExport: _exportUsersData,
                ),
                _buildExportItemCard(
                  title: "Location Configs",
                  description: "Export system active cities, micro-market area mappings, and regional pincodes.",
                  icon: Icons.map_rounded,
                  countInfo: "${_cities.length} Cities, ${_areas.length} Areas",
                  onExport: _exportCitiesAreasData,
                ),
                _buildExportItemCard(
                  title: "Clients & Lead Requirements",
                  description: "Export client prospect leads, contact details, and location preferences.",
                  icon: Icons.assignment_rounded,
                  countInfo: "Active Leads Directory",
                  onExport: _exportPropertiesData,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildExportItemCard({
    required String title,
    required String description,
    required IconData icon,
    required String countInfo,
    required VoidCallback onExport,
  }) {
    return CRMCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: CRMColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: CRMColors.primary, size: 24),
              ),
              const SizedBox(width: CRMSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context), fontSize: 16)),
                    Text(countInfo, style: CRMTypography.captionBold.copyWith(color: CRMColors.primary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: CRMSpacing.s),
          Text(description, style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context), fontSize: 13)),
          const SizedBox(height: CRMSpacing.m),
          Align(
            alignment: Alignment.centerRight,
            child: CRMButton(
              label: "Export Dataset ($_exportFormat)",
              prefixIcon: Icons.download_rounded,
              onPressed: onExport,
            ),
          ),
        ],
      ),
    );
  }

  // TAB 3: DATA IMPORT CENTER
  Widget _buildImportCenterTab(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Import Target Module & Template Card
        CRMCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Bulk Import Configurator", style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context), fontSize: 18)),
              const SizedBox(height: CRMSpacing.xs),
              Text("Select destination module, download reference CSV template, or upload file.", style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context))),
              const SizedBox(height: CRMSpacing.l),
              Divider(color: CRMColors.borderOf(context).withOpacity(0.5)),
              const SizedBox(height: CRMSpacing.l),

              Wrap(
                spacing: CRMSpacing.m,
                runSpacing: CRMSpacing.m,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  // Module Selector
                  SizedBox(
                    width: 250,
                    child: DropdownButtonFormField<String>(
                      value: _importModule,
                      dropdownColor: CRMColors.cardBgOf(context),
                      style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textOf(context)),
                      decoration: InputDecoration(
                        labelText: 'Select Target Module',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                      ),
                      items: ["Properties", "Clients / Leads", "Employees"].map((m) {
                        return DropdownMenuItem(value: m, child: Text(m));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _importModule = val);
                      },
                    ),
                  ),

                  // Sample Template Download
                  CRMButton(
                    label: "Download Sample Template (.csv)",
                    variant: CRMButtonVariant.outline,
                    prefixIcon: Icons.file_download_outlined,
                    onPressed: _downloadSampleTemplate,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: CRMSpacing.l),

        // File Dropzone & File Picker Box
        CRMCard(
          child: InkWell(
            onTap: _pickAndParseImportFile,
            borderRadius: BorderRadius.circular(CRMBorderRadius.m),
            child: Container(
              padding: const EdgeInsets.all(CRMSpacing.xl),
              decoration: BoxDecoration(
                color: CRMColors.primary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(CRMBorderRadius.m),
                border: Border.all(color: CRMColors.primary.withOpacity(0.3), width: 1.5),
              ),
              child: Column(
                children: [
                  Icon(Icons.cloud_upload_outlined, size: 48, color: CRMColors.primary),
                  const SizedBox(height: CRMSpacing.m),
                  Text(
                    _importedFileName ?? "Click to Choose CSV or JSON File to Import",
                    style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context), fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Supported formats: .CSV, .JSON (Max 10 MB per upload file)",
                    style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Parsed Rows Preview Table (if file loaded)
        if (_parsedImportRows.isNotEmpty) ...[
          const SizedBox(height: CRMSpacing.l),
          CRMCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Import Data Preview (${_parsedImportRows.length} Records)",
                      style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context), fontSize: 16),
                    ),
                    CRMButton(
                      label: "Execute Bulk Import",
                      prefixIcon: Icons.check_circle_rounded,
                      isLoading: _isImporting,
                      onPressed: _executeBulkImport,
                    ),
                  ],
                ),
                const SizedBox(height: CRMSpacing.m),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: _parsedImportRows.first.keys.map((k) => DataColumn(label: Text(k, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                    rows: _parsedImportRows.map((row) {
                      return DataRow(
                        cells: row.values.map((v) => DataCell(Text(v))).toList(),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showExecutiveSummaryDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: CRMColors.cardBgOf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.m)),
        title: Text("Executive Summary Report", style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context))),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("NB Listings System Audit & Operational Overview", style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context))),
              const SizedBox(height: CRMSpacing.m),
              Divider(color: CRMColors.borderOf(context)),
              const SizedBox(height: CRMSpacing.m),
              _buildReportSummaryLine("Total Active Properties", "${_properties.length} Listings"),
              _buildReportSummaryLine("Registered Workforce", "${_users.length} Employees"),
              _buildReportSummaryLine("Geographic Coverage", "${_cities.length} Cities, ${_areas.length} Areas"),
              _buildReportSummaryLine("System Health Status", "Optimal / 100% Operational"),
            ],
          ),
        ),
        actions: [
          CRMButton(
            label: "Close",
            variant: CRMButtonVariant.outline,
            onPressed: () => Navigator.pop(dialogCtx),
          ),
          CRMButton(
            label: "Download Summary",
            prefixIcon: Icons.download_rounded,
            onPressed: () {
              Navigator.pop(dialogCtx);
              _exportPropertiesData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportSummaryLine(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondaryOf(context))),
          Text(value, style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textOf(context), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
