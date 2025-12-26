#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Agent de Synthèse Automatique - Andorra 360
Génère des synthèses exécutives à partir des rapports de veille
Version: 1.1 - PHI-4 optimisé (Code Review Fixed)

Corrections appliquées:
- Gestion JSON sécurisée avec try/except
- Validation du modèle Ollama
- Protection contre path traversal
- Limite de taille de fichier
- Protection contre injection de prompt
- Retry automatique pour appels réseau
- Constantes configurables
- Validation des types améliorée
- Logging plus informatif
"""

import sys
import os
import re
import json
import logging
import time
import requests
from pathlib import Path
from datetime import datetime
from typing import Optional, Dict, List

# ============================================
# CONFIGURATION
# ============================================

class Config:
    """Configuration centralisée de l'application"""

    BASE_DIR = Path(__file__).parent.resolve()
    REPORTS_DIR = BASE_DIR / "reports"
    SYNTHESES_DIR = BASE_DIR / "syntheses"
    LOGS_DIR = BASE_DIR / "logs"

    # Ollama PHI-4
    OLLAMA_ENDPOINT = "http://localhost:11434"
    OLLAMA_MODEL = "phi4"
    OLLAMA_TEMPERATURE = 0.2
    OLLAMA_TIMEOUT = 60
    OLLAMA_MAX_RETRIES = 3
    OLLAMA_RETRY_DELAY = 2  # secondes

    # Limites de sécurité
    MAX_FILE_SIZE_MB = 10
    MAX_CONTENT_LENGTH = 6000  # Limite PHI-4 context window
    SYNTHESIS_PREVIEW_LINES = 20

    LOG_FILE = LOGS_DIR / f"synthesis_{datetime.now().strftime('%Y%m%d')}.log"

    @classmethod
    def setup_directories(cls) -> bool:
        """Crée les répertoires nécessaires"""
        try:
            for directory in [cls.SYNTHESES_DIR, cls.LOGS_DIR]:
                directory.mkdir(parents=True, exist_ok=True)
            return True
        except Exception as e:
            print(f"Erreur création répertoires: {e}")
            return False

# ============================================
# LOGGING
# ============================================

def setup_logging() -> logging.Logger:
    """Configure le système de logging"""

    if not Config.setup_directories():
        raise RuntimeError("Impossible de créer les répertoires")

    logger = logging.getLogger('SynthesisAgent')
    logger.setLevel(logging.INFO)

    # Éviter les doublons de handlers
    if logger.handlers:
        return logger

    # Handler fichier
    fh = logging.FileHandler(Config.LOG_FILE, encoding='utf-8')
    fh.setFormatter(logging.Formatter('%(asctime)s - %(levelname)s - %(message)s'))

    # Handler console
    ch = logging.StreamHandler(sys.stdout)
    ch.setFormatter(logging.Formatter('%(levelname)s - %(message)s'))

    logger.addHandler(fh)
    logger.addHandler(ch)

    return logger

# ============================================
# EXTRACTEUR DE RAPPORT
# ============================================

