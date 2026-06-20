import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../l10n/app_localizations.dart';
import '../models/map_building_model.dart';
import '../services/map_parser_service.dart';
import '../widgets/campus_map_painter.dart';

class MapScreen extends StatefulWidget {
  final bool embed;
  final String? targetRoomCode;
  const MapScreen({super.key, this.embed = false, this.targetRoomCode});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final GlobalKey _mapKey = GlobalKey();
  List<SvgPathData> _paths = [];
  List<MapBuilding> _buildings = [];
  String? _selectedBuildingId;
  String? _previouslySelectedBuildingId;
  Rect _totalBounds = Rect.zero;
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  final TransformationController _transformationController =
      TransformationController();
  List<MapBuilding> _searchResults = [];

  late AnimationController _animationController;
  Animation<Matrix4>? _mapAnimation;

  late AnimationController _labelOpacityController;
  late Animation<double> _labelOpacityAnimation;
  String? _pendingZoomBuildingId;
  String? _queryRoomCode;

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
      _pendingZoomBuildingId = null;
      _queryRoomCode = null;
    } else {
      _previouslySelectedBuildingId = null;
      _queryRoomCode = null;
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
      final buildings = jsonList
          .map((item) => MapBuilding.fromJson(item))
          .toList();

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

        if (widget.targetRoomCode != null && widget.targetRoomCode!.isNotEmpty) {
          _handleAutoTargetRoom(widget.targetRoomCode!, buildings);
        }
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

  void _handleAutoTargetRoom(String roomCode, List<MapBuilding> buildings) {
    final regExp = RegExp(r'^([A-Za-z]+)(\d*)');
    final match = regExp.firstMatch(roomCode.trim());
    if (match == null) return;

    final String codePrefix = match.group(1)!.toUpperCase();

    MapBuilding? targetBuilding;
    for (var b in buildings) {
      final bIdUpper = b.id.toUpperCase();
      if (bIdUpper.endsWith('-$codePrefix') ||
          b.aliases.any((alias) => alias.toUpperCase() == codePrefix)) {
        targetBuilding = b;
        break;
      }
    }

    if (targetBuilding != null) {
      final bId = targetBuilding.id;
      _updateSelection(bId);

      setState(() {
        _queryRoomCode = roomCode;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final renderBox = _mapKey.currentContext?.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            _zoomToBuilding(bId, renderBox.size);
          }
        }
      });
    }
  }

  void _animateToMatrix(Matrix4 targetMatrix) {
    _mapAnimation =
        Matrix4Tween(
          begin: _transformationController.value,
          end: targetMatrix,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOutCubic,
          ),
        );
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

    final double scaleX = viewportSize.width / _totalBounds.width;
    final double scaleY = viewportSize.height / _totalBounds.height;
    double fitScale = scaleX < scaleY ? scaleX : scaleY;
    fitScale *= 0.95;

    double fitOffsetX =
        (viewportSize.width - _totalBounds.width * fitScale) / 2 -
        _totalBounds.left * fitScale;
    double fitOffsetY =
        (viewportSize.height - _totalBounds.height * fitScale) / 2 -
        _totalBounds.top * fitScale;

    double bCenterX =
        (buildingBounds.left + buildingBounds.width / 2) * fitScale +
        fitOffsetX;
    double bCenterY =
        (buildingBounds.top + buildingBounds.height / 2) * fitScale +
        fitOffsetY;

    double targetZoom = 2.5;

    double tx = viewportSize.width / 2 - bCenterX * targetZoom;
    double ty = viewportSize.height / 2 - bCenterY * targetZoom;

    final targetMatrix = Matrix4.diagonal3Values(targetZoom, targetZoom, 1.0)
      ..setTranslationRaw(tx, ty, 0.0);

    _animateToMatrix(targetMatrix);
  }

  void _handleMapTap(Offset localPosition, Size viewportSize) {
    FocusScope.of(context).unfocus();
    if (_totalBounds.isEmpty || _paths.isEmpty) return;

    double scaleX = viewportSize.width / _totalBounds.width;
    double scaleY = viewportSize.height / _totalBounds.height;
    double fitScale = scaleX < scaleY ? scaleX : scaleY;
    fitScale *= 0.95;

    double fitOffsetX =
        (viewportSize.width - _totalBounds.width * fitScale) / 2 -
        _totalBounds.left * fitScale;
    double fitOffsetY =
        (viewportSize.height - _totalBounds.height * fitScale) / 2 -
        _totalBounds.top * fitScale;

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
        description: AppLocalizations.of(context).mapNoDescription,
      ),
    );


    return Card(
      elevation: 6,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
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
            if (_queryRoomCode != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_rounded, size: 14, color: colorScheme.secondary),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context).mapQueryRoom(_queryRoomCode ?? ''),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (building.keyLocations.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: building.keyLocations.map((loc) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer.withValues(
                        alpha: 0.6,
                      ),
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
                    label: Text(
                      AppLocalizations.of(context).mapExternalNav,
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.layers_outlined, size: 16),
                    label: Text(
                      _queryRoomCode != null
                          ? AppLocalizations.of(context)
                              .mapFloorPlanUnavailable(_queryRoomCode!)
                          : AppLocalizations.of(context)
                              .mapFloorPlanUnderConstruction,
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      backgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: null,
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
      _pendingZoomBuildingId = building.id;
    });
    _updateSelection(building.id);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      final loadingBody = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context).mapLoadingText),
          ],
        ),
      );

      if (widget.embed) {
        return loadingBody;
      }
      return Scaffold(body: loadingBody);
    }

    final bodyContent = LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);

        if (_pendingZoomBuildingId != null) {
          final viewInsetsBottom = mediaQuery.viewInsets.bottom;
          if (viewInsetsBottom == 0) {
            final buildingId = _pendingZoomBuildingId!;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _pendingZoomBuildingId == buildingId) {
                setState(() {
                  _pendingZoomBuildingId = null;
                });
                _zoomToBuilding(buildingId, viewportSize);
              }
            });
          }
        }

        return Stack(
          key: _mapKey,
          children: [
            InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.8,
              maxScale: 6.0,
              boundaryMargin: const EdgeInsets.all(200),
              child: GestureDetector(
                onTapUp: (details) =>
                    _handleMapTap(details.localPosition, viewportSize),
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
                      themePrimaryContainerColor: colorScheme.primaryContainer
                          .withValues(alpha: 0.7),
                      baseBackgroundColor: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!widget.embed) ...[
                    IconButton.filled(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.surface,
                        foregroundColor: colorScheme.onSurface,
                        minimumSize: const Size(56, 56),
                        maximumSize: const Size(56, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 1,
                        shadowColor: Colors.black.withValues(alpha: 0.1),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      children: [
                        SearchBar(
                          controller: _searchController,
                          hintText: AppLocalizations.of(context).mapSearchHint,
                          leading: const Icon(Icons.search),
                          trailing: _searchController.text.isNotEmpty
                              ? [
                                  IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                    },
                                  ),
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
                                ),
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
                                    leading: const Icon(
                                      Icons.location_city_outlined,
                                    ),
                                    title: Text(building.name),
                                    subtitle: Text(
                                      building.keyLocations.isNotEmpty
                                          ? building.keyLocations.join(", ")
                                          : building.description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onTap: () => _selectSearchResult(
                                      building,
                                      viewportSize,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
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
      body: SafeArea(child: bodyContent),
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

// Mock floor screen removed for production release to avoid exposing
// hard-coded test floor-plan data. If you need to restore or replace
// this with a production-ready floor plan viewer, implement a
// proper screen that loads data from assets or a backend.

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
        corridorRect.left +
            (corridorRect.width - textPainterCorridor.width) / 2,
        corridorRect.top +
            (corridorRect.height - textPainterCorridor.height) / 2,
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
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
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
