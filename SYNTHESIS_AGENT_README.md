# 📚 Guide d'Utilisation - Synthesis Agent v1.1 (Fixed)

## 📁 Fichiers Créés

```
GIT-COPILOT/
├── synthesis_agent_fixed.py          # ✅ Code corrigé et sécurisé
├── SYNTHESIS_AGENT_CHANGELOG.md      # 📋 Liste détaillée des corrections
├── SYNTHESIS_AGENT_README.md         # 📚 Ce fichier
└── test_synthesis_agent.py           # 🧪 Tests de validation
```

---

## 🚀 Installation

### 1. Remplacer l'ancien code (optionnel)

```bash
# Sauvegarder l'ancienne version
mv synthesis_agent.py synthesis_agent_v1.0_backup.py

# Utiliser la nouvelle version
mv synthesis_agent_fixed.py synthesis_agent.py
```

### 2. Rendre exécutable

```bash
chmod +x synthesis_agent.py
```

### 3. Vérifier les prérequis

```bash
# Tester que tout fonctionne
python3 test_synthesis_agent.py
```

**Résultat attendu**:
```
✅ Tous les tests sont passés !
```

---

## 🎯 Utilisation

### Lancement Simple

```bash
python3 synthesis_agent.py
```

### Exemple de Sortie

```
    ╔══════════════════════════════════════════════════════════╗
    ║  Agent de Synthèse Andorra 360 - PHI-4 v1.1 (Fixed)   ║
    ║  Synthèses exécutives automatiques                     ║
    ╚══════════════════════════════════════════════════════════╝

INFO - 🔍 Vérification Ollama/PHI-4...
INFO - ✅ Ollama connecté (modèle: phi4)
INFO - 📂 Recherche du dernier rapport...
INFO - 📄 Dernier rapport: rapport_andorre_20251226.md
INFO - 📖 Extraction: 45.32KB
INFO - ✅ Contenu extrait: 12450 caractères
INFO - 🧠 Prompt préparé: 13200 caractères
INFO - 🧠 Génération synthèse (tentative 1)...
INFO - ✅ Synthèse générée en 8.45s (1234 caractères)
INFO - 💾 Synthèse sauvegardée: synthese_executive_20251226_143022.md (3.21KB)
```

---

## 🔧 Configuration

Toutes les constantes sont centralisées dans la classe `Config`:

```python
class Config:
    # Répertoires
    REPORTS_DIR = BASE_DIR / "reports"
    SYNTHESES_DIR = BASE_DIR / "syntheses"
    LOGS_DIR = BASE_DIR / "logs"

    # Ollama
    OLLAMA_ENDPOINT = "http://localhost:11434"
    OLLAMA_MODEL = "phi4"
    OLLAMA_TEMPERATURE = 0.2
    OLLAMA_TIMEOUT = 60
    OLLAMA_MAX_RETRIES = 3
    OLLAMA_RETRY_DELAY = 2

    # Sécurité
    MAX_FILE_SIZE_MB = 10
    MAX_CONTENT_LENGTH = 6000
    SYNTHESIS_PREVIEW_LINES = 20
```

### Personnalisation

Pour modifier la configuration, éditez directement la classe `Config` dans le fichier.

---

## 🛡️ Améliorations de Sécurité

### 1. Protection Path Traversal
Le code valide que tous les fichiers sont bien dans le répertoire autorisé.

### 2. Limite de Taille
Les fichiers > 10MB sont rejetés automatiquement.

### 3. Validation JSON
Les réponses Ollama invalides sont gérées proprement.

### 4. Protection Injection Prompt
Les caractères spéciaux sont échappés avant injection dans le prompt.

### 5. Retry Réseau
3 tentatives automatiques avec délai exponentiel en cas d'échec.

---

## 🐛 Résolution de Problèmes

### Problème: "Ollama non disponible"

**Solution**:
```bash
# Vérifier qu'Ollama est lancé
curl http://localhost:11434/api/tags

# Si non lancé, démarrer Ollama
ollama serve
```

---

### Problème: "Modèle phi4 non trouvé"

**Solution**:
```bash
# Télécharger le modèle PHI-4
ollama pull phi4

# Vérifier les modèles disponibles
ollama list
```

---

### Problème: "Aucun rapport trouvé"

**Solution**:
```bash
# Vérifier que le répertoire reports/ existe
ls -la reports/

# Vérifier le format des noms de fichiers
# Format attendu: rapport_andorre_*.md
```

---

### Problème: "Fichier trop volumineux"

**Solution 1** (augmenter la limite):
```python
class Config:
    MAX_FILE_SIZE_MB = 20  # Augmenter à 20MB
```

**Solution 2** (réduire le fichier):
```bash
# Compresser ou diviser le rapport
```