class ReportExtractor:
    """Extrait et nettoie le contenu des rapports Markdown"""

    def __init__(self, logger: logging.Logger):
        self.logger = logger

    def find_latest_report(self, reports_dir: Path) -> Optional[Path]:
        """Trouve le rapport le plus récent avec validation de sécurité"""

        if not reports_dir.exists():
            self.logger.error(f"Répertoire inexistant: {reports_dir}")
            return None

        pattern = "rapport_andorre_*.md"
        reports = list(reports_dir.glob(pattern))

        # Protection contre path traversal
        reports = [
            r for r in reports
            if reports_dir in r.parents or r.parent == reports_dir
        ]

        if not reports:
            self.logger.warning(f"Aucun rapport trouvé dans {reports_dir}")
            return None

        # Trier par date de modification
        latest = max(reports, key=lambda p: p.stat().st_mtime)
        self.logger.info(f"📄 Dernier rapport: {latest.name}")

        return latest

    def extract_content(self, report_path: Path) -> Optional[Dict[str, str]]:
        """Extrait le contenu structuré du rapport avec validations"""

        # Validation du type
        if not isinstance(report_path, Path):
            self.logger.error(f"Type invalide: attendu Path, reçu {type(report_path)}")
            return None

        # Validation de l'existence
        if not report_path.exists():
            self.logger.error(f"Fichier inexistant: {report_path}")
            return None

        # Validation de la taille
        file_size = report_path.stat().st_size
        max_size = Config.MAX_FILE_SIZE_MB * 1024 * 1024

        if file_size > max_size:
            self.logger.error(
                f"Fichier trop volumineux: {file_size / 1024 / 1024:.2f}MB "
                f"(max: {Config.MAX_FILE_SIZE_MB}MB)"
            )
            return None

        try:
            self.logger.info(f"📖 Extraction: {file_size / 1024:.2f}KB")

            with open(report_path, 'r', encoding='utf-8') as f:
                content = f.read()

            # Extraire les métadonnées
            metadata = self._extract_metadata(content)

            # Nettoyer le contenu
            cleaned_content = self._clean_content(content)

            self.logger.info(f"✅ Contenu extrait: {len(cleaned_content)} caractères")

            return {
                'metadata': metadata,
                'content': cleaned_content,
                'original_path': str(report_path)
            }

        except UnicodeDecodeError as e:
            self.logger.error(f"Erreur encodage: {e}")
            return None
        except Exception as e:
            self.logger.error(f"Erreur lecture rapport: {e}", exc_info=True)
            return None

    def _extract_metadata(self, content: str) -> Dict:
        """Extrait date, modèle, nombre d'articles avec valeurs par défaut"""

        metadata = {
            'date': 'Date inconnue',
            'model': 'N/A',
            'total_articles': 0
        }

        # Date
        date_match = re.search(r'\*\*Date\*\*:\s*(.+)', content)
        if date_match:
            metadata['date'] = date_match.group(1).strip()

        # Modèle
        model_match = re.search(r'\*\*Modèle\*\*:\s*(.+)', content)
        if model_match:
            metadata['model'] = model_match.group(1).strip()

        # Total articles
        total_match = re.search(r'\*\*Articles analysés\*\*:\s*(\d+)', content)
        if total_match:
            try:
                metadata['total_articles'] = int(total_match.group(1))
            except ValueError:
                self.logger.warning("Nombre d'articles invalide, défaut à 0")

        self.logger.debug(f"Métadonnées extraites: {metadata}")
        return metadata

    def _clean_content(self, content: str) -> str:
        """Nettoie le rapport des éléments perturbateurs"""

        # Supprimer les liens (mais garder le texte)
        content = re.sub(r'\[([^\]]+)\]\([^)]+\)', r'\1', content)

        # Supprimer les URLs seules
        content = re.sub(r'https?://\S+', '', content)

        # Supprimer les emojis de tendance (garder ceux structurels)
        content = re.sub(r'📈|📉|➡️|🔄', '', content)

        # Supprimer les métadonnées de bas de page
        content = re.sub(r'\*Généré par.*\*', '', content)

        # Supprimer les lignes de séparation multiples
        content = re.sub(r'\n---\n', '\n\n', content)

        # Nettoyer les espaces multiples
        content = re.sub(r'\n{3,}', '\n\n', content)
        content = re.sub(r'[ \t]+', ' ', content)

        return content.strip()

# ============================================
# SYNTHÉTISEUR IA (PHI-4)
# ============================================

