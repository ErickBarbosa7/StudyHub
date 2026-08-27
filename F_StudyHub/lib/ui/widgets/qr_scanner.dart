import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme.dart';

class QrScannerSheet extends StatefulWidget {
  const QrScannerSheet({super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: kColorPaper,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => const QrScannerSheet(),
    );
  }

  @override
  State<QrScannerSheet> createState() => _QrScannerSheetState();
}

class _QrScannerSheetState extends State<QrScannerSheet> {
  MobileScannerController? _scannerController;
  _CameraStatus _status = _CameraStatus.initializing;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initScanner();
  }

  Future<void> _initScanner() async {
    try {
      _scannerController?.dispose();
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );

      await _scannerController!.start();

      if (!mounted) return;

      final error = _scannerController!.value.error;
      if (error != null && error.errorCode == MobileScannerErrorCode.permissionDenied) {
        _setError('Permiso de cámara denegado. Actívalo en Configuración > StudyHub.');
      } else if (_scannerController!.value.isRunning) {
        setState(() => _status = _CameraStatus.ready);
      } else {
        _setError('No se pudo acceder a la cámara. Verifica los permisos.');
      }
    } on MobileScannerException catch (e) {
      if (!mounted) return;
      _setError(_getMessageForErrorCode(e.errorCode));
    } catch (e) {
      if (!mounted) return;
      _setError('No se pudo acceder a la cámara. Verifica los permisos.');
    }
  }

  String _getMessageForErrorCode(MobileScannerErrorCode code) {
    switch (code) {
      case MobileScannerErrorCode.permissionDenied:
        return 'Permiso de cámara denegado. Actívalo en Configuración > StudyHub.';
      case MobileScannerErrorCode.controllerDisposed:
        return 'La cámara fue cerrada inesperadamente.';
      case MobileScannerErrorCode.controllerAlreadyInitialized:
        return 'La cámara ya está en uso.';
      case MobileScannerErrorCode.controllerUninitialized:
        return 'La cámara no está disponible en este momento.';
      case MobileScannerErrorCode.unsupported:
        return 'Tu dispositivo no soporta escaneo de código QR.';
      default:
        return 'No se pudo acceder a la cámara. Verifica los permisos.';
    }
  }

  void _setError(String message) {
    if (mounted) {
      setState(() {
        _status = _CameraStatus.error;
        _errorMessage = message;
      });
    }
  }

  void _retryCamera() {
    setState(() {
      _status = _CameraStatus.initializing;
      _errorMessage = '';
    });
    _initScanner();
  }

  void _onDetect(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null || code.trim().isEmpty) return;

    _scannerController?.stop();
    if (mounted) {
      Navigator.of(context).pop(code.trim());
    }
  }

  void _manualEntry() {
    _scannerController?.stop();
    if (mounted) {
      Navigator.of(context).pop<String?>(null);
    }
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kColorSageSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: kColorDeepSage,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Escanear código',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: kColorInk,
                          fontWeight: AppType.weightSemiBold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_status == _CameraStatus.error)
              _buildErrorView()
            else
              _buildCameraView(),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _manualEntry,
              style: TextButton.styleFrom(
                foregroundColor: kColorTextSecondary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Escribir código manualmente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    return Column(
      children: [
        Text(
          'Apunta la cámara al código QR de la sala.',
          textAlign: TextAlign.center,
          style: AppType.secondaryItalic(
            size: AppType.sizeCaption,
            color: kColorTextSecondary,
          ),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 260,
            child: _status == _CameraStatus.initializing
                ? Container(
                    color: kColorInk,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: kColorPaper,
                        strokeWidth: 2.5,
                      ),
                    ),
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      MobileScanner(
                        controller: _scannerController,
                        onDetect: _onDetect,
                      ),
                      _buildScanOverlay(),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanOverlay() {
    return SizedBox(
      width: 220,
      height: 220,
      child: CustomPaint(
        painter: _ScanOverlayPainter(),
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kColorGoldSoft,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.videocam_off_rounded,
            size: 48,
            color: kColorTextSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: AppType.secondaryItalic(
              size: AppType.sizeBody,
              color: kColorInk,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _retryCamera,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text('Reintentar'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

enum _CameraStatus { initializing, ready, error }

class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kColorDeepSage
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double cornerLength = 30;
    const double radius = 16;

    final paths = [
      _cornerPath(Offset.zero, Offset(cornerLength, 0), Offset(0, cornerLength), radius),
      _cornerPath(Offset(size.width, 0), Offset(size.width - cornerLength, 0), Offset(size.width, cornerLength), radius),
      _cornerPath(Offset(0, size.height), Offset(cornerLength, size.height), Offset(0, size.height - cornerLength), radius),
      _cornerPath(Offset(size.width, size.height), Offset(size.width - cornerLength, size.height), Offset(size.width, size.height - cornerLength), radius),
    ];

    for (final path in paths) {
      canvas.drawPath(path, paint);
    }
  }

  Path _cornerPath(Offset corner, Offset hEnd, Offset vEnd, double r) {
    return Path()
      ..moveTo(corner.dx, corner.dy + r)
      ..quadraticBezierTo(corner.dx, corner.dy, corner.dx + r * (hEnd.dx > corner.dx ? 1 : -1), corner.dy)
      ..lineTo(hEnd.dx, hEnd.dy)
      ..moveTo(corner.dx + r * (vEnd.dx > corner.dx ? 1 : -1), corner.dy)
      ..quadraticBezierTo(corner.dx, corner.dy, corner.dx, corner.dy + r * (vEnd.dy > corner.dy ? 1 : -1))
      ..lineTo(vEnd.dx, vEnd.dy);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
