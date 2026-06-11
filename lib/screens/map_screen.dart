import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/map_building_model.dart';
import '../services/map_parser_service.dart';
import '../widgets/campus_map_painter.dart';

class MapScreen extends StatefulWidget {
  final bool embed;
  const MapScreen({super.key, this.embed = false});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  List<SvgPathData> _paths = [];
  List<MapBuilding> _buildings = [];
  String? _selectedBuildingId;
  String? _previouslySelectedBuildingId;
  Rect _totalBounds = Rect.zero;
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  final TransformationController _transformationController = TransformationController();
  List<MapBuilding> _searchResults = [];

  late AnimationController _animationController;
  Animation<Matrix4>? _mapAnimation;

  late AnimationController _labelOpacityController;
  late Animation<double> _labelOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animationController.addListener(() {
      if (_mapAnimation != null) {
        _transformationController.value = _mapAnimation!.value;
      }
    });

    _labelOpacityController = AnimationController(
      duration: const Duration(milliseconds: 300),
      value: 1.0,
      vsync: this,
    );
    _labelOpacityAnimation = CurvedAnimation(
      parent: _labelOpacityController,
      curve: Curves.easeInOut,
    );

    _loadMapData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _labelOpacityController.dispose();
    _searchController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _updateSelection(String? buildingId) {
    if (_selectedBuildingId == buildingId) return;

    if (buildingId == null) {

      _previouslySelectedBuildingId = _selectedBuildingId;
    } else {

      _previouslySelectedBuildingId = null;
    }

    setState(() {
      _selectedBuildingId = buildingId;
    });

    if (buildingId != null) {
      _labelOpacityController.reverse();
    } else {
      _labelOpacityController.forward();
    }
  }

