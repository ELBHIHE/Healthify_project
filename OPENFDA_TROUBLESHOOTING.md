# 🔧 Guide de Dépannage - OpenFDA Integration

## ❌ Problèmes Courants et Solutions

### Problème 1: "Timeout: impossible de se connecter à OpenFDA"

**Symptôme**: Recherche qui ne répond pas ou affiche l'erreur timeout après 10s

**Causes possibles**:
- ❌ Pas de connexion Internet
- ❌ Connexion Internet très lente (<1Mbps)
- ❌ Serveur OpenFDA indisponible
- ❌ Firewall/VPN bloquant les appels HTTP

**Solutions**:
1. **Vérifiez votre connexion Internet**
   ```
   Ouvrez un navigateur → allez sur google.com
   Si ça charge lentement, c'est votre connexion
   ```

2. **Réessayez plus tard**
   ```
   Attendez 30 secondes et réessayez
   (Le serveur OpenFDA peut être temporairement indisponible)
   ```

3. **Vérifiez votre firewall/VPN**
   ```
   Essayez sans VPN ou avec un autre VPN
   Vérifiez que port 443 (HTTPS) n'est pas bloqué
   ```

4. **Augmentez le timeout (développeur)**
   ```dart
   // Dans lib/services/openfda_service.dart
   static const Duration _timeout = Duration(seconds: 20); // Était 10s
   ```

---

### Problème 2: "Aucun résultat trouvé pour: [nom du médicament]"

**Symptôme**: La recherche retourne une liste vide même pour un médicament courant

**Causes possibles**:
- ❌ Médicament n'existe pas dans la base FDA (ex: médicament français uniquement)
- ❌ Nom mal orthographié
- ❌ Vous cherchez le nom générique au lieu du brand name
- ❌ Nom trop spécifique ou trop court

**Solutions**:
1. **Essayez le nom générique**
   ```
   ❌ Chercher: "Advil"
   ✅ Chercher: "Ibuprofen"
   
   ❌ Chercher: "Tylenol"
   ✅ Chercher: "Acetaminophen" ou "Paracetamol"
   ```

2. **Vérifiez l'orthographe**
   ```
   ❌ "Metfromine"
   ✅ "Metformin" ou "Metformine"
   ```

3. **Essayez des variantes anglaises**
   ```
   OpenFDA est basée aux USA, utilise les noms anglais
   
   ❌ "Paracétamol"
   ✅ "Acetaminophen"
   ```

4. **Cherchez les marques principales**
   ```
   ✅ Glucophage (Metformin)
   ✅ Lipitor (Atorvastatin)
   ✅ Lisinopril (ACE inhibitor)
   ```

5. **Consultez open.fda.gov**
   ```
   Allez sur https://open.fda.gov/
   Cherchez votre médicament pour voir le nom exact
   ```

---

### Problème 3: Affichage d'informations incomplètes

**Symptôme**: Certains champs sont vides ou affichent "Non disponible"

**Causes**:
- ✅ C'est normal! OpenFDA n'a pas toutes les infos pour tous les médicaments
- Les vieux médicaments ont moins de données
- Certains champs ne sont pas remplis dans la base FDA

**Solutions**:
1. **C'est okay - c'est les données FDA**
   Les infos manquantes signifient que la FDA n'a pas ces données

2. **Complétez avec une recherche externe**
   ```
   Consultez:
   - Google "Drug Name side effects"
   - RxList.com
   - Drugs.com
   - Votre pharmacien
   ```

3. **Prioriser les infos disponibles**
   ```
   ✅ Dosage: Fiable
   ✅ Contre-indications: Très important
   ✅ Effets secondaires: Données réelles rapportées
   ⚠️ Interactions: A valider avec pharmacien
   ```

---

### Problème 4: Les effets secondaires semblent incorrects

**Symptôme**: Beaucoup d'effets secondaires non-pertinents listés

**Raison**:
- OpenFDA utilise les **vrais rapports des utilisateurs**
- Certains rapports peuvent inclure des coïncidences
- La corrélation ≠ causalité

**Exemple**:
```
Un utilisateur rapporte:
"J'ai pris Metformine et j'ai mal à la tête"

Cela ne signifie pas que Metformine CAUSE le mal de tête
(Il/elle avait peut-être mal à la tête avant)

Les vrais effets courants: nausées, diarrhée
```

**Solutions**:
1. **Consultez votre médecin/pharmacien**
   ```
   Lui: "Lesquels sont probables?"
   ```

2. **Priorisez par fréquence**
   ```
   Les premiers dans la liste sont les plus rapportés
   ```

3. **Consultez Drugs.com pour info médicale**
   ```
   https://www.drugs.com/ - données vérifiées par des médecins
   ```

---

### Problème 5: "Les interactions ne marchent pas"

**Symptôme**: Le bouton "Vérifier les interactions" est désactivé ou retourne aucun résultat

**Raison**:
- ❌ Vous n'avez pas au moins 2 médicaments dans votre liste
- ❌ La détection d'interactions est basique (bêta)
- ❌ OpenFDA n'a pas de DB d'interactions complète

