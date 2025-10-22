//+------------------------------------------------------------------+
//|                                          MarketCompass_v5.mq5    |
//|                     Copyright 2024, Market Compass Trading v5.1  |
//|                       Professional Multi-Asset Trading System    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Market Compass Trading"
#property link      "https://marketcompass.trading"
#property version   "5.10"
#property description "Zaawansowany system tradingowy z pełną diagnostyką"
#property description "Wsparcie: Forex, Metals, Crypto | Tryb: Manual/Auto"
#property description "GUI: Polski/English | Debug: Full diagnostic system"
#property strict

//+------------------------------------------------------------------+
//|                            INCLUDES                              |
//+------------------------------------------------------------------+
#include "MC5_Core.mqh"
#include "MC5_Utils.mqh"
#include "MC5_Managers.mqh"
#include "MC5_Analysis.mqh"
#include "MC5_Strategies.mqh"
#include "MC5_GUI.mqh"

//+------------------------------------------------------------------+
//|                      PARAMETRY WEJŚCIOWE                        |
//+------------------------------------------------------------------+
input group "═══════════════ USTAWIENIA GŁÓWNE ═══════════════"
input ENUM_TRADING_MODE    InpTradingMode = MODE_STANDARD;        // 🎯 Tryb Tradingu
input ENUM_LANGUAGE        InpLanguage = LANG_POLISH;             // 🌍 Język / Language
input bool                 InpAutoTrading = true;                 // 🤖 Auto-Trading
input ulong                InpMagicNumber = 500001;               // 🔢 Magic Number
input string               InpComment = "MC_v5";                  // 💬 Komentarz

input group "═══════════════ ZARZĄDZANIE RYZYKIEM ═══════════════"
input double               InpRiskPerTrade = 1.0;                 // 💰 Ryzyko na transakcję (%)
input double               InpMaxDailyLoss = 5.0;                 // 📉 Max dzienna strata (%) - 0 = wyłączone
input double               InpMaxTotalDrawdown = 20.0;            // 📊 Max całkowity drawdown (%)
input int                  InpMaxPositions = 10;                  // 📈 Max otwartych pozycji
input bool                 InpUseMoneyManagement = true;          // 💼 Zarządzanie kapitałem

input group "═══════════════ STRATEGIA ═══════════════"
input ENUM_STRATEGY_TYPE   InpDefaultStrategy = STRATEGY_ADAPTIVE; // 🎲 Domyślna strategia
input int                  InpMinSignalScore = 60;                // 📊 Min siła sygnału (0-100)
input double               InpMinRiskReward = 1.5;                // 📈 Min Risk:Reward - POPRAWIONE
input bool                 InpUseMultiTimeframe = true;           // 🕐 Analiza Multi-TF
input bool                 InpUseVolumeAnalysis = true;           // 📊 Analiza wolumenu

input group "═══════════════ INTERFACE & POWIADOMIENIA ═══════════════"
input bool                 InpShowDashboard = true;               // 📱 Pokaż Dashboard
input bool                 InpEnableGUI = true;                   // 🖥️ Włącz GUI
input bool                 InpShowAlerts = false;                 // 🔔 Alerty dźwiękowe
input bool                 InpSendNotifications = false;          // 📲 Powiadomienia Push

input group "═══════════════ DIAGNOSTYKA I DEBUG ═══════════════"
input ENUM_DEBUG_LEVEL     InpDebugLevel = DEBUG_NORMAL;          // 🔍 Poziom debugowania
input bool                 InpLogToFile = true;                   // 📝 Zapisz logi do pliku
input bool                 InpEnableLogging = true;               // 📊 Włącz logowanie
input int                  InpLogFrequency = 1000;                // 📈 Częstotliwość logowania

//+------------------------------------------------------------------+
//|                          ZMIENNE GLOBALNE                        |
//+------------------------------------------------------------------+
// Managers - z kontrolą duplikacji
CDiagnostics*      g_diagnostics = NULL;
CDataManager*      g_dataManager = NULL;
CRiskManager*      g_riskManager = NULL;
CSignalManager*    g_signalManager = NULL;
CPositionManager*  g_positionManager = NULL;
CMarketAnalyzer*   g_marketAnalyzer = NULL;
CDashboard*        g_dashboard = NULL;

// Strategies
CBaseStrategy*     g_activeStrategy = NULL;

// System state
SystemState        g_systemState;
MarketConditions   g_marketConditions;
PerformanceStats   g_performance;

// Cache dla optymalizacji wydajności
struct SystemCache {
    ENUM_INSTRUMENT_TYPE instrumentType;
    datetime lastInstrumentCheck;
    double lastSpread;
    datetime lastSpreadCheck;
    bool isCryptoMode;
    bool isBTCMode;
    double lastATR;
    datetime lastATRCheck;
};
SystemCache g_cache;

// Signal management - POPRAWIONE
struct SignalManagement {
    datetime lastSignalCheck;
    datetime lastValidSignal;
    int signalCheckInterval;
    int signalsGeneratedThisBar;
    int maxSignalsPerBar;
    bool signalPending;
    // Persystencja
    datetime sessionStart;
    int sessionSignalsGenerated;
    int sessionSignalsExecuted;
};
SignalManagement g_signalMgmt;

// Flagi dla optymalizacji - będą ustawiane z cache
bool               g_isCryptoMode = false;
bool               g_isBTCMode = false;

// Konfiguracja instrumentu
InstrumentConfig   g_instrumentConfig;

// Throttling dla operacji
datetime g_lastDashboardUpdate = 0;
datetime g_lastMarketAnalysis = 0;
datetime g_lastRiskCheck = 0;

