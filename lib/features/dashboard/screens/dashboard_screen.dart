import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../properties/repository/properties_repository.dart';
import '../../properties/services/properties_service.dart';
import '../../properties/models/property_model.dart';
import '../../../core/storage/repository_coordinator.dart';
import '../../../core/storage/isar_collections.dart';
import '../../../core/storage/model_mappers.dart';
import '../../../core/design_system/widgets/drawers.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/skeletons.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/dashboard_bloc.dart';
import '../models/dashboard_summary.dart';
import '../../../core/api/dio_client.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/utils/file_downloader.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(LoadDashboard());
  }

  void _showActionSnackbar(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action functionality coming soon!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context); // Register theme dependency to rebuild on toggle
    final authState = context.watch<AuthBloc>().state;
    String userEmail = 'admin@nbdeveloper.com';
    bool isAdmin = false;
    if (authState is Authenticated) {
      userEmail = authState.user.email;
      isAdmin = authState.user.role == 'Admin' || authState.user.role == 'Super Admin';
    }

    final dateString = _getFormattedDate();
    final greeting = _getGreeting();

    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading || state is DashboardInitial) {
          return const Padding(
            padding: EdgeInsets.all(CRMSpacing.l),
            child: CRMListSkeleton(count: 4),
          );
        } else if (state is DashboardError) {
          return _buildErrorState(state.message);
        } else if (state is DashboardLoadedState || state is DashboardRefreshing) {
          final data = (state is DashboardLoadedState)
              ? state.data
              : (state as DashboardRefreshing).data;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<DashboardBloc>().add(RefreshDashboard());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: CRMSpacing.m,
                vertical: CRMSpacing.l,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Welcome Header
                  _buildWelcomeHeader(userEmail, dateString, greeting),
                  const SizedBox(height: CRMSpacing.l),

                  // 2. Quick Actions
                  _buildQuickActions(),
                  const SizedBox(height: CRMSpacing.l),

                  // 3. KPI Grids (Overflow Fixed inside this method)
                  _buildKPIGrids(data.summary),
                  const SizedBox(height: CRMSpacing.l),

                  // Split analytics and Tasks layout (Responsive LayoutBuilder)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth >= 900;
                      if (isDesktop) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  _buildAnalyticsChart(),
                                  const SizedBox(height: CRMSpacing.l),
                                  _buildRecentProperties(data.recentProperties),
                                ],
                              ),
                            ),
                            const SizedBox(width: CRMSpacing.l),
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  _buildTodayWork(data.checklist),
                                  const SizedBox(height: CRMSpacing.l),
                                  _buildFollowups(data.followups),
                                  if (isAdmin) ...[
                                    const SizedBox(height: CRMSpacing.l),
                                    _buildRecentActivities(data.activity),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            _buildAnalyticsChart(),
                            const SizedBox(height: CRMSpacing.l),
                            _buildTodayWork(data.checklist),
                            const SizedBox(height: CRMSpacing.l),
                            _buildFollowups(data.followups),
                            const SizedBox(height: CRMSpacing.l),
                            _buildRecentProperties(data.recentProperties),
                            if (isAdmin) ...[
                              const SizedBox(height: CRMSpacing.l),
                              _buildRecentActivities(data.activity),
                            ],
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: CRMSpacing.l),

                  // 10. Performance Indicators
                  _buildPerformanceBlock(),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildWelcomeHeader(String email, String dateString, String greeting) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    Widget leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: CRMTypography.body.copyWith(
            color: CRMColors.textSecondaryOf(context),
            fontSize: isMobile ? 14 : 16,
          ),
        ),
        Text(
          email.split('@').first,
          style: CRMTypography.pageTitle.copyWith(
            color: CRMColors.textOf(context),
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 22 : 28,
          ),
        ),
      ],
    );

    Widget rightColumn = Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          dateString,
          style: CRMTypography.bodyMedium.copyWith(
            color: CRMColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftColumn,
          const SizedBox(height: CRMSpacing.s),
          rightColumn,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        leftColumn,
        rightColumn,
      ],
    );
  }

  Widget _buildQuickActions() {
    return CRMCard(
      title: 'Quick Operations',
      subtitle: 'Perform common CRM operational workflows instantly',
      child: Padding(
        padding: const EdgeInsets.only(top: CRMSpacing.s),
        child: Wrap(
          spacing: CRMSpacing.s,
          runSpacing: CRMSpacing.s,
          alignment: WrapAlignment.start,
          children: [
            CRMButton(
              label: 'Add Property',
              prefixIcon: Icons.add_business_rounded,
              onPressed: () => context.go('/properties'),
            ),
            CRMButton(
              label: 'Add Requirement',
              prefixIcon: Icons.add_task_rounded,
              variant: CRMButtonVariant.secondary,
              onPressed: () => context.go('/requirements'),
            ),
            CRMButton(
              label: 'Import Excel',
              prefixIcon: Icons.file_upload_rounded,
              variant: CRMButtonVariant.outline,
              onPressed: _showImportExcelDialog,
            ),
            CRMButton(
              label: 'Create Follow-up',
              prefixIcon: Icons.alarm_add_rounded,
              variant: CRMButtonVariant.outline,
              onPressed: _showCreateFollowupDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPIGrids(DashboardSummary summary) {
    final double screenWidth = MediaQuery.of(context).size.width;

    final cards = [
      CRMKPICard(
        title: 'Total Properties',
        value: '${summary.totalProperties}',
        icon: Icons.inventory_2_outlined,
        growthPercent: 8.5,
      ),
      CRMKPICard(
        title: 'Available',
        value: '${summary.available}',
        icon: Icons.check_circle_outline_rounded,
        iconColor: CRMColors.success,
        growthPercent: 12.0,
      ),
      CRMKPICard(
        title: 'Sold',
        value: '${summary.sold}',
        icon: Icons.sell_outlined,
        iconColor: CRMColors.warning,
        growthPercent: -2.3,
      ),
      CRMKPICard(
        title: 'Rented',
        value: '${summary.rented}',
        icon: Icons.key_outlined,
        iconColor: CRMColors.info,
        growthPercent: 4.8,
      ),
      CRMKPICard(
        title: 'Requirements',
        value: '${summary.requirements}',
        icon: Icons.assignment_turned_in_outlined,
        growthPercent: 15.2,
      ),
    ];

    final int crossAxisCount = screenWidth >= 1100
        ? 5
        : (screenWidth >= 700 ? 3 : 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: CRMSpacing.xs, bottom: CRMSpacing.s),
          child: Text(
            'Property Metrics', 
            style: CRMTypography.sectionTitle.copyWith(
              color: CRMColors.textOf(context),
              fontWeight: FontWeight.bold,
            )
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: CRMSpacing.m,
            mainAxisSpacing: CRMSpacing.m,
            childAspectRatio: screenWidth < 600 ? 0.8 : (screenWidth < 950 ? 0.9 : 1.2),
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            return cards[index];
          },
        ),
      ],
    );
  }

  Widget _buildTodayWork(List<ChecklistItem> items) {
    return CRMCard(
      title: "Today's Work checklist",
      subtitle: 'Operations and tasks assigned for today',
      headerAction: IconButton(
        icon: Icon(Icons.add_circle_outline_rounded, color: CRMColors.primary, size: 20),
        onPressed: _showAddChecklistDialog,
        tooltip: 'Add Task',
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: CRMSpacing.m),
        child: items.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text('No tasks for today.', style: TextStyle(color: CRMColors.textSecondaryOf(context))),
                ),
              )
            : Column(
                children: items.map((item) => _buildTaskTile(item)).toList(),
              ),
      ),
    );
  }

  Widget _buildTaskTile(ChecklistItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: CRMSpacing.s),
      padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: CRMSpacing.xs),
      decoration: BoxDecoration(
        color: CRMColors.backgroundOf(context).withOpacity(0.4),
        borderRadius: BorderRadius.circular(CRMBorderRadius.s),
        border: Border.all(color: CRMColors.backgroundOf(context)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: item.isCompleted,
            activeColor: CRMColors.success,
            onChanged: (val) async {
              if (val != null) {
                try {
                  await DioClient.dio.patch('/checklist/${item.id}/toggle', data: {'is_completed': val});
                  if (mounted) {
                    context.read<DashboardBloc>().add(RefreshDashboard());
                  }
                } catch (e) {
                  // error
                }
              }
            },
          ),
          const SizedBox(width: CRMSpacing.s),
          Expanded(
            child: Text(
              item.title, 
              style: CRMTypography.bodyMedium.copyWith(
                color: CRMColors.textOf(context),
                fontWeight: FontWeight.w600,
                decoration: item.isCompleted ? TextDecoration.lineThrough : null,
              )
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: CRMColors.danger, size: 18),
            onPressed: () async {
              try {
                await DioClient.dio.delete('/checklist/${item.id}');
                if (mounted) {
                  context.read<DashboardBloc>().add(RefreshDashboard());
                }
              } catch (e) {
                // error
              }
            },
          ),
        ],
      ),
    );
  }

  void _showAddChecklistDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: CRMColors.cardBg,
          title: Text('Add New Task', style: CRMTypography.sectionTitle.copyWith(color: CRMColors.text)),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Task Title',
              filled: true,
              fillColor: CRMColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            CRMButton(
              label: 'Save',
              onPressed: () async {
                final title = controller.text.trim();
                if (title.isNotEmpty) {
                  try {
                    await DioClient.dio.post('/checklist', data: {'title': title});
                    if (mounted) {
                      context.read<DashboardBloc>().add(RefreshDashboard());
                    }
                  } catch (e) {
                    // error
                  }
                }
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildFollowups(List<DashboardFollowup> followups) {
    return CRMCard(
      title: "Upcoming Follow-ups",
      subtitle: 'Schedule of communications and clients appointments',
      headerAction: IconButton(
        icon: Icon(Icons.alarm_add_rounded, color: CRMColors.primary, size: 20),
        onPressed: _showCreateFollowupDialog,
        tooltip: 'Add Follow-up',
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: CRMSpacing.m),
        child: followups.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text('No upcoming follow-ups.', style: TextStyle(color: CRMColors.textSecondaryOf(context))),
                ),
              )
            : Column(
                children: followups.map((f) => _buildFollowupTile(f)).toList(),
              ),
      ),
    );
  }

  Widget _buildFollowupTile(DashboardFollowup f) {
    final date = DateTime.tryParse(f.followupDate)?.toLocal() ?? DateTime.now();
    final formattedTime = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    final formattedDate = "${date.day}/${date.month}/${date.year}";

    return Container(
      margin: const EdgeInsets.only(bottom: CRMSpacing.s),
      padding: const EdgeInsets.all(CRMSpacing.m),
      decoration: BoxDecoration(
        color: CRMColors.backgroundOf(context).withOpacity(0.4),
        borderRadius: BorderRadius.circular(CRMBorderRadius.s),
        border: Border.all(color: CRMColors.backgroundOf(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: f.status == 'Pending' ? CRMColors.warning.withOpacity(0.1) : CRMColors.success.withOpacity(0.1),
            radius: 18,
            child: Icon(
              Icons.phone_in_talk_rounded,
              color: f.status == 'Pending' ? CRMColors.warning : CRMColors.success,
              size: 18,
            ),
          ),
          const SizedBox(width: CRMSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.clientName,
                  style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textOf(context), fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text('Mobile: ${f.mobile}', style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context))),
                if (f.notes != null && f.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(f.notes!, style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context), fontStyle: FontStyle.italic)),
                ],
                const SizedBox(height: 6),
                Text('Scheduled: $formattedDate at $formattedTime', style: CRMTypography.caption.copyWith(color: CRMColors.primary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (f.status == 'Pending') ...[
                IconButton(
                  icon: Icon(Icons.check_circle_outline_rounded, color: CRMColors.success, size: 20),
                  onPressed: () async {
                    try {
                      await DioClient.dio.patch('/followups/${f.id}/status', data: {'status': 'Completed'});
                      if (mounted) {
                        context.read<DashboardBloc>().add(RefreshDashboard());
                      }
                    } catch (e) {
                      // error
                    }
                  },
                  tooltip: 'Mark Completed',
                ),
              ],
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, color: CRMColors.danger, size: 18),
                onPressed: () async {
                  try {
                    await DioClient.dio.delete('/followups/${f.id}');
                    if (mounted) {
                      context.read<DashboardBloc>().add(RefreshDashboard());
                    }
                  } catch (e) {
                    // error
                  }
                },
                tooltip: 'Delete Follow-up',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showImportExcelDialog() {
    int currentStep = 1; // 1: Upload, 2: Parsing & Validating, 3: Preview & Duplicate Resolution, 4: Committing, 5: Report
    String uploadStatusMessage = "Ready for upload";
    double progressValue = 0.0;
    
    PlatformFile? pickedFile;
    Map<String, dynamic> previewData = {};
    String selectedResolution = "skip"; // skip, import_all, update
    
    Map<String, dynamic> finalReport = {};
    bool isCommitError = false;
    String commitErrorMessage = "";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            
            Future<void> downloadTemplate() async {
              try {
                final response = await DioClient.dio.get<List<int>>(
                  '/properties/import/template',
                  options: Options(responseType: ResponseType.bytes),
                );

                await FileDownloader.download(
                  response.data!,
                  'properties_import_template.xlsx',
                );
              } catch (_) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Failed to download template. Ensure server is running.')),
                );
              }
            }

            // File selection trigger
            Future<void> pickFile() async {
              try {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['xlsx', 'xls', 'xlsm', 'xlsb', 'csv'],
                );
                if (result != null && result.files.isNotEmpty) {
                  setModalState(() {
                    pickedFile = result.files.first;
                  });
                }
              } catch (e) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Error selecting file: $e')),
                );
              }
            }

            // Stage 2: Progress simulation & server preview upload
            Future<void> runPreviewAnalysis() async {
              if (pickedFile == null || (!kIsWeb && pickedFile!.path == null) || (kIsWeb && pickedFile!.bytes == null)) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Please select an Excel or CSV file first.')),
                );
                return;
              }

              setModalState(() {
                currentStep = 2;
                uploadStatusMessage = "Reading file buffer...";
                progressValue = 0.2;
              });
              await Future.delayed(const Duration(milliseconds: 300));

              setModalState(() {
                uploadStatusMessage = "Uploading file to server...";
                progressValue = 0.5;
              });

              try {
                MultipartFile file;
                if (kIsWeb) {
                  file = MultipartFile.fromBytes(
                    pickedFile!.bytes!,
                    filename: pickedFile!.name,
                  );
                } else {
                  file = await MultipartFile.fromFile(
                    pickedFile!.path!,
                    filename: pickedFile!.name,
                  );
                }

                final formData = FormData.fromMap({
                  'file': file,
                });

                final response = await DioClient.dio.post(
                  '/properties/import',
                  data: formData,
                );
                
                previewData = response.data['data'] ?? {};
              } catch (e) {
                String errorMsg = "Failed to parse import file.";
                if (e is DioException) {
                  errorMsg = e.response?.data['message'] ?? e.message ?? errorMsg;
                }
                setModalState(() {
                  currentStep = 1;
                  uploadStatusMessage = errorMsg;
                });
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(errorMsg), backgroundColor: CRMColors.danger),
                );
                return;
              }

              setModalState(() {
                currentStep = 3;
                progressValue = 1.0;
              });
            }

            // Stage 4: Committing database insert
            Future<void> commitImport() async {
              if (pickedFile == null || (!kIsWeb && pickedFile!.path == null) || (kIsWeb && pickedFile!.bytes == null)) return;

              setModalState(() {
                currentStep = 4;
                uploadStatusMessage = "Importing valid rows...";
                progressValue = 0.4;
              });

              try {
                MultipartFile file;
                if (kIsWeb) {
                  file = MultipartFile.fromBytes(
                    pickedFile!.bytes!,
                    filename: pickedFile!.name,
                  );
                } else {
                  file = await MultipartFile.fromFile(
                    pickedFile!.path!,
                    filename: pickedFile!.name,
                  );
                }

                final formData = FormData.fromMap({
                  'file': file,
                });

                final response = await DioClient.dio.post(
                  '/properties/import?action=commit',
                  queryParameters: {'duplicateResolution': selectedResolution},
                  data: formData,
                );
                finalReport = response.data['data'] ?? {};
              } catch (e) {
                String errorMsg = "Failed to commit import.";
                if (e is DioException) {
                  errorMsg = e.response?.data['message'] ?? e.message ?? errorMsg;
                }
                setModalState(() {
                  isCommitError = true;
                  commitErrorMessage = errorMsg;
                });
              }

              if (mounted) {
                context.read<DashboardBloc>().add(RefreshDashboard());
              }

              setModalState(() {
                currentStep = 5;
                progressValue = 1.0;
              });
            }

            Widget stepWidget;

            if (currentStep == 1) {
              final String fileName = pickedFile != null ? pickedFile!.name : 'Click to select Excel/CSV file';
              final String fileSize = pickedFile != null ? '${(pickedFile!.size / 1024).toStringAsFixed(1)} KB' : 'Max 5 MB';

              stepWidget = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: pickFile,
                      child: Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: CRMColors.backgroundOf(context),
                          borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                          border: Border.all(
                            color: pickedFile != null ? CRMColors.success : CRMColors.primary.withOpacity(0.3),
                            width: 1.5,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              pickedFile != null ? Icons.task_outlined : Icons.file_upload_rounded,
                              size: 36,
                              color: pickedFile != null ? CRMColors.success : CRMColors.primary,
                            ),
                            const SizedBox(height: CRMSpacing.s),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                fileName,
                                style: CRMTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: CRMColors.textOf(context),
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              fileSize,
                              style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: CRMSpacing.m),
                  OutlinedButton.icon(
                    onPressed: downloadTemplate,
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Download Excel Template'),
                  ),
                ],
              );
            } else if (currentStep == 2 || currentStep == 4) {
              stepWidget = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: CRMSpacing.m),
                  LinearProgressIndicator(value: progressValue, color: CRMColors.primary),
                  const SizedBox(height: CRMSpacing.m),
                  Text(
                    uploadStatusMessage,
                    style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textOf(context), fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            } else if (currentStep == 3) {
              final summary = previewData['summary'] ?? {};
              final preview = previewData['preview'] ?? {};
              final List invalidList = preview['invalid'] ?? [];
              final List duplicateList = preview['duplicates'] ?? [];

              stepWidget = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMetricSummary('Total', '${summary['totalRows'] ?? 0}', CRMColors.primary),
                      _buildMetricSummary('Valid', '${summary['validRows'] ?? 0}', CRMColors.success),
                      _buildMetricSummary('Duplicates', '${summary['duplicateRows'] ?? 0}', CRMColors.warning),
                      _buildMetricSummary('Invalid', '${summary['invalidRows'] ?? 0}', CRMColors.danger),
                    ],
                  ),
                  const SizedBox(height: CRMSpacing.m),
                  if (invalidList.isNotEmpty) ...[
                    Text('Validation Warnings & Errors:', style: CRMTypography.body.copyWith(fontWeight: FontWeight.bold, color: CRMColors.textOf(context))),
                    const SizedBox(height: CRMSpacing.xs),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: CRMColors.backgroundOf(context),
                        borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        children: invalidList.map((inv) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Text(
                              'Row ${inv['rowNum']}: ${inv['errors']?.join(', ')}',
                              style: CRMTypography.caption.copyWith(color: CRMColors.danger),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: CRMSpacing.m),
                  ],
                  Text('Duplicate Resolution Strategy:', style: CRMTypography.body.copyWith(fontWeight: FontWeight.bold, color: CRMColors.textOf(context))),
                  const SizedBox(height: CRMSpacing.xs),
                  DropdownButtonFormField<String>(
                    dropdownColor: CRMColors.cardBg,
                    value: selectedResolution,
                    items: const [
                      DropdownMenuItem(value: 'skip', child: Text('Skip duplicate entries')),
                      DropdownMenuItem(value: 'update', child: Text('Update existing database records')),
                      DropdownMenuItem(value: 'import_all', child: Text('Import all rows as new records')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedResolution = val);
                      }
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: CRMColors.backgroundOf(context),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                    ),
                  ),
                ],
              );
            } else {
              stepWidget = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    isCommitError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
                    color: isCommitError ? CRMColors.danger : CRMColors.success,
                    size: 48,
                  ),
                  const SizedBox(height: CRMSpacing.m),
                  Text(
                    isCommitError ? 'Import Committing Failed' : 'Import Completed Successfully!',
                    style: CRMTypography.body.copyWith(fontWeight: FontWeight.bold, color: CRMColors.textOf(context)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: CRMSpacing.m),
                  isCommitError
                      ? Text(
                          commitErrorMessage,
                          style: CRMTypography.caption.copyWith(color: CRMColors.danger),
                          textAlign: TextAlign.center,
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildMetricSummary('Imported', '${finalReport['imported'] ?? 0}', CRMColors.success),
                            _buildMetricSummary('Updated', '${finalReport['updated'] ?? 0}', CRMColors.info),
                            _buildMetricSummary('Skipped', '${finalReport['skipped'] ?? 0}', CRMColors.warning),
                            _buildMetricSummary('Failed', '${finalReport['failed'] ?? 0}', CRMColors.danger),
                          ],
                        ),
                ],
              );
            }

            return AlertDialog(
              backgroundColor: CRMColors.cardBg,
              title: Text(
                currentStep == 5 ? 'Import Report' : 'Properties Import Wizard',
                style: CRMTypography.sectionTitle.copyWith(color: CRMColors.text),
              ),
              content: SizedBox(
                width: 420,
                child: stepWidget,
              ),
              actions: [
                if (currentStep == 1) ...[
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  CRMButton(
                    label: 'Analyze File',
                    onPressed: runPreviewAnalysis,
                  ),
                ] else if (currentStep == 3) ...[
                  TextButton(
                    onPressed: () => setModalState(() => currentStep = 1),
                    child: const Text('Back'),
                  ),
                  CRMButton(
                    label: 'Commit Import',
                    onPressed: commitImport,
                  ),
                ] else if (currentStep == 5) ...[
                  CRMButton(
                    label: 'Close Wizard',
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ]
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMetricSummary(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: CRMTypography.sectionTitle.copyWith(fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: CRMColors.textSecondary),
        ),
      ],
    );
  }

  void _showCreateFollowupDialog() {
    final clientNameController = TextEditingController();
    final mobileController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: CRMColors.cardBg,
              title: Text('Schedule Follow-up', style: CRMTypography.sectionTitle.copyWith(color: CRMColors.text)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: clientNameController,
                      decoration: InputDecoration(
                        labelText: 'Client Name',
                        filled: true,
                        fillColor: CRMColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                      ),
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    TextField(
                      controller: mobileController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Mobile Number',
                        filled: true,
                        fillColor: CRMColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                      ),
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: 'Follow-up Notes',
                        filled: true,
                        fillColor: CRMColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                      ),
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    ListTile(
                      title: Text('Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                      trailing: Icon(Icons.calendar_today_rounded, color: CRMColors.primary),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setModalState(() => selectedDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                CRMButton(
                  label: 'Schedule',
                  onPressed: () async {
                    final clientName = clientNameController.text.trim();
                    final mobile = mobileController.text.trim();
                    final notes = notesController.text.trim();

                    if (clientName.isNotEmpty && mobile.isNotEmpty) {
                      try {
                        await DioClient.dio.post('/followups', data: {
                          'client_name': clientName,
                          'mobile': mobile,
                          'notes': notes,
                          'followup_date': selectedDate.toUtc().toIso8601String(),
                        });
                        if (mounted) {
                          context.read<DashboardBloc>().add(RefreshDashboard());
                        }
                      } catch (e) {
                        // error
                      }
                    }
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAnalyticsChart() {
    return CRMCard(
      title: 'Properties & Requirements Analytics',
      subtitle: 'System entries volume registered month-over-month',
      child: Container(
        height: 240,
        padding: const EdgeInsets.only(top: CRMSpacing.l),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double containerWidth = constraints.maxWidth;
            final double barWidth = (containerWidth / 7).clamp(24.0, 48.0);

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar('Jan', 60, CRMColors.primary, barWidth),
                _buildBar('Feb', 90, CRMColors.primary.withOpacity(0.7), barWidth),
                _buildBar('Mar', 120, CRMColors.primary, barWidth),
                _buildBar('Apr', 75, CRMColors.primary.withOpacity(0.7), barWidth),
                _buildBar('May', 150, CRMColors.success, barWidth),
                _buildBar('Jun', 180, CRMColors.success, barWidth),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBar(String label, double height, Color color, double width) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(CRMBorderRadius.xs),
              topRight: Radius.circular(CRMBorderRadius.xs),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ]
          ),
        ),
        const SizedBox(height: CRMSpacing.s),
        Text(
          label, 
          style: CRMTypography.caption.copyWith(
            color: CRMColors.textSecondaryOf(context),
            fontWeight: FontWeight.w500
          )
        ),
      ],
    );
  }

  Widget _buildRecentProperties(List<RecentProperty> properties) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    return CRMCard(
      title: 'Recent Properties',
      subtitle: 'Latest listings registered in the CRM platform',
      child: Padding(
        padding: const EdgeInsets.only(top: CRMSpacing.s),
        child: properties.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No listings found.',
                    style: TextStyle(color: CRMColors.textSecondaryOf(context)),
                  ),
                ),
              )
            : isMobile
                ? Column(
                    children: properties.map((p) => _buildMobilePropertyCard(p)).toList(),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final double tableMinWidth = 600.0;
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: constraints.maxWidth > tableMinWidth
                                ? constraints.maxWidth
                                : tableMinWidth,
                          ),
                          child: Table(
                            columnWidths: const {
                              0: FlexColumnWidth(1.2), // Code
                              1: FlexColumnWidth(2.5), // Title
                              2: FlexColumnWidth(1.8), // Area
                              3: FlexColumnWidth(1.2), // Price
                              4: FlexColumnWidth(1.3), // Status
                            },
                            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                            border: TableBorder(
                              horizontalInside: BorderSide(
                                color: CRMColors.borderOf(context).withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            children: [
                              TableRow(
                                decoration: BoxDecoration(
                                  color: CRMColors.backgroundOf(context).withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(CRMBorderRadius.xs),
                                ),
                                children: [
                                  _buildTableHeaderCell('Code'),
                                  _buildTableHeaderCell('Title'),
                                  _buildTableHeaderCell('Area'),
                                  _buildTableHeaderCell('Price'),
                                  _buildTableHeaderCell('Status'),
                                ],
                              ),
                              ...properties.map((p) {
                                return TableRow(
                                  children: [
                                    _buildTableDataCell(
                                      InkWell(
                                        onTap: () => _openPropertyDetails(p.id),
                                        child: MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: Text(
                                            p.code, 
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold, 
                                              color: CRMColors.primary,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    _buildTableDataCell(
                                      InkWell(
                                        onTap: () => _openPropertyDetails(p.id),
                                        child: MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: Text(p.title, style: TextStyle(color: CRMColors.textOf(context))),
                                        ),
                                      ),
                                    ),
                                    _buildTableDataCell(
                                      InkWell(
                                        onTap: () => _openPropertyDetails(p.id),
                                        child: MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: Text(p.areaName, style: TextStyle(color: CRMColors.textSecondaryOf(context))),
                                        ),
                                      ),
                                    ),
                                    _buildTableDataCell(
                                      InkWell(
                                        onTap: () => _openPropertyDetails(p.id),
                                        child: MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: Text('₹${p.price.toStringAsFixed(0)}', style: TextStyle(color: CRMColors.textOf(context), fontWeight: FontWeight.w600)),
                                        ),
                                      ),
                                    ),
                                    _buildTableDataCell(
                                      InkWell(
                                        onTap: () => _openPropertyDetails(p.id),
                                        child: MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: p.status.toLowerCase() == 'available' 
                                                    ? CRMColors.success.withOpacity(0.1) 
                                                    : CRMColors.warning.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(CRMBorderRadius.xs),
                                              ),
                                              child: Text(
                                                p.status, 
                                                style: TextStyle(
                                                  color: p.status.toLowerCase() == 'available' ? CRMColors.success : CRMColors.warning,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold
                                                )
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildTableHeaderCell(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: 12),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: CRMColors.textOf(context),
        ),
      ),
    );
  }

  Widget _buildTableDataCell(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: 12),
      child: child,
    );
  }

  Widget _buildMobilePropertyCard(RecentProperty p) {
    return InkWell(
      onTap: () => _openPropertyDetails(p.id),
      borderRadius: BorderRadius.circular(CRMBorderRadius.s),
      child: Container(
        margin: const EdgeInsets.only(bottom: CRMSpacing.s),
        padding: const EdgeInsets.all(CRMSpacing.m),
        decoration: BoxDecoration(
          color: CRMColors.backgroundOf(context).withOpacity(0.4),
          borderRadius: BorderRadius.circular(CRMBorderRadius.s),
          border: Border.all(color: CRMColors.backgroundOf(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  p.code,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: CRMColors.primary,
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: p.status.toLowerCase() == 'available' 
                        ? CRMColors.success.withOpacity(0.1) 
                        : CRMColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(CRMBorderRadius.xs),
                  ),
                  child: Text(
                    p.status, 
                    style: TextStyle(
                      color: p.status.toLowerCase() == 'available' ? CRMColors.success : CRMColors.warning,
                      fontSize: 11,
                      fontWeight: FontWeight.bold
                    )
                  ),
                ),
              ],
            ),
            const SizedBox(height: CRMSpacing.xs),
            Text(
              p.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: CRMColors.textOf(context),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: CRMSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: CRMColors.textSecondaryOf(context)),
                    const SizedBox(width: 4),
                    Text(
                      p.areaName,
                      style: TextStyle(
                        color: CRMColors.textSecondaryOf(context),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Text(
                  '₹${p.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: CRMColors.textOf(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities(List<RecentActivity> activities) {
    return CRMCard(
      title: 'Recent Audit Activities',
      subtitle: 'Trace logs of structural edits inside CRM database',
      child: Padding(
        padding: const EdgeInsets.only(top: CRMSpacing.m),
        child: activities.isEmpty
            ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('No activity logs.')))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: CRMSpacing.s),
                    padding: const EdgeInsets.all(CRMSpacing.m),
                    decoration: BoxDecoration(
                      color: CRMColors.backgroundOf(context).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.history_toggle_off_rounded, color: CRMColors.primary, size: 20),
                        const SizedBox(width: CRMSpacing.m),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity.description, 
                                style: CRMTypography.bodyMedium.copyWith(
                                  color: CRMColors.textOf(context),
                                  fontWeight: FontWeight.w500
                                )
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'User: ${activity.user} | ${activity.timestamp}',
                                style: CRMTypography.caption.copyWith(color: CRMColors.textMutedOf(context)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildPerformanceBlock() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 4;
        double childAspectRatio = 2.2;
        
        if (constraints.maxWidth < 600) {
          crossAxisCount = 2;
          childAspectRatio = 1.4;
        } else if (constraints.maxWidth < 900) {
          crossAxisCount = 2;
          childAspectRatio = 1.8;
        }

        return CRMCard(
          title: 'Agency CRM Performance metrics',
          subtitle: 'Real-time performance metrics tracking brokers and regions',
          child: Padding(
            padding: const EdgeInsets.only(top: CRMSpacing.m),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: CRMSpacing.m,
              mainAxisSpacing: CRMSpacing.m,
              childAspectRatio: childAspectRatio,
              children: [
                _buildPerformanceCard('Top Broker', 'System Administrator', Icons.stars_rounded),
                _buildPerformanceCard('Top Area', 'Prahladnagar', Icons.location_on_rounded),
                _buildPerformanceCard('Top Property', 'PR-1001', Icons.home_rounded),
                _buildPerformanceCard('Monthly Growth', '+24.5%', Icons.trending_up_rounded),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPerformanceCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(CRMSpacing.m),
      decoration: BoxDecoration(
        color: CRMColors.backgroundOf(context),
        borderRadius: BorderRadius.circular(CRMBorderRadius.s),
        border: Border.all(color: CRMColors.backgroundOf(context).withOpacity(0.8)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: CRMColors.primary.withOpacity(0.1),
            radius: 18,
            child: Icon(icon, color: CRMColors.primary, size: 20),
          ),
          const SizedBox(width: CRMSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label, 
                  style: CRMTypography.caption.copyWith(
                    color: CRMColors.textSecondaryOf(context),
                    fontWeight: FontWeight.w500
                  )
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: CRMTypography.bodyMedium.copyWith(
                    color: CRMColors.textOf(context), 
                    fontWeight: FontWeight.bold
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openPropertyDetails(String propertyId) {
    context.go('/properties?openId=$propertyId');
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CRMSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: CRMColors.danger, size: 54),
            const SizedBox(height: CRMSpacing.m),
            Text(
              'Failed to Load Dashboard', 
              style: CRMTypography.sectionTitle.copyWith(
                color: CRMColors.textOf(context),
                fontWeight: FontWeight.bold
              )
            ),
            const SizedBox(height: CRMSpacing.xs),
            Text(message, style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context)), textAlign: TextAlign.center),
            const SizedBox(height: CRMSpacing.l),
            CRMButton(
              label: 'Retry Connection',
              onPressed: () {
                context.read<DashboardBloc>().add(LoadDashboard());
              },
            ),
          ],
        ),
      ),
    );
  }
}