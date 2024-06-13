import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Jigsaw Puzzle',
      home: JigsawPuzzle(),
    );
  }
}

class JigsawPuzzle extends StatefulWidget {
  @override
  _JigsawPuzzleState createState() => _JigsawPuzzleState();
}

class _JigsawPuzzleState extends State<JigsawPuzzle> {
  final int gridSize = 3;
  ui.Image? image;
  List<Widget> pieces = [];
  Size screenSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  void _loadImage() async {
    final ByteData data = await rootBundle.load('assets/img3.png');
    final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final ui.FrameInfo fi = await codec.getNextFrame();
    setState(() {
      image = fi.image;
      _createPieces();
    });
  }

  void _createPieces() {
    if (image == null || screenSize == Size.zero) return;

    final pieceWidth = screenSize.width / gridSize;
    final pieceHeight = screenSize.height / gridSize;

    pieces = List.generate(gridSize * gridSize, (index) {
      int x = (index % gridSize) * pieceWidth.toInt();
      int y = (index ~/ gridSize) * pieceHeight.toInt();
      return DraggablePuzzlePiece(
        key: UniqueKey(),
        image: image!,
        srcPosition: Offset(x.toDouble(), y.toDouble()),
        pieceSize: Size(pieceWidth, pieceHeight),
        screenSize: screenSize,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      if (screenSize == Size.zero) {
        setState(() {
          screenSize = MediaQuery.of(context).size;
          _createPieces();
        });
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text("Flutter Jigsaw Puzzle")),
      body: image == null
          ? Center(child: CircularProgressIndicator())
          : Stack(children: pieces),
    );
  }
}

class DraggablePuzzlePiece extends StatefulWidget {
  final ui.Image image;
  final Offset srcPosition;
  final Size pieceSize;
  final Size screenSize;

  DraggablePuzzlePiece({
    Key? key,
    required this.image,
    required this.srcPosition,
    required this.pieceSize,
    required this.screenSize,
  }) : super(key: key);

  @override
  _DraggablePuzzlePieceState createState() => _DraggablePuzzlePieceState();
}

class _DraggablePuzzlePieceState extends State<DraggablePuzzlePiece> {
  Offset position = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Draggable(
        feedback: CustomPaint(
          painter: PiecePainter(widget.image, widget.srcPosition, widget.pieceSize, widget.screenSize),
          child: Container(width: widget.pieceSize.width, height: widget.pieceSize.height),
        ),
        childWhenDragging: Container(),
        child: CustomPaint(
          painter: PiecePainter(widget.image, widget.srcPosition, widget.pieceSize, widget.screenSize),
          child: Container(width: widget.pieceSize.width, height: widget.pieceSize.height),
        ),
        onDraggableCanceled: (velocity, offset) {
          setState(() {
            position = offset;
          });
        },
        onDragEnd: (details) {
          setState(() {
            position = details.offset;
          });
        },
      ),
    );
  }
}

class PiecePainter extends CustomPainter {
  final ui.Image image;
  final Offset srcPosition;
  final Size pieceSize;
  final Size screenSize;

  PiecePainter(this.image, this.srcPosition, this.pieceSize, this.screenSize);

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = screenSize.width / image.width;
    final double scaleY = screenSize.height / image.height;

    final Rect srcRect = Rect.fromLTWH(
      srcPosition.dx / scaleX,
      srcPosition.dy / scaleY,
      pieceSize.width / scaleX,
      pieceSize.height / scaleY,
    );
    final Rect dstRect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawImageRect(image, srcRect, dstRect, Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