//+------------------------------------------------------------------+
//|                    FUNKCJA INICJALIZACJI                        |
//+------------------------------------------------------------------+
int OnInit() {
    // Zabezpieczenie przed podwójną inicjalizacją
    if(g_systemState.isInitialized) {
        CleanupAll();
    }
    
    // Inicjalizacja diagnostyki
    if(InpEnableLogging) {
        if(g_diagnostics == NULL) {
            g_diagnostics = new CDiagnostics(InpDebugLevel, InpLogToFile);
        }
        g_diagnostics.StartSession();
        
        g_diagnostics.Log(DEBUG_CRITICAL, "SYSTEM", "═══════════════════════════════════════════════════");
        g_diagnostics.Log(DEBUG_CRITICAL, "SYSTEM", "    MARKET COMPASS v5.1 - INICJALIZACJA");
        g_diagnostics.Log(DEBUG_CRITICAL, "SYSTEM", "═══════════════════════════════════════════════════");
    }
    
    // Inicjalizacja zmiennych globalnych
    InitializeGlobalVariables();
    InitializeSignalManagement();
    InitializeCache();
    
    // Wczytaj persystentne dane
    LoadPersistentData();
    
    // Sprawdzenie podstawowych warunków
    if(!CheckInitialConditions()) {
        if(InpEnableLogging && g_diagnostics != NULL) {
            g_diagnostics.Log(DEBUG_CRITICAL, "INIT", "❌ Warunki początkowe nie spełnione!");
        }
        return INIT_FAILED;
    }
    
    // Wykryj typ instrumentu i dostosuj parametry
    DetectAndConfigureInstrument();
    
    // Inicjalizacja managerów z kontrolą duplikacji
    if(!InitializeManagersSafe()) {
        if(InpEnableLogging && g_diagnostics != NULL) {
            g_diagnostics.Log(DEBUG_CRITICAL, "INIT", "❌ Błąd inicjalizacji managerów!");
        }
        CleanupManagers();
        return INIT_FAILED;
    }
    
    // Inicjalizacja strategii
    if(!InitializeStrategies()) {
        if(InpEnableLogging && g_diagnostics != NULL) {
            g_diagnostics.Log(DEBUG_CRITICAL, "INIT", "❌ Błąd inicjalizacji strategii!");
        }
        CleanupAll();
        return INIT_FAILED;
    }
    
    // Inicjalizacja GUI
    if(InpShowDashboard && InpEnableGUI) {
        if(g_dashboard == NULL) {
            g_dashboard = new CDashboard(InpLanguage);
        }
        if(!g_dashboard.Initialize()) {
            if(InpEnableLogging && g_diagnostics != NULL) {
                g_diagnostics.Log(DEBUG_NORMAL, "GUI", "⚠️ Dashboard nie został zainicjalizowany");
            }
        }
    }
    
    // Ustaw stan systemu
    g_systemState.isActive = true;
    g_systemState.isInitialized = true;
    g_systemState.startTime = TimeCurrent();
    g_systemState.lastUpdateTime = TimeCurrent();
    
    // Pierwsze odświeżenie danych
    RefreshAllData();
    
    // Ustaw timer
    int timerInterval = 2;
    EventSetTimer(timerInterval);
    
    if(InpEnableLogging && g_diagnostics != NULL) {
        g_diagnostics.Log(DEBUG_CRITICAL, "SYSTEM", "✅ SYSTEM GOTOWY DO PRACY!");
        g_diagnostics.Log(DEBUG_CRITICAL, "SYSTEM", 
            StringFormat("Max pozycji: %d, Min score: %d, Min R:R: %.2f", 
                InpMaxPositions, InpMinSignalScore, InpMinRiskReward));
    }
    ShowInitializationReport();
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//|                      FUNKCJA DEINICJALIZACJI                    |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    EventKillTimer();
    
    if(InpEnableLogging && g_diagnostics != NULL) {
        g_diagnostics.Log(DEBUG_CRITICAL, "SYSTEM", "═══════════════════════════════════════════════════");
        g_diagnostics.Log(DEBUG_CRITICAL, "SYSTEM", "    ZAMYKANIE SYSTEMU");
        g_diagnostics.Log(DEBUG_CRITICAL, "SYSTEM", "═══════════════════════════════════════════════════");
    }
    
    // Zapisz statystyki końcowe
    SaveFinalReport();
    
    // Zapisz persystentne dane
    SavePersistentData();
    
    // Wyczyść wszystko
    CleanupAll();
    
    // Pokaż powód zamknięcia
    string reasonText = GetDeInitReasonText(reason);
    if(InpEnableLogging && g_diagnostics != NULL) {
        g_diagnostics.Log(DEBUG_CRITICAL, "SYSTEM", "Powód zamknięcia: " + reasonText);
    }
    
    Comment("");
    ChartRedraw();
}

