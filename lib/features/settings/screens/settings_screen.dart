import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/theme/theme_manager.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../properties/models/property_model.dart';
import '../../properties/services/properties_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PropertiesService _propertiesService = PropertiesService();
  bool _isLoading = true;
  List<LookupItem> _cities = [];
  List<AreaLookup> _areas = [];
  String? _selectedCityForArea;

  final _cityController = TextEditingController();
  final _areaNameController = TextEditingController();
  final _pincodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ThemeManager().addListener(_onThemeChanged);
    _loadLocationMetadata();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadLocationMetadata() async {
    setState(() => _isLoading = true);
    try {
      final response = await _propertiesService.getPropertyMetadata();
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final meta = PropertyMetadataModel.fromJson(data['metadata'] ?? {});
      setState(() {
        _cities = meta.cities;
        _areas = meta.areas;
        if (_cities.isNotEmpty) {
          _selectedCityForArea = _cities.first.id;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load location configs: $e'), backgroundColor: CRMColors.danger),
        );
      }
    }
  }

  Future<void> _addCity() async {
    final name = _cityController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final result = await _propertiesService.createCity(name);
      final newCity = LookupItem(
        id: result['data']['city']['id'],
        name: result['data']['city']['city_name'],
      );
      setState(() {
        _cities.add(newCity);
        _selectedCityForArea = newCity.id;
        _cityController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('City created successfully'), backgroundColor: CRMColors.success),
      );
      _loadLocationMetadata();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add city: $e'), backgroundColor: CRMColors.danger),
      );
    }
  }

  Future<void> _addArea() async {
    final name = _areaNameController.text.trim();
    final pincode = _pincodeController.text.trim();
    if (name.isEmpty || pincode.isEmpty || _selectedCityForArea == null) return;

    setState(() => _isLoading = true);
    try {
      await _propertiesService.createArea(_selectedCityForArea!, name, pincode);
      setState(() {
        _areaNameController.clear();
        _pincodeController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Area created successfully'), backgroundColor: CRMColors.success),
      );
      _loadLocationMetadata();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add area: $e'), backgroundColor: CRMColors.danger),
      );
    }
  }

  Widget _buildProfileCard(String name, String email) {
    return CRMCard(
      title: 'User Profile',
      subtitle: 'Manage your personal account details',
      child: Padding(
        padding: const EdgeInsets.only(top: CRMSpacing.m),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: CRMColors.primary.withOpacity(0.12),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: CRMTypography.sectionTitle.copyWith(
                      color: CRMColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: CRMSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: CRMTypography.bodyMedium.copyWith(
                          color: CRMColors.text,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: CRMSpacing.l),
            Container(
              padding: const EdgeInsets.all(CRMSpacing.m),
              decoration: BoxDecoration(
                color: CRMColors.info.withOpacity(0.08),
                borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                border: Border.all(color: CRMColors.info.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: CRMColors.info, size: 20),
                  const SizedBox(width: CRMSpacing.s),
                  Expanded(
                    child: Text(
                      'Profile details editing is coming soon!',
                      style: CRMTypography.captionBold.copyWith(color: CRMColors.info),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceCard() {
    final isDark = ThemeManager().isDarkMode;
    return CRMCard(
      title: 'Appearance',
      subtitle: 'Customize the visual theme of the application',
      child: Padding(
        padding: const EdgeInsets.only(top: CRMSpacing.xs),
        child: SwitchListTile(
          title: Text(
            'Dark Mode',
            style: CRMTypography.bodyMedium.copyWith(
              color: CRMColors.text,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            'Toggle between light and dark visual themes',
            style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
          ),
          secondary: Icon(
            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            color: isDark ? CRMColors.primary : CRMColors.textSecondary,
          ),
          value: isDark,
          activeColor: CRMColors.primary,
          onChanged: (val) {
            ThemeManager().toggleTheme();
          },
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    final authState = context.watch<AuthBloc>().state;
    String currentUserName = 'Guest';
    String currentUserEmail = '';
    if (authState is Authenticated) {
      currentUserEmail = authState.user.email;
      final localPart = currentUserEmail.split('@').first;
      currentUserName = localPart.isNotEmpty 
          ? '${localPart[0].toUpperCase()}${localPart.substring(1)}'
          : 'User';
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(CRMSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('System Configuration', style: CRMTypography.body.copyWith(color: CRMColors.textSecondary)),
                  Text(
                    'Settings & Profile',
                    style: CRMTypography.pageTitle.copyWith(
                      color: CRMColors.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: CRMSpacing.l),
                  if (isMobile) ...[
                    _buildProfileCard(currentUserName, currentUserEmail),
                    const SizedBox(height: CRMSpacing.l),
                    _buildAppearanceCard(),
                    const SizedBox(height: CRMSpacing.l),
                    _buildCityCard(),
                    const SizedBox(height: CRMSpacing.l),
                    _buildAreaCard(),
                  ] else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildProfileCard(currentUserName, currentUserEmail),
                              const SizedBox(height: CRMSpacing.l),
                              _buildAppearanceCard(),
                            ],
                          ),
                        ),
                        const SizedBox(width: CRMSpacing.l),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildCityCard(),
                              const SizedBox(height: CRMSpacing.l),
                              _buildAreaCard(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildCityCard() {
    return CRMCard(
      title: 'City Configs',
      subtitle: 'Manage system-wide active cities',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    labelText: 'New City Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                  ),
                ),
              ),
              const SizedBox(width: CRMSpacing.s),
              CRMButton(
                label: 'Add',
                onPressed: _addCity,
              ),
            ],
          ),
          const SizedBox(height: CRMSpacing.m),
          SizedBox(
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: CRMColors.border),
                borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              ),
              child: ListView.separated(
                itemCount: _cities.length,
                separatorBuilder: (_, __) => Divider(color: CRMColors.border, height: 1),
                itemBuilder: (context, index) {
                  final city = _cities[index];
                  return ListTile(
                    title: Text(city.name, style: TextStyle(color: CRMColors.textOf(context))),
                    dense: true,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaCard() {
    final filtered = _areas.where((a) => a.cityId == _selectedCityForArea).toList();

    return CRMCard(
      title: 'Area Mapping Configs',
      subtitle: 'Map micro-markets and local communities to cities',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedCityForArea,
            decoration: InputDecoration(
              labelText: 'Select City',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
            ),
            items: _cities.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
            onChanged: (v) => setState(() => _selectedCityForArea = v),
          ),
          const SizedBox(height: CRMSpacing.s),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _areaNameController,
                  decoration: InputDecoration(
                    labelText: 'New Area Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                  ),
                ),
              ),
              const SizedBox(width: CRMSpacing.s),
              Expanded(
                child: TextField(
                  controller: _pincodeController,
                  decoration: InputDecoration(
                    labelText: 'Pincode',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: CRMSpacing.s),
              CRMButton(
                label: 'Add',
                onPressed: _addArea,
              ),
            ],
          ),
          const SizedBox(height: CRMSpacing.m),
          SizedBox(
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: CRMColors.border),
                borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              ),
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => Divider(color: CRMColors.border, height: 1),
                itemBuilder: (context, index) {
                  final area = filtered[index];
                  return ListTile(
                    title: Text(area.name, style: TextStyle(color: CRMColors.textOf(context))),
                    trailing: Text(area.pincode, style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary)),
                    dense: true,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    ThemeManager().removeListener(_onThemeChanged);
    _cityController.dispose();
    _areaNameController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }
}
