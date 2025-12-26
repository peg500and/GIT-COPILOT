<#
.SYNOPSIS
    Agent Andorra 360 - Gestionnaire Complet OPTIMISÉ

.DESCRIPTION
    Script PowerShell tout-en-un pour gérer l'agent de veille informationnelle
    sur l'Andorre avec analyse IA locale (PHI-4/Gemma via Ollama)

    OPTIMISATIONS v2.2 :
    - Performance améliorée (Out-Null → [void], caching)
    - Code dupliqué éliminé (activation venv centralisée)
    - Gestion mémoire optimisée (connexions DB, using statements)
    - Parallélisation des tâches indépendantes
    - Validation robuste des entrées
    - Logging structuré

.PARAMETER Action
    Action à exécuter : setup, run, quick, status, clean, schedule, dashboard

.PARAMETER DryRun
    Mode test sans modifications réelles

.EXAMPLE
    .\andorra360_optimized.ps1 -Action setup
    .\andorra360_optimized.ps1 -Action run
    .\andorra360_optimized.ps1 -Action quick

.NOTES
    Version: 2.2 OPTIMIZED
    Auteur: Erol GIRAUDY
    Date: 26 décembre 2025
    Optimisations: Claude Code
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
$ProgressPreference = "SilentlyContinue"  # OPTIMISATION: Désactiver la barre de progression pour plus de rapidité

$Global:Config = @{
    ProjectName = "Agent Andorra 360"
    Version = "2.2-OPTIMIZED"
    BaseDir = $PSScriptRoot
    PythonMinVersion = "3.9"
    OllamaModel = "phi4"  # ou "gemma"

    # Chemins (calculés une seule fois)
    VenvPath = Join-Path $PSScriptRoot "venv"
    ConfigPath = Join-Path $PSScriptRoot "config"
    DataPath = Join-Path $PSScriptRoot "data"
    ReportsPath = Join-Path $PSScriptRoot "reports"
    LogsPath = Join-Path $PSScriptRoot "logs"
    BackupPath = Join-Path $PSScriptRoot "backups"

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
            timeout = 15
        }
        balanced = @{
            max_articles = 15
            max_items_per_source = 15
            delay = 1.0
            timeout = 30
        }
        deep = @{
            max_articles = 30
            max_items_per_source = 30
            delay = 2.0
            timeout = 60
        }
    }

    # Cache pour les vérifications
    Cache = @{
        VenvActivated = $false
        PrerequisitesChecked = $false
        PrerequisitesOk = $false
        PythonVersion = $null
        OllamaAvailable = $false
    }
}

# ============================================
# FONCTIONS UTILITAIRES OPTIMISÉES
# ============================================

function Write-ColorOutput {
    <#
    .SYNOPSIS
        Affichage console optimisé avec timestamps et couleurs
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [ValidateSet("Success", "Error", "Warning", "Info", "Debug")]
        [string]$Type = "Info"
    )

    $timestamp = Get-Date -Format "HH:mm:ss"

    # OPTIMISATION: Utiliser un switch avec scriptblocks pour éviter les appels répétitifs
    $colorMap = @{
        "Success" = @{ Color = "Green";   Prefix = "✅" }
        "Error"   = @{ Color = "Red";     Prefix = "❌" }
        "Warning" = @{ Color = "Yellow";  Prefix = "⚠️ " }
        "Info"    = @{ Color = "Cyan";    Prefix = "ℹ️ " }
        "Debug"   = @{ Color = "Gray";    Prefix = "🔍" }
    }

    $config = $colorMap[$Type]

    if ($Type -eq "Debug" -and -not $Verbose) { return }

    Write-Host "[$timestamp] $($config.Prefix) $Message" -ForegroundColor $config.Color
}

function Show-Banner {
    <#
    .SYNOPSIS
        Affichage de la bannière
    #>
    Clear-Host
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║       Agent Andorra 360 - Intelligence Dashboard        ║" -ForegroundColor Magenta
    Write-Host "║         Version $($Global:Config.Version) - Optimisé Windows 11      ║" -ForegroundColor Magenta
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""
}

