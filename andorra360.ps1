<#
.SYNOPSIS
    Agent Andorra 360 - Gestionnaire Complet Optimisé

.DESCRIPTION
    Script PowerShell tout-en-un pour gérer l'agent de veille informationnelle
    sur l'Andorre avec analyse IA locale (PHI-4/Gemma via Ollama)

.PARAMETER Action
    Action à exécuter : setup, run, quick, status, clean, schedule, dashboard

.PARAMETER DryRun
    Mode test sans modifications réelles

.EXAMPLE
    .\andorra360.ps1 -Action setup
    .\andorra360.ps1 -Action run
    .\andorra360.ps1 -Action quick

.NOTES
    Version: 2.2
    Auteur: Erol GIRAUDY
    Date: 26 décembre 2025
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('setup', 'run', 'quick', 'status', 'clean', 'schedule', 'dashboard', 'update', 'backup')]
    [string]$Action = 'run',

    [Parameter(Mandatory=$false)]
    [switch]$DryRun,

    [Parameter(Mandatory=$false)]
    [switch]$Verbose,

    [Parameter(Mandatory=$false)]
    [ValidateSet('quick', 'balanced', 'deep')]
    [string]$Mode = 'balanced'
)

# ============================================
# CONFIGURATION GLOBALE
# ============================================

$ErrorActionPreference = "Stop"
$Global:Config = @{
    ProjectName = "Agent Andorra 360"
    Version = "2.2"
    BaseDir = $PSScriptRoot
    PythonMinVersion = "3.9"
    OllamaModel = "phi4"  # ou "gemma"

    # Chemins
    VenvPath = Join-Path $PSScriptRoot "venv"
    ConfigPath = Join-Path $PSScriptRoot "config"
    DataPath = Join-Path $PSScriptRoot "data"
    ReportsPath = Join-Path $PSScriptRoot "reports"
    LogsPath = Join-Path $PSScriptRoot "logs"

    # Fichiers
    SourcesConfig = Join-Path $PSScriptRoot "config\sources_andorre.yaml"
    DatabaseFile = Join-Path $PSScriptRoot "data\articles_andorre.db"
    RequirementsFile = Join-Path $PSScriptRoot "requirements.txt"

    # Modes d'exécution
    Modes = @{
        quick = @{
            max_articles = 10
            max_items_per_source = 10
            delay = 0.5
        }
        balanced = @{
            max_articles = 15
            max_items_per_source = 15
            delay = 1.0
        }
        deep = @{
            max_articles = 30
            max_items_per_source = 30
            delay = 2.0
        }
    }
}

# ============================================
# FONCTIONS UTILITAIRES
# ============================================

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Type = "Info"
    )

    $timestamp = Get-Date -Format "HH:mm:ss"

    switch ($Type) {
        "Success" { Write-Host "[$timestamp] ✅ $Message" -ForegroundColor Green }
        "Error"   { Write-Host "[$timestamp] ❌ $Message" -ForegroundColor Red }
        "Warning" { Write-Host "[$timestamp] ⚠️  $Message" -ForegroundColor Yellow }
        "Info"    { Write-Host "[$timestamp] ℹ️  $Message" -ForegroundColor Cyan }
        "Debug"   { if ($Verbose) { Write-Host "[$timestamp] 🔍 $Message" -ForegroundColor Gray } }
        default   { Write-Host "[$timestamp] $Message" }
    }
}

function Show-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║       Agent Andorra 360 - Intelligence Dashboard        ║" -ForegroundColor Magenta
    Write-Host "║              Version $($Global:Config.Version) - Optimisé Windows 11           ║" -ForegroundColor Magenta
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""
}

