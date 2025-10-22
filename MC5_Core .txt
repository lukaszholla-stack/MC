//+------------------------------------------------------------------+
//|                                                     MC5_Core.mqh |
//|                 Rdzeń systemu - typy, stałe, zmienne globalne    |
//+------------------------------------------------------------------+
#ifndef MC5_CORE_MQH
#define MC5_CORE_MQH

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\OrderInfo.mqh>

//+------------------------------------------------------------------+
//|                         WERSJA SYSTEMU                           |
//+------------------------------------------------------------------+
#define SYSTEM_NAME         "Market Compass"
#define SYSTEM_VERSION      "5.1.0"
#define SYSTEM_BUILD        "2024.01.15"
#define SYSTEM_AUTHOR       "Market Compass Trading"

//+------------------------------------------------------------------+
//|                    ELEGANCKA PALETA KOLORÓW                      |
//+------------------------------------------------------------------+
#define CLR_NAVY            C'25,25,50'      // Navy blue - główne tło
#define CLR_NAVY_DARK       C'15,15,35'      // Ciemny navy - tło paneli
#define CLR_NAVY_LIGHT      C'35,35,70'      // Jasny navy - akcenty
#define CLR_GOLD            C'218,165,32'    // Złoty - najważniejsze elementy
#define CLR_GOLD_LIGHT      C'255,215,0'     // Jasne złoto - hover
#define CLR_SILVER          C'192,192,192'   // Srebrny - tekst drugorzędny
#define CLR_SILVER_LIGHT    C'220,220,220'   // Jasny srebrny
#define CLR_WHITE           C'255,255,255'   // Biały - główny tekst
#define CLR_BLACK           C'0,0,0'         // Czarny - kontrasty

// Kolory tła i paneli
#define CLR_BACKGROUND      CLR_NAVY_DARK     // Główne tło
#define CLR_PANEL           CLR_NAVY          // Tło paneli
#define CLR_HEADER          C'20,20,45'       // Nagłówki - ciemny navy
#define CLR_BORDER          CLR_GOLD          // Ramki - złote

// Kolory statusów
#define CLR_PRIMARY         CLR_GOLD          // Główny akcent
#define CLR_SECONDARY       CLR_SILVER        // Drugorzędny
#define CLR_SUCCESS         C'46,125,50'      // Zielony sukces
#define CLR_DANGER          C'183,28,28'      // Czerwony
#define CLR_WARNING         CLR_GOLD          // Ostrzeżenie
#define CLR_INFO            C'66,165,245'     // Info - jasny błękit

// Kolory tekstu
#define CLR_TEXT_PRIMARY    CLR_WHITE         // Główny tekst
#define CLR_TEXT_SECONDARY  CLR_SILVER        // Drugorzędny tekst

// Kolory dla wykresów
#define CLR_BULLISH         C'46,125,50'      // Wzrostowy
#define CLR_BEARISH         C'183,28,28'      // Spadkowy
#define CLR_NEUTRAL         CLR_SILVER        // Neutralny

//+------------------------------------------------------------------+
//|                      PARAMETRY SYSTEMU                           |
//+------------------------------------------------------------------+
#define MAX_POSITIONS       10                // Max pozycji
#define MIN_BARS_REQUIRED   50                // Min wymaganych barów
#define MAX_SLIPPAGE        30                // Max poślizg w punktach
#define BUFFER_SIZE         100               // Rozmiar buforów
#define INDICATOR_BUFFER    10                // Bufor wskaźników

// Prefixes dla obiektów
#define PREFIX_PANEL       "MCV5_Panel_"
#define PREFIX_BUTTON      "MCV5_Btn_"
#define PREFIX_LABEL       "MCV5_Lbl_"

//+------------------------------------------------------------------+
//|                          ENUMERACJE                              |
//+------------------------------------------------------------------+
// Tryby tradingu
enum ENUM_TRADING_MODE {
    MODE_SAFE,              // Bezpieczny (0.5% ryzyka)
    MODE_STANDARD,          // Standardowy (1-2% ryzyka)
    MODE_AGGRESSIVE,        // Agresywny (2-3% ryzyka)
    MODE_CUSTOM             // Własny
};

