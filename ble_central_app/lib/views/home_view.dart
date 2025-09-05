import 'package:flutter/material.dart';
import 'package:clover/clover.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';

import '../view_models/central_scanner_view_model.dart';
import '../widgets/device_card.dart';
import '../widgets/scanner_header.dart';
import '../widgets/search_controls.dart';
import '../widgets/filter_drawer.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ViewModel.of<CentralScannerViewModel>(context);
    final state = viewModel.state;

    return Scaffold(
      key: _scaffoldKey,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('BLE 중앙 스캐너'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Icon(
                        Symbols.radar,
                        size: 120,
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.1),
                      ),
                    ),
                    Positioned(
                      bottom: 60,
                      left: 16,
                      right: 16,
                      child: ScannerHeader(viewModel: viewModel),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                icon: const Icon(Symbols.tune),
                tooltip: '필터 설정',
              ),
              IconButton(
                onPressed: () => _showDeviceInfo(context, viewModel),
                icon: const Icon(Symbols.info),
                tooltip: '정보',
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  tabs: [
                    Tab(
                      icon: const Icon(Symbols.radar),
                      text: '스캔 (${viewModel.discoveries.length})',
                    ),
                    Tab(
                      icon: const Icon(Symbols.favorite),
                      text: '즐겨찾기 (${viewModel.favoriteDiscoveries.length})',
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverFillRemaining(
            child: Column(
              children: [
                SearchControls(viewModel: viewModel),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildScanTab(context, viewModel, state),
                      _buildFavoritesTab(context, viewModel),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      endDrawer: FilterDrawer(viewModel: viewModel),
      floatingActionButton: _buildFloatingActionButton(context, viewModel, state),
    );
  }

  Widget _buildScanTab(BuildContext context, CentralScannerViewModel viewModel, BluetoothLowEnergyState state) {
    if (state != BluetoothLowEnergyState.poweredOn) {
      return _buildStateView(context, state, viewModel);
    }

    final discoveries = viewModel.discoveries;
    
    if (discoveries.isEmpty && !viewModel.discovering) {
      return _buildEmptyState(context, false);
    }
    
    if (discoveries.isEmpty && viewModel.discovering) {
      return _buildEmptyState(context, true);
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (!viewModel.discovering) {
          await viewModel.startDiscovery();
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: discoveries.length,
        itemBuilder: (context, index) {
          final discovery = discoveries[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DeviceCard(
              discovery: discovery,
              viewModel: viewModel,
              onTap: () => _onDeviceTap(context, discovery),
              onLongPress: () => _onDeviceLongPress(context, discovery),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFavoritesTab(BuildContext context, CentralScannerViewModel viewModel) {
    final favorites = viewModel.favoriteDiscoveries;
    
    if (favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.favorite,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '즐겨찾기한 기기가 없습니다',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '기기 카드를 길게 눌러 즐겨찾기에 추가하세요',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final discovery = favorites[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: DeviceCard(
            discovery: discovery,
            viewModel: viewModel,
            onTap: () => _onDeviceTap(context, discovery),
            onLongPress: () => _onDeviceLongPress(context, discovery),
          ),
        );
      },
    );
  }

  Widget _buildStateView(BuildContext context, BluetoothLowEnergyState state, CentralScannerViewModel viewModel) {
    IconData icon;
    Color color;
    String title;
    String subtitle;
    Widget? action;

    switch (state) {
      case BluetoothLowEnergyState.poweredOff:
        icon = Symbols.bluetooth_disabled;
        color = Colors.orange;
        title = '블루투스가 꺼져있습니다';
        subtitle = '설정에서 블루투스를 켜주세요';
        break;
      case BluetoothLowEnergyState.unauthorized:
        icon = Symbols.block;
        color = Colors.red;
        title = '블루투스 권한이 필요합니다';
        subtitle = '설정에서 권한을 허용해주세요';
        action = ElevatedButton.icon(
          onPressed: () => viewModel.showAppSettings(),
          icon: const Icon(Symbols.settings),
          label: const Text('설정으로 이동'),
        );
        break;
      case BluetoothLowEnergyState.unsupported:
        icon = Symbols.error;
        color = Colors.grey;
        title = '블루투스를 지원하지 않습니다';
        subtitle = '이 기기에서는 BLE를 사용할 수 없습니다';
        break;
      default:
        icon = Symbols.bluetooth;
        color = Colors.blue;
        title = '블루투스 준비 중';
        subtitle = '잠시만 기다려주세요';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool scanning) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (scanning) ...[
              const SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 24),
              Text(
                '블루투스 기기를 검색하는 중...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '주변 기기가 검색되면 여기에 표시됩니다',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              Icon(
                Symbols.radar,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                '블루투스 기기를 검색해보세요',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '스캔 버튼을 눌러 주변 기기를 찾을 수 있습니다',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context, CentralScannerViewModel viewModel, BluetoothLowEnergyState state) {
    if (state != BluetoothLowEnergyState.poweredOn) {
      return null;
    }

    final discovering = viewModel.discovering;
    
    return FloatingActionButton.extended(
      onPressed: () async {
        if (discovering) {
          await viewModel.stopDiscovery();
        } else {
          await viewModel.startDiscovery();
        }
      },
      icon: discovering 
          ? const Icon(Symbols.stop) 
          : const Icon(Symbols.search),
      label: Text(discovering ? '중지' : '스캔 시작'),
      backgroundColor: discovering ? Colors.red : Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
    );
  }

  void _onDeviceTap(BuildContext context, DiscoveredEventArgs discovery) {
    // 기기 상세 정보 표시
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _buildDeviceDetailSheet(context, discovery),
    );
  }

  void _onDeviceLongPress(BuildContext context, DiscoveredEventArgs discovery) {
    final viewModel = ViewModel.of<CentralScannerViewModel>(context);
    final uuid = discovery.peripheral.uuid.toString();
    final isFavorite = viewModel.isFavorite(uuid);
    
    viewModel.toggleFavorite(uuid);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorite ? '즐겨찾기에서 제거됨' : '즐겨찾기에 추가됨',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildDeviceDetailSheet(BuildContext context, DiscoveredEventArgs discovery) {
    final name = discovery.advertisement.name ?? '알 수 없는 기기';
    final uuid = discovery.peripheral.uuid;
    final rssi = discovery.rssi;
    final serviceUUIDs = discovery.advertisement.serviceUUIDs;
    final manufacturerData = discovery.advertisement.manufacturerSpecificData;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '기기 정보',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('이름', name),
                  _buildInfoRow('UUID', uuid.toString()),
                  _buildInfoRow('신호강도', '$rssi dBm'),
                  if (serviceUUIDs.isNotEmpty)
                    _buildInfoRow('서비스 수', '${serviceUUIDs.length}개'),
                  if (manufacturerData.isNotEmpty)
                    _buildInfoRow('제조사 데이터', '${manufacturerData.length}개'),
                ],
              ),
            ),
          ),
          if (serviceUUIDs.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '서비스 UUID',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: serviceUUIDs.length,
                itemBuilder: (context, index) {
                  final serviceUuid = serviceUUIDs[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        serviceUuid.toString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showDeviceInfo(BuildContext context, CentralScannerViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('앱 정보'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BLE 중앙 스캐너 v1.0.0'),
            SizedBox(height: 8),
            Text('Bluetooth Low Energy 기기를 검색하고 관리하는 전문 도구입니다.'),
            SizedBox(height: 16),
            Text('주요 기능:'),
            Text('• 실시간 BLE 기기 스캔'),
            Text('• RSSI 기반 신호 강도 표시'),
            Text('• 즐겨찾기 기기 관리'),
            Text('• 고급 필터링 옵션'),
            Text('• 상세한 기기 정보'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}