function Test-Prerequisites {
    Write-ColorOutput "Vérification des prérequis..." "Info"

    $allOk = $true

    # Python
    try {
        $pythonVersion = python --version 2>&1
        if ($pythonVersion -match "Python (\d+\.\d+)") {
            $version = [version]$matches[1]
            if ($version -ge [version]$Global:Config.PythonMinVersion) {
                Write-ColorOutput "Python $version détecté" "Success"
            } else {
                Write-ColorOutput "Python $version trop ancien (minimum $($Global:Config.PythonMinVersion))" "Error"
                $allOk = $false
            }
        }
    } catch {
        Write-ColorOutput "Python non trouvé dans le PATH" "Error"
        $allOk = $false
    }

    # Ollama
    try {
        $ollamaCheck = ollama list 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "Ollama détecté et fonctionnel" "Success"

            # Vérifier le modèle
            if ($ollamaCheck -match $Global:Config.OllamaModel) {
                Write-ColorOutput "Modèle $($Global:Config.OllamaModel) disponible" "Success"
            } else {
                Write-ColorOutput "Modèle $($Global:Config.OllamaModel) non trouvé" "Warning"
                Write-ColorOutput "Exécutez: ollama pull $($Global:Config.OllamaModel)" "Info"
            }
        }
    } catch {
        Write-ColorOutput "Ollama non trouvé ou non démarré" "Error"
        $allOk = $false
    }

    return $allOk
}

function Initialize-Directories {
    Write-ColorOutput "Création des répertoires..." "Info"

    $directories = @(
        $Global:Config.ConfigPath,
        $Global:Config.DataPath,
        $Global:Config.ReportsPath,
        $Global:Config.LogsPath
    )

    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-ColorOutput "Créé: $dir" "Success"
        }
    }
}

function Setup-VirtualEnvironment {
    Write-ColorOutput "Configuration de l'environnement virtuel..." "Info"

    if (Test-Path $Global:Config.VenvPath) {
        Write-ColorOutput "Environnement virtuel existe déjà" "Info"
        return $true
    }

    try {
        Write-ColorOutput "Création de l'environnement virtuel..." "Info"
        python -m venv $Global:Config.VenvPath

        Write-ColorOutput "Activation de l'environnement..." "Info"
        $activateScript = Join-Path $Global:Config.VenvPath "Scripts\Activate.ps1"
        & $activateScript

        Write-ColorOutput "Installation des dépendances..." "Info"
        python -m pip install --upgrade pip --quiet

        # Dépendances principales
        $packages = @(
            "pyyaml",
            "feedparser",
            "requests",
            "urllib3",
            "python-dateutil"
        )

        foreach ($package in $packages) {
            Write-ColorOutput "Installation: $package" "Debug"
            python -m pip install $package --quiet
        }

        # Dépendances optionnelles
        try {
            python -m pip install win10toast --quiet
            Write-ColorOutput "win10toast installé (notifications)" "Success"
        } catch {
            Write-ColorOutput "win10toast non installé (optionnel)" "Warning"
        }

        Write-ColorOutput "Environnement virtuel configuré" "Success"
        return $true

    } catch {
        Write-ColorOutput "Erreur lors de la configuration: $_" "Error"
        return $false
    }
}