// Języki interfejsu
enum ENUM_LANGUAGE {
    LANG_POLISH,           // Polski
    LANG_ENGLISH           // English
};

// Poziomy debugowania
enum ENUM_DEBUG_LEVEL {
    DEBUG_OFF = 0,         // Wyłączony
    DEBUG_CRITICAL = 1,    // Tylko krytyczne
    DEBUG_NORMAL = 2,      // Normalne
    DEBUG_VERBOSE = 3,     // Szczegółowe
    DEBUG_PARANOID = 4     // Wszystko
};

// Typy instrumentów
enum ENUM_INSTRUMENT_TYPE {
    INSTRUMENT_FOREX,      // Pary walutowe
    INSTRUMENT_METAL,      // Metale
    INSTRUMENT_CRYPTO,     // Kryptowaluty
    INSTRUMENT_INDEX,      // Indeksy
    INSTRUMENT_STOCK,      // Akcje
    INSTRUMENT_UNKNOWN     // Nieznany
};

// Typy strategii
enum ENUM_STRATEGY_TYPE {
    STRATEGY_TREND,        // Podążanie za trendem
    STRATEGY_REVERSAL,     // Odwrócenie trendu
    STRATEGY_BREAKOUT,     // Wybicie
    STRATEGY_SCALPING,     // Skalpowanie
    STRATEGY_GRID,         // Siatka
    STRATEGY_ADAPTIVE      // Adaptacyjna
};

// Fazy rynku
enum ENUM_MARKET_PHASE {
    PHASE_ACCUMULATION,    // Akumulacja
    PHASE_MARKUP,          // Wzrost
    PHASE_DISTRIBUTION,    // Dystrybucja
    PHASE_DECLINE,         // Spadek
    PHASE_RANGING,         // Konsolidacja
    PHASE_VOLATILE,        // Wysoka zmienność
    PHASE_QUIET            // Niska zmienność
};

// Sesje rynkowe
enum ENUM_MARKET_SESSION {
    SESSION_SYDNEY,        // Sydney (22:00-07:00)
    SESSION_TOKYO,         // Tokyo (00:00-09:00)
    SESSION_LONDON,        // London (08:00-17:00)
    SESSION_NEWYORK,       // New York (13:00-22:00)
    SESSION_CLOSED         // Rynek zamknięty
};

// Kierunki sygnału
enum ENUM_SIGNAL_DIRECTION {
    SIGNAL_NONE = 0,       // Brak
    SIGNAL_BUY = 1,        // Kupno
    SIGNAL_SELL = -1       // Sprzedaż
};

//+------------------------------------------------------------------+
//|                          STRUKTURY                              |
//+------------------------------------------------------------------+
// Stan systemu
struct SystemState {
    bool isActive;
    bool isInitialized;
    bool isTrading;
    datetime startTime;
    datetime lastUpdateTime;
    int ticksProcessed;
    int barsProcessed;
    string lastError;
    
    void Reset() {
        isActive = false;
        isInitialized = false;
        isTrading = false;
        startTime = 0;
        lastUpdateTime = 0;
        ticksProcessed = 0;
        barsProcessed = 0;
        lastError = "";
    }
};

// Warunki rynkowe
struct MarketConditions {
    ENUM_MARKET_PHASE phase;
    ENUM_MARKET_SESSION session;
    int trendDirection;
    double trendStrength;
    double volatility;
    double momentum;
    double volume;
    double spread;
    double liquidity;
    bool isTrending;
    bool isVolatile;
    datetime lastUpdate;
    
    void Reset() {
        phase = PHASE_RANGING;
        session = SESSION_CLOSED;
        trendDirection = 0;
        trendStrength = 0;
        volatility = 0;
        momentum = 0;
        volume = 0;
        spread = 0;
        liquidity = 0;
        isTrending = false;
        isVolatile = false;
        lastUpdate = 0;
    }
};

// Sygnał handlowy
struct TradeSignal {
    ENUM_SIGNAL_DIRECTION direction;
    ENUM_STRATEGY_TYPE strategy;
    int strength;
    double entryPrice;
    double stopLoss;
    double takeProfit;
    double lotSize;
    double riskAmount;
    double riskRewardRatio;
    string reason;
    string comment;
    datetime expiry;
    bool isValid;
    