//+------------------------------------------------------------------+
//|                         FUNKCJA OnTick                          |
//+------------------------------------------------------------------+
void OnTick() {
    // Sprawdź czy system jest aktywny
    if(!g_systemState.isActive || !g_systemState.isInitialized) {
        return;
    }
    
    // Zwiększ liczniki
    g_totalTicks++;
    g_systemState.ticksProcessed++;
    
    // Diagnostyka z ograniczeniem
    if(InpEnableLogging && (g_totalTicks % InpLogFrequency == 0) && g_diagnostics != NULL) {
        g_diagnostics.Log(DEBUG_VERBOSE, "TICK", "Tick #" + IntegerToString(g_totalTicks));
    }
    
    // Odśwież dane rynkowe
    if(!RefreshMarketData()) {
        if(InpEnableLogging && g_totalTicks % 10 == 0 && g_diagnostics != NULL) {
            g_diagnostics.Log(DEBUG_NORMAL, "DATA", "⚠️ Nie można odświeżyć danych rynkowych");
        }
        return;
    }
    
    // Sprawdź nowe bary
    CheckNewBars();
    
    // Aktualizuj analizę rynku z throttling (co 3 sekundy)
    if(TimeCurrent() - g_lastMarketAnalysis >= 3) {
        UpdateMarketAnalysis();
        g_lastMarketAnalysis = TimeCurrent();
    }
    
    // Sprawdź warunki risk management z throttling (co 2 sekundy)
    if(TimeCurrent() - g_lastRiskCheck >= 2) {
        if(!CheckRiskConditions()) {
            if(InpEnableLogging && g_diagnostics != NULL) {
                g_diagnostics.Log(DEBUG_NORMAL, "RISK", "🛑 Warunki ryzyka nie pozwalają na handel");
            }
            g_lastRiskCheck = TimeCurrent();
            return;
        }
        g_lastRiskCheck = TimeCurrent();
    }
    
    // Zarządzaj otwartymi pozycjami
    ManageOpenPositions();
    
    // Kontrolowane sprawdzanie sygnałów
    if(ShouldCheckSignals()) {
        CheckForSignals();
    }
    
    // Aktualizuj dashboard z throttling (co 1 sekundę)
    if(InpEnableGUI && TimeCurrent() - g_lastDashboardUpdate >= 1) {
        UpdateDashboard();
        g_lastDashboardUpdate = TimeCurrent();
    }
    
    // Usuń komentarz rzadziej
    static datetime lastCommentClear = 0;
    if(TimeCurrent() - lastCommentClear >= 10) {
        Comment("");
        lastCommentClear = TimeCurrent();
    }
}

//+------------------------------------------------------------------+
//|                        FUNKCJA OnTimer                          |
//+------------------------------------------------------------------+
void OnTimer() {
    // Aktualizacja GUI
    if(InpEnableGUI && g_dashboard != NULL) {
        g_dashboard.Update();
    }
    
    // Co 10 sekund - sprawdź stan systemu
    static datetime lastSystemCheck = 0;
    if(TimeCurrent() - lastSystemCheck >= 10) {
        CheckSystemHealth();
        AdaptToMarketConditions();
        CleanupCache();
        lastSystemCheck = TimeCurrent();
    }
    
    // Co minutę - zapisz stan
    static datetime lastStateSave = 0;
    if(TimeCurrent() - lastStateSave >= 60) {
        SaveSystemState();
        SavePersistentData();
        lastStateSave = TimeCurrent();
    }
    
    // Co 5 minut - optymalizacja pamięci
    static datetime lastMemoryOptimization = 0;
    if(TimeCurrent() - lastMemoryOptimization >= 300) {
        OptimizeMemory();
        lastMemoryOptimization = TimeCurrent();
    }
}

//+------------------------------------------------------------------+
//|                    FUNKCJA OnChartEvent                         |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam) {
    
    if(id == CHARTEVENT_OBJECT_CLICK) {
        string clickedObject = sparam;
        
        if(StringFind(clickedObject, PREFIX_PANEL) == 0) {
            HandleGUIButtonClick(clickedObject);
        }
    }
    
    if(id == CHARTEVENT_KEYDOWN) {
        int key = (int)lparam;
        HandleKeyPress(key);
    }
}

//+------------------------------------------------------------------+
//|                 FUNKCJE INICJALIZACYJNE - POPRAWIONE            |
//+------------------------------------------------------------------+
// Inicjalizacja cache
void InitializeCache() {
    g_cache.instrumentType = INSTRUMENT_UNKNOWN;
    g_cache.lastInstrumentCheck = 0;
    g_cache.lastSpread = 0;
    g_cache.lastSpreadCheck = 0;
    g_cache.isCryptoMode = false;
    g_cache.isBTCMode = false;
    g_cache.lastATR = 0;
    g_cache.lastATRCheck = 0;
}

// Inicjalizacja signal management z persystencją
void InitializeSignalManagement() {
    // Jeśli nowa sesja (ponad 24h), resetuj
    if(g_signalMgmt.sessionStart == 0 || 
       TimeCurrent() - g_signalMgmt.sessionStart > 86400) {
        g_signalMgmt.sessionStart = TimeCurrent();
        g_signalMgmt.sessionSignalsGenerated = 0;
        g_signalMgmt.sessionSignalsExecuted = 0;
    }
    
    // Synchronizacja globalnych liczników
    g_signalsGenerated = g_signalMgmt.sessionSignalsGenerated;
    g_signalsExecuted = g_signalMgmt.sessionSignalsExecuted;
    
    g_signalMgmt.lastSignalCheck = 0;
    g_signalMgmt.lastValidSignal = 0;
    g_signalMgmt.signalCheckInterval = 45;
    g_signalMgmt.signalsGeneratedThisBar = 0;
    g_signalMgmt.maxSignalsPerBar = 3;  // Zmniejszone dla lepszej jakości
    g_signalMgmt.signalPending = false;
    
    // Reset performance stats jeśli nowa sesja
    if(TimeCurrent() - g_signalMgmt.sessionStart < 60) {
        g_performance.Reset();
    }
}