function Create-ConfigurationFile {
    param(
        [string]$ConfigMode = "balanced"
    )

    Write-ColorOutput "Génération du fichier de configuration..." "Info"

    $modeConfig = $Global:Config.Modes[$ConfigMode]

    $yamlContent = @"
# Configuration Agent Andorra 360 - Optimisé
# Version: $($Global:Config.Version)
# Mode: $ConfigMode
# Généré: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

general:
  # Configuration IA
  ollama_model: "$($Global:Config.OllamaModel)"
  ollama_temperature: 0.1
  ollama_num_predict: 500
  ollama_endpoint: "http://localhost:11434"
  ollama_timeout: 30
  ollama_max_retries: 2
  ollama_retry_delay: 2

  # Performance
  max_articles_per_run: $($modeConfig.max_articles)
  max_items_per_source: $($modeConfig.max_items_per_source)
  max_total_articles: 50
  batch_size: 3
  delay_between_sources: $($modeConfig.delay)
  delay_between_analysis: $($modeConfig.delay)

  # Répertoires
  output_dir: "reports"
  data_dir: "data"
  logs_dir: "logs"

  # Notifications
  notifications:
    enabled: true
    email: false
    windows_toast: true
    telegram: false

# Sources RSS - Optimisées
sources:
  # === PRIORITÉ 1 : Médias Quotidiens ===
  el_periodic:
    name: "El Periòdic d'Andorra"
    type: rss
    url: "https://www.elperiodic.ad/rss"
    enabled: true
    priority: 1
    max_items: $($modeConfig.max_items_per_source)
    language: "ca"
    keywords:
      - "govern"
      - "consell"
      - "parlament"
      - "economia"
      - "turisme"
      - "andorra"

  bondia_diari:
    name: "BonDia Diari"
    type: rss
    url: "https://www.bondia.ad/rss.xml"
    enabled: true
    priority: 1
    max_items: $($modeConfig.max_items_per_source)
    language: "ca"
    keywords:
      - "govern"
      - "economia"
      - "andorra"

  diari_andorra:
    name: "Diari d'Andorra"
    type: rss
    url: "https://www.diariandorra.ad/uploads/rss/continguts.xml"
    enabled: true
    priority: 1
    max_items: $($modeConfig.max_items_per_source)
    language: "ca"
    keywords:
      - "govern"
      - "economia"
      - "andorra"

  # === PRIORITÉ 2 : Business ===
  andorra_business:
    name: "Andorra Business"
    type: rss
    url: "https://www.andorrabusiness.com/feed/"
    enabled: true
    priority: 2
    max_items: 10
    language: "ca"
    keywords:
      - "business"
      - "empresa"
      - "economia"

  actua:
    name: "Actua"
    type: rss
    url: "https://www.actua.ad/feed/"
    enabled: true
    priority: 2
    max_items: 10
    language: "ca"
    keywords:
      - "actualitat"
      - "andorra"

# Configuration analyse IA
analysis:
  max_content_length: 800

  prompt_template: |
    Analyse BRÈVE de cet article andorran :

    Titre: {title}
    Source: {source}
    Contenu: {content}

    Réponds en JSON uniquement (pas de markdown) :
    {{
      "categories": ["max 2 catégories"],
      "importance": 1-5,
      "resume_neutre": "1-2 phrases courtes",
      "impact": {{
        "residents": "direct/indirect/aucun",
        "entreprises": "direct/indirect/aucun",
        "institutions": "direct/indirect/aucun"
      }},
      "acteurs_cles": ["max 3 acteurs"],
      "paroisses_concernees": ["si applicable"],
      "themes_principaux": ["max 2 thèmes"],
      "tendance": "positive/neutre/negative/mixte",
      "mots_cles": ["max 3 mots"]
    }}

  fallback_on_error: true
  retry_attempts: 2
  timeout_seconds: 30

# Configuration rapports
reports:
  formats:
    markdown:
      enabled: true
      template: "detailed"
      group_by: "importance"
    json:
      enabled: true
      pretty_print: false

  html_dashboard:
    enabled: false

# Configuration base de données
database:
  type: "sqlite"
  path: "data/articles_andorre.db"
  retention_days: 90

# Configuration logs
logging:
  level: "INFO"
  format: "detailed"
  rotation:
    enabled: true
    max_size_mb: 10
    backup_count: 5

# Configuration notifications Windows
windows_toast:
  enabled: true
  duration: 10
  send_on:
    - "high_importance"
"@

    $configFile = Join-Path $Global:Config.ConfigPath "sources_andorre_$ConfigMode.yaml"

    # Utiliser UTF8 sans BOM (compatible PowerShell 5.1 et 7+)
    try {
        [System.IO.File]::WriteAllText($configFile, $yamlContent, (New-Object System.Text.UTF8Encoding($false)))
        Write-ColorOutput "Configuration créée: $configFile" "Success"
    } catch {
        # Fallback pour anciennes versions
        $yamlContent | Out-File -FilePath $configFile -Encoding UTF8
        Write-ColorOutput "Configuration créée (UTF8): $configFile" "Success"
    }

    # Créer un lien par défaut
    $defaultConfig = $Global:Config.SourcesConfig
    if (-not (Test-Path $defaultConfig)) {
        Copy-Item $configFile $defaultConfig
        Write-ColorOutput "Configuration par défaut créée" "Success"
    }
}