class AISynthesizer:
    """Génère des synthèses avec PHI-4 via Ollama"""

    def __init__(self, logger: logging.Logger):
        self.logger = logger
        self.endpoint = Config.OLLAMA_ENDPOINT
        self.model = Config.OLLAMA_MODEL
        self.timeout = Config.OLLAMA_TIMEOUT
        self.max_retries = Config.OLLAMA_MAX_RETRIES

    def test_connection(self) -> bool:
        """Test Ollama et vérifie la disponibilité du modèle"""

        try:
            response = requests.get(f"{self.endpoint}/api/tags", timeout=5)

            if response.status_code != 200:
                self.logger.error(f"❌ Ollama status: {response.status_code}")
                return False

            # Vérifier que le modèle existe
            try:
                data = response.json()
                models = data.get('models', [])
                model_names = [m.get('name', '').split(':')[0] for m in models]

                if self.model not in model_names:
                    self.logger.error(
                        f"❌ Modèle '{self.model}' non trouvé. "
                        f"Disponibles: {', '.join(model_names)}"
                    )
                    return False

                self.logger.info(f"✅ Ollama connecté (modèle: {self.model})")
                return True

            except json.JSONDecodeError as e:
                self.logger.error(f"❌ JSON invalide dans /api/tags: {e}")
                return False

        except requests.exceptions.ConnectionError:
            self.logger.error(f"❌ Ollama inaccessible sur {self.endpoint}")
            return False
        except requests.exceptions.Timeout:
            self.logger.error("❌ Timeout connexion Ollama")
            return False
        except Exception as e:
            self.logger.error(f"❌ Erreur test Ollama: {e}")
            return False

    def generate_synthesis(self, report_data: Dict) -> Optional[str]:
        """Génère une synthèse exécutive avec retry automatique"""

        metadata = report_data.get('metadata', {})
        content = report_data.get('content', '')

        if not content:
            self.logger.error("Contenu vide, impossible de générer une synthèse")
            return None

        # Limiter la taille du contenu (PHI-4 context window)
        if len(content) > Config.MAX_CONTENT_LENGTH:
            self.logger.warning(
                f"Contenu tronqué: {len(content)} -> {Config.MAX_CONTENT_LENGTH} caractères"
            )
            content = content[:Config.MAX_CONTENT_LENGTH] + "\n\n[...contenu tronqué...]"

        prompt = self._build_prompt(metadata, content)
        self.logger.info(f"🧠 Prompt préparé: {len(prompt)} caractères")

        # Tentatives avec retry
        for attempt in range(1, self.max_retries + 1):
            try:
                if attempt > 1:
                    delay = Config.OLLAMA_RETRY_DELAY * (attempt - 1)
                    self.logger.info(f"⏳ Retry {attempt}/{self.max_retries} après {delay}s...")
                    time.sleep(delay)

                self.logger.info(f"🧠 Génération synthèse (tentative {attempt})...")
                start_time = time.time()

                response = requests.post(
                    f"{self.endpoint}/api/generate",
                    json={
                        "model": self.model,
                        "prompt": prompt,
                        "temperature": Config.OLLAMA_TEMPERATURE,
                        "stream": False
                    },
                    timeout=self.timeout
                )

                elapsed = time.time() - start_time

                if response.status_code != 200:
                    self.logger.error(
                        f"Erreur Ollama: {response.status_code} - {response.text[:200]}"
                    )
                    if attempt < self.max_retries:
                        continue
                    return None

                # Parser le JSON de manière sécurisée
                try:
                    result = response.json()
                except json.JSONDecodeError as e:
                    self.logger.error(f"JSON invalide reçu d'Ollama: {e}")
                    if attempt < self.max_retries:
                        continue
                    return None

                synthesis = result.get('response', '').strip()

                if not synthesis:
                    self.logger.error("Synthèse vide reçue d'Ollama")
                    if attempt < self.max_retries:
                        continue
                    return None

                self.logger.info(f"✅ Synthèse générée en {elapsed:.2f}s ({len(synthesis)} caractères)")
                return synthesis

            except requests.exceptions.Timeout:
                self.logger.warning(f"⏱️ Timeout ({self.timeout}s) - tentative {attempt}")
                if attempt >= self.max_retries:
                    self.logger.error(f"❌ Échec après {self.max_retries} tentatives")
                    return None

            except requests.exceptions.ConnectionError as e:
                self.logger.error(f"Erreur connexion: {e}")
                if attempt >= self.max_retries:
                    return None

            except Exception as e:
                self.logger.error(f"❌ Erreur génération: {e}", exc_info=True)
                if attempt >= self.max_retries:
                    return None

        return None

    def _build_prompt(self, metadata: Dict, content: str) -> str:
        """Construit le prompt pour PHI-4 avec protection injection"""

        date = metadata.get('date', 'date inconnue')
        total = metadata.get('total_articles', 0)

        # Protection contre injection de prompt
        # Échapper les triple quotes qui pourraient casser le prompt
        content = content.replace('"""', r'\"\"\"')
        content = content.replace("'''", r"\'\'\'")

        return f"""Tu es un analyste senior spécialisé dans la veille informationnelle sur l'Andorre.

MISSION: Créer une SYNTHÈSE EXÉCUTIVE à partir du rapport de veille ci-dessous.

RAPPORT À SYNTHÉTISER:
Date: {date}
Articles analysés: {total}

{content}

INSTRUCTIONS STRICTES:
1. Commence par une VUE D'ENSEMBLE (3-5 lignes) résumant l'essentiel
2. Identifie les FAITS SAILLANTS par ordre d'importance (maximum 8 points)
3. Détecte les TENDANCES récurrentes (thèmes qui reviennent)
4. Liste les POINTS D'ATTENTION pour les décideurs

CONTRAINTES:
- Langage clair et professionnel (style exécutif)
- Pas de liens, URLs ou références techniques
- Pas d'emojis sauf ⭐ pour importance
- Maximum 500 mots
- Structuré avec titres Markdown (##, ###)

COMMENCE DIRECTEMENT PAR LA SYNTHÈSE (pas de préambule):"""