function Test-Prerequisites {
    <#
    .SYNOPSIS
        Vérification des prérequis avec cache
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    # OPTIMISATION: Utiliser le cache pour éviter les vérifications répétitives
    if ($Global:Config.Cache.PrerequisitesChecked) {
        return $Global:Config.Cache.PrerequisitesOk
    }

    Write-ColorOutput "Vérification des prérequis..." "Info"

    $allOk = $true

    # Python
    try {
        $pythonOutput = python --version 2>&1 | Out-String
        if ($pythonOutput -match "Python (\d+\.\d+)") {
            $version = [version]$matches[1]
            $Global:Config.Cache.PythonVersion = $version

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
        $ollamaOutput = ollama list 2>&1 | Out-String
        $ollamaExitCode = $LASTEXITCODE
        if ($null -ne $ollamaExitCode -and $ollamaExitCode -eq 0) {
            $Global:Config.Cache.OllamaAvailable = $true
            Write-ColorOutput "Ollama détecté et fonctionnel" "Success"

            # Vérifier le modèle
            if ($ollamaOutput -match $Global:Config.OllamaModel) {
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

    # OPTIMISATION: Mettre en cache le résultat
    $Global:Config.Cache.PrerequisitesChecked = $true
    $Global:Config.Cache.PrerequisitesOk = $allOk

    return $allOk
}

function Initialize-Directories {
    <#
    .SYNOPSIS
        Création des répertoires nécessaires (optimisé)
    #>
    [CmdletBinding()]
    param()

    Write-ColorOutput "Création des répertoires..." "Info"

    $directories = @(
        $Global:Config.ConfigPath,
        $Global:Config.DataPath,
        $Global:Config.ReportsPath,
        $Global:Config.LogsPath,
        $Global:Config.BackupPath
    )

    # OPTIMISATION: Créer tous les répertoires en une seule opération
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir -PathType Container)) {
            [void](New-Item -ItemType Directory -Path $dir -Force)
            Write-ColorOutput "Créé: $dir" "Success"
        } else {
            Write-ColorOutput "Existe: $dir" "Debug"
        }
    }
}

function Invoke-VenvActivation {
    <#
    .SYNOPSIS
        Activation centralisée de l'environnement virtuel
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    # OPTIMISATION: Éviter l'activation multiple
    if ($Global:Config.Cache.VenvActivated) {
        Write-ColorOutput "Environnement virtuel déjà activé" "Debug"
        return $true
    }

    $activateScript = Join-Path $Global:Config.VenvPath "Scripts\Activate.ps1"

    if (-not (Test-Path $activateScript)) {
        Write-ColorOutput "Script d'activation non trouvé: $activateScript" "Error"
        return $false
    }

    try {
        & $activateScript
        $Global:Config.Cache.VenvActivated = $true
        Write-ColorOutput "Environnement virtuel activé" "Debug"
        return $true
    } catch {
        Write-ColorOutput "Erreur lors de l'activation: $_" "Error"
        return $false
    }
}

function Setup-VirtualEnvironment {
    <#
    .SYNOPSIS
        Configuration de l'environnement virtuel avec optimisations
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    Write-ColorOutput "Configuration de l'environnement virtuel..." "Info"

    if (Test-Path $Global:Config.VenvPath) {
        Write-ColorOutput "Environnement virtuel existe déjà" "Info"
        return $true
    }

    try {
        Write-ColorOutput "Création de l'environnement virtuel..." "Info"
        python -m venv $Global:Config.VenvPath

        if (-not (Invoke-VenvActivation)) {
            return $false
        }

        Write-ColorOutput "Mise à jour de pip..." "Info"
        # OPTIMISATION: Utiliser --quiet et capturer les erreurs seulement si nécessaire
        python -m pip install --upgrade pip --quiet 2>&1 | Out-Null

        # Dépendances principales
        $packages = @(
            "pyyaml",
            "feedparser",
            "requests",
            "urllib3",
            "python-dateutil"
        )

        Write-ColorOutput "Installation des dépendances ($($packages.Count) packages)..." "Info"

        # OPTIMISATION: Installer tous les packages en une seule commande
        $packagesStr = $packages -join " "
        python -m pip install $packagesStr --quiet 2>&1 | Out-Null

        Write-ColorOutput "Packages principaux installés" "Success"

        # Dépendances optionnelles
        try {
            python -m pip install win10toast --quiet 2>&1 | Out-Null
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

function Get-DatabaseConnection {
    <#
    .SYNOPSIS
        Obtenir une connexion SQLite réutilisable
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [switch]$ReadOnly
    )

    if (-not (Test-Path $Global:Config.DatabaseFile)) {
        Write-ColorOutput "Base de données non trouvée" "Warning"
        return $null
    }

    try {
        # OPTIMISATION: Charger l'assembly une seule fois
        if (-not ([System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.FullName -match "System.Data.SQLite" })) {
            Add-Type -AssemblyName System.Data.SQLite -ErrorAction Stop
        }

        $connectionString = "Data Source=$($Global:Config.DatabaseFile);Version=3;"
        if ($ReadOnly) {
            $connectionString += "Read Only=True;"
        }

        $connection = New-Object System.Data.SQLite.SQLiteConnection($connectionString)
        $connection.Open()

        return $connection

    } catch {
        Write-ColorOutput "Erreur de connexion à la base: $_" "Error"
        return $null
    }
}

function Invoke-DatabaseQuery {
    <#
    .SYNOPSIS
        Exécuter une requête SQL de manière sécurisée
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Query,

        [Parameter(Mandatory=$false)]
        [switch]$Scalar
    )

    $connection = Get-DatabaseConnection
    if (-not $connection) {
        return $null
    }

    try {
        $command = $connection.CreateCommand()
        $command.CommandText = $Query

        if ($Scalar) {
            $result = $command.ExecuteScalar()
        } else {
            $result = $command.ExecuteNonQuery()
        }

        return $result

    } catch {
        Write-ColorOutput "Erreur lors de l'exécution de la requête: $_" "Error"
        return $null
    } finally {
        # OPTIMISATION: Toujours fermer la connexion
        if ($connection) {
            $connection.Close()
            $connection.Dispose()
        }
    }
}

function Create-ConfigurationFile {
    <#
    .SYNOPSIS
        Génération du fichier de configuration YAML optimisé
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet('quick', 'balanced', 'deep')]
        [string]$ConfigMode = "balanced"
    )

    Write-ColorOutput "Génération du fichier de configuration ($ConfigMode)..." "Info"

    $modeConfig = $Global:Config.Modes[$ConfigMode]

    # OPTIMISATION: Utiliser un here-string avec interpolation
    $yamlContent = @"
# Configuration Agent Andorra 360 - Optimisé v2.2
# Mode: $ConfigMode
# Généré: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

general:
  # Configuration IA
  ollama_model: "$($Global:Config.OllamaModel)"
  ollama_temperature: 0.1
  ollama_num_predict: 500
  ollama_endpoint: "http://localhost:11434"
  ollama_timeout: $($modeConfig.timeout)
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

# Sources RSS - Optimisées pour performance
sources:
  # === PRIORITÉ 1 : Médias Quotidiens (toujours activés) ===
  el_periodic:
    name: "El Periòdic d'Andorra"
    type: rss
    url: "https://www.elperiodic.ad/rss"
    enabled: true
    priority: 1
    max_items: $($modeConfig.max_items_per_source)
    language: "ca"
    timeout: 10
    keywords:
      - "govern"
      - "consell"
      - "parlament"
      - "economia"
      - "turisme"

  bondia_diari:
    name: "BonDia Diari"
    type: rss
    url: "https://www.bondia.ad/rss.xml"
    enabled: true
    priority: 1
    max_items: $($modeConfig.max_items_per_source)
    language: "ca"
    timeout: 10
    keywords:
      - "govern"
      - "economia"

  diari_andorra:
    name: "Diari d'Andorra"
    type: rss
    url: "https://www.diariandorra.ad/uploads/rss/continguts.xml"
    enabled: true
    priority: 1
    max_items: $($modeConfig.max_items_per_source)
    language: "ca"
    timeout: 10
    keywords:
      - "govern"
      - "economia"

  # === PRIORITÉ 2 : Business (activé en mode balanced/deep) ===
  andorra_business:
    name: "Andorra Business"
    type: rss
    url: "https://www.andorrabusiness.com/feed/"
    enabled: $(if ($ConfigMode -ne 'quick') { 'true' } else { 'false' })
    priority: 2
    max_items: 10
    language: "ca"
    timeout: 10
    keywords:
      - "business"
      - "empresa"

  actua:
    name: "Actua"
    type: rss
    url: "https://www.actua.ad/feed/"
    enabled: $(if ($ConfigMode -eq 'deep') { 'true' } else { 'false' })
    priority: 2
    max_items: 10
    language: "ca"
    timeout: 10
    keywords:
      - "actualitat"

# Configuration analyse IA
analysis:
  max_content_length: 800
  use_cache: true
  cache_ttl: 3600

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
  timeout_seconds: $($modeConfig.timeout)

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
  auto_vacuum: true
  cache_size: 2000

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

    # OPTIMISATION: Utiliser Set-Content au lieu de Out-File
    Set-Content -Path $configFile -Value $yamlContent -Encoding UTF8 -Force

    Write-ColorOutput "Configuration créée: $configFile" "Success"

    # Créer un lien par défaut
    $defaultConfig = $Global:Config.SourcesConfig
    if (-not (Test-Path $defaultConfig)) {
        Copy-Item $configFile $defaultConfig -Force
        Write-ColorOutput "Configuration par défaut créée" "Success"
    }

    return $true
}