// Bezpieczna inicjalizacja managerów
bool InitializeManagersSafe() {
    if(InpEnableLogging && g_diagnostics != NULL) {
        g_diagnostics.Log(DEBUG_NORMAL, "INIT", "Inicjalizacja managerów (bezpieczna)...");
    }
    
    // Data Manager
    if(g_dataManager == NULL) {
        g_dataManager = new CDataManager();
        if(!g_dataManager.Initialize()) {
            if(InpEnableLogging && g_diagnostics != NULL) {
                g_diagnostics.Log(DEBUG_CRITICAL, "INIT", "❌ Błąd inicjalizacji DataManager");
            }
            return false;
        }
    }
    
    // Risk Manager
    if(g_riskManager == NULL) {
        double maxDailyLoss = InpMaxDailyLoss > 0 ? InpMaxDailyLoss : 999999;
        g_riskManager = new CRiskManager(InpRiskPerTrade, maxDailyLoss, InpMaxTotalDrawdown);
        if(!g_riskManager.Initialize()) {
            if(InpEnableLogging && g_diagnostics != NULL) {
                g_diagnostics.Log(DEBUG_CRITICAL, "INIT", "❌ Błąd inicjalizacji RiskManager");
            }
            return false;
        }
    }
    
    // Market Analyzer
    if(g_marketAnalyzer == NULL) {
        g_marketAnalyzer = new CMarketAnalyzer();
        if(!g_marketAnalyzer.Initialize()) {
            if(InpEnableLogging && g_diagnostics != NULL) {
                g_diagnostics.Log(DEBUG_CRITICAL, "INIT", "❌ Błąd inicjalizacji MarketAnalyzer");
            }
            return false;
        }
    }
    
    // Signal Manager - z POPRAWIONYMI progami
    if(g_signalManager == NULL) {
        g_signalManager = new CSignalManager(InpMinSignalScore, InpMinRiskReward);
        if(!g_signalManager.Initialize()) {
            if(InpEnableLogging && g_diagnostics != NULL) {
                g_diagnostics.Log(DEBUG_CRITICAL, "INIT", "❌ Błąd inicjalizacji SignalManager");
            }
            return false;
        }
    }
    
    // Position Manager
    if(g_positionManager == NULL) {
        g_positionManager = new CPositionManager(InpMagicNumber, InpMaxPositions);
        if(!g_positionManager.Initialize()) {
            if(InpEnableLogging && g_diagnostics != NULL) {
                g_diagnostics.Log(DEBUG_CRITICAL, "INIT", "❌ Błąd inicjalizacji PositionManager");
            }
            return false;
        }
        
        // Ustaw parametry trailing stop - POPRAWIONE
        g_positionManager.SetTrailingParams(
            true,   // use trailing
            0.5,    // activation - 50% zysku
            0.3,    // distance - 30% ATR
            0.05    // step - 5% ATR
        );
        
        // Ustaw breakeven - POPRAWIONE
        g_positionManager.SetBreakevenParams(
            true,   // use breakeven
            0.3,    // activation - 30% zysku
            10      // offset w punktach
        );
        
        // Ustaw partial close - POPRAWIONE
        g_positionManager.SetPartialCloseParams(
            true,   // use partial
            50,     // 50% close
            0.7     // przy 70% TP
        );
    }
    
    // Specjalne ustawienia po inicjalizacji
    DetectAndConfigureInstrument();
    
    if(InpEnableLogging && g_diagnostics != NULL) {
        g_diagnostics.Log(DEBUG_NORMAL, "INIT", "✅ Wszystkie managery zainicjalizowane bezpiecznie");
    }
    return true;
}

// Wykryj i skonfiguruj instrument - z cache
void DetectAndConfigureInstrument() {
    // Sprawdź cache
    if(TimeCurrent() - g_cache.lastInstrumentCheck < 60) {
        g_isCryptoMode = g_cache.isCryptoMode;
        g_isBTCMode = g_cache.isBTCMode;
        return;
    }
    
    ENUM_INSTRUMENT_TYPE instrumentType = DetectInstrumentType(_Symbol);
    string symbolUpper = _Symbol;
    StringToUpper(symbolUpper);
    
    // Wykrywanie dla złota
    if(StringFind(symbolUpper, "XAUUSD") >= 0 || StringFind(symbolUpper, "GOLD") >= 0) {
        instrumentType = INSTRUMENT_METAL;
        DEBUG_MSG(DEBUG_CRITICAL, "INIT", "🥇 GOLD DETECTED - Metal mode activated");
    }
    
    g_isCryptoMode = (instrumentType == INSTRUMENT_CRYPTO);
    g_isBTCMode = (StringFind(symbolUpper, "BTC") >= 0 || StringFind(symbolUpper, "BITCOIN") >= 0);
    
    // Zapisz w cache
    g_cache.instrumentType = instrumentType;
    g_cache.isCryptoMode = g_isCryptoMode;
    g_cache.isBTCMode = g_isBTCMode;
    g_cache.lastInstrumentCheck = TimeCurrent();
    
    // Konfiguracja częstotliwości - POPRAWIONE
    if(g_isBTCMode) {
        if(InpEnableLogging && g_diagnostics != NULL) {
            g_diagnostics.Log(DEBUG_CRITICAL, "INIT", "⚡ BTC MODE ACTIVATED - Optimized frequency");
        }
        
        g_signalMgmt.signalCheckInterval = 30;
        g_signalMgmt.maxSignalsPerBar = 3;
        
        if(g_signalManager != NULL) {
            g_signalManager.SetMinSignalScore(InpMinSignalScore);
            g_signalManager.SetMinRiskReward(InpMinRiskReward);
            g_signalManager.SetSignalCooldown(45);
        }
    }
    else if(g_isCryptoMode) {
        if(InpEnableLogging && g_diagnostics != NULL) {
            g_diagnostics.Log(DEBUG_CRITICAL, "INIT", "₿ CRYPTO MODE - High frequency");
        }
        
        g_signalMgmt.signalCheckInterval = 35;
        g_signalMgmt.maxSignalsPerBar = 4;
        
        if(g_signalManager != NULL) {
            g_signalManager.SetMinSignalScore(InpMinSignalScore);
            g_signalManager.SetMinRiskReward(InpMinRiskReward);
            g_signalManager.SetSignalCooldown(45);
        }
    }
    else if(instrumentType == INSTRUMENT_METAL) {
        if(InpEnableLogging && g_diagnostics != NULL) {
            g_diagnostics.Log(DEBUG_CRITICAL, "INIT", "🥇 METAL MODE - Moderate frequency");
        }
        
        g_signalMgmt.signalCheckInterval = 40;
        g_signalMgmt.maxSignalsPerBar = 3;
        
        if(g_signalManager != NULL) {
            g_signalManager.SetMinSignalScore(InpMinSignalScore);
            g_signalManager.SetMinRiskReward(InpMinRiskReward);
            g_signalManager.SetSignalCooldown(60);
        }
    }
    else {
        if(InpEnableLogging && g_diagnostics != NULL) {
            g_diagnostics.Log(DEBUG_CRITICAL, "INIT", "💱 FOREX MODE - Standard frequency");
        }
        
        g_signalMgmt.signalCheckInterval = 60;
        g_signalMgmt.maxSignalsPerBar = 3;
        
        if(g_signalManager != NULL) {
            g_signalManager.SetMinSignalScore(InpMinSignalScore);
            g_signalManager.SetMinRiskReward(InpMinRiskReward);
            g_signalManager.SetSignalCooldown(90);
        }
    }
}