    void Reset() {
        direction = SIGNAL_NONE;
        strategy = STRATEGY_ADAPTIVE;
        strength = 0;
        entryPrice = 0;
        stopLoss = 0;
        takeProfit = 0;
        lotSize = 0;
        riskAmount = 0;
        riskRewardRatio = 0;
        reason = "";
        comment = "";
        expiry = 0;
        isValid = false;
    }
};

// Status ryzyka
struct RiskStatus {
    double accountBalance;
    double accountEquity;
    double freeMargin;
    double marginLevel;
    double dailyProfit;
    double dailyLoss;
    double dailyDrawdown;
    double maxDrawdown;
    double currentRisk;
    bool canTrade;
    bool dailyLimitReached;
    bool emergencyStop;
    string stopReason;
    
    void Reset() {
        accountBalance = 0;
        accountEquity = 0;
        freeMargin = 0;
        marginLevel = 0;
        dailyProfit = 0;
        dailyLoss = 0;
        dailyDrawdown = 0;
        maxDrawdown = 0;
        currentRisk = 0;
        canTrade = true;
        dailyLimitReached = false;
        emergencyStop = false;
        stopReason = "";
    }
};

// Statystyki wydajności
struct PerformanceStats {
    int totalSignals;
    int executedSignals;
    int totalTrades;
    int winningTrades;
    int losingTrades;
    double totalProfit;
    double totalLoss;
    double grossProfit;
    double grossLoss;
    double profitFactor;
    double winRate;
    double avgWin;
    double avgLoss;
    double avgRR;
    double sharpeRatio;
    double maxConsecutiveWins;
    double maxConsecutiveLosses;
    double bestTrade;
    double worstTrade;
    datetime lastTradeTime;
    
    void Reset() {
        totalSignals = 0;
        executedSignals = 0;
        totalTrades = 0;
        winningTrades = 0;
        losingTrades = 0;
        totalProfit = 0;
        totalLoss = 0;
        grossProfit = 0;
        grossLoss = 0;
        profitFactor = 0;
        winRate = 0;
        avgWin = 0;
        avgLoss = 0;
        avgRR = 0;
        sharpeRatio = 0;
        maxConsecutiveWins = 0;
        maxConsecutiveLosses = 0;
        bestTrade = 0;
        worstTrade = 0;
        lastTradeTime = 0;
    }
};

// Dane dla Dashboard
struct DashboardData {
    double balance;
    double equity;
    double freeMargin;
    double marginLevel;
    int openPositions;
    double totalVolume;
    double floatingPL;
    PerformanceStats performance;
    MarketConditions marketConditions;
    RiskStatus riskStatus;
    SystemState systemState;
};

// Konfiguracja instrumentu
struct InstrumentConfig {
    ENUM_INSTRUMENT_TYPE type;
    string symbol;
    double minLot;
    double maxLot;
    double lotStep;
    int digits;
    double pointValue;
    double tickValue;
    double tickSize;
    double contractSize;
    int freezeLevel;
    int stopsLevel;
    double margin;
    bool tradeAllowed;
    
    void Reset() {
        type = INSTRUMENT_UNKNOWN;
        symbol = "";
        minLot = 0;
        maxLot = 0;
        lotStep = 0;
        digits = 0;
        pointValue = 0;
        tickValue = 0;
        tickSize = 0;
        contractSize = 0;
        freezeLevel = 0;
        stopsLevel = 0;
        margin = 0;
        tradeAllowed = false;
    }
};

// Poziomy cenowe
struct PriceLevels {
    double pivot;
    double r1, r2, r3;
    double s1, s2, s3;
    double dailyHigh;
    double dailyLow;
    double weeklyHigh;
    double weeklyLow;
    double monthlyHigh;
    double monthlyLow;
    
    void Reset() {
        pivot = 0;
        r1 = r2 = r3 = 0;
        s1 = s2 = s3 = 0;
        dailyHigh = dailyLow = 0;
        weeklyHigh = weeklyLow = 0;
        monthlyHigh = monthlyLow = 0;
    }
};

