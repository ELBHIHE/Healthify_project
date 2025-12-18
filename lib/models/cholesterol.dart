import '../utils/constants.dart';

class Cholesterol {
  final int? id;
  final String userId;
  final double total;
  final double hdl;
  final double ldl;
  final DateTime dateBilan;
  final String? remarque;

  Cholesterol({
    this.id,
    required this.userId,
    required this.total,
    required this.hdl,
    required this.ldl,
    DateTime? dateBilan,
    this.remarque,
  }) : dateBilan = dateBilan ?? DateTime.now();

  // Calculer le ratio Total/HDL
  double calculerRatio() {
    if (hdl == 0) return 0;
    return total / hdl;
  }

  // Interpréter le résultat
  String interpreterResultat() {
    if (ldl > ValeursReference.ldlMax) {
      return 'Risque cardiovasculaire';
    } else if (hdl < ValeursReference.hdlMin) {
      return 'HDL trop faible';
    } else {
      double ratio = calculerRatio();
      if (ratio > 5.0) {
        return 'Ratio élevé';
      } else if (ratio < 3.5) {
        return 'Excellent';
      } else {
        return 'Bon';
      }
    }
  }

  // Obtenir un conseil personnalisé
  String obtenirConseil() {
    if (ldl > ValeursReference.ldlMax) {
      return 'LDL élevé – limitez les graisses saturées et privilégiez les oméga-3.';
    } else if (hdl < ValeursReference.hdlMin) {
      return 'HDL faible – pratiquez une activité physique régulière.';
    } else {
      return 'Votre bilan lipidique est satisfaisant. Maintenez une alimentation équilibrée.';
    }
  }

  // Convertir en Map pour la BDD locale
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'total': total,
      'hdl': hdl,
      'ldl': ldl,
      'dateBilan': dateBilan.toIso8601String(),
      'remarque': remarque,
    };
  }

  // Créer depuis Map (BDD locale)
  factory Cholesterol.fromMap(Map<String, dynamic> map) {
    return Cholesterol(
      id: map['id'] as int?,
      userId: map['userId'] as String,
      total: map['total'] as double,
      hdl: map['hdl'] as double,
      ldl: map['ldl'] as double,
      dateBilan: DateTime.parse(map['dateBilan'] as String),
      remarque: map['remarque'] as String?,
    );
  }

  // Convertir en JSON (Firebase)
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'total': total,
      'hdl': hdl,
      'ldl': ldl,
      'dateBilan': dateBilan.toIso8601String(),
      'remarque': remarque,
      'ratio': calculerRatio(),
      'interpretation': interpreterResultat(),
    };
  }

  // Créer depuis JSON (Firebase)
  factory Cholesterol.fromJson(Map<String, dynamic> json) {
    return Cholesterol(
      userId: json['userId'] as String,
      total: (json['total'] as num).toDouble(),
      hdl: (json['hdl'] as num).toDouble(),
      ldl: (json['ldl'] as num).toDouble(),
      dateBilan: DateTime.parse(json['dateBilan'] as String),
      remarque: json['remarque'] as String?,
    );
  }

  // Copie avec modification
  Cholesterol copyWith({
    int? id,
    String? userId,
    double? total,
    double? hdl,
    double? ldl,
    DateTime? dateBilan,
    String? remarque,
  }) {
    return Cholesterol(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      total: total ?? this.total,
      hdl: hdl ?? this.hdl,
      ldl: ldl ?? this.ldl,
      dateBilan: dateBilan ?? this.dateBilan,
      remarque: remarque ?? this.remarque,
    );
  }

  @override
  String toString() {
    return 'Cholesterol{id: $id, total: $total, HDL: $hdl, LDL: $ldl, ratio: ${calculerRatio().toStringAsFixed(2)}}';
  }
}