import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/config/env.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_view.dart';

class ShipMapPoint {
  const ShipMapPoint({
    required this.id,
    required this.title,
    required this.latitude,
    required this.longitude,
    this.subtitle,
    this.isActive = true,
  });

  final String id;
  final String title;
  final double latitude;
  final double longitude;
  final String? subtitle;
  final bool isActive;

  bool get hasCoordinate => latitude != 0 || longitude != 0;
}

class ShipMapCard extends StatelessWidget {
  const ShipMapCard({
    required this.points,
    required this.accent,
    this.onRefresh,
    this.isRefreshing = false,
    this.height = 176,
    this.emptyTitle = 'Lokasi belum tersedia',
    this.emptyMessage =
        'Lokasi kapal akan tampil setelah Nakhoda mengirim GPS.',
    super.key,
  });

  final List<ShipMapPoint> points;
  final Color accent;
  final VoidCallback? onRefresh;
  final bool isRefreshing;
  final double height;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final validPoints = points.where((point) => point.hasCoordinate).toList();
    if (validPoints.isEmpty) {
      return AppCard(
        child: EmptyView(
          title: emptyTitle,
          message: emptyMessage,
          icon: Icons.location_off_outlined,
        ),
      );
    }

    final hasMapsKey = Env.googleMapsApiKey.isNotEmpty;
    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radius),
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              Positioned.fill(
                child: hasMapsKey
                    ? GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _centerOf(validPoints),
                          zoom: validPoints.length == 1 ? 12 : 6.4,
                        ),
                        markers: _markersOf(validPoints),
                        mapToolbarEnabled: false,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                      )
                    : _MapPreview(points: validPoints, accent: accent),
              ),
              Positioned(
                top: AppSizes.sm,
                right: AppSizes.sm,
                child: IconButton.filledTonal(
                  tooltip: 'Refresh lokasi',
                  onPressed: isRefreshing ? null : onRefresh,
                  icon: isRefreshing
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded, size: 18),
                ),
              ),
              Positioned(
                left: AppSizes.sm,
                bottom: AppSizes.sm,
                child: _MapCountBadge(
                  count: validPoints.length,
                  accent: accent,
                  preview: !hasMapsKey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Set<Marker> _markersOf(List<ShipMapPoint> points) {
    return {
      for (final point in points)
        Marker(
          markerId: MarkerId(point.id),
          position: LatLng(point.latitude, point.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            point.isActive
                ? BitmapDescriptor.hueAzure
                : BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(title: point.title, snippet: point.subtitle),
        ),
    };
  }

  LatLng _centerOf(List<ShipMapPoint> points) {
    final total = points.fold<({double lat, double lng})>(
      (lat: 0, lng: 0),
      (sum, point) =>
          (lat: sum.lat + point.latitude, lng: sum.lng + point.longitude),
    );
    return LatLng(total.lat / points.length, total.lng / points.length);
  }
}

class _MapPreview extends StatelessWidget {
  const _MapPreview({required this.points, required this.accent});

  final List<ShipMapPoint> points;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final markerCount = points.length.clamp(1, 4).toInt();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.12),
            const Color(0xFFEAF6F0),
            const Color(0xFFE8F3FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _MapGridPainter(accent: accent)),
          ),
          for (var index = 0; index < markerCount; index++)
            _PreviewMarker(index: index, color: _markerColor(index)),
        ],
      ),
    );
  }

  Color _markerColor(int index) {
    return switch (index) {
      0 => accent,
      1 => AppColors.warning,
      2 => AppColors.danger,
      _ => AppColors.success,
    };
  }
}

class _PreviewMarker extends StatelessWidget {
  const _PreviewMarker({required this.index, required this.color});

  final int index;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final alignments = [
      const Alignment(-0.45, -0.2),
      const Alignment(0.35, -0.45),
      const Alignment(0.08, 0.38),
      const Alignment(0.58, 0.25),
    ];
    return Align(
      alignment: alignments[index],
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.directions_boat_filled, color: color, size: 16),
      ),
    );
  }
}

class _MapCountBadge extends StatelessWidget {
  const _MapCountBadge({
    required this.count,
    required this.accent,
    required this.preview,
  });

  final int count;
  final Color accent;
  final bool preview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppSizes.pill),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Text(
        preview
            ? 'API key Maps belum diisi - $count kapal'
            : '$count kapal terpantau',
        style: TextStyle(
          color: accent,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  const _MapGridPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.48)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (var index = 1; index <= 3; index++) {
      final dx = size.width * index / 4;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint);
    }
    for (var index = 1; index <= 2; index++) {
      final dy = size.height * index / 3;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint);
    }

    final routePaint = Paint()
      ..color = accent.withValues(alpha: 0.2)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.12, size.height * 0.68)
      ..quadraticBezierTo(
        size.width * 0.38,
        size.height * 0.22,
        size.width * 0.62,
        size.height * 0.42,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.55,
        size.width * 0.9,
        size.height * 0.28,
      );
    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}