//+------------------------------------------------------------------+
//|                    OBIEKTY HANDLOWE MQL5                         |
//+------------------------------------------------------------------+
// Globalne obiekty handlowe
CTrade            g_trade;           // Obiekt do wykonywania transakcji
CPositionInfo     g_position;        // Info o pozycjach
CSymbolInfo       g_symbol;          // Info o symbolu
CAccountInfo      g_account;         // Info o koncie
COrderInfo        g_order;           // Info o zleceniach

//+------------------------------------------------------------------+
//|                      UCHWYTY WSKAŹNIKÓW                          |
//+------------------------------------------------------------------+
// Wskaźniki główne (M15)
int g_handle_atr_m15 = INVALID_HANDLE;
int g_handle_rsi_m15 = INVALID_HANDLE;
int g_handle_macd_m15 = INVALID_HANDLE;
int g_handle_bb_m15 = INVALID_HANDLE;
int g_handle_ema_fast_m15 = INVALID_HANDLE;
int g_handle_ema_slow_m15 = INVALID_HANDLE;
int g_handle_adx_m15 = INVALID_HANDLE;
int g_handle_stoch_m15 = INVALID_HANDLE;
int g_handle_cci_m15 = INVALID_HANDLE;
int g_handle_volumes_m15 = INVALID_HANDLE;

// Wskaźniki pomocnicze (H1)
int g_handle_atr_h1 = INVALID_HANDLE;
int g_handle_rsi_h1 = INVALID_HANDLE;
int g_handle_ema_200_h1 = INVALID_HANDLE;

// Wskaźniki długoterminowe (H4/D1)
int g_handle_atr_h4 = INVALID_HANDLE;
int g_handle_ema_200_d1 = INVALID_HANDLE;

//+------------------------------------------------------------------+
//|                        BUFORY DANYCH                             |
//+------------------------------------------------------------------+
// Bufory dla wskaźników M15
double g_buffer_atr_m15[];
double g_buffer_rsi_m15[];
double g_buffer_macd_main[];
double g_buffer_macd_signal[];
double g_buffer_bb_upper[];
double g_buffer_bb_middle[];
double g_buffer_bb_lower[];
double g_buffer_ema_fast[];
double g_buffer_ema_slow[];
double g_buffer_adx[];
double g_buffer_adx_plus[];
double g_buffer_adx_minus[];
double g_buffer_stoch_main[];
double g_buffer_stoch_signal[];
double g_buffer_cci[];
double g_buffer_volumes[];

// Bufory dla wyższych TF
double g_buffer_atr_h1[];
double g_buffer_rsi_h1[];
double g_buffer_ema_200_h1[];
double g_buffer_atr_h4[];
double g_buffer_ema_200_d1[];

//+------------------------------------------------------------------+
//|                      ZMIENNE CZASOWE                             |
//+------------------------------------------------------------------+
datetime g_lastBarTime_M1 = 0;
datetime g_lastBarTime_M5 = 0;
datetime g_lastBarTime_M15 = 0;
datetime g_lastBarTime_H1 = 0;
datetime g_lastBarTime_H4 = 0;
datetime g_lastBarTime_D1 = 0;

datetime g_sessionStartTime = 0;
datetime g_dailyResetTime = 0;
datetime g_lastSignalTime = 0;
datetime g_lastTradeTime = 0;

//+------------------------------------------------------------------+
//|                        LICZNIKI                                  |
//+------------------------------------------------------------------+
int g_totalTicks = 0;
int g_totalBars = 0;
int g_signalsGenerated = 0;
int g_signalsExecuted = 0;
int g_errorsCount = 0;
int g_reconnectCount = 0;

//+------------------------------------------------------------------+
//|                         FLAGI                                    |
//+------------------------------------------------------------------+
bool g_isFirstTick = true;
bool g_isNewDay = false;
bool g_isWeekend = false;
bool g_isNewsTime = false;
bool g_isSessionOpen = true;

// Deklaracje zewnętrznych zmiennych (używane w innych modułach)
extern bool g_isCryptoMode;
extern bool g_isBTCMode;
extern InstrumentConfig g_instrumentConfig;

// Deklaracje forward dla klas (będą zdefiniowane w innych modułach)
class CDiagnostics;
class CDataManager;
class CRiskManager;
class CSignalManager;
class CPositionManager;
class CMarketAnalyzer;
class CDashboard;

