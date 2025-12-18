class Medicament {
  final int? id;
  final String userId;
  final String nom;
  final String periode; // Matin, Midi, Soir, Nuit
  final DateTime dateAjout;
  final bool estActif;

  Medicament({
    this.id,
    required this.userId,
    required this.nom,
    required this.periode,
    DateTime? dateAjout,
    this.estActif = true,
  }) : dateAjout = dateAjout ?? DateTime.now();

  // Obtenir le rappel formaté
  String obtenirRappel() {
    String moment = '';
    switch (periode) {
      case 'Matin':
        moment = '8h00';
        break;
      case 'Midi':
        moment = '12h00';
        break;
      case 'Soir':
        moment = '20h00';
        break;
      case 'Nuit':
        moment = '22h00';
        break;
      default:
        moment = '8h00';
    }
    return 'Prendre $nom à $moment';
  }

  // Modifier l'état actif/inactif
  Medicament toggleActif() {
    return copyWith(estActif: !estActif);
  }

  // Convertir en Map pour la BDD locale
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'nom': nom,
      'periode': periode,
      'dateAjout': dateAjout.toIso8601String(),
      'estActif': estActif ? 1 : 0,
    };
  }

  // Créer depuis Map (BDD locale)
  factory Medicament.fromMap(Map<String, dynamic> map) {
    return Medicament(
      id: map['id'] as int?,
      userId: map['userId'] as String,
      nom: map['nom'] as String,
      periode: map['periode'] as String,
      dateAjout: DateTime.parse(map['dateAjout'] as String),
      estActif: map['estActif'] == 1,
    );
  }

  // Convertir en JSON (Firebase)
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'nom': nom,
      'periode': periode,
      'dateAjout': dateAjout.toIso8601String(),
      'estActif': estActif,
    };
  }

  // Créer depuis JSON (Firebase)
  factory Medicament.fromJson(Map<String, dynamic> json) {
    return Medicament(
      userId: json['userId'] as String,
      nom: json['nom'] as String,
      periode: json['periode'] as String,
      dateAjout: DateTime.parse(json['dateAjout'] as String),
      estActif: json['estActif'] as bool? ?? true,
    );
  }

  // Copie avec modification
  Medicament copyWith({
    int? id,
    String? userId,
    String? nom,
    String? periode,
    DateTime? dateAjout,
    bool? estActif,
  }) {
    return Medicament(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nom: nom ?? this.nom,
      periode: periode ?? this.periode,
      dateAjout: dateAjout ?? this.dateAjout,
      estActif: estActif ?? this.estActif,
    );
  }

  @override
  String toString() {
    return 'Medicament{id: $id, nom: $nom, periode: $periode, actif: $estActif}';
  }
}