**Solutions**:
1. **Ajoutez au moins 2 médicaments**
   ```
   Allez à l'onglet "Mes médicaments"
   Ajoutez 2 médicaments minimum
   Puis retournez à "Recherche OpenFDA"
   ```

2. **Consultez TOUJOURS un pharmacien**
   ```
   ⚠️ Cette détection est BASIQUE
   
   Pharmacien : EXPERT
   App: Outil d'info seulement
   
   Pour interactions critiques → PHARMACIEN
   ```

3. **Utilisez un vrai checker d'interactions**
   ```
   Medscape Interaction Checker: 
   https://reference.medscape.com/drug-interactionchecker
   
   Drugs.com Interaction Checker:
   https://www.drugs.com/drug_interactions.html
   ```

---

### Problème 6: L'app se freeze pendant la recherche

**Symptôme**: L'écran ne répond plus pendant une recherche OpenFDA

**Cause**:
- ❌ Timeout trop long (voir Problème 1)
- ❌ Appel API fait sur le main thread (bug)
- ❌ Widget rebuild à chaque caractère

**Solutions**:
1. **Attendez 10-15 secondes**
   ```
   Les appels API ont un timeout de 10s
   Si ca prend du temps, l'app attendra jusqu'à 10s
   ```

2. **Vérifiez que Provider n'est pas écouté**
   ```dart
   // BON: Provider avec listen: false
   Provider.of<Provider>(context, listen: false)
   
   // MAUVAIS: Provider qui écoute continuellement
   Provider.of<Provider>(context) // sans listen: false
   ```

3. **Signalez le bug**
   ```
   Si l'app freeze longtemps (>15s):
   1. Ouvrez les logs: flutter logs
   2. Cherchez les erreurs
   3. Signalez avec les logs
   ```

---

### Problème 7: L'API retourne des données étranges

**Symptôme**: Les informations affichées semblent incohérentes ou dupliquées

**Raison**:
- OpenFDA a parfois des formats de données inconsistants
- Certains médicaments ont plusieurs entrées

**Solutions**:
1. **C'est les données FDA - pas le bug de l'app**
   ```
   La responsabilité: FDA fournit les données
   Notre app: affiche les données
   ```

2. **Contactez OpenFDA si données incorrectes**
   ```
   https://open.fda.gov/updates/contact/
   ```

3. **Signalez à l'app si l'affichage est confus**
   ```
   On peut améliorer le formatage des données
   ```

---

## 🔍 Diagnostique - Comment déboguer

### Étape 1: Activez les logs Flutter

```bash
flutter logs
```

### Étape 2: Essayez la recherche et observez les logs

Recherchez les lignes contenant:
```
🔍 OpenFDA search:    [Votre recherche]
📋 Détails médicament: [Votre recherche]
✅ ... résultats trouvés
⚠️ Aucun résultat
❌ ... erreur
```

### Étape 3: Notez l'erreur exacte

```
Exemple de log utile:
I/flutter: ⚠️ Aucun résultat trouvé pour: metfromine
```

### Étape 4: Essayez variantes

```
flutter logs > ~/Desktop/healthify_logs.txt
# Ouvrez le fichier et cherchez les logs
```

---

## ✅ Vérification de Santé

Avant de reporter un bug, testez:

1. **Connexion Internet** ✅
   ```
   ping open.fda.gov
   # Doit retourner une réponse
   ```

2. **Appel API direct** ✅
   ```
   Ouvrez dans un navigateur:
   https://api.fda.gov/drug/label.json?search=openfda.brand_name:metformin&limit=1
   
   Doit retourner du JSON
   ```

3. **L'app compile** ✅
   ```
   flutter clean
   flutter pub get
   flutter run
   ```

4. **Logs sont visibles** ✅
   ```
   flutter logs
   # Doit afficher des lignes
   ```

---

## 📞 Où Obtenir de l'Aide

### Pour problèmes OpenFDA (données)
- 🏛️ **FDA**: https://open.fda.gov/
- 📧 **Contact FDA**: https://open.fda.gov/updates/contact/

### Pour problèmes app (technique)
- 🐛 **Bug Report**: Vérifiez flutter logs
- 💬 **Questions**: Consultez OPENFDA_GUIDE.md

### Pour questions médicales
- ⚕️ **Votre pharmacien** (EXPERT)
- 🏥 **Votre médecin**
- 📞 **Poison Control** (urgence): +1-800-222-1222 (USA)

### Pour infos sur les médicaments
- 💊 **Drugs.com**: https://www.drugs.com/
- 📋 **Medscape**: https://reference.medscape.com/
- 🏥 **Your Pharmacist**: Meilleure source!

---

## 🎯 Checklist Avant de Reporter un Bug

- [ ] Avez-vous une connexion Internet active?
- [ ] Avez-vous attendu 15 secondes?
- [ ] Avez-vous essayé différentes orthographes?
- [ ] Avez-vous consultez open.fda.gov directement?
- [ ] flutter logs montre une erreur spécifique?
- [ ] Le problème se reproduit à chaque fois?

Si vous cochez tout, alors c'est un vrai bug! 🐛

---

**Dernière mise à jour**: 7 décembre 2025

*L'objectif: Rendre votre expérience OpenFDA aussi smooth que possible!* ✨
