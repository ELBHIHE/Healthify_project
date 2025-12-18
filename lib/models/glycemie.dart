import '../utils/constants.dart';

class Glycemie {
  final int? id;
  final String userId; // Firebase UID ou ID local
  final double valeur;
  final String moment;
  final DateTime dateMesure;
  final String? remarque;

  Glycemie({
    this.id,
    required this.userId,
    required this.valeur,
    required this.moment,
    DateTime? dateMesure,
    this.remarque,
  }) : dateMesure = dateMesure ?? DateTime.now();

  // Calculer le statut automatiquement
  String calculerStatut() {
    if (valeur < ValeursReference.glycemieMin) {
      return 'Hypoglycémie';
    } else if (valeur <= ValeursReference.glycemieMax) {
      return 'Normal';
    } else {
      return 'Hyperglycémie';
    }
  }

  // Obtenir un conseil personnalisé
  String obtenirConseil() {
    if (valeur < ValeursReference.glycemieMin) {
      return 'Hypoglycémie détectée – prenez un jus sucré ou un fruit.';
    } else if (valeur <= ValeursReference.glycemieMax) {
      return 'Votre glycémie est dans la normale. Continuez ainsi !';
    } else {
      return 'Glycémie élevée – évitez les aliments sucrés et consultez votre médecin.';
    }
  }

  // Convertir en Map pour la BDD locale
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'valeur': valeur,
      'moment': moment,
      'dateMesure': dateMesure.toIso8601String(),
      'remarque': remarque,
    };
  }

  // Créer depuis Map (BDD locale)
  factory Glycemie.fromMap(Map<String, dynamic> map) {
    return Glycemie(
      id: map['id'] as int?,
      userId: map['userId'] as String,
      valeur: map['valeur'] as double,
      moment: map['moment'] as String,
      dateMesure: DateTime.parse(map['dateMesure'] as String),
      remarque: map['remarque'] as String?,
    );
  }

  // Convertir en JSON (Firebase)
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'valeur': valeur,
      'moment': moment,
      'dateMesure': dateMesure.toIso8601String(),
      'remarque': remarque,
      'statut': calculerStatut(),
    };
  }

  // Créer depuis JSON (Firebase)
  factory Glycemie.fromJson(Map<String, dynamic> json, String docId) {
    return Glycemie(
      userId: json['userId'] as String,
      valeur: (json['valeur'] as num).toDouble(),
      moment: json['moment'] as String,
      dateMesure: DateTime.parse(json['dateMesure'] as String),
      remarque: json['remarque'] as String?,
    );
  }

  // Copie avec modification
  Glycemie copyWith({
    int? id,
    String? userId,
    double? valeur,
    String? moment,
    DateTime? dateMesure,
    String? remarque,
  }) {
    return Glycemie(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      valeur: valeur ?? this.valeur,
      moment: moment ?? this.moment,
      dateMesure: dateMesure ?? this.dateMesure,
      remarque: remarque ?? this.remarque,
    );
  }

  @override
  String toString() {
    return 'Glycemie{id: $id, valeur: $valeur mg/dL, moment: $moment, statut: ${calculerStatut()}}';
  }
}