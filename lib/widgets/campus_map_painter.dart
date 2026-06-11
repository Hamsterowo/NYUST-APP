import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/map_building_model.dart';
import '../services/map_parser_service.dart';

class CampusMapPainter extends CustomPainter {
  final List<SvgPathData> paths;
  final String? selectedId;
  final String? previouslySelectedId;
  final Rect totalBounds;
  final Color themePrimaryColor;
  final Color themePrimaryContainerColor;
  final Color baseBackgroundColor;
  final TransformationController transformationController;
  final Animation<double> labelOpacityAnimation;
  final List<MapBuilding> buildings;

  CampusMapPainter({
    required this.paths,
    required this.selectedId,
    required this.previouslySelectedId,
    required this.totalBounds,
    required this.themePrimaryColor,
    required this.themePrimaryContainerColor,
    required this.baseBackgroundColor,
    required this.transformationController,
    required this.labelOpacityAnimation,
    required this.buildings,
  }) : super(repaint: Listenable.merge([transformationController, labelOpacityAnimation]));

  @override
  void paint(Canvas canvas, Size size) {
    if (paths.isEmpty || totalBounds.isEmpty) return;

    double scaleX = size.width / totalBounds.width;
    double scaleY = size.height / totalBounds.height;
    double scale = scaleX < scaleY ? scaleX : scaleY;
    scale *= 0.95;

    double offsetX = (size.width - totalBounds.width * scale) / 2 - totalBounds.left * scale;
    double offsetY = (size.height - totalBounds.height * scale) / 2 - totalBounds.top * scale;

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);

    final bgRect = totalBounds.inflate(100.0);
    final bgRRect = RRect.fromRectAndRadius(bgRect, const Radius.circular(32.0));

    final bgPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = baseBackgroundColor;
    canvas.drawRRect(bgRRect, bgPaint);

    final bgStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 / scale
      ..color = themePrimaryColor.withValues(alpha: 0.15);
    canvas.drawRRect(bgRRect, bgStrokePaint);

    final fillPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()..style = PaintingStyle.stroke;

    for (var data in paths) {
      final isSelected = selectedId != null && data.id == selectedId;

      if (isSelected) {
        fillPaint.color = themePrimaryContainerColor;
      } else {
        fillPaint.color = data.fillColor ?? const Color(0x00000000);
      }

      if (fillPaint.color.a > 0) {
        canvas.drawPath(data.path, fillPaint);
      }

      if (isSelected) {
        strokePaint.color = themePrimaryColor;
        strokePaint.strokeWidth = 2.5 / scale;
      } else {
        strokePaint.color = data.strokeColor ?? const Color(0xFF000000);
        strokePaint.strokeWidth = 1.0 / scale;
      }

      if (strokePaint.color.a > 0) {
        canvas.drawPath(data.path, strokePaint);
      }
    }

    final double labelOpacity = labelOpacityAnimation.value;

    if (labelOpacity > 0.05 || selectedId != null || previouslySelectedId != null) {
      final textPainter = TextPainter(textDirection: TextDirection.ltr);
      final Set<String> drawnIds = {};

      for (var data in paths) {
        if (data.id.isEmpty || drawnIds.contains(data.id)) continue;

        final isSelectedBuilding = (selectedId != null && data.id == selectedId) ||
            (previouslySelectedId != null && data.id == previouslySelectedId);
        final double itemOpacity = isSelectedBuilding ? 1.0 : labelOpacity;

        if (itemOpacity <= 0.05) continue;

        String labelText = '';
        bool isBlock = data.id.startsWith('block-');

        if (data.isBuilding) {
          final building = buildings.firstWhere(
            (b) => b.id == data.id,
            orElse: () => MapBuilding(
              id: data.id,
              name: '',
              aliases: [],
              keyLocations: [],
              description: '',
            ),
          );
          if (building.name.isNotEmpty) {

            labelText = building.aliases.isNotEmpty
                ? building.aliases.first
                : building.name.substring(0, math.min(4, building.name.length));
          }
        } else if (isBlock) {

          if (data.id == 'block-A') labelText = '活動中心區';
          if (data.id == 'block-management') labelText = '管理學院';
          if (data.id == 'block-engineering') labelText = '工程學院';
          if (data.id == 'block-haas') labelText = '人文科學院';
          if (data.id == 'block-design') labelText = '設計學院';
          if (data.id == 'block-sports field') labelText = '體育場區';
        }

        if (labelText.isNotEmpty) {
          drawnIds.add(data.id);

          final bounds = data.path.getBounds();
          final center = bounds.center;

          final textColor = isBlock
              ? themePrimaryColor.withValues(alpha: itemOpacity)
              : const Color(0xFF151515).withValues(alpha: itemOpacity);

          final double fontSize = isBlock ? 26.0 : 17.0;

          textPainter.text = TextSpan(
            text: labelText,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          );
          textPainter.layout();
          final textOffset = Offset(
            center.dx - textPainter.width / 2,
            center.dy - textPainter.height / 2,
          );

          textPainter.text = TextSpan(
            text: labelText,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 3.5
                ..strokeCap = StrokeCap.round
                ..strokeJoin = StrokeJoin.round
                ..color = Colors.white.withValues(alpha: itemOpacity),
            ),
          );
          textPainter.layout();
          textPainter.paint(canvas, textOffset);

          textPainter.text = TextSpan(
            text: labelText,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          );
          textPainter.layout();
          textPainter.paint(canvas, textOffset);
        }
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CampusMapPainter oldDelegate) {
    return oldDelegate.selectedId != selectedId ||
        oldDelegate.previouslySelectedId != previouslySelectedId ||
        oldDelegate.paths != paths ||
        oldDelegate.totalBounds != totalBounds ||
        oldDelegate.themePrimaryColor != themePrimaryColor ||
        oldDelegate.themePrimaryContainerColor != themePrimaryContainerColor ||
        oldDelegate.baseBackgroundColor != baseBackgroundColor ||
        oldDelegate.labelOpacityAnimation.value != labelOpacityAnimation.value ||
        oldDelegate.buildings != buildings;
  }
}