---

### Problème: "Timeout Ollama"

**Solution**:
```python
class Config:
    OLLAMA_TIMEOUT = 120  # Augmenter à 2 minutes
    OLLAMA_MAX_RETRIES = 5  # Plus de tentatives
```

---

## 📊 Différences avec la v1.0

| Feature | v1.0 | v1.1 |
|---------|------|------|
| Gestion erreurs JSON | ❌ | ✅ |
| Validation modèle | ❌ | ✅ |
| Protection path traversal | ❌ | ✅ |
| Limite taille fichier | ❌ | ✅ |
| Retry automatique | ❌ | ✅ |
| Configuration centralisée | ⚠️ | ✅ |
| Logging détaillé | ✅ | ✅+ |
| Type hints complets | ⚠️ | ✅ |

---

## 🧪 Tests

### Lancer les Tests

```bash
python3 test_synthesis_agent.py
```

### Tests Inclus

1. ✅ Imports des modules
2. ✅ Syntaxe Python valide
3. ✅ Configuration correcte
4. ✅ Classes instanciables
5. ✅ Features de sécurité présentes

---

## 📝 Structure du Code

```
synthesis_agent_fixed.py
├── Config                    # Configuration centralisée
├── setup_logging()          # Initialisation logs
├── ReportExtractor          # Extraction rapports
│   ├── find_latest_report() # Recherche fichier
│   ├── extract_content()    # Lecture + validation
│   └── _clean_content()     # Nettoyage texte
├── AISynthesizer            # Génération synthèses
│   ├── test_connection()    # Validation Ollama
│   ├── generate_synthesis() # Appel IA avec retry
│   └── _build_prompt()      # Construction prompt
├── SynthesisWriter          # Sauvegarde fichiers
│   ├── save_synthesis()     # Écriture MD
│   └── _build_document()    # Construction document
└── SynthesisAgent           # Orchestration
    ├── run()                # Cycle complet
    ├── _print_summary()     # Résumé exécution
    └── _print_preview()     # Aperçu synthèse
```

---

## 🔍 Logs

Les logs sont sauvegardés dans:
```
logs/synthesis_YYYYMMDD.log
```

**Format**:
```
2025-12-26 14:30:22 - INFO - 🔍 Vérification Ollama/PHI-4...
2025-12-26 14:30:22 - INFO - ✅ Ollama connecté (modèle: phi4)
2025-12-26 14:30:23 - ERROR - ❌ Fichier trop volumineux: 15.32MB (max: 10MB)
```

---

## 📈 Performance

### Temps Moyens

| Étape | Temps Moyen |
|-------|-------------|
| Vérification Ollama | < 1s |
| Recherche rapport | < 1s |
| Extraction contenu | < 1s |
| Génération synthèse | 8-15s |
| Sauvegarde | < 1s |
| **TOTAL** | **10-18s** |

### Optimisations

- Limite context window à 6000 caractères
- Cache logging (pas de recréation handlers)
- Validation early (échec rapide si erreur)

---

## 🎓 Bonnes Pratiques

### 1. Surveillance des Logs
```bash
# Suivre les logs en temps réel
tail -f logs/synthesis_*.log
```

### 2. Rotation des Logs
Les logs sont automatiquement créés par date. Nettoyer régulièrement:
```bash
# Supprimer logs > 30 jours
find logs/ -name "synthesis_*.log" -mtime +30 -delete
```

### 3. Vérification Modèle
Avant utilisation intensive:
```bash
# Test rapide
ollama run phi4 "Test"
```

---

## 🆘 Support

### Erreurs Courantes

**ValueError: invalid literal for int()**
→ Métadonnées corrompues dans le rapport source

**ConnectionRefusedError**
→ Ollama n'est pas démarré

**JSONDecodeError**
→ Réponse Ollama invalide (désormais géré automatiquement)

---

## 📜 Licence

Même licence que le projet original Andorra 360.

---

## 👤 Auteur

**Version originale**: Développeur Andorra 360
**Code Review & Fixes**: AI Code Reviewer
**Date**: 2025-12-26

---

## 🔄 Changelog

Voir `SYNTHESIS_AGENT_CHANGELOG.md` pour la liste complète des corrections.

---

## ✅ Checklist de Déploiement

- [ ] Sauvegarder l'ancienne version
- [ ] Copier `synthesis_agent_fixed.py`
- [ ] Lancer `test_synthesis_agent.py`
- [ ] Vérifier qu'Ollama est lancé
- [ ] Vérifier que `phi4` est installé
- [ ] Tester avec un rapport réel
- [ ] Vérifier les logs
- [ ] Vérifier la synthèse générée

---

**Prêt à l'emploi ! 🚀**