bool InitializeStrategies() {
    DEBUG_MSG(DEBUG_NORMAL, "INIT", "Initializing strategies...");
    
    // Użyj cache dla typu instrumentu
    ENUM_INSTRUMENT_TYPE instrumentType = g_cache.instrumentType;
    if(instrumentType == INSTRUMENT_UNKNOWN) {
        instrumentType = DetectInstrumentType(_Symbol);
    }
    
    // Utwórz odpowiednią strategię
    switch(instrumentType) {
        case INSTRUMENT_FOREX:
            g_activeStrategy = new CForexStrategy();
            DEBUG_MSG(DEBUG_NORMAL, "STRATEGY", "📈 Aktywna strategia: FOREX");
            break;
            
        case INSTRUMENT_METAL:
            g_activeStrategy = new CMetalStrategy();
            DEBUG_MSG(DEBUG_NORMAL, "STRATEGY", "🥇 Aktywna strategia: METALS");
            break;
            
        case INSTRUMENT_CRYPTO:
            g_activeStrategy = new CCryptoStrategy();
            DEBUG_MSG(DEBUG_NORMAL, "STRATEGY", "₿ Aktywna strategia: CRYPTO");
            break;
            
        default:
            g_activeStrategy = new CAdaptiveStrategy();
            DEBUG_MSG(DEBUG_NORMAL, "STRATEGY", "📊 Domyślna strategia: ADAPTIVE");
    }
    
    if(!g_activeStrategy.Initialize()) {
        DEBUG_MSG(DEBUG_CRITICAL, "STRATEGY", "❌ Błąd inicjalizacji strategii");
        return false;
    }
    
    // Ustaw progi
    g_activeStrategy.SetMinScore(InpMinSignalScore);
    g_activeStrategy.SetMinRR(InpMinRiskReward);
    
    return true;
}

//+------------------------------------------------------------------+
//|                    FUNKCJE OPERACYJNE                           |
//+------------------------------------------------------------------+
bool ShouldCheckSignals() {
    if(!CanOpenNewPosition()) {
        return false;
    }
    
    datetime currentTime = TimeCurrent();
    int timeSinceLastCheck = (int)(currentTime - g_signalMgmt.lastSignalCheck);
    
    if(timeSinceLastCheck < g_signalMgmt.signalCheckInterval) {
        return false;
    }
    
    // Sprawdź limit sygnałów na bar
    static datetime lastBarTime = 0;
    datetime currentBarTime = iTime(_Symbol, PERIOD_M15, 0);
    
    if(currentBarTime != lastBarTime) {
        lastBarTime = currentBarTime;
        g_signalMgmt.signalsGeneratedThisBar = 0;
    }
    
    if(g_signalMgmt.signalsGeneratedThisBar >= g_signalMgmt.maxSignalsPerBar) {
        return false;
    }
    
    return true;
}

void CheckForSignals() {
    if(g_signalManager == NULL || g_activeStrategy == NULL) return;
    
    g_signalMgmt.lastSignalCheck = TimeCurrent();
    
    TradeSignal signal = g_activeStrategy.CheckSignal();
    
    if(signal.isValid) {
        g_signalMgmt.sessionSignalsGenerated++;
        g_signalsGenerated = g_signalMgmt.sessionSignalsGenerated;
        g_signalMgmt.signalsGeneratedThisBar++;
        g_performance.totalSignals++;
        
        if(InpEnableLogging && g_diagnostics != NULL) {
            g_diagnostics.Log(DEBUG_CRITICAL, "SIGNAL", 
                StringFormat("📊 NOWY SYGNAŁ #%d: %s | Siła: %d | R:R: %.2f | %s",
                    g_signalsGenerated,
                    signal.direction == SIGNAL_BUY ? "BUY" : "SELL",
                    signal.strength,
                    signal.riskRewardRatio,
                    signal.reason));
        }
        
        if(g_signalManager.ValidateSignal(signal)) {
            g_signalMgmt.lastValidSignal = TimeCurrent();
            ExecuteTrade(signal);
        } else {
            if(InpEnableLogging && g_diagnostics != NULL) {
                g_diagnostics.Log(DEBUG_NORMAL, "SIGNAL", 
                    StringFormat("❌ Sygnał #%d nie przeszedł walidacji", g_signalsGenerated));
            }
        }
    }
}