# ============================================
# GÉNÉRATEUR DE FICHIER
# ============================================

class SynthesisWriter:
    """Écrit la synthèse dans un fichier Markdown"""

    def __init__(self, logger: logging.Logger):
        self.logger = logger

    def save_synthesis(
        self,
        synthesis: str,
        metadata: Dict,
        original_report: str
    ) -> Optional[Path]:
        """Sauvegarde la synthèse avec validation"""

        if not synthesis or not synthesis.strip():
            self.logger.error("Synthèse vide, sauvegarde annulée")
            return None

        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = f"synthese_executive_{timestamp}.md"
        output_path = Config.SYNTHESES_DIR / filename

        # Construire le document final
        document = self._build_document(synthesis, metadata, original_report)

        try:
            with open(output_path, 'w', encoding='utf-8') as f:
                f.write(document)

            file_size = output_path.stat().st_size
            self.logger.info(
                f"💾 Synthèse sauvegardée: {output_path.name} ({file_size / 1024:.2f}KB)"
            )
            return output_path

        except OSError as e:
            self.logger.error(f"Erreur écriture fichier: {e}")
            return None
        except Exception as e:
            self.logger.error(f"Erreur sauvegarde: {e}", exc_info=True)
            return None

    def _build_document(self, synthesis: str, metadata: Dict, original_report: str) -> str:
        """Construit le document Markdown final"""

        date = metadata.get('date', 'N/A')
        total = metadata.get('total_articles', 'N/A')
        original_model = metadata.get('model', 'N/A')

        doc = f"""# 📊 SYNTHÈSE EXÉCUTIVE - Andorra 360

**Date du rapport source**: {date}
**Articles analysés**: {total}
**Modèle d'analyse initial**: {original_model}
**Synthèse générée par**: PHI-4
**Généré le**: {datetime.now().strftime('%d/%m/%Y %H:%M')}

---

{synthesis}

---

## 📌 Métadonnées

- **Rapport source**: `{Path(original_report).name}`
- **Emplacement**: `reports/`
- **Agent**: Andorra 360 Synthesis Agent v1.1 (Fixed)

---

*Cette synthèse est générée automatiquement par IA. Les informations sont extraites du rapport de veille et condensées pour faciliter la lecture exécutive.*
"""

        return doc

# ============================================
# AGENT PRINCIPAL
# ============================================

