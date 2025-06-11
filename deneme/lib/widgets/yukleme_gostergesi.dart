import 'package:flutter/material.dart';

enum YuklemeStili {
  dairesel,
  dogrusal,
  pulseLogo,
  kartYukleme,
}

class YuklemeGostergesi extends StatefulWidget {
  final YuklemeStili stil;
  final String? mesaj;
  final Color? renk;
  final double? boyut;
  final bool overlay; // Tüm ekranı kaplayacak mı

  const YuklemeGostergesi({
    Key? key,
    this.stil = YuklemeStili.dairesel,
    this.mesaj,
    this.renk,
    this.boyut,
    this.overlay = false,
  }) : super(key: key);

  @override
  _YuklemeGostergesState createState() => _YuklemeGostergesState();
}

class _YuklemeGostergesState extends State<YuklemeGostergesi>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget yukleyici = _buildYukleyici();
    
    if (widget.overlay) {
      return Container(
        color: Colors.black54,
        child: Center(child: yukleyici),
      );
    }
    
    return yukleyici;
  }

  Widget _buildYukleyici() {
    switch (widget.stil) {
      case YuklemeStili.dairesel:
        return _buildDaireselYukleyici();
      case YuklemeStili.dogrusal:
        return _buildDogrusalYukleyici();
      case YuklemeStili.pulseLogo:
        return _buildPulseLogoYukleyici();
      case YuklemeStili.kartYukleme:
        return _buildKartYuklemeYukleyici();
    }
  }

  Widget _buildDaireselYukleyici() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(
          color: widget.renk ?? Colors.green,
          strokeWidth: 3,
        ),
        if (widget.mesaj != null) ...[
          SizedBox(height: 16),
          Text(
            widget.mesaj!,
            style: TextStyle(
              color: widget.renk ?? Colors.green[700],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildDogrusalYukleyici() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.mesaj != null) ...[
          Text(
            widget.mesaj!,
            style: TextStyle(
              color: widget.renk ?? Colors.green[700],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
        ],
        LinearProgressIndicator(
          color: widget.renk ?? Colors.green,
          backgroundColor: Colors.green[100],
        ),
      ],
    );
  }

  Widget _buildPulseLogoYukleyici() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: widget.boyut ?? 60,
                height: widget.boyut ?? 60,
                decoration: BoxDecoration(
                  color: widget.renk ?? Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.restaurant,
                  color: Colors.white,
                  size: (widget.boyut ?? 60) * 0.5,
                ),
              ),
              if (widget.mesaj != null) ...[
                SizedBox(height: 16),
                Text(
                  widget.mesaj!,
                  style: TextStyle(
                    color: widget.renk ?? Colors.green[700],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildKartYuklemeYukleyici() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: widget.renk ?? Colors.green,
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              widget.mesaj ?? 'Yükleniyor...',
              style: TextStyle(
                color: widget.renk ?? Colors.green[700],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Kullanım kolaylığı için static metodlar
class YuklemeHelper {
  static Widget dairesel({String? mesaj, Color? renk}) {
    return YuklemeGostergesi(
      stil: YuklemeStili.dairesel,
      mesaj: mesaj,
      renk: renk,
    );
  }

  static Widget dogrusal({String? mesaj, Color? renk}) {
    return YuklemeGostergesi(
      stil: YuklemeStili.dogrusal,
      mesaj: mesaj,
      renk: renk,
    );
  }

  static Widget pulseLogo({String? mesaj, Color? renk, double? boyut}) {
    return YuklemeGostergesi(
      stil: YuklemeStili.pulseLogo,
      mesaj: mesaj,
      renk: renk,
      boyut: boyut,
    );
  }

  static Widget kartYukleme({String? mesaj, Color? renk}) {
    return YuklemeGostergesi(
      stil: YuklemeStili.kartYukleme,
      mesaj: mesaj,
      renk: renk,
    );
  }

  static Widget overlay({String? mesaj, YuklemeStili stil = YuklemeStili.dairesel}) {
    return YuklemeGostergesi(
      stil: stil,
      mesaj: mesaj,
      overlay: true,
    );
  }
}

// Skeleton Loading Widget
class SkeletonLoader extends StatefulWidget {
  final double height;
  final double width;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    Key? key,
    required this.height,
    required this.width,
    this.borderRadius,
  }) : super(key: key);

  @override
  _SkeletonLoaderState createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutSine),
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.topRight,
                colors: [
                  Colors.grey[300]!,
                  Colors.grey[100]!,
                  Colors.grey[300]!,
                ],
                stops: [
                  _animation.value - 0.3,
                  _animation.value,
                  _animation.value + 0.3,
                ],
                transform: GradientRotation(0.5),
              ).createShader(bounds);
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
              ),
            ),
          );
        },
      ),
    );
  }
} 