function Invoke-Agent {
    param(
        [string]$ConfigMode = "balanced",
        [switch]$Test
    )

    Write-ColorOutput "Lancement de l'agent (mode: $ConfigMode)..." "Info"

    # Activer l'environnement virtuel
    $activateScript = Join-Path $Global:Config.VenvPath "Scripts\Activate.ps1"
    if (-not (Test-Path $activateScript)) {
        Write-ColorOutput "Environnement virtuel non trouvé. Exécutez: .\andorra360.ps1 -Action setup" "Error"
        return $false
    }

    & $activateScript

    # Vérifier le script Python
    $pythonScript = Join-Path $PSScriptRoot "veille_andorre.py"
    if (-not (Test-Path $pythonScript)) {
        Write-ColorOutput "Script Python non trouvé: $pythonScript" "Error"
        return $false
    }

    # Configurer le fichier de config
    $configFile = Join-Path $Global:Config.ConfigPath "sources_andorre_$ConfigMode.yaml"
    if (-not (Test-Path $configFile)) {
        Create-ConfigurationFile -ConfigMode $ConfigMode
    }

    # Lancer l'agent
    try {
        $startTime = Get-Date

        if ($Test) {
            Write-ColorOutput "Mode TEST activé (dry-run)" "Warning"
            python $pythonScript --config $configFile --dry-run
        } else {
            python $pythonScript --config $configFile
        }

        $duration = (Get-Date) - $startTime

        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "Agent terminé avec succès en $($duration.TotalSeconds.ToString('F1'))s" "Success"
            return $true
        } else {
            Write-ColorOutput "Agent terminé avec erreur (code: $LASTEXITCODE)" "Error"
            return $false
        }

    } catch {
        Write-ColorOutput "Erreur lors de l'exécution: $_" "Error"
        return $false
    }
}

function Show-Status {
    Write-ColorOutput "État du système..." "Info"
    Write-Host ""

    # Environnement virtuel
    if (Test-Path $Global:Config.VenvPath) {
        Write-ColorOutput "Environnement virtuel: ✅ OK" "Success"
    } else {
        Write-ColorOutput "Environnement virtuel: ❌ Non configuré" "Error"
    }

    # Base de données
    if (Test-Path $Global:Config.DatabaseFile) {
        $dbSize = (Get-Item $Global:Config.DatabaseFile).Length / 1MB
        Write-ColorOutput "Base de données: ✅ OK ($($dbSize.ToString('F2')) MB)" "Success"

        # Compter les articles avec méthode compatible
        try {
            # Tenter d'utiliser SQLite si disponible
            $sqliteLoaded = $false
            try {
                Add-Type -AssemblyName System.Data.SQLite -ErrorAction SilentlyContinue
                $sqliteLoaded = $true
            } catch {
                # Assembly non disponible, utiliser Python comme fallback
            }

            if ($sqliteLoaded) {
                $connectionString = "Data Source=$($Global:Config.DatabaseFile);Version=3;"
                $connection = New-Object System.Data.SQLite.SQLiteConnection($connectionString)
                $connection.Open()

                $command = $connection.CreateCommand()
                $command.CommandText = "SELECT COUNT(*) FROM articles"
                $count = $command.ExecuteScalar()

                $connection.Close()

                Write-ColorOutput "  Articles en base: $count" "Info"
            } else {
                Write-ColorOutput "  (Utilisez Python/SQLite pour les statistiques)" "Info"
            }
        } catch {
            Write-ColorOutput "  Statistiques indisponibles" "Warning"
        }
    } else {
        Write-ColorOutput "Base de données: ⚠️  Vide" "Warning"
    }

    # Rapports
    if (Test-Path $Global:Config.ReportsPath) {
        $reports = Get-ChildItem -Path $Global:Config.ReportsPath -Filter "*.md" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
        if ($reports -and $reports.Count -gt 0) {
            Write-ColorOutput "Rapports: ✅ $($reports.Count) fichiers" "Success"
            Write-ColorOutput "  Dernier: $($reports[0].Name) ($($reports[0].LastWriteTime))" "Info"
        } else {
            Write-ColorOutput "Rapports: ⚠️  Aucun" "Warning"
        }
    }

    # Logs
    if (Test-Path $Global:Config.LogsPath) {
        $logs = Get-ChildItem -Path $Global:Config.LogsPath -Filter "*.log" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
        if ($logs -and $logs.Count -gt 0) {
            Write-ColorOutput "Logs: ✅ $($logs.Count) fichiers" "Success"

            # Afficher les dernières lignes du dernier log
            Write-Host ""
            Write-ColorOutput "Dernières lignes du log:" "Info"
            $lastLog = $logs[0].FullName
            Get-Content $lastLog -Tail 5 -ErrorAction SilentlyContinue | ForEach-Object {
                Write-Host "  $_" -ForegroundColor Gray
            }
        }
    }

    Write-Host ""
}

