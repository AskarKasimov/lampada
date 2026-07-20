import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'brand_mark.dart';

/// Брендинг на время загрузки. Спиннер появляется с задержкой: кэш отдаёт
/// карточки за доли секунды, индикатор там не нужен, а при ожидании сети
/// без него неподвижный логотип выглядит зависшим приложением.
class BrandLoadingView extends StatefulWidget {
  const BrandLoadingView({
    super.key,
    this.spinnerDelay = const Duration(seconds: 3),
  });

  final Duration spinnerDelay;

  @override
  State<BrandLoadingView> createState() => _BrandLoadingViewState();
}

class _BrandLoadingViewState extends State<BrandLoadingView> {
  Timer? _timer;
  bool _showSpinner = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.spinnerDelay, () {
      if (mounted) setState(() => _showSpinner = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BrandMark(),
          const SizedBox(height: 28),
          // Место под спиннер держим всегда — иначе брендинг дёргается вверх
          // ровно в тот момент, когда юзер на него смотрит.
          SizedBox(
            width: 18,
            height: 18,
            child: _showSpinner
                ? CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.link,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