  Future<void> _loadMapData() async {
    try {

      final paths = await MapParserService.parseMapSvg('assets/map.svg');

      final jsonString = await rootBundle.loadString('assets/map_data.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      final buildings = jsonList.map((item) => MapBuilding.fromJson(item)).toList();

      Rect totalBounds = Rect.zero;
      for (var p in paths) {
        final bounds = p.path.getBounds();
        if (totalBounds == Rect.zero) {
          totalBounds = bounds;
        } else {
          totalBounds = totalBounds.expandToInclude(bounds);
        }
      }

      if (mounted) {
        setState(() {
          _paths = paths;
          _buildings = buildings;
          _totalBounds = totalBounds;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading map data: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _animateToMatrix(Matrix4 targetMatrix) {
    _mapAnimation = Matrix4Tween(
      begin: _transformationController.value,
      end: targetMatrix,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));
    _animationController.forward(from: 0.0);
  }

  void _zoomToBuilding(String buildingId, Size viewportSize) {

    Rect buildingBounds = Rect.zero;
    for (var pathData in _paths) {
      if (pathData.id == buildingId) {
        final bounds = pathData.path.getBounds();
        if (buildingBounds == Rect.zero) {
          buildingBounds = bounds;
        } else {
          buildingBounds = buildingBounds.expandToInclude(bounds);
        }
      }
    }

    if (buildingBounds == Rect.zero || _totalBounds.isEmpty) return;

    double scaleX = viewportSize.width / _totalBounds.width;
    double scaleY = viewportSize.height / _totalBounds.height;
    double fitScale = scaleX < scaleY ? scaleX : scaleY;
    fitScale *= 0.95;

    double fitOffsetX = (viewportSize.width - _totalBounds.width * fitScale) / 2 - _totalBounds.left * fitScale;
    double fitOffsetY = (viewportSize.height - _totalBounds.height * fitScale) / 2 - _totalBounds.top * fitScale;

    double bCenterX = (buildingBounds.left + buildingBounds.width / 2) * fitScale + fitOffsetX;
    double bCenterY = (buildingBounds.top + buildingBounds.height / 2) * fitScale + fitOffsetY;

    double targetZoom = 2.5;

    double tx = viewportSize.width / 2 - bCenterX * targetZoom;
    double ty = viewportSize.height / 2 - bCenterY * targetZoom;

    final targetMatrix = Matrix4.diagonal3Values(targetZoom, targetZoom, 1.0)
      ..setTranslationRaw(tx, ty, 0.0);

    _animateToMatrix(targetMatrix);
  }

  void _handleMapTap(Offset localPosition, Size viewportSize) {
    if (_totalBounds.isEmpty || _paths.isEmpty) return;

    double scaleX = viewportSize.width / _totalBounds.width;
    double scaleY = viewportSize.height / _totalBounds.height;
    double fitScale = scaleX < scaleY ? scaleX : scaleY;
    fitScale *= 0.95;

    double fitOffsetX = (viewportSize.width - _totalBounds.width * fitScale) / 2 - _totalBounds.left * fitScale;
    double fitOffsetY = (viewportSize.height - _totalBounds.height * fitScale) / 2 - _totalBounds.top * fitScale;

    final double svgX = (localPosition.dx - fitOffsetX) / fitScale;
    final double svgY = (localPosition.dy - fitOffsetY) / fitScale;
    final Offset svgTouchPoint = Offset(svgX, svgY);

    String? tappedId;
    for (var data in _paths) {
      if (data.isBuilding && data.path.contains(svgTouchPoint)) {
        tappedId = data.id;
      }
    }

    if (tappedId != null) {
      _updateSelection(tappedId);

      _zoomToBuilding(tappedId, viewportSize);
    } else {

      _updateSelection(null);
    }
  }

  Widget _buildFloatingInfoCard(ColorScheme colorScheme) {
    if (_selectedBuildingId == null) return const SizedBox.shrink();

    final building = _buildings.firstWhere(
      (b) => b.id == _selectedBuildingId,
      orElse: () => MapBuilding(
        id: _selectedBuildingId!,
        name: _selectedBuildingId!.replaceAll('building-', '').toUpperCase(),
        aliases: [],
        keyLocations: [],
        description: '暫無此建築物之詳細介紹。',
      ),
    );

    final bool hasFloorPlan = building.id == 'building-EL';

    return Card(
      elevation: 6,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      color: colorScheme.surface.withValues(alpha: 0.95),
      shadowColor: Colors.black.withValues(alpha: 0.15),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          building.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          building.id.replaceAll('building-', '').toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    _updateSelection(null);
                  },
                ),
              ],
            ),
            if (building.keyLocations.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: building.keyLocations.map((loc) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      loc,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ] else ...[
              const SizedBox(height: 4),
            ],

            Text(
              building.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.navigation_outlined, size: 16),
                    label: const Text('外部地圖導航', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {

                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.layers_outlined, size: 16),
                    label: Text(
                      hasFloorPlan ? '進入平面圖' : '平面圖建置中',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      backgroundColor: hasFloorPlan ? null : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: hasFloorPlan
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MockFloorScreen(
                                  buildingName: building.name,
                                ),
                              ),
                            );
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final results = _buildings.where((b) => b.matches(query)).toList();
    setState(() {
      _searchResults = results;
    });
  }

  void _selectSearchResult(MapBuilding building, Size viewportSize) {
    _searchController.text = building.name;
    FocusScope.of(context).unfocus();

    setState(() {
      _searchResults = [];
    });
    _updateSelection(building.id);

    _zoomToBuilding(building.id, viewportSize);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      final loadingBody = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在繪製向量校園地圖...'),
          ],
        ),
      );

      if (widget.embed) {
        return loadingBody;
      }
      return Scaffold(
        body: loadingBody,
      );
    }

