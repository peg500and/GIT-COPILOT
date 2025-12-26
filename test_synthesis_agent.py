#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de test pour vérifier le bon fonctionnement du Synthesis Agent v1.1
"""

import sys
from pathlib import Path

def test_imports():
    """Test 1: Vérifier que tous les imports fonctionnent"""
    print("🧪 Test 1: Imports...")
    try:
        import requests
        import json
        import logging
        print("   ✅ Modules standards OK")
        return True
    except ImportError as e:
        print(f"   ❌ Erreur import: {e}")
        return False

def test_syntax():
    """Test 2: Vérifier la syntaxe du fichier"""
    print("🧪 Test 2: Syntaxe Python...")
    try:
        import py_compile
        py_compile.compile('synthesis_agent_fixed.py', doraise=True)
        print("   ✅ Syntaxe valide")
        return True
    except py_compile.PyCompileError as e:
        print(f"   ❌ Erreur syntaxe: {e}")
        return False

def test_config():
    """Test 3: Vérifier la classe Config"""
    print("🧪 Test 3: Configuration...")
    try:
        sys.path.insert(0, str(Path(__file__).parent))
        from synthesis_agent_fixed import Config

        assert Config.MAX_FILE_SIZE_MB == 10, "MAX_FILE_SIZE_MB incorrect"
        assert Config.MAX_CONTENT_LENGTH == 6000, "MAX_CONTENT_LENGTH incorrect"
        assert Config.OLLAMA_MAX_RETRIES == 3, "OLLAMA_MAX_RETRIES incorrect"
        assert Config.OLLAMA_MODEL == "phi4", "OLLAMA_MODEL incorrect"

        print("   ✅ Configuration OK")
        return True
    except Exception as e:
        print(f"   ❌ Erreur config: {e}")
        return False

def test_classes():
    """Test 4: Vérifier l'instanciation des classes"""
    print("🧪 Test 4: Classes...")
    try:
        sys.path.insert(0, str(Path(__file__).parent))
        from synthesis_agent_fixed import (
            ReportExtractor,
            AISynthesizer,
            SynthesisWriter,
            setup_logging
        )

        logger = setup_logging()

        # Tester l'instanciation
        extractor = ReportExtractor(logger)
        synthesizer = AISynthesizer(logger)
        writer = SynthesisWriter(logger)

        print("   ✅ Classes instanciables")
        return True
    except Exception as e:
        print(f"   ❌ Erreur classes: {e}")
        return False

def test_security_features():
    """Test 5: Vérifier les features de sécurité"""
    print("🧪 Test 5: Features de sécurité...")
    try:
        with open('synthesis_agent_fixed.py', 'r') as f:
            content = f.read()

        checks = [
            ('Path traversal protection', 'reports_dir in r.parents'),
            ('File size check', 'MAX_FILE_SIZE_MB'),
            ('JSON error handling', 'json.JSONDecodeError'),
            ('Prompt injection protection', 'replace(\'"""\''),
            ('Retry mechanism', 'max_retries'),
        ]

        all_ok = True
        for name, pattern in checks:
            if pattern in content:
                print(f"   ✅ {name}")
            else:
                print(f"   ❌ {name} manquant")
                all_ok = False

        return all_ok
    except Exception as e:
        print(f"   ❌ Erreur: {e}")
        return False

def main():
    """Exécute tous les tests"""
    print("\n" + "="*60)
    print("🔍 TESTS DE VALIDATION - Synthesis Agent v1.1 (Fixed)")
    print("="*60 + "\n")

    tests = [
        test_imports,
        test_syntax,
        test_config,
        test_classes,
        test_security_features,
    ]

    results = []
    for test in tests:
        try:
            results.append(test())
        except Exception as e:
            print(f"   ❌ Exception: {e}")
            results.append(False)
        print()

    # Résumé
    print("="*60)
    passed = sum(results)
    total = len(results)

    print(f"📊 RÉSULTAT: {passed}/{total} tests passés")

    if passed == total:
        print("✅ Tous les tests sont passés !")
        print("="*60)
        return 0
    else:
        print(f"❌ {total - passed} test(s) échoué(s)")
        print("="*60)
        return 1

if __name__ == "__main__":
    sys.exit(main())