// Wskaźniki na managery (będą utworzone w głównym pliku)
extern CDiagnostics*      g_diagnostics;
extern CDataManager*      g_dataManager;
extern CRiskManager*      g_riskManager;
extern CSignalManager*    g_signalManager;
extern CPositionManager*  g_positionManager;
extern CMarketAnalyzer*   g_marketAnalyzer;
extern CDashboard*        g_dashboard;

//+------------------------------------------------------------------+
//|                      FUNKCJE GLOBALNE                            |
//+------------------------------------------------------------------+
// Inicjalizacja zmiennych globalnych
void InitializeGlobalVariables() {
    // Reset czasów
    g_lastBarTime_M1 = 0;
    g_lastBarTime_M5 = 0;
    g_lastBarTime_M15 = 0;
    g_lastBarTime_H1 = 0;
    g_lastBarTime_H4 = 0;
    g_lastBarTime_D1 = 0;
    
    g_sessionStartTime = TimeCurrent();
    g_dailyResetTime = TimeCurrent();
    g_lastSignalTime = 0;
    g_lastTradeTime = 0;
    
    // Reset liczników
    g_totalTicks = 0;
    g_totalBars = 0;
    g_signalsGenerated = 0;
    g_signalsExecuted = 0;
    g_errorsCount = 0;
    g_reconnectCount = 0;
    
    // Reset flag
    g_isFirstTick = true;
    g_isNewDay = false;
    g_isWeekend = false;
    g_isNewsTime = false;
    g_isSessionOpen = true;
    
    // Konfiguracja instrumentu
    LoadInstrumentConfig();
    
    // Przygotuj bufory
    PrepareBuffers();
}

// Ładowanie konfiguracji instrumentu
void LoadInstrumentConfig() {
    g_instrumentConfig.Reset();
    
    if(!g_symbol.Name(_Symbol)) {
        return;
    }
    
    g_symbol.Refresh();
    
    g_instrumentConfig.symbol = _Symbol;
    g_instrumentConfig.minLot = g_symbol.LotsMin();
    g_instrumentConfig.maxLot = g_symbol.LotsMax();
    g_instrumentConfig.lotStep = g_symbol.LotsStep();
    g_instrumentConfig.digits = g_symbol.Digits();
    g_instrumentConfig.pointValue = g_symbol.Point();
    g_instrumentConfig.tickValue = g_symbol.TickValue();
    g_instrumentConfig.tickSize = g_symbol.TickSize();
    g_instrumentConfig.contractSize = g_symbol.ContractSize();
    g_instrumentConfig.freezeLevel = (int)g_symbol.FreezeLevel();
    g_instrumentConfig.stopsLevel = (int)g_symbol.StopsLevel();
    g_instrumentConfig.tradeAllowed = g_symbol.TradeMode() != SYMBOL_TRADE_MODE_DISABLED;
}

