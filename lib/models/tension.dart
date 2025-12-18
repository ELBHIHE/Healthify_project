class Tension {
  final int? id;
  final String userId;
  final int systolique;
  final int diastolique;
  final DateTime dateMesure;
  final String? remarque;

  Tension({
    this.id,
    required this.userId,
    required this.systolique,
    required this.diastolique,
    DateTime? dateMesure,
    this.remarque,
  }) : dateMesure = dateMesure ?? DateTime.now();

  // Classifier la tension
  String classifierTension() {
    if (systolique < 120 && diastolique < 80) {
      return 'Optimale';
    } else if (systolique < 130 && diastolique < 85) {
      return 'Normale';
    } else if (systolique < 140 || diastolique < 90) {
      return 'Normale haute';
    } else if (systolique < 160 || diastolique < 100) {
      return 'Hypertension légère';
    } else {
      return 'Hypertension sévère';
    }
  }

  // Obtenir un conseil personnalisé
  String obtenirConseil() {
    if (systolique < 100 || diastolique < 60) {
      return 'Tension basse détectée – reposez-vous et surveillez vos symptômes.';
    } else if (systolique < 120 && diastolique < 80) {
      return 'Votre tension est optimale. Continuez vos bonnes habitudes !';
    } else if (systolique < 140 && diastolique < 90) {
      return 'Tension légèrement élevée – limitez le sel et faites de l\'exercice.';
    } else {
      return 'Tension élevée – consultez votre médecin et détendez-vous.';
    }
  }

  // Format d'affichage (ex: "120/80")
  String get affichage => '$systolique/$diastolique mmHg';

  // Convertir en Map pour la BDD locale
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'systolique': systolique,
      'diastolique': diastolique,
      'dateMesure': dateMesure.toIso8601String(),
      'remarque': remarque,
    };
  }

  // Créer depuis Map (BDD locale)
  factory Tension.fromMap(Map<String, dynamic> map) {
    return Tension(
      id: map['id'] as int?,
      userId: map['userId'] as String,
      systolique: map['systolique'] as int,
      diastolique: map['diastolique'] as int,
      dateMesure: DateTime.parse(map['dateMesure'] as String),
      remarque: map['remarque'] as String?,
    );
  }

  // Convertir en JSON (Firebase)
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'systolique': systolique,
      'diastolique': diastolique,
      'dateMesure': dateMesure.toIso8601String(),
      'remarque': remarque,
      'statut': classifierTension(),
    };
  }

  // Créer depuis JSON (Firebase)
  factory Tension.fromJson(Map<String, dynamic> json) {
    return Tension(
      userId: json['userId'] as String,
      systolique: json['systolique'] as int,
      diastolique: json['diastolique'] as int,
      dateMesure: DateTime.parse(json['dateMesure'] as String),
      remarque: json['remarque'] as String?,
    );
  }

  // Copie avec modification
  Tension copyWith({
    int? id,
    String? userId,
    int? systolique,
    int? diastolique,
    DateTime? dateMesure,
    String? remarque,
  }) {
    return Tension(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      systolique: systolique ?? this.systolique,
      diastolique: diastolique ?? this.diastolique,
      dateMesure: dateMesure ?? this.dateMesure,
      remarque: remarque ?? this.remarque,
    );
  }

  @override
  String toString() {
    return 'Tension{id: $id, valeur: $affichage, statut: ${classifierTension()}}';
  }
}