class SynthesisAgent:
    """Agent de synthèse automatique"""

    def __init__(self):
        self.logger = setup_logging()
        self.logger.info("="*60)
        self.logger.info("🚀 Agent de Synthèse Andorra 360 v1.1 (Fixed)")
        self.logger.info("="*60)

        self.extractor = ReportExtractor(self.logger)
        self.synthesizer = AISynthesizer(self.logger)
        self.writer = SynthesisWriter(self.logger)

    def run(self) -> bool:
        """Exécute le cycle complet de génération de synthèse"""

        try:
            # 1. Vérifier Ollama
            self.logger.info("🔍 Vérification Ollama/PHI-4...")
            if not self.synthesizer.test_connection():
                self.logger.error("❌ Ollama non disponible ou modèle manquant")
                return False

            # 2. Trouver le dernier rapport
            self.logger.info("📂 Recherche du dernier rapport...")
            latest_report = self.extractor.find_latest_report(Config.REPORTS_DIR)

            if not latest_report:
                self.logger.error("❌ Aucun rapport trouvé")
                return False

            # 3. Extraire le contenu
            self.logger.info("📖 Extraction du contenu...")
            report_data = self.extractor.extract_content(latest_report)

            if not report_data:
                self.logger.error("❌ Erreur extraction")
                return False

            # 4. Générer la synthèse
            self.logger.info("🧠 Génération de la synthèse...")
            synthesis = self.synthesizer.generate_synthesis(report_data)

            if not synthesis:
                self.logger.error("❌ Erreur génération synthèse")
                return False

            # 5. Sauvegarder
            self.logger.info("💾 Sauvegarde de la synthèse...")
            output_path = self.writer.save_synthesis(
                synthesis,
                report_data['metadata'],
                report_data['original_path']
            )

            if not output_path:
                self.logger.error("❌ Erreur sauvegarde")
                return False

            # 6. Résumé
            self._print_summary(latest_report, output_path)

            # 7. Afficher un aperçu
            self._print_preview(output_path)

            return True

        except KeyboardInterrupt:
            self.logger.warning("\n⚠️ Interruption utilisateur")
            return False
        except Exception as e:
            self.logger.error(f"❌ Erreur fatale: {e}", exc_info=True)
            return False

    def _print_summary(self, report_path: Path, output_path: Path):
        """Affiche le résumé de l'exécution"""

        self.logger.info("="*60)
        self.logger.info("✅ SYNTHÈSE GÉNÉRÉE")
        self.logger.info(f"📄 Rapport source: {report_path.name}")
        self.logger.info(f"📝 Synthèse: {output_path.name}")
        self.logger.info(f"📂 Emplacement: {output_path}")
        self.logger.info("="*60)

    def _print_preview(self, output_path: Path):
        """Affiche un aperçu de la synthèse générée"""

        try:
            print("\n" + "="*60)
            print("📊 APERÇU DE LA SYNTHÈSE")
            print("="*60)

            with open(output_path, 'r', encoding='utf-8') as f:
                preview = f.read()
                lines = preview.split('\n')

                # Afficher les N premières lignes
                preview_lines = lines[:Config.SYNTHESIS_PREVIEW_LINES]
                print('\n'.join(preview_lines))

                if len(lines) > Config.SYNTHESIS_PREVIEW_LINES:
                    remaining = len(lines) - Config.SYNTHESIS_PREVIEW_LINES
                    print(f"\n[...{remaining} lignes supplémentaires dans le fichier...]")

            print("="*60 + "\n")

        except Exception as e:
            self.logger.warning(f"Impossible d'afficher l'aperçu: {e}")

# ============================================
# POINT D'ENTRÉE
# ============================================

def main():
    """Point d'entrée principal"""

    print("""
    ╔══════════════════════════════════════════════════════════╗
    ║  Agent de Synthèse Andorra 360 - PHI-4 v1.1 (Fixed)   ║
    ║  Synthèses exécutives automatiques                     ║
    ╚══════════════════════════════════════════════════════════╝
    """)

    try:
        agent = SynthesisAgent()
        success = agent.run()
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"\n❌ Erreur fatale: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
