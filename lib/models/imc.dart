import '../utils/constants.dart';

class IMC {
  final int? id;
  final String userId;
  final double taille; // en mètres
  final double poids; // en kg
  final double imc;
  final DateTime dateMesure;

  IMC({
    this.id,
    required this.userId,
    required this.taille,
    required this.poids,
    double? imc,
    DateTime? dateMesure,
  })  : imc = imc ?? (poids / (taille * taille)),
        dateMesure = dateMesure ?? DateTime.now();

  // Calculer l'IMC
  static double calculerIMC(double poids, double tailleCm) {
    double tailleM = tailleCm / 100;
    return poids / (tailleM * tailleM);
  }

  // Déterminer la catégorie
  String determinerCategorie() {
    if (imc < ValeursReference.imcSousPoids) {
      return 'Sous-poids';
    } else if (imc < ValeursReference.imcNormal) {
      return 'Normal';
    } else if (imc < ValeursReference.imcSurpoids) {
      return 'Surpoids';
    } else {
      return 'Obésité';
    }
  }

  // Calculer le poids idéal (Formule de Lorentz)
  double calculerPoidsIdeal() {
    double tailleEnCm = taille * 100;
    return (tailleEnCm - 100) - (tailleEnCm - 150) / 3;
  }

  // Obtenir un conseil personnalisé
  String obtenirConseil() {
    if (imc < ValeursReference.imcSousPoids) {
      return 'Vous êtes en sous-poids. Adoptez une alimentation plus riche et consultez un nutritionniste.';
    } else if (imc < ValeursReference.imcNormal) {
      return 'Votre IMC est normal ! Maintenez une alimentation équilibrée et une activité physique régulière.';
    } else if (imc < ValeursReference.imcSurpoids) {
      return 'Vous êtes en surpoids. Privilégiez une alimentation équilibrée et augmentez votre activité physique.';
    } else {
      return 'Obésité détectée. Il est recommandé de consulter un médecin pour un suivi personnalisé.';
    }
  }

  // Convertir en Map pour la BDD locale
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'taille': taille,
      'poids': poids,
      'imc': imc,
      'dateMesure': dateMesure.toIso8601String(),
    };
  }

  // Créer depuis Map (BDD locale)
  factory IMC.fromMap(Map<String, dynamic> map) {
    return IMC(
      id: map['id'] as int?,
      userId: map['userId'] as String,
      taille: map['taille'] as double,
      poids: map['poids'] as double,
      imc: map['imc'] as double,
      dateMesure: DateTime.parse(map['dateMesure'] as String),
    );
  }

  // Convertir en JSON (Firebase)
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'taille': taille,
      'poids': poids,
      'imc': imc,
      'dateMesure': dateMesure.toIso8601String(),
      'categorie': determinerCategorie(),
      'poidsIdeal': calculerPoidsIdeal(),
    };
  }

  // Créer depuis JSON (Firebase)
  factory IMC.fromJson(Map<String, dynamic> json) {
    return IMC(
      userId: json['userId'] as String,
      taille: (json['taille'] as num).toDouble(),
      poids: (json['poids'] as num).toDouble(),
      imc: (json['imc'] as num).toDouble(),
      dateMesure: DateTime.parse(json['dateMesure'] as String),
    );
  }

  // Copie avec modification
  IMC copyWith({
    int? id,
    String? userId,
    double? taille,
    double? poids,
    double? imc,
    DateTime? dateMesure,
  }) {
    return IMC(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      taille: taille ?? this.taille,
      poids: poids ?? this.poids,
      imc: imc ?? this.imc,
      dateMesure: dateMesure ?? this.dateMesure,
    );
  }

  @override
  String toString() {
    return 'IMC{id: $id, valeur: ${imc.toStringAsFixed(1)}, catégorie: ${determinerCategorie()}, poids: $poids kg, taille: ${(taille * 100).toStringAsFixed(0)} cm}';
  }
}