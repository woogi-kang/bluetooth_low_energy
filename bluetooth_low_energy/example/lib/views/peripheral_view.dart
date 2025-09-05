import 'package:bluetooth_low_energy_example/view_models.dart';
import 'package:clover/clover.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import 'compact_characteristic_view.dart';
import 'compact_service_view.dart';

class PeripheralView extends StatefulWidget {
  const PeripheralView({super.key});

  @override
  State<PeripheralView> createState() => _PeripheralViewState();
}

class _PeripheralViewState extends State<PeripheralView> with SingleTickerProviderStateMixin {
  bool _isConnecting = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animationController.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryAutoConnect();
    });
  }

  void _tryAutoConnect() async {
    final viewModel = ViewModel.of<PeripheralViewModel>(context);
    if (!viewModel.connected) {
      setState(() => _isConnecting = true);
      try {
        await viewModel.connect();
        await viewModel.discoverGATT();
      } catch (e) {
        if (mounted) {
          _showConnectionError(e.toString());
        }
      } finally {
        if (mounted) {
          setState(() => _isConnecting = false);
        }
      }
    }
  }

  void _showConnectionError(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Symbols.error, color: Colors.red),
        title: const Text('연결 실패'),
        content: Text('기기에 연결할 수 없습니다.\n\n$error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _tryAutoConnect();
            },
            child: const Text('재시도'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ViewModel.of<PeripheralViewModel>(context);
    final connected = viewModel.connected;
    final serviceViewModels = viewModel.serviceViewModels;
    final deviceName = viewModel.name ?? '알 수 없는 기기';
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 48, // 작은 화면에 맞게 높이 줄임
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          deviceName.length > 15 ? '${deviceName.substring(0, 15)}...' : deviceName,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          _buildConnectionButton(viewModel, connected),
        ],
      ),
      body: _buildCompactBody(connected, serviceViewModels),
    );
  }

  Widget _buildCompactBody(bool connected, List<ServiceViewModel> serviceViewModels) {
    return Column(
      children: [
        // 상태 헤더 - 작게 만듦
        _buildCompactStatusHeader(connected),
        // 메인 컨텐츠 영역
        Expanded(
          child: _buildMainContent(connected, serviceViewModels),
        ),
      ],
    );
  }

  Widget _buildMainContent(bool connected, List<ServiceViewModel> serviceViewModels) {
    if (_isConnecting) {
      return _buildCompactConnectingView();
    } else if (!connected) {
      return _buildCompactDisconnectedView();
    } else if (serviceViewModels.isEmpty) {
      return _buildCompactEmptyView();
    } else {
      return AnimatedOpacity(
        opacity: _animationController.isCompleted ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 500),
        child: _buildCompactServicesView(serviceViewModels),
      );
    }
  }







  Widget _buildCompactStatusHeader(bool connected) {
    final viewModel = ViewModel.of<PeripheralViewModel>(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: connected ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: connected ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            connected ? Symbols.check_circle : Symbols.error,
            color: connected ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connected ? '연결됨' : '연결안됨',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: connected ? Colors.green : Colors.red,
                  ),
                ),
                Text(
                  viewModel.uuid.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactConnectingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 16),
          Text(
            '연결 중...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDisconnectedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Symbols.bluetooth_disabled,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            '연결이 끊어졌습니다',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _tryAutoConnect,
            icon: Icon(Symbols.refresh, size: 16),
            label: const Text('다시 연결'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Symbols.device_unknown,
            size: 48,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          Text(
            '서비스를 찾을 수 없습니다',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactServicesView(List<ServiceViewModel> serviceViewModels) {
    return Scrollbar(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 작은 헤더
            Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Icon(
                    Symbols.list_alt,
                    color: Theme.of(context).colorScheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'GATT 서비스 (${serviceViewModels.length}개)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // 서비스 목록을 단순한 리스트로 표시
            ...serviceViewModels.map((serviceViewModel) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InheritedViewModel(
                  viewModel: serviceViewModel,
                  view: const CompactServiceView(),
                ),
                // 해당 서비스의 특성들 표시
                ...serviceViewModel.characteristicViewModels.map((charViewModel) => 
                  InheritedViewModel(
                    viewModel: charViewModel,
                    view: const CompactCharacteristicView(),
                  )
                ),
              ],
            )),
            const SizedBox(height: 80), // 더 큰 하단 여백으로 스크롤 여유 공간 확보
          ],
        ),
      ),
    );
  }


  Widget _buildConnectionButton(PeripheralViewModel viewModel, bool connected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ElevatedButton(
        onPressed: _isConnecting ? null : () async {
          if (connected) {
            await viewModel.disconnect();
          } else {
            _tryAutoConnect();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: connected ? Colors.red : Colors.blue,
          foregroundColor: Colors.white,
          minimumSize: const Size(60, 32),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        child: _isConnecting 
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                connected ? '해제' : '연결',
                style: const TextStyle(fontSize: 12),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }


}