void ExecuteTrade(TradeSignal& signal) {
    if(g_positionManager == NULL) return;
    
    // Oblicz wielkość pozycji
    double lotSize = CalculatePositionSize(signal.stopLoss);
    
    if(lotSize <= 0) {
        if(InpEnableLogging && g_diagnostics != NULL) {
            g_diagnostics.Log(DEBUG_NORMAL, "TRADE", "❌ Nieprawidłowa wielkość pozycji");
        }
        return;
    }
    
    signal.lotSize = lotSize;
    
    bool success = g_positionManager.OpenPosition(signal);
    
    if(success) {
        g_signalMgmt.sessionSignalsExecuted++;
        g_signalsExecuted = g_signalMgmt.sessionSignalsExecuted;
        g_performance.executedSignals++;
        
        if(InpEnableLogging && g_diagnostics != NULL) {
            g_diagnostics.Log(DEBUG_CRITICAL, "TRADE", 
                StringFormat("✅ POZYCJA OTWARTA #%d: %s %.2f lots @ %.5f | SL: %.5f | TP: %.5f",
                    g_signalsExecuted,
                    signal.direction == SIGNAL_BUY ? "BUY" : "SELL",
                    signal.lotSize,
                    signal.entryPrice,
                    signal.stopLoss,
                    signal.takeProfit));
        }
        
        if(InpShowAlerts) {
            PlaySound("alert.wav");
        }
        
        if(InpSendNotifications) {
            SendNotification(StringFormat("MC5: %s %s @ %.5f",
                signal.direction == SIGNAL_BUY ? "BUY" : "SELL",
                _Symbol,
                signal.entryPrice));
        }
    } else {
        if(InpEnableLogging && g_diagnostics != NULL) {
            g_diagnostics.Log(DEBUG_NORMAL, "TRADE", "❌ Nie udało się otworzyć pozycji");
        }
    }
}

double CalculatePositionSize(double stopLossDistance) {
    if(stopLossDistance <= 0) {
        DEBUG_MSG(DEBUG_NORMAL, "RISK", "Invalid stop loss distance");
        return 0;
    }
    
    if(g_riskManager != NULL) {
        return g_riskManager.CalculatePositionSize(stopLossDistance);
    }
    
    // Fallback
    double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    double riskAmount = accountBalance * (InpRiskPerTrade / 100);
    
    ENUM_INSTRUMENT_TYPE instrumentType = g_cache.instrumentType;
    if(instrumentType == INSTRUMENT_UNKNOWN) {
        instrumentType = DetectInstrumentType(_Symbol);
    }
    
    double lotSize = 0;
    
    if(instrumentType == INSTRUMENT_CRYPTO) {
        double contractSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
        double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
        double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
        
        if(contractSize > 0 && tickValue > 0 && tickSize > 0) {
            lotSize = (riskAmount * tickSize) / (stopLossDistance * tickValue);
        }
    } else {
        double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
        double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
        
        if(tickValue > 0 && tickSize > 0) {
            double stopLossPoints = stopLossDistance / _Point;
            double pointValue = tickValue * _Point / tickSize;
            
            if(pointValue > 0 && stopLossPoints > 0) {
                lotSize = riskAmount / (stopLossPoints * pointValue);
            }
        }
    }
    
    // Skalowanie lota - POPRAWIONE
    if(accountBalance >= 10000) {
        lotSize = MathMax(0.1, MathMin(2.0, lotSize));
    } else if(accountBalance >= 5000) {
        lotSize = MathMax(0.05, MathMin(1.0, lotSize));
    } else if(accountBalance >= 2000) {
        lotSize = MathMax(0.02, MathMin(0.5, lotSize));
    } else if(accountBalance >= 1000) {
        lotSize = MathMax(0.01, MathMin(0.2, lotSize));
    } else {
        lotSize = MathMax(0.01, MathMin(0.1, lotSize));
    }
    
    return NormalizeLot(lotSize);
}

// NOWE FUNKCJE POMOCNICZE

void SavePersistentData() {
    string filename = "MC5_persistent.dat";
    int handle = FileOpen(filename, FILE_WRITE|FILE_BIN);
    
    if(handle != INVALID_HANDLE) {
        FileWriteLong(handle, g_signalMgmt.sessionStart);
        FileWriteInteger(handle, g_signalMgmt.sessionSignalsGenerated);
        FileWriteInteger(handle, g_signalMgmt.sessionSignalsExecuted);
        FileWriteInteger(handle, g_performance.totalTrades);
        FileWriteInteger(handle, g_performance.winningTrades);
        FileWriteInteger(handle, g_performance.losingTrades);
        FileWriteDouble(handle, g_performance.totalProfit);
        FileWriteDouble(handle, g_performance.winRate);
        
        FileClose(handle);
        
        DEBUG_MSG(DEBUG_VERBOSE, "SYSTEM", "Persistent data saved");
    }
}

void LoadPersistentData() {
    string filename = "MC5_persistent.dat";
    
    if(FileIsExist(filename)) {
        int handle = FileOpen(filename, FILE_READ|FILE_BIN);
        
        if(handle != INVALID_HANDLE) {
            g_signalMgmt.sessionStart = (datetime)FileReadLong(handle);
            g_signalMgmt.sessionSignalsGenerated = FileReadInteger(handle);
            g_signalMgmt.sessionSignalsExecuted = FileReadInteger(handle);
            g_performance.totalTrades = FileReadInteger(handle);
            g_performance.winningTrades = FileReadInteger(handle);
            g_performance.losingTrades = FileReadInteger(handle);
            g_performance.totalProfit = FileReadDouble(handle);
            g_performance.winRate = FileReadDouble(handle);
            
            FileClose(handle);
            
            DEBUG_MSG(DEBUG_VERBOSE, "SYSTEM", "Persistent data loaded");
        }
    }
}

void CleanupCache() {
    // Resetuj cache co 5 minut
    if(TimeCurrent() - g_cache.lastInstrumentCheck > 300) {
        g_cache.lastInstrumentCheck = 0;
    }
    
    if(TimeCurrent() - g_cache.lastSpreadCheck > 60) {
        g_cache.lastSpreadCheck = 0;
    }
    
    if(TimeCurrent() - g_cache.lastATRCheck > 30) {
        g_cache.lastATRCheck = 0;
    }
}

void OptimizeMemory() {
    // Wyczyść niepotrzebne bufory
    if(g_positionManager != NULL) {
        g_positionManager.CleanupTrailingCache();
    }
    
    // Wyczyść stare logi
    if(g_diagnostics != NULL) {
        g_diagnostics.RotateLogs();
    }
    
    DEBUG_MSG(DEBUG_VERBOSE, "SYSTEM", "Memory optimization completed");
}