// Przygotowanie buforów
void PrepareBuffers() {
    int bufferSize = BUFFER_SIZE;
    
    // M15 buffers
    ArrayResize(g_buffer_atr_m15, bufferSize);
    ArrayResize(g_buffer_rsi_m15, bufferSize);
    ArrayResize(g_buffer_macd_main, bufferSize);
    ArrayResize(g_buffer_macd_signal, bufferSize);
    ArrayResize(g_buffer_bb_upper, bufferSize);
    ArrayResize(g_buffer_bb_middle, bufferSize);
    ArrayResize(g_buffer_bb_lower, bufferSize);
    ArrayResize(g_buffer_ema_fast, bufferSize);
    ArrayResize(g_buffer_ema_slow, bufferSize);
    ArrayResize(g_buffer_adx, bufferSize);
    ArrayResize(g_buffer_adx_plus, bufferSize);
    ArrayResize(g_buffer_adx_minus, bufferSize);
    ArrayResize(g_buffer_stoch_main, bufferSize);
    ArrayResize(g_buffer_stoch_signal, bufferSize);
    ArrayResize(g_buffer_cci, bufferSize);
    ArrayResize(g_buffer_volumes, bufferSize);
    
    // Higher TF buffers
    ArrayResize(g_buffer_atr_h1, bufferSize);
    ArrayResize(g_buffer_rsi_h1, bufferSize);
    ArrayResize(g_buffer_ema_200_h1, bufferSize);
    ArrayResize(g_buffer_atr_h4, bufferSize);
    ArrayResize(g_buffer_ema_200_d1, bufferSize);
    
    // Set as series
    ArraySetAsSeries(g_buffer_atr_m15, true);
    ArraySetAsSeries(g_buffer_rsi_m15, true);
    ArraySetAsSeries(g_buffer_macd_main, true);
    ArraySetAsSeries(g_buffer_macd_signal, true);
    ArraySetAsSeries(g_buffer_bb_upper, true);
    ArraySetAsSeries(g_buffer_bb_middle, true);
    ArraySetAsSeries(g_buffer_bb_lower, true);
    ArraySetAsSeries(g_buffer_ema_fast, true);
    ArraySetAsSeries(g_buffer_ema_slow, true);
    ArraySetAsSeries(g_buffer_adx, true);
    ArraySetAsSeries(g_buffer_adx_plus, true);
    ArraySetAsSeries(g_buffer_adx_minus, true);
    ArraySetAsSeries(g_buffer_stoch_main, true);
    ArraySetAsSeries(g_buffer_stoch_signal, true);
    ArraySetAsSeries(g_buffer_cci, true);
    ArraySetAsSeries(g_buffer_volumes, true);
    
    ArraySetAsSeries(g_buffer_atr_h1, true);
    ArraySetAsSeries(g_buffer_rsi_h1, true);
    ArraySetAsSeries(g_buffer_ema_200_h1, true);
    ArraySetAsSeries(g_buffer_atr_h4, true);
    ArraySetAsSeries(g_buffer_ema_200_d1, true);
}

// Cleanup wszystkich globalnych zasobów
void CleanupGlobalVariables() {
    // Zwolnij wskaźniki
    if(g_handle_atr_m15 != INVALID_HANDLE) IndicatorRelease(g_handle_atr_m15);
    if(g_handle_rsi_m15 != INVALID_HANDLE) IndicatorRelease(g_handle_rsi_m15);
    if(g_handle_macd_m15 != INVALID_HANDLE) IndicatorRelease(g_handle_macd_m15);
    if(g_handle_bb_m15 != INVALID_HANDLE) IndicatorRelease(g_handle_bb_m15);
    if(g_handle_ema_fast_m15 != INVALID_HANDLE) IndicatorRelease(g_handle_ema_fast_m15);
    if(g_handle_ema_slow_m15 != INVALID_HANDLE) IndicatorRelease(g_handle_ema_slow_m15);
    if(g_handle_adx_m15 != INVALID_HANDLE) IndicatorRelease(g_handle_adx_m15);
    if(g_handle_stoch_m15 != INVALID_HANDLE) IndicatorRelease(g_handle_stoch_m15);
    if(g_handle_cci_m15 != INVALID_HANDLE) IndicatorRelease(g_handle_cci_m15);
    if(g_handle_volumes_m15 != INVALID_HANDLE) IndicatorRelease(g_handle_volumes_m15);
    
    if(g_handle_atr_h1 != INVALID_HANDLE) IndicatorRelease(g_handle_atr_h1);
    if(g_handle_rsi_h1 != INVALID_HANDLE) IndicatorRelease(g_handle_rsi_h1);
    if(g_handle_ema_200_h1 != INVALID_HANDLE) IndicatorRelease(g_handle_ema_200_h1);
    if(g_handle_atr_h4 != INVALID_HANDLE) IndicatorRelease(g_handle_atr_h4);
    if(g_handle_ema_200_d1 != INVALID_HANDLE) IndicatorRelease(g_handle_ema_200_d1);
}

//+------------------------------------------------------------------+
//|                      MAKRA POMOCNICZE                            |
//+------------------------------------------------------------------+
#define DEBUG_MSG(level, component, message) \
    if(InpEnableLogging && g_diagnostics != NULL) g_diagnostics.Log(level, component, message); \
    else if(InpEnableLogging) Print("[" + component + "] " + message)

#define IS_VALID_HANDLE(handle) ((handle) != INVALID_HANDLE)

#endif // MC5_CORE_MQH