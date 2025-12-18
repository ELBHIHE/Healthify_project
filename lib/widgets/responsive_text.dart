import 'package:flutter/material.dart';

/// Widget de texte responsive qui s'adapte automatiquement
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow overflow;
  final TextAlign? textAlign;

  const ResponsiveText(
    this.text, {
    Key? key,
    this.style,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.textAlign,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculer la taille de police adaptée
        double baseFontSize = style?.fontSize ?? 14.0;
        double responsiveFontSize = baseFontSize;

        // Réduire la taille de police sur petits écrans
        if (constraints.maxWidth < 300) {
          responsiveFontSize = baseFontSize * 0.85;
        } else if (constraints.maxWidth < 350) {
          responsiveFontSize = baseFontSize * 0.9;
        }

        return Text(
          text,
          style: style?.copyWith(fontSize: responsiveFontSize) ?? 
                 TextStyle(fontSize: responsiveFontSize),
          maxLines: maxLines,
          overflow: overflow,
          textAlign: textAlign,
        );
      },
    );
  }
}

/// Extension pour faciliter l'utilisation
extension ResponsiveTextExtension on String {
  Widget toResponsiveText({
    TextStyle? style,
    int? maxLines = 1,
    TextOverflow overflow = TextOverflow.ellipsis,
    TextAlign? textAlign,
  }) {
    return ResponsiveText(
      this,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}

/// Widget pour texte avec icône qui gère l'overflow
class IconText extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;
  final TextStyle? textStyle;
  final double spacing;

  const IconText({
    Key? key,
    required this.icon,
    required this.text,
    this.iconColor,
    this.textStyle,
    this.spacing = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: textStyle?.fontSize ?? 16),
        SizedBox(width: spacing),
        Flexible(
          child: Text(
            text,
            style: textStyle,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}