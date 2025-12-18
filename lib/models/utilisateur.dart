class Utilisateur {
  final int? id;
  final String nom;
  final String email;
  final int age;
  final double taille;
  final DateTime dateCreation;

  Utilisateur({
    this.id,
    required this.nom,
    required this.email,
    required this.age,
    required this.taille,
    DateTime? dateCreation,
  }) : dateCreation = dateCreation ?? DateTime.now();

  // Convertir en Map pour la BDD
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'email': email,
      'age': age,
      'taille': taille,
      'dateCreation': dateCreation.toIso8601String(),
    };
  }

  // Créer depuis Map (BDD)
  factory Utilisateur.fromMap(Map<String, dynamic> map) {
    return Utilisateur(
      id: map['id'] as int?,
      nom: map['nom'] as String,
      email: map['email'] as String,
      age: map['age'] as int,
      taille: map['taille'] as double,
      dateCreation: DateTime.parse(map['dateCreation'] as String),
    );
  }

  // Créer depuis JSON (Firebase)
  factory Utilisateur.fromJson(Map<String, dynamic> json) {
    return Utilisateur(
      nom: json['nom'] as String,
      email: json['email'] as String,
      age: json['age'] as int,
      taille: (json['taille'] as num).toDouble(),
      dateCreation: json['dateCreation'] != null
          ? DateTime.parse(json['dateCreation'] as String)
          : DateTime.now(),
    );
  }

  // Convertir en JSON (Firebase)
  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'email': email,
      'age': age,
      'taille': taille,
      'dateCreation': dateCreation.toIso8601String(),
    };
  }

  // Copie avec modification
  Utilisateur copyWith({
    int? id,
    String? nom,
    String? email,
    int? age,
    double? taille,
    DateTime? dateCreation,
  }) {
    return Utilisateur(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      email: email ?? this.email,
      age: age ?? this.age,
      taille: taille ?? this.taille,
      dateCreation: dateCreation ?? this.dateCreation,
    );
  }

  @override
  String toString() {
    return 'Utilisateur{id: $id, nom: $nom, email: $email, age: $age, taille: $taille}';
  }
}