    final bodyContent = LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);

        return Stack(
          children: [
            InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.8,
              maxScale: 6.0,
              boundaryMargin: const EdgeInsets.all(200),
              child: GestureDetector(
                onTapUp: (details) => _handleMapTap(details.localPosition, viewportSize),
                child: SizedBox(
                  width: viewportSize.width,
                  height: viewportSize.height,
                  child: CustomPaint(
                    painter: CampusMapPainter(
                      paths: _paths,
                      selectedId: _selectedBuildingId,
                      previouslySelectedId: _previouslySelectedBuildingId,
                      totalBounds: _totalBounds,
                      themePrimaryColor: colorScheme.primary,
                      themePrimaryContainerColor: colorScheme.primaryContainer.withValues(alpha: 0.7),
                      baseBackgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      transformationController: _transformationController,
                      labelOpacityAnimation: _labelOpacityAnimation,
                      buildings: _buildings,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  SearchBar(
                    controller: _searchController,
                    hintText: '搜尋校園大樓 (例: 工五, 5, 活動中心)...',
                    leading: const Icon(Icons.search),
                    trailing: _searchController.text.isNotEmpty
                        ? [
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          ]
                        : null,
                    onChanged: _onSearchChanged,
                  ),
                  if (_searchResults.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 250),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final building = _searchResults[index];
                            return ListTile(
                              leading: const Icon(Icons.location_city_outlined),
                              title: Text(building.name),
                              subtitle: Text(
                                building.keyLocations.isNotEmpty
                                    ? '主要單位: ${building.keyLocations.join(", ")}'
                                    : building.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => _selectSearchResult(building, viewportSize),
                            );
                          },
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              bottom: _selectedBuildingId != null ? 195 : 24,
              right: 24,
              child: FloatingActionButton.small(
                heroTag: 'reset_zoom',
                onPressed: () {
                  _animateToMatrix(Matrix4.identity());
                  _updateSelection(null);
                  setState(() {
                    _searchController.clear();
                    _searchResults = [];
                  });
                },
                child: const Icon(Icons.zoom_out_map),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              left: 16,
              right: 16,
              bottom: _selectedBuildingId != null ? 16 : -220,
              child: _buildFloatingInfoCard(colorScheme),
            ),
          ],
        );
      },
    );

    if (widget.embed) {
      return bodyContent;
    }

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      body: SafeArea(
        child: bodyContent,
      ),
    );
  }
}

class FloorRoom {
  final String code;
  final String name;
  final Rect rect;
  final bool isService;

  FloorRoom({
    required this.code,
    required this.name,
    required this.rect,
    this.isService = false,
  });
}

class MockFloorScreen extends StatefulWidget {
  final String buildingName;

  const MockFloorScreen({
    super.key,
    required this.buildingName,
  });

  @override
  State<MockFloorScreen> createState() => _MockFloorScreenState();
}

class _MockFloorScreenState extends State<MockFloorScreen> {
  String _currentFloor = '1F';
  String? _selectedRoomCode;
  bool _isFloorLeverExpanded = false;
  Timer? _floorLeverTimer;

  @override
  void dispose() {
    _floorLeverTimer?.cancel();
    super.dispose();
  }