// Pozostałe funkcje bez zmian...
bool CheckInitialConditions() {
    if(InpEnableLogging && g_diagnostics != NULL) {
        g_diagnostics.Log(DEBUG_NORMAL, "INIT", "Sprawdzanie warunków początkowych...");
    }
    
    if(!TerminalInfoInteger(TERMINAL_CONNECTED)) {
        if(InpEnableLogging && g_diagnostics != NULL) {
            g_diagnostics.Log(DEBUG_CRITICAL, "INIT", "❌ Brak połączenia z serwerem!");
        }
        return false;
    }
    
    if(!SymbolInfoInteger(_Symbol, SYMBOL_SELECT)) {
        if(InpEnableLogging && g_diagnostics != NULL) {
            g_diagnostics.Log(DEBUG_CRITICAL, "INIT", "❌ Symbol " + _Symbol + " nie jest dostępny!");
        }
        return false;
    }
    
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    if(balance < 50) {
        if(InpEnableLogging && g_diagnostics != NULL) {
            g_diagnostics.Log(DEBUG_CRITICAL, "INIT", "❌ Za niski depozyt: " + DoubleToString(balance, 2));
        }
        return false;
    }
    
    int bars = Bars(_Symbol, PERIOD_CURRENT);
    if(bars < 50) {
        if(InpEnableLogging && g_diagnostics != NULL) {
            g_diagnostics.Log(DEBUG_CRITICAL, "INIT", "❌ Za mało danych historycznych: " + IntegerToString(bars));
        }
        return false;
    }
    
    if(InpEnableLogging && g_diagnostics != NULL) {
        g_diagnostics.Log(DEBUG_NORMAL, "INIT", "✅ Warunki początkowe spełnione");
    }
    return true;
}

void RefreshAllData() {
    if(g_dataManager != NULL) g_dataManager.RefreshAll();
    if(g_marketAnalyzer != NULL) g_marketAnalyzer.Analyze();
}

bool RefreshMarketData() {
    if(g_dataManager == NULL) return false;
    return g_dataManager.RefreshTick();
}

void UpdateMarketAnalysis() {
    if(g_marketAnalyzer != NULL) {
        g_marketConditions = g_marketAnalyzer.GetCurrentConditions();
    }
}

bool CheckRiskConditions() {
    if(g_riskManager == NULL) return false;
    
    RiskStatus riskStatus = g_riskManager.GetCurrentStatus();
    
    if(riskStatus.emergencyStop) {
        if(InpEnableLogging && g_diagnostics != NULL) {
            g_diagnostics.Log(DEBUG_CRITICAL, "RISK", "🚨 EMERGENCY STOP AKTYWNY!");
        }
        return false;
    }
    
    if(InpMaxDailyLoss > 0 && riskStatus.dailyLimitReached) {
        static datetime lastWarning = 0;
        if(TimeCurrent() - lastWarning > 300) {
            if(InpEnableLogging && g_diagnostics != NULL) {
                g_diagnostics.Log(DEBUG_NORMAL, "RISK", "⚠️ Osiągnięto dzienny limit strat");
            }
            lastWarning = TimeCurrent();
        }
        return false;
    }
    
    return riskStatus.canTrade;
}

void ManageOpenPositions() {
    if(g_positionManager == NULL) return;
    
    g_positionManager.ManageAll();
    g_positionManager.CheckTrailingStops();
    g_positionManager.CheckBreakeven();
    g_positionManager.CheckPartialClose();
}

bool CanOpenNewPosition() {
    if(!InpAutoTrading) {
        return false;
    }
    
    if(g_positionManager == NULL) return false;
    
    int ourPositions = g_positionManager.GetOpenPositionsCount();
    
    if(ourPositions >= InpMaxPositions) {
        DEBUG_MSG(DEBUG_VERBOSE, "POSITION", 
            StringFormat("Max positions reached: %d/%d", ourPositions, InpMaxPositions));
        return false;
    }
    
    if(g_riskManager != NULL && !g_riskManager.CanOpenNewPosition()) {
        return false;
    }
    
    return true;
}

void CheckNewBars() {
    static datetime lastM15 = 0, lastH1 = 0;
    
    datetime currentM15 = iTime(_Symbol, PERIOD_M15, 0);
    datetime currentH1 = iTime(_Symbol, PERIOD_H1, 0);
    
    if(currentM15 > lastM15 && lastM15 > 0) {
        OnBarM15();
        lastM15 = currentM15;
    }
    if(lastM15 == 0) lastM15 = currentM15;
    
    if(currentH1 > lastH1 && lastH1 > 0) {
        OnBarH1();
        lastH1 = currentH1;
    }
    if(lastH1 == 0) lastH1 = currentH1;
}

void OnBarM15() {
    if(InpEnableLogging && g_diagnostics != NULL) {
        g_diagnostics.Log(DEBUG_VERBOSE, "BAR", "Nowy bar M15");
    }
    
    RefreshAllData();
    g_signalMgmt.signalsGeneratedThisBar = 0;
}

void OnBarH1() {
    if(InpEnableLogging && g_diagnostics != NULL) {
        g_diagnostics.Log(DEBUG_NORMAL, "BAR", "📊 Nowy bar H1");
    }
    
    if(g_marketAnalyzer != NULL) {
        g_marketAnalyzer.UpdateKeyLevels();
    }
    
    AdaptToMarketConditions();
}

void AdaptToMarketConditions() {
    if(g_marketAnalyzer == NULL) return;
    
    MarketConditions conditions = g_marketAnalyzer.GetCurrentConditions();
    
    if(conditions.isVolatile) {
        if(g_signalManager != NULL) {
            g_signalManager.SetMinSignalScore(MathMax(55, InpMinSignalScore - 5));
        }
        if(g_positionManager != NULL) {
            g_positionManager.SetTrailingParams(true, 0.4, 0.25, 0.03);
        }
    }
    else if(conditions.volatility < 0.5) {
        if(g_signalManager != NULL) {
            g_signalManager.SetMinSignalScore(MathMin(70, InpMinSignalScore + 5));
        }
        if(g_positionManager != NULL) {
            g_positionManager.SetTrailingParams(true, 0.6, 0.35, 0.05);
        }
    }
}