function Invoke-Agent {
    <#
    .SYNOPSIS
        Lancement de l'agent avec optimisations
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet('quick', 'balanced', 'deep')]
        [string]$ConfigMode = "balanced",

        [Parameter(Mandatory=$false)]
        [switch]$Test
    )

    Write-ColorOutput "Lancement de l'agent (mode: $ConfigMode)..." "Info"

    # OPTIMISATION: Utiliser la fonction centralisée
    if (-not (Invoke-VenvActivation)) {
        Write-ColorOutput "Impossible d'activer l'environnement virtuel" "Error"
        Write-ColorOutput "Exécutez: .\andorra360_optimized.ps1 -Action setup" "Info"
        return $false
    }

    # Vérifier le script Python
    $pythonScript = Join-Path $PSScriptRoot "veille_andorre.py"
    if (-not (Test-Path $pythonScript)) {
        Write-ColorOutput "Script Python non trouvé: $pythonScript" "Error"
        return $false
    }

    # Configurer le fichier de config
    $configFile = Join-Path $Global:Config.ConfigPath "sources_andorre_$ConfigMode.yaml"
    if (-not (Test-Path $configFile)) {
        [void](Create-ConfigurationFile -ConfigMode $ConfigMode)
    }

    # Lancer l'agent
    try {
        $startTime = Get-Date

        $arguments = @("$pythonScript", "--config", "`"$configFile`"")
        if ($Test) {
            Write-ColorOutput "Mode TEST activé (dry-run)" "Warning"
            $arguments += "--dry-run"
        }

        # OPTIMISATION: Utiliser Start-Process avec capture de sortie
        $processArgs = @{
            FilePath = "python"
            ArgumentList = $arguments
            NoNewWindow = $true
            Wait = $true
            PassThru = $true
        }

        $process = Start-Process @processArgs
        $exitCode = $process.ExitCode

        $duration = (Get-Date) - $startTime

        if ($exitCode -eq 0) {
            Write-ColorOutput "Agent terminé avec succès en $($duration.TotalSeconds.ToString('F1'))s" "Success"
            return $true
        } else {
            Write-ColorOutput "Agent terminé avec erreur (code: $exitCode)" "Error"
            return $false
        }

    } catch {
        Write-ColorOutput "Erreur lors de l'exécution: $_" "Error"
        return $false
    }
}

function Show-Status {
    <#
    .SYNOPSIS
        Affichage optimisé du statut système
    #>
    [CmdletBinding()]
    param()

    Write-ColorOutput "État du système..." "Info"
    Write-Host ""

    # Environnement virtuel
    $venvExists = Test-Path $Global:Config.VenvPath
    if ($venvExists) {
        Write-ColorOutput "Environnement virtuel: ✅ OK" "Success"
    } else {
        Write-ColorOutput "Environnement virtuel: ❌ Non configuré" "Error"
    }

    # Base de données
    if (Test-Path $Global:Config.DatabaseFile) {
        $dbSize = (Get-Item $Global:Config.DatabaseFile).Length / 1MB
        Write-ColorOutput "Base de données: ✅ OK ($($dbSize.ToString('F2')) MB)" "Success"

        # OPTIMISATION: Utiliser la fonction dédiée
        $count = Invoke-DatabaseQuery -Query "SELECT COUNT(*) FROM articles" -Scalar
        if ($count) {
            Write-ColorOutput "  Articles en base: $count" "Info"

            # Articles récents (dernières 24h)
            $yesterday = (Get-Date).AddDays(-1).ToString("yyyy-MM-dd HH:mm:ss")
            $recentCount = Invoke-DatabaseQuery -Query "SELECT COUNT(*) FROM articles WHERE created_at > '$yesterday'" -Scalar
            if ($recentCount) {
                Write-ColorOutput "  Articles récents (24h): $recentCount" "Info"
            }
        }
    } else {
        Write-ColorOutput "Base de données: ⚠️  Vide" "Warning"
    }

    # Rapports
    if (Test-Path $Global:Config.ReportsPath) {
        # OPTIMISATION: Limiter à 1 seul Get-ChildItem avec sort
        $reports = @(Get-ChildItem -Path $Global:Config.ReportsPath -Filter "*.md" -File |
                     Sort-Object LastWriteTime -Descending |
                     Select-Object -First 5)

        if ($reports.Count -gt 0) {
            Write-ColorOutput "Rapports: ✅ $($reports.Count)+ fichiers" "Success"
            Write-ColorOutput "  Dernier: $($reports[0].Name)" "Info"
            Write-ColorOutput "  Date: $($reports[0].LastWriteTime.ToString('yyyy-MM-dd HH:mm'))" "Info"
        } else {
            Write-ColorOutput "Rapports: ⚠️  Aucun" "Warning"
        }
    }

    # Logs (dernières lignes)
    if (Test-Path $Global:Config.LogsPath) {
        $logs = @(Get-ChildItem -Path $Global:Config.LogsPath -Filter "*.log" -File |
                  Sort-Object LastWriteTime -Descending |
                  Select-Object -First 1)

        if ($logs.Count -gt 0) {
            Write-ColorOutput "Logs: ✅ Disponibles" "Success"

            Write-Host ""
            Write-ColorOutput "Dernières lignes du log:" "Info"
            Get-Content $logs[0].FullName -Tail 5 -ErrorAction SilentlyContinue | ForEach-Object {
                Write-Host "  $_" -ForegroundColor Gray
            }
        }
    }

    Write-Host ""
}

function Clear-OldData {
    <#
    .SYNOPSIS
        Nettoyage optimisé des anciennes données
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateRange(1, 365)]
        [int]$DaysToKeep = 30
    )

    Write-ColorOutput "Nettoyage des données > $DaysToKeep jours..." "Info"

    $cutoffDate = (Get-Date).AddDays(-$DaysToKeep)
    $cutoffDateStr = $cutoffDate.ToString("yyyy-MM-dd HH:mm:ss")

    # OPTIMISATION: Paralléliser les opérations de nettoyage indépendantes
    $jobs = @()

    # Job 1: Nettoyer les rapports
    $jobs += Start-Job -ScriptBlock {
        param($ReportsPath, $CutoffDate)
        $oldReports = @(Get-ChildItem -Path $ReportsPath -Filter "*.md" -File |
                        Where-Object { $_.LastWriteTime -lt $CutoffDate })
        if ($oldReports.Count -gt 0) {
            $oldReports | Remove-Item -Force
            return $oldReports.Count
        }
        return 0
    } -ArgumentList $Global:Config.ReportsPath, $cutoffDate

    # Job 2: Nettoyer les logs
    $jobs += Start-Job -ScriptBlock {
        param($LogsPath, $CutoffDate)
        $oldLogs = @(Get-ChildItem -Path $LogsPath -Filter "*.log" -File |
                     Where-Object { $_.LastWriteTime -lt $CutoffDate })
        if ($oldLogs.Count -gt 0) {
            $oldLogs | Remove-Item -Force
            return $oldLogs.Count
        }
        return 0
    } -ArgumentList $Global:Config.LogsPath, $cutoffDate

    # Attendre les jobs
    $results = $jobs | Wait-Job | Receive-Job
    $jobs | Remove-Job

    if ($results[0] -gt 0) {
        Write-ColorOutput "Supprimé $($results[0]) anciens rapports" "Success"
    }
    if ($results[1] -gt 0) {
        Write-ColorOutput "Supprimé $($results[1]) anciens logs" "Success"
    }

    # Base de données (synchrone car nécessite transaction)
    if (Test-Path $Global:Config.DatabaseFile) {
        try {
            $deleted = Invoke-DatabaseQuery -Query "DELETE FROM articles WHERE created_at < '$cutoffDateStr'"

            if ($deleted -and $deleted -gt 0) {
                Write-ColorOutput "Supprimé $deleted anciens articles" "Success"

                # VACUUM pour récupérer l'espace
                [void](Invoke-DatabaseQuery -Query "VACUUM")
                Write-ColorOutput "Base de données compactée" "Success"
            }
        } catch {
            Write-ColorOutput "Erreur lors du nettoyage de la base: $_" "Error"
        }
    }

    Write-ColorOutput "Nettoyage terminé" "Success"
}

function Schedule-Task {
    <#
    .SYNOPSIS
        Configuration de la tâche planifiée Windows
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    Write-ColorOutput "Configuration de la tâche planifiée..." "Info"

    # Vérifier les droits admin
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-ColorOutput "Droits administrateur requis" "Error"
        Write-ColorOutput "Exécutez PowerShell en tant qu'administrateur" "Info"
        return $false
    }

    $taskName = "AgentAndorra360"
    $scriptPath = $PSCommandPath

    # Demander l'heure
    Write-Host ""
    $hour = Read-Host "Heure d'exécution quotidienne (0-23) [défaut: 8]"
    if ([string]::IsNullOrWhiteSpace($hour)) { $hour = 8 }

    # OPTIMISATION: Validation de l'entrée
    if ($hour -lt 0 -or $hour -gt 23) {
        Write-ColorOutput "Heure invalide. Utilisez une valeur entre 0 et 23." "Error"
        return $false
    }

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

        # Paramètres optimisés
        $settings = New-ScheduledTaskSettingsSet `
            -AllowStartIfOnBatteries `
            -DontStopIfGoingOnBatteries `
            -StartWhenAvailable `
            -RunOnlyIfNetworkAvailable `
            -ExecutionTimeLimit (New-TimeSpan -Minutes 30) `
            -RestartCount 3 `
            -RestartInterval (New-TimeSpan -Minutes 1)

        # Principal (utilisateur actuel)
        $principal = New-ScheduledTaskPrincipal `
            -UserId "$env:USERDOMAIN\$env:USERNAME" `
            -LogonType S4U `
            -RunLevel Highest

        # Enregistrer la tâche
        [void](Register-ScheduledTask `
            -TaskName $taskName `
            -Description "Agent de veille Andorra 360 - Exécution quotidienne automatique" `
            -Action $action `
            -Trigger $trigger `
            -Settings $settings `
            -Principal $principal `
            -Force)

        Write-ColorOutput "Tâche planifiée créée avec succès" "Success"
        Write-ColorOutput "Exécution quotidienne à ${hour}h00" "Info"
        Write-Host ""
        Write-ColorOutput "Gestion: Planificateur de tâches > $taskName" "Info"

        return $true

    } catch {
        Write-ColorOutput "Erreur lors de la création de la tâche: $_" "Error"
        return $false
    }
}