  void _resetFloorLeverTimer() {
    _floorLeverTimer?.cancel();
    _floorLeverTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isFloorLeverExpanded = false;
        });
      }
    });
  }

  String _getRoomName(String code) {
    switch (code) {

      case 'EL101': return '資工系多媒體教室';
      case 'EL102': return '電子系微處理器實驗室';
      case 'EL105': return '資訊工程學系系辦公室';
      case 'EL108': return '研討會議室';
      case 'EL110': return '電力實驗室';

      case 'EL201': return '電機系辦公室';
      case 'EL202': return '自動控制實驗室';
      case 'EL205': return '嵌入式系統晶片實驗室';
      case 'EL208': return '電力電子研究室';
      case 'EL210': return '感測器研究室';

      case 'EL301': return '第二PC電腦教室';
      case 'EL302': return '微處理機實驗室';
      case 'EL305': return '機器人導引與控制實驗室';
      case 'EL308': return '智慧機器人與自動化實驗室';
      case 'EL310': return '自動化檢測實驗室';

      case 'EL401': return '通信系統實驗室';
      case 'EL402': return '無人載具系統整合實驗室';
      case 'EL405': return '通訊組會議室';
      case 'EL408': return '射頻電路實驗室';
      case 'EL410': return '視訊與影像處理實驗室';

      case 'EL501': return '研究生工作室一';
      case 'EL502': return '研究生工作室二';
      case 'EL505': return '電力與能源研發中心';
      case 'EL508': return '電磁干擾實驗室';
      case 'EL510': return '高壓發電機房';
      default: return '學術研究室';
    }
  }

  List<FloorRoom> _getCurrentFloorRooms() {
    final fNum = _currentFloor.replaceAll('F', '');
    return [
      FloorRoom(
        code: 'EL${fNum}01',
        name: _getRoomName('EL${fNum}01'),
        rect: const Rect.fromLTWH(40, 40, 120, 120),
      ),
      FloorRoom(
        code: 'EL${fNum}02',
        name: _getRoomName('EL${fNum}02'),
        rect: const Rect.fromLTWH(170, 40, 120, 120),
      ),
      FloorRoom(
        code: '樓梯/電梯',
        name: '垂直交通區',
        rect: const Rect.fromLTWH(300, 40, 120, 120),
        isService: true,
      ),
      FloorRoom(
        code: 'EL${fNum}05',
        name: _getRoomName('EL${fNum}05'),
        rect: const Rect.fromLTWH(430, 40, 130, 120),
      ),
      FloorRoom(
        code: '盥洗室',
        name: '公共服務區',
        rect: const Rect.fromLTWH(40, 240, 120, 120),
        isService: true,
      ),
      FloorRoom(
        code: 'EL${fNum}08',
        name: _getRoomName('EL${fNum}08'),
        rect: const Rect.fromLTWH(170, 240, 120, 120),
      ),
      FloorRoom(
        code: '機電室',
        name: '機電控制區',
        rect: const Rect.fromLTWH(300, 240, 120, 120),
        isService: true,
      ),
      FloorRoom(
        code: 'EL${fNum}10',
        name: _getRoomName('EL${fNum}10'),
        rect: const Rect.fromLTWH(430, 240, 130, 120),
      ),
    ];
  }

  void _handleFloorPlanTap(Offset localPos) {
    final rooms = _getCurrentFloorRooms();
    for (var room in rooms) {
      if (room.rect.contains(localPos)) {
        if (room.isService) return;
        setState(() {
          if (_selectedRoomCode == room.code) {
            _selectedRoomCode = null;
          } else {
            _selectedRoomCode = room.code;
          }
        });
        return;
      }
    }
    setState(() {
      _selectedRoomCode = null;
    });
  }

  void _showRoomListSheet(BuildContext context, ColorScheme colorScheme) {
    final rooms = _getCurrentFloorRooms().where((r) => !r.isService).toList();

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: colorScheme.surface,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Text(
                  '${widget.buildingName} - $_currentFloor 空間配置',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: rooms.length,
                  itemBuilder: (context, idx) {
                    final room = rooms[idx];
                    final isSelected = _selectedRoomCode == room.code;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSelected
                            ? colorScheme.primary
                            : colorScheme.primary.withValues(alpha: 0.1),
                        foregroundColor: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.primary,
                        child: const Icon(Icons.meeting_room_outlined),
                      ),
                      title: Text(
                        room.code,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(room.name),
                      selected: isSelected,
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: colorScheme.primary)
                          : const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _selectedRoomCode = room.code;
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloorLever(ColorScheme colorScheme) {
    final floors = ['5F', '4F', '3F', '2F', '1F'];
    final activeIndex = floors.indexOf(_currentFloor);

    return GestureDetector(
      onTap: _resetFloorLeverTimer,
      child: Container(
        width: 48,
        height: 250,
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [

            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubic,
              left: 2,
              top: 8 + activeIndex * 48,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),

            ...List.generate(floors.length, (idx) {
              final floorText = floors[idx];
              final isCurrent = floorText == _currentFloor;
              return Positioned(
                left: 2,
                top: 8 + idx * 48,
                width: 42,
                height: 42,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentFloor = floorText;
                      _selectedRoomCode = null;
                    });
                    _resetFloorLeverTimer();
                  },
                  child: Container(
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        color: isCurrent ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      child: Text(floorText),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFloorLeverTrigger(ColorScheme colorScheme) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            setState(() {
              _isFloorLeverExpanded = true;
            });
            _resetFloorLeverTimer();
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _currentFloor,
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  height: 1.1,
                ),
              ),
              Icon(
                Icons.unfold_more,
                size: 14,
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.buildingName} 平面圖'),
        backgroundColor: colorScheme.surface,
      ),
      body: SafeArea(
        child: Stack(
          children: [

            Positioned.fill(
              child: Container(
                color: colorScheme.surfaceContainerLowest,
                child: InteractiveViewer(
                  maxScale: 4.0,
                  minScale: 0.5,
                  child: Center(
                    child: SizedBox(
                      width: 600,
                      height: 400,
                      child: GestureDetector(
                        onTapUp: (details) {
                          _handleFloorPlanTap(details.localPosition);
                        },
                        child: CustomPaint(
                          size: const Size(600, 400),
                          painter: FloorPlanPainter(
                            floor: _currentFloor,
                            rooms: _getCurrentFloorRooms(),
                            selectedRoomCode: _selectedRoomCode,
                            colorScheme: colorScheme,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              left: _isFloorLeverExpanded ? 16 : -60,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildFloorLever(colorScheme),
              ),
            ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              left: _isFloorLeverExpanded ? -60 : 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildFloorLeverTrigger(colorScheme),
              ),
            ),

            Positioned(
              right: 24,
              bottom: 24,
              child: FloatingActionButton(
                heroTag: 'floor_plan_list',
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                child: const Icon(Icons.format_list_bulleted),
                onPressed: () => _showRoomListSheet(context, colorScheme),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FloorPlanPainter extends CustomPainter {
  final String floor;
  final List<FloorRoom> rooms;
  final String? selectedRoomCode;
  final ColorScheme colorScheme;

  FloorPlanPainter({
    required this.floor,
    required this.rooms,
    required this.selectedRoomCode,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {

    final paintBg = Paint()
      ..color = colorScheme.surfaceContainerLow
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(16),
      ),
      paintBg,
    );

    final paintOuterBorder = Paint()
      ..color = colorScheme.outlineVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(16),
      ),
      paintOuterBorder,
    );

    final corridorRect = const Rect.fromLTWH(40, 160, 520, 80);
    final paintCorridor = Paint()
      ..color = colorScheme.surfaceContainerHigh
      ..style = PaintingStyle.fill;
    canvas.drawRect(corridorRect, paintCorridor);

    final paintCorridorBorder = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(corridorRect, paintCorridorBorder);

    final textPainterCorridor = TextPainter(
      text: TextSpan(
        text: '中 央 走 廊 (Corridor)',
        style: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 4.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainterCorridor.layout();
    textPainterCorridor.paint(
      canvas,
      Offset(
        corridorRect.left + (corridorRect.width - textPainterCorridor.width) / 2,
        corridorRect.top + (corridorRect.height - textPainterCorridor.height) / 2,
      ),
    );

    for (var room in rooms) {
      final isSelected = selectedRoomCode == room.code;

      final paintRoom = Paint();
      if (isSelected) {
        paintRoom.color = colorScheme.primaryContainer;
      } else if (room.isService) {
        paintRoom.color = colorScheme.surfaceContainer;
      } else {
        paintRoom.color = colorScheme.surface;
      }
      paintRoom.style = PaintingStyle.fill;
      canvas.drawRect(room.rect, paintRoom);

      final paintRoomBorder = Paint()
        ..color = isSelected ? colorScheme.primary : colorScheme.outlineVariant
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3.0 : 1.5;
      canvas.drawRect(room.rect, paintRoomBorder);

      if (isSelected) {
        final glowPaint = Paint()
          ..color = colorScheme.primary.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
        canvas.drawRect(room.rect, glowPaint);
      }

      final textSpan = TextSpan(
        children: [
          TextSpan(
            text: '${room.code}\n',
            style: TextStyle(
              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              height: 1.3,
            ),
          ),
          TextSpan(
            text: room.name,
            style: TextStyle(
              color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
              fontSize: 10,
              height: 1.3,
            ),
          ),
        ],
      );

      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: room.rect.width - 10);
      textPainter.paint(
        canvas,
        Offset(
          room.rect.left + (room.rect.width - textPainter.width) / 2,
          room.rect.top + (room.rect.height - textPainter.height) / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant FloorPlanPainter oldDelegate) {
    return oldDelegate.floor != floor ||
        oldDelegate.selectedRoomCode != selectedRoomCode ||
        oldDelegate.rooms != rooms;
  }
}