void UpdateDashboard() {
    if(g_dashboard == NULL || !InpShowDashboard || !InpEnableGUI) return;
    
    DashboardData data;
    
    data.balance = AccountInfoDouble(ACCOUNT_BALANCE);
    data.equity = AccountInfoDouble(ACCOUNT_EQUITY);
    data.freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    data.marginLevel = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
    
    if(g_positionManager != NULL) {
        data.openPositions = g_positionManager.GetOpenPositionsCount();
        data.totalVolume = g_positionManager.GetTotalVolume();
        data.floatingPL = g_positionManager.GetFloatingPL();
    }
    
    data.performance.totalSignals = g_signalsGenerated;
    data.performance.executedSignals = g_signalsExecuted;
    
    data.marketConditions = g_marketConditions;
    
    if(g_riskManager != NULL) {
        data.riskStatus = g_riskManager.GetCurrentStatus();
    }
    
    g_dashboard.UpdateData(data);
    g_dashboard.Update();
}

void CheckSystemHealth() {
    if(InpEnableLogging && g_diagnostics != NULL) {
        g_diagnostics.Log(DEBUG_VERBOSE, "HEALTH", "Sprawdzanie stanu systemu...");
    }
    
    if(!TerminalInfoInteger(TERMINAL_CONNECTED)) {
        if(InpEnableLogging && g_diagnostics != NULL) {
            g_diagnostics.Log(DEBUG_CRITICAL, "HEALTH", "❌ Utracono połączenie z serwerem!");
        }
        g_systemState.isActive = false;
        return;
    }
    
    int memoryUsed = TerminalInfoInteger(TERMINAL_MEMORY_USED);
    if(memoryUsed > 1000) {
        if(InpEnableLogging && g_diagnostics != NULL) {
            g_diagnostics.Log(DEBUG_NORMAL, "HEALTH", "⚠️ Wysokie zużycie pamięci: " + IntegerToString(memoryUsed) + " MB");
        }
    }
    
    if(g_riskManager != NULL) {
        g_riskManager.ResetDaily();
    }
}

void SaveSystemState() {
    if(g_diagnostics != NULL && InpEnableLogging) {
        g_diagnostics.SaveState(g_systemState);
    }
}

void SaveFinalReport() {
    if(g_diagnostics != NULL && InpEnableLogging) {
        g_diagnostics.SaveFinalReport(g_performance);
    }
}

void ShowInitializationReport() {
    string report = "\n";
    report += "╔════════════════════════════════════════════════╗\n";
    report += "║        MARKET COMPASS v5.1 - READY             ║\n";
    report += "╠════════════════════════════════════════════════╣\n";
    report += "║ Symbol: " + StringFormat("%-39s", _Symbol) + "║\n";
    report += "║ Type: " + StringFormat("%-41s", g_isBTCMode ? "BTC OPTIMIZED" : 
                                                   g_isCryptoMode ? "CRYPTO" : 
                                                   g_cache.instrumentType == INSTRUMENT_METAL ? "METAL/GOLD" : "STANDARD") + "║\n";
    report += "║ Account: " + StringFormat("%-38.2f", AccountInfoDouble(ACCOUNT_BALANCE)) + "║\n";
    report += "║ Max Positions: " + StringFormat("%-32d", InpMaxPositions) + "║\n";
    report += "║ Min Signal Score: " + StringFormat("%-29d", InpMinSignalScore) + "║\n";
    report += "║ Min Risk:Reward: " + StringFormat("%-30.2f", InpMinRiskReward) + "║\n";
    report += "║ Signal Check Interval: " + StringFormat("%-24d", g_signalMgmt.signalCheckInterval) + "║\n";
    report += "║ Max Signals/Bar: " + StringFormat("%-30d", g_signalMgmt.maxSignalsPerBar) + "║\n";
    report += "╚════════════════════════════════════════════════╝\n";
    
    Print(report);
}

string GetDeInitReasonText(int reason) {
    switch(reason) {
        case REASON_PROGRAM: return "Program stopped";
        case REASON_REMOVE: return "Program removed";
        case REASON_RECOMPILE: return "Program recompiled";
        case REASON_CHARTCHANGE: return "Chart changed";
        case REASON_CHARTCLOSE: return "Chart closed";
        case REASON_PARAMETERS: return "Parameters changed";
        case REASON_ACCOUNT: return "Account changed";
        case REASON_TEMPLATE: return "Template applied";
        case REASON_INITFAILED: return "Initialization failed";
        case REASON_CLOSE: return "Terminal closed";
        default: return "Unknown reason";
    }
}

void CleanupManagers() {
    if(g_dataManager != NULL) { delete g_dataManager; g_dataManager = NULL; }
    if(g_riskManager != NULL) { delete g_riskManager; g_riskManager = NULL; }
    if(g_signalManager != NULL) { delete g_signalManager; g_signalManager = NULL; }
    if(g_positionManager != NULL) { delete g_positionManager; g_positionManager = NULL; }
    if(g_marketAnalyzer != NULL) { delete g_marketAnalyzer; g_marketAnalyzer = NULL; }
}

void CleanupAll() {
    CleanupManagers();
    
    if(g_activeStrategy != NULL) { delete g_activeStrategy; g_activeStrategy = NULL; }
    if(g_dashboard != NULL) { delete g_dashboard; g_dashboard = NULL; }
    if(g_diagnostics != NULL) { 
        g_diagnostics.EndSession();
        delete g_diagnostics; 
        g_diagnostics = NULL; 
    }
}