function Clear-OldData {
    param(
        [int]$DaysToKeep = 30
    )

    Write-ColorOutput "Nettoyage des anciennes données ($DaysToKeep jours)..." "Info"

    $cutoffDate = (Get-Date).AddDays(-$DaysToKeep)

    # Rapports
    $oldReports = Get-ChildItem -Path $Global:Config.ReportsPath -Filter "*.md" -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt $cutoffDate }
    if ($oldReports -and $oldReports.Count -gt 0) {
        $oldReports | Remove-Item -Force
        Write-ColorOutput "Supprimé $($oldReports.Count) anciens rapports" "Success"
    }

    # Logs
    $oldLogs = Get-ChildItem -Path $Global:Config.LogsPath -Filter "*.log" -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt $cutoffDate }
    if ($oldLogs -and $oldLogs.Count -gt 0) {
        $oldLogs | Remove-Item -Force
        Write-ColorOutput "Supprimé $($oldLogs.Count) anciens logs" "Success"
    }

    # Base de données (via SQL si disponible)
    if (Test-Path $Global:Config.DatabaseFile) {
        try {
            $sqliteLoaded = $false
            try {
                Add-Type -AssemblyName System.Data.SQLite -ErrorAction SilentlyContinue
                $sqliteLoaded = $true
            } catch {
                Write-ColorOutput "SQLite Assembly non disponible, utilisez Python pour nettoyer la DB" "Warning"
            }

            if ($sqliteLoaded) {
                $connectionString = "Data Source=$($Global:Config.DatabaseFile);Version=3;"
                $connection = New-Object System.Data.SQLite.SQLiteConnection($connectionString)
                $connection.Open()

                $command = $connection.CreateCommand()
                $cutoffDateStr = $cutoffDate.ToString("yyyy-MM-dd")
                $command.CommandText = "DELETE FROM articles WHERE created_at < '$cutoffDateStr'"
                $deleted = $command.ExecuteNonQuery()

                # Vacuum pour récupérer l'espace
                $command.CommandText = "VACUUM"
                $command.ExecuteNonQuery()

                $connection.Close()

                if ($deleted -gt 0) {
                    Write-ColorOutput "Supprimé $deleted anciens articles de la base" "Success"
                }
            }
        } catch {
            Write-ColorOutput "Erreur lors du nettoyage de la base: $_" "Warning"
        }
    }

    Write-ColorOutput "Nettoyage terminé" "Success"
}

