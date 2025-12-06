import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class ManualCropPage extends StatefulWidget {
  final Uint8List imageBytes;
  final int potNumber;

  const ManualCropPage({
    super.key,
    required this.imageBytes,
    required this.potNumber,
  });

  @override
  State<ManualCropPage> createState() => _ManualCropPageState();
}

class _ManualCropPageState extends State<ManualCropPage> {
  double boxX = 30;
  double boxY = 30;
  double boxSize = 150;
  bool resizing = false;

  double viewW = 0; // ukuran viewer container
  double viewH = 0;

  double displayW = 0; // ukuran image yg tampil
  double displayH = 0;
  double offsetX = 0; // offset padding horizontal/vertikal
  double offsetY = 0;

  late ui.Image originalImage;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  Future<void> _decodeImage() async {
    originalImage = await decodeImageFromList(widget.imageBytes);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (originalImage == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Loading...")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Crop Pot ${widget.potNumber}")),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // viewer full width
          viewW = constraints.maxWidth;
          viewH =
              constraints.maxHeight * 0.6; // pake 60% height biar button ada

          final imgRatio = originalImage.width / originalImage.height;
          final viewerRatio = viewW / viewH;

          if (imgRatio > viewerRatio) {
            // image lebih lebar → full width
            displayW = viewW;
            displayH = viewW / imgRatio;
            offsetX = 0;
            offsetY = (viewH - displayH) / 2;
          } else {
            // image lebih tinggi → full height
            displayH = viewH;
            displayW = viewH * imgRatio;
            offsetX = (viewW - displayW) / 2;
            offsetY = 0;
          }

          return Column(
            children: [
              SizedBox(
                width: viewW,
                height: viewH,
                child: Stack(
                  children: [
                    Positioned(
                      left: offsetX,
                      top: offsetY,
                      width: displayW,
                      height: displayH,
                      child: Image.memory(
                        widget.imageBytes,
                        fit: BoxFit.contain,
                      ),
                    ),

                    Positioned(
                      left: boxX,
                      top: boxY,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          if (!resizing) {
                            setState(() {
                              boxX = (boxX + details.delta.dx).clamp(
                                offsetX,
                                offsetX + displayW - boxSize,
                              );
                              boxY = (boxY + details.delta.dy).clamp(
                                offsetY,
                                offsetY + displayH - boxSize,
                              );
                            });
                          }
                        },
                        child: Stack(
                          children: [
                            Container(
                              width: boxSize,
                              height: boxSize,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.yellow,
                                  width: 3,
                                ),
                              ),
                            ),
                            Positioned(
                              right: -12,
                              bottom: -12,
                              child: _resizeHandle(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: cropImage,
                child: const Text("Save Crop"),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _resizeHandle() {
    return GestureDetector(
      onPanStart: (_) => resizing = true,
      onPanEnd: (_) => resizing = false,
      onPanUpdate: (details) {
        setState(() {
          double newSize = boxSize + details.delta.dx;
          newSize = newSize.clamp(60, displayW + offsetX - boxX);
          if (boxX + newSize > offsetX + displayW)
            newSize = offsetX + displayW - boxX;
          if (boxY + newSize > offsetY + displayH)
            newSize = offsetY + displayH - boxY;
          boxSize = newSize;
        });
      },
      child: Container(
        width: 25,
        height: 25,
        decoration: BoxDecoration(
          color: Colors.yellow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black, width: 1.5),
        ),
        child: const Icon(Icons.zoom_out_map, size: 16, color: Colors.black),
      ),
    );
  }

  Future<void> cropImage() async {
    final scaleX = originalImage.width / displayW;
    final scaleY = originalImage.height / displayH;

    final srcRect = Rect.fromLTWH(
      (boxX - offsetX) * scaleX,
      (boxY - offsetY) * scaleY,
      boxSize * scaleX,
      boxSize * scaleY,
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // batasi dstRect max 1024 px
    final maxDstSize = 1024.0;
    final dstSize = boxSize > maxDstSize ? maxDstSize : boxSize;

    final dstRect = Rect.fromLTWH(0, 0, dstSize, dstSize);
    canvas.drawImageRect(originalImage, srcRect, dstRect, Paint());

    final pic = recorder.endRecording();
    final cropped = await pic.toImage(dstSize.toInt(), dstSize.toInt());
    final data = await cropped.toByteData(format: ui.ImageByteFormat.png);
    final bytes = data!.buffer.asUint8List();

    Navigator.pop(context, {
      "image": bytes,
      "rect": {
        "x_min": ((boxX - offsetX) * scaleX).toInt(),
        "y_min": ((boxY - offsetY) * scaleY).toInt(),
        "x_max": ((boxX - offsetX + boxSize) * scaleX).toInt(),
        "y_max": ((boxY - offsetY + boxSize) * scaleY).toInt(),
      },
      "rect_ratio": {
        "x_min": (boxX - offsetX) / displayW,
        "y_min": (boxY - offsetY) / displayH,
        "x_max": (boxX - offsetX + boxSize) / displayW,
        "y_max": (boxY - offsetY + boxSize) / displayH,
      },
    });
  }
}