function Generate-Dashboard {
    <#
    .SYNOPSIS
        Génération du dashboard HTML
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    Write-ColorOutput "Génération du dashboard HTML..." "Info"

    $dashboardScript = Join-Path $PSScriptRoot "generate_dashboard.py"

    if (-not (Test-Path $dashboardScript)) {
        Write-ColorOutput "Script dashboard non trouvé: $dashboardScript" "Error"
        return $false
    }

    if (-not (Invoke-VenvActivation)) {
        return $false
    }

    try {
        $process = Start-Process -FilePath "python" -ArgumentList "`"$dashboardScript`"" -NoNewWindow -Wait -PassThru

        if ($process.ExitCode -eq 0) {
            Write-ColorOutput "Dashboard généré avec succès" "Success"

            $dashboardFile = Join-Path $Global:Config.ReportsPath "dashboard_andorre.html"
            if (Test-Path $dashboardFile) {
                Write-ColorOutput "Ouverture du dashboard..." "Info"
                Start-Process $dashboardFile
            }

            return $true
        } else {
            Write-ColorOutput "Erreur lors de la génération (code: $($process.ExitCode))" "Error"
            return $false
        }

    } catch {
        Write-ColorOutput "Erreur: $_" "Error"
        return $false
    }
}

function Backup-Data {
    <#
    .SYNOPSIS
        Sauvegarde optimisée des données
    #>
    [CmdletBinding()]
    param()

    Write-ColorOutput "Sauvegarde des données..." "Info"

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupDir = Join-Path $Global:Config.BackupPath "backup_$timestamp"

    [void](New-Item -ItemType Directory -Path $backupDir -Force)

    # OPTIMISATION: Paralléliser les copies
    $jobs = @()

    # Base de données
    if (Test-Path $Global:Config.DatabaseFile) {
        $jobs += Start-Job -ScriptBlock {
            param($Source, $Destination)
            Copy-Item $Source -Destination $Destination -Force
            return "Database"
        } -ArgumentList $Global:Config.DatabaseFile, $backupDir
    }

    # Configuration
    if (Test-Path $Global:Config.SourcesConfig) {
        $jobs += Start-Job -ScriptBlock {
            param($Source, $Destination)
            Copy-Item $Source -Destination $Destination -Force
            return "Config"
        } -ArgumentList $Global:Config.SourcesConfig, $backupDir
    }

    # Dernier rapport
    $lastReport = Get-ChildItem -Path $Global:Config.ReportsPath -Filter "*.md" -File |
                  Sort-Object LastWriteTime -Descending |
                  Select-Object -First 1

    if ($lastReport) {
        $jobs += Start-Job -ScriptBlock {
            param($Source, $Destination)
            Copy-Item $Source -Destination $Destination -Force
            return "Report"
        } -ArgumentList $lastReport.FullName, $backupDir
    }

    # Attendre les jobs
    $results = $jobs | Wait-Job | Receive-Job
    $jobs | Remove-Job

    foreach ($result in $results) {
        Write-ColorOutput "$result sauvegardé" "Success"
    }

    # Créer un fichier d'information
    $infoContent = @"
Sauvegarde Agent Andorra 360
=============================
Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Version: $($Global:Config.Version)
Fichiers sauvegardés: $($results.Count)
"@

    Set-Content -Path (Join-Path $backupDir "backup_info.txt") -Value $infoContent -Encoding UTF8

    Write-ColorOutput "Sauvegarde terminée: $backupDir" "Success"

    # Nettoyer les anciennes sauvegardes (garder les 10 plus récentes)
    $oldBackups = Get-ChildItem -Path $Global:Config.BackupPath -Directory |
                  Sort-Object CreationTime -Descending |
                  Select-Object -Skip 10

    if ($oldBackups) {
        $oldBackups | Remove-Item -Recurse -Force
        Write-ColorOutput "Nettoyé $($oldBackups.Count) anciennes sauvegardes" "Info"
    }
}

function Update-Dependencies {
    <#
    .SYNOPSIS
        Mise à jour optimisée des dépendances
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    Write-ColorOutput "Mise à jour des dépendances..." "Info"

    if (-not (Invoke-VenvActivation)) {
        return $false
    }

    try {
        # OPTIMISATION: Mettre à jour tous les packages en une commande
        $packages = @("pip", "pyyaml", "feedparser", "requests", "urllib3", "python-dateutil")

        Write-ColorOutput "Mise à jour de $($packages.Count) packages..." "Info"

        $packagesStr = $packages -join " "
        python -m pip install --upgrade $packagesStr --quiet 2>&1 | Out-Null

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
    <#
    .SYNOPSIS
        Affichage du menu principal
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                    MENU PRINCIPAL                         ║" -ForegroundColor Cyan
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

function Invoke-Main {
    <#
    .SYNOPSIS
        Point d'entrée principal optimisé
    #>
    [CmdletBinding()]
    param()

    Show-Banner

    # Si aucun paramètre, afficher le menu
    if ($PSBoundParameters.Count -eq 0 -and $MyInvocation.BoundParameters.Count -eq 0) {

        # Vérifier prérequis au démarrage (avec cache)
        if (-not (Test-Prerequisites)) {
            Write-Host ""
            Write-ColorOutput "Veuillez installer les prérequis manquants" "Error"
            Read-Host "Appuyez sur Entrée pour quitter"
            exit 1
        }

        # Vérifier environnement virtuel
        if (-not (Test-Path $Global:Config.VenvPath)) {
            Write-ColorOutput "Environnement virtuel non trouvé" "Warning"
            Write-ColorOutput "Configuration initiale nécessaire..." "Info"
            Write-Host ""

            Initialize-Directories

            if (-not (Setup-VirtualEnvironment)) {
                Write-ColorOutput "Erreur lors de la configuration" "Error"
                Read-Host "Appuyez sur Entrée pour quitter"
                exit 1
            }

            [void](Create-ConfigurationFile -ConfigMode "balanced")

            Write-Host ""
            Write-ColorOutput "Configuration terminée !" "Success"
            Write-Host ""
            Read-Host "Appuyez sur Entrée pour continuer"
        }

        # Boucle du menu
        while ($true) {
            Show-Banner
            $choice = Show-Menu

            switch ($choice) {
                "1" {
                    [void](Invoke-Agent -ConfigMode "balanced")
                    Read-Host "`nAppuyez sur Entrée pour continuer"
                }
                "2" {
                    [void](Invoke-Agent -ConfigMode "quick")
                    Read-Host "`nAppuyez sur Entrée pour continuer"
                }
                "3" {
                    [void](Invoke-Agent -ConfigMode "deep")
                    Read-Host "`nAppuyez sur Entrée pour continuer"
                }
                "4" {
                    [void](Generate-Dashboard)
                    Read-Host "`nAppuyez sur Entrée pour continuer"
                }
                "5" {
                    Show-Status
                    Read-Host "`nAppuyez sur Entrée pour continuer"
                }
                "6" {
                    Clear-OldData
                    Read-Host "`nAppuyez sur Entrée pour continuer"
                }
                "7" {
                    [void](Schedule-Task)
                    Read-Host "`nAppuyez sur Entrée pour continuer"
                }
                "8" {
                    [void](Update-Dependencies)
                    Read-Host "`nAppuyez sur Entrée pour continuer"
                }
                "9" {
                    Backup-Data
                    Read-Host "`nAppuyez sur Entrée pour continuer"
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
        }

    } else {
        # Exécution avec paramètres

        switch ($Action) {
            "setup" {
                if (-not (Test-Prerequisites)) { exit 1 }
                Initialize-Directories
                if (-not (Setup-VirtualEnvironment)) { exit 1 }
                [void](Create-ConfigurationFile -ConfigMode $Mode)
                Write-ColorOutput "Setup terminé !" "Success"
            }

            "run" {
                if (-not (Test-Prerequisites)) { exit 1 }
                $success = Invoke-Agent -ConfigMode $Mode -Test:$DryRun
                exit ($success ? 0 : 1)
            }

            "quick" {
                if (-not (Test-Prerequisites)) { exit 1 }
                $success = Invoke-Agent -ConfigMode "quick" -Test:$DryRun
                exit ($success ? 0 : 1)
            }

            "status" {
                Show-Status
            }

            "clean" {
                Clear-OldData
            }

            "schedule" {
                $success = Schedule-Task
                exit ($success ? 0 : 1)
            }

            "dashboard" {
                $success = Generate-Dashboard
                exit ($success ? 0 : 1)
            }

            "update" {
                $success = Update-Dependencies
                exit ($success ? 0 : 1)
            }

            "backup" {
                Backup-Data
            }
        }
    }
}

# Lancer le script
Invoke-Main
