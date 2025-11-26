import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class ManualCropPage extends StatefulWidget {
  final Uint8List imageBytes;

  const ManualCropPage({super.key, required this.imageBytes});

  @override
  State<ManualCropPage> createState() => _ManualCropPageState();
}

class _ManualCropPageState extends State<ManualCropPage> {
  double boxX = 30;
  double boxY = 30;
  double boxSize = 150;

  double imgW = 0;
  double imgH = 0;

  bool resizing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manual Crop")),
      body: LayoutBuilder(
        builder: (context, constraints) {
          imgW = constraints.maxWidth;
          imgH = imgW * 0.75; // rasio aman

          return Column(
            children: [
              SizedBox(
                width: imgW,
                height: imgH,
                child: Stack(
                  children: [
                    /// IMAGE
                    Image.memory(
                      widget.imageBytes,
                      width: imgW,
                      height: imgH,
                      fit: BoxFit.cover,
                    ),

                    /// DRAG + RESIZE BOX
                    Positioned(
                      left: boxX,
                      top: boxY,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          if (!resizing) {
                            // DRAG MODE
                            setState(() {
                              boxX = (boxX + details.delta.dx).clamp(
                                0,
                                imgW - boxSize,
                              );
                              boxY = (boxY + details.delta.dy).clamp(
                                0,
                                imgH - boxSize,
                              );
                            });
                          }
                        },
                        child: Stack(
                          children: [
                            /// BOX AREA
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

                            /// RESIZE HANDLE (pojok kanan bawah)
                            Positioned(
                              right: -12,
                              bottom: -12,
                              child: GestureDetector(
                                onPanStart: (_) => resizing = true,
                                onPanEnd: (_) => resizing = false,
                                onPanUpdate: (details) {
                                  setState(() {
                                    double newSize = boxSize + details.delta.dx;

                                    // Biar tetap kotak
                                    newSize = newSize.clamp(60, imgW);

                                    // Prevent keluar batas
                                    if (boxX + newSize > imgW) {
                                      newSize = imgW - boxX;
                                    }
                                    if (boxY + newSize > imgH) {
                                      newSize = imgH - boxY;
                                    }

                                    boxSize = newSize;
                                  });
                                },
                                child: Container(
                                  width: 25,
                                  height: 25,
                                  decoration: BoxDecoration(
                                    color: Colors.yellow,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.zoom_out_map,
                                    size: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
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

  Future<void> cropImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final original = await decodeImageFromList(widget.imageBytes);

    final scaleX = original.width / imgW;
    final scaleY = original.height / imgH;

    final srcRect = Rect.fromLTWH(
      boxX * scaleX,
      boxY * scaleY,
      boxSize * scaleX,
      boxSize * scaleY,
    );

    final dstRect = Rect.fromLTWH(0, 0, boxSize, boxSize);

    canvas.drawImageRect(original, srcRect, dstRect, Paint());

    final pic = recorder.endRecording();
    final cropped = await pic.toImage(boxSize.toInt(), boxSize.toInt());

    final data = await cropped.toByteData(format: ui.ImageByteFormat.png);
    final bytes = data!.buffer.asUint8List();
    
    Navigator.pop(context, {
      "image": bytes,
      "bounding_box": {
        "x_min": boxX.toInt(),
        "y_min": boxY.toInt(),
        "x_max": (boxX + boxSize).toInt(),
        "y_max": (boxY + boxSize).toInt(),
      },
    });
  }
}