function Schedule-Task {
    Write-ColorOutput "Configuration de la tâche planifiée..." "Info"

    # Vérifier les droits admin
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-ColorOutput "Droits administrateur requis pour planifier une tâche" "Error"
        Write-ColorOutput "Exécutez PowerShell en tant qu'administrateur" "Info"
        return $false
    }

    $taskName = "AgentAndorra360"
    $scriptPath = $PSCommandPath

    # Demander l'heure
    Write-Host ""
    $hour = Read-Host "Heure d'exécution quotidienne (0-23) [défaut: 8]"
    if ([string]::IsNullOrWhiteSpace($hour)) { $hour = 8 }

    try {
        # Supprimer tâche existante
        $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if ($existingTask) {
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
            Write-ColorOutput "Ancienne tâche supprimée" "Info"
        }

        # Créer l'action
        $action = New-ScheduledTaskAction `
            -Execute "powershell.exe" `
            -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -Action run -Mode balanced" `
            -WorkingDirectory $PSScriptRoot

        # Créer le déclencheur (quotidien)
        $trigger = New-ScheduledTaskTrigger -Daily -At "$($hour):00"

        # Paramètres
        $settings = New-ScheduledTaskSettingsSet `
            -AllowStartIfOnBatteries `
            -DontStopIfGoingOnBatteries `
            -StartWhenAvailable `
            -RunOnlyIfNetworkAvailable `
            -ExecutionTimeLimit (New-TimeSpan -Minutes 30)

        # Principal (utilisateur actuel)
        $principal = New-ScheduledTaskPrincipal `
            -UserId "$env:USERDOMAIN\$env:USERNAME" `
            -LogonType S4U `
            -RunLevel Highest

        # Enregistrer la tâche
        Register-ScheduledTask `
            -TaskName $taskName `
            -Description "Agent de veille Andorra 360 - Exécution quotidienne" `
            -Action $action `
            -Trigger $trigger `
            -Settings $settings `
            -Principal $principal `
            -Force | Out-Null

        Write-ColorOutput "Tâche planifiée créée avec succès" "Success"
        Write-ColorOutput "Exécution quotidienne à ${hour}h00" "Info"
        Write-Host ""
        Write-ColorOutput "Pour modifier: Planificateur de tâches > $taskName" "Info"

        return $true

    } catch {
        Write-ColorOutput "Erreur lors de la création de la tâche: $_" "Error"
        return $false
    }
}

function Generate-Dashboard {
    Write-ColorOutput "Génération du dashboard HTML..." "Info"

    $dashboardScript = Join-Path $PSScriptRoot "generate_dashboard.py"

    if (-not (Test-Path $dashboardScript)) {
        Write-ColorOutput "Script dashboard non trouvé: $dashboardScript" "Error"
        return $false
    }

    # Activer l'environnement virtuel
    $activateScript = Join-Path $Global:Config.VenvPath "Scripts\Activate.ps1"
    & $activateScript

    try {
        python $dashboardScript

        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "Dashboard généré avec succès" "Success"

            $dashboardFile = Join-Path $Global:Config.ReportsPath "dashboard_andorre.html"
            if (Test-Path $dashboardFile) {
                Write-ColorOutput "Ouverture du dashboard..." "Info"
                Start-Process $dashboardFile
            }

            return $true
        } else {
            Write-ColorOutput "Erreur lors de la génération" "Error"
            return $false
        }

    } catch {
        Write-ColorOutput "Erreur: $_" "Error"
        return $false
    }
}

function Backup-Data {
    Write-ColorOutput "Sauvegarde des données..." "Info"

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupDir = Join-Path $PSScriptRoot "backups\backup_$timestamp"

    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

    # Base de données
    if (Test-Path $Global:Config.DatabaseFile) {
        Copy-Item $Global:Config.DatabaseFile -Destination $backupDir
        Write-ColorOutput "Base de données sauvegardée" "Success"
    }

    # Configuration
    if (Test-Path $Global:Config.SourcesConfig) {
        Copy-Item $Global:Config.SourcesConfig -Destination $backupDir
        Write-ColorOutput "Configuration sauvegardée" "Success"
    }

    # Dernier rapport
    $lastReport = Get-ChildItem -Path $Global:Config.ReportsPath -Filter "*.md" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($lastReport) {
        Copy-Item $lastReport.FullName -Destination $backupDir
        Write-ColorOutput "Dernier rapport sauvegardé" "Success"
    }

    Write-ColorOutput "Sauvegarde terminée: $backupDir" "Success"
}

function Update-Dependencies {
    Write-ColorOutput "Mise à jour des dépendances..." "Info"

    $activateScript = Join-Path $Global:Config.VenvPath "Scripts\Activate.ps1"

    if (-not (Test-Path $activateScript)) {
        Write-ColorOutput "Environnement virtuel non trouvé" "Error"
        return $false
    }

    & $activateScript

    try {
        python -m pip install --upgrade pip
        python -m pip install --upgrade pyyaml feedparser requests urllib3 python-dateutil

        Write-ColorOutput "Dépendances mises à jour" "Success"
        return $true
    } catch {
        Write-ColorOutput "Erreur lors de la mise à jour: $_" "Error"
        return $false
    }
}

# ============================================
# MENU INTERACTIF
# ============================================

function Show-Menu {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                      MENU PRINCIPAL                       ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] 🚀 Lancer l'agent (mode balanced)" -ForegroundColor White
    Write-Host "  [2] ⚡ Lancer l'agent (mode quick)" -ForegroundColor White
    Write-Host "  [3] 🔍 Lancer l'agent (mode deep)" -ForegroundColor White
    Write-Host "  [4] 📊 Générer le dashboard HTML" -ForegroundColor White
    Write-Host "  [5] ℹ️  Afficher le statut" -ForegroundColor White
    Write-Host "  [6] 🧹 Nettoyer les anciennes données" -ForegroundColor White
    Write-Host "  [7] ⏰ Planifier l'exécution automatique" -ForegroundColor White
    Write-Host "  [8] 🔧 Mise à jour des dépendances" -ForegroundColor White
    Write-Host "  [9] 💾 Sauvegarder les données" -ForegroundColor White
    Write-Host "  [0] ❌ Quitter" -ForegroundColor White
    Write-Host ""

    $choice = Read-Host "Votre choix"
    return $choice
}

# ============================================
# POINT D'ENTRÉE PRINCIPAL
# ============================================

Show-Banner

# Si aucun paramètre, afficher le menu
if ($PSBoundParameters.Count -eq 0) {

    # Vérifier prérequis au démarrage
    if (-not (Test-Prerequisites)) {
        Write-Host ""
        Write-ColorOutput "Veuillez installer les prérequis manquants" "Error"
        pause
        exit 1
    }

    # Vérifier environnement virtuel
    if (-not (Test-Path $Global:Config.VenvPath)) {
        Write-ColorOutput "Environnement virtuel non trouvé" "Warning"
        Write-ColorOutput "Configuration initiale nécessaire..." "Info"
        Write-Host ""

        Initialize-Directories
        Setup-VirtualEnvironment
        Create-ConfigurationFile -ConfigMode "balanced"

        Write-Host ""
        Write-ColorOutput "Configuration terminée !" "Success"
        Write-Host ""
        pause
    }

    # Boucle du menu
    do {
        Show-Banner
        $choice = Show-Menu

        switch ($choice) {
            "1" {
                Invoke-Agent -ConfigMode "balanced"
                pause
            }
            "2" {
                Invoke-Agent -ConfigMode "quick"
                pause
            }
            "3" {
                Invoke-Agent -ConfigMode "deep"
                pause
            }
            "4" {
                Generate-Dashboard
                pause
            }
            "5" {
                Show-Status
                pause
            }
            "6" {
                Clear-OldData
                pause
            }
            "7" {
                Schedule-Task
                pause
            }
            "8" {
                Update-Dependencies
                pause
            }
            "9" {
                Backup-Data
                pause
            }
            "0" {
                Write-ColorOutput "Au revoir !" "Info"
                exit 0
            }
            default {
                Write-ColorOutput "Choix invalide" "Warning"
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)

} else {
    # Exécution avec paramètres

    switch ($Action) {
        "setup" {
            if (-not (Test-Prerequisites)) { exit 1 }
            Initialize-Directories
            Setup-VirtualEnvironment
            Create-ConfigurationFile -ConfigMode $Mode
            Write-ColorOutput "Setup terminé !" "Success"
        }

        "run" {
            if (-not (Test-Prerequisites)) { exit 1 }
            $success = Invoke-Agent -ConfigMode $Mode -Test:$DryRun
            if ($success) {
                exit 0
            } else {
                exit 1
            }
        }

        "quick" {
            if (-not (Test-Prerequisites)) { exit 1 }
            $success = Invoke-Agent -ConfigMode "quick" -Test:$DryRun
            if ($success) {
                exit 0
            } else {
                exit 1
            }
        }

        "status" {
            Show-Status
        }

        "clean" {
            Clear-OldData
        }

        "schedule" {
            $success = Schedule-Task
            if ($success) {
                exit 0
            } else {
                exit 1
            }
        }

        "dashboard" {
            $success = Generate-Dashboard
            if ($success) {
                exit 0
            } else {
                exit 1
            }
        }

        "update" {
            $success = Update-Dependencies
            if ($success) {
                exit 0
            } else {
                exit 1
            }
        }

        "backup" {
            Backup-Data
        }
    }
}
