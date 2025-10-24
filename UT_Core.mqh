//+------------------------------------------------------------------+
//|                                                      UT_Core.mqh |
//|                       Ultimate Trader EA - Core Types & Structures |
//|                                   Hybrid System v1.0.0            |
//+------------------------------------------------------------------+
#property copyright "Ultimate Trader Development Team"
#property version   "1.00"
#property strict

#ifndef UT_CORE_MQH
#define UT_CORE_MQH

// Standard MT5 libraries
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\AccountInfo.mqh>

//+------------------------------------------------------------------+
//|                           ENUMERATIONS                            |
//+------------------------------------------------------------------+

// Trading modes (risk profiles)
enum ENUM_TRADING_MODE {
    MODE_SAFE,          // 0.5% risk, conservative, min confirmations: 8
    MODE_BALANCED,      // 1.0% risk, standard, min confirmations: 6
    MODE_AGGRESSIVE     // 2.0% risk, aggressive, min confirmations: 4
};

// Strategy selection modes
enum ENUM_STRATEGY_MODE {
    STRATEGY_AUTO,      // Auto-select best strategy based on market
    STRATEGY_FOREX,     // Force Forex strategy (trend + momentum)
    STRATEGY_METAL,     // Force Metal strategy (support/resistance)
    STRATEGY_CRYPTO,    // Force Crypto strategy (high-frequency)
    STRATEGY_HARMONIC,  // Force Harmonic patterns (Gartley, Butterfly, Bat)
    STRATEGY_ELLIOTT,   // Force Elliott Waves (ABC, Wave 5)
    STRATEGY_SCALPING,  // Force High-Frequency Scalping
    STRATEGY_ADAPTIVE,  // Adaptive strategy (auto-detects instrument type)
    STRATEGY_HYBRID     // Mix of all (adaptive ML-based weighting)
};

// Language options
enum ENUM_LANGUAGE {
    LANG_AUTO,          // Auto-detect from MT5 language
    LANG_POLISH,        // Polski
    LANG_ENGLISH        // English
};

// Market phases (from MC5)
enum ENUM_MARKET_PHASE {
    PHASE_ACCUMULATION, // Consolidation after downtrend
    PHASE_MARKUP,       // Strong uptrend
    PHASE_DISTRIBUTION, // Consolidation after uptrend
    PHASE_MARKDOWN,     // Strong downtrend
    PHASE_RANGING       // No clear trend
};

// Signal directions
enum ENUM_SIGNAL_DIRECTION {
    SIGNAL_NONE,        // No signal
    SIGNAL_BUY,         // Buy signal
    SIGNAL_SELL         // Sell signal
};

// Instrument types (auto-detection)
enum ENUM_INSTRUMENT_TYPE {
    INSTRUMENT_UNKNOWN, // Unknown instrument
    INSTRUMENT_FOREX,   // Currency pairs (EURUSD, GBPUSD, etc.)
    INSTRUMENT_METAL,   // Precious metals (XAUUSD, XAGUSD, etc.)
    INSTRUMENT_CRYPTO,  // Cryptocurrencies (BTCUSD, ETHUSD, etc.)
    INSTRUMENT_INDEX,   // Indices (SPX500, NAS100, etc.)
    INSTRUMENT_COMMODITY // Commodities (WTIUSD, BRENT, etc.)
};

// Debug levels
enum ENUM_DEBUG_LEVEL {
    DEBUG_OFF,          // No debug output
    DEBUG_CRITICAL,     // Only critical errors
    DEBUG_NORMAL,       // Normal operations
    DEBUG_VERBOSE,      // Detailed operations
    DEBUG_PARANOID      // Everything (performance impact!)
};

//+------------------------------------------------------------------+
//|                            STRUCTURES                             |
//+------------------------------------------------------------------+

// Market conditions (enhanced from MC5)
struct MarketConditions {
    // Phase and trend
    ENUM_MARKET_PHASE phase;
    int trendDirection;         // -1 = bearish, 0 = ranging, 1 = bullish
    double trendStrength;       // 0-100 (based on ADX)
    double volatility;          // ATR-based
    double momentum;            // -100 to +100

    // Market characteristics
    bool isTrending;            // ADX > 25
    bool isVolatile;            // ATR > 150% of MA(ATR, 20)
    double volume;              // Current volume
    double spread;              // Current spread in points

    // Multi-timeframe trend alignment
    int h4Trend;                // H4 trend (-1/0/+1)
    int d1Trend;                // D1 trend (-1/0/+1)
    int w1Trend;                // W1 trend (-1/0/+1)
    int trendAlignment;         // Sum of all trends (-3 to +3)

    // Key indicators
    double rsi;                 // RSI(14)
    double macd;                // MACD main line
    double macdSignal;          // MACD signal line
    double adx;                 // ADX(14)
    double stochastic;          // Stochastic %K
    double ema20;               // EMA(20)
    double ema50;               // EMA(50)
    double ema200;              // EMA(200)

    // Advanced patterns (from GoldTraderEA)
    bool hasHarmonicPattern;    // Gartley, Butterfly, Bat detected
    string harmonicType;        // Pattern name
    double harmonicEntry;       // Suggested entry price

    bool hasBullishDivergence;  // RSI/MACD bullish divergence
    bool hasBearishDivergence;  // RSI/MACD bearish divergence
    string divergenceType;      // "RSI", "MACD", "Both"

    // Support/Resistance levels
    double nearestSupport;      // Closest support level
    double nearestResistance;   // Closest resistance level
    double pivotPoint;          // Daily pivot point
    double r1, r2, r3;          // Resistance levels
    double s1, s2, s3;          // Support levels

    // Volume analysis
    double volumeSpike;         // Volume vs MA(Volume, 20) ratio
    bool volumeBreakout;        // High volume + price breakout

    // Session info
    string session;             // "Asian", "London", "NewYork", "Overlap"
    bool isBadTradingDay;       // NFP, holidays, extreme volatility

    void Reset() {
        phase = PHASE_RANGING;
        trendDirection = 0;
        trendStrength = 0;
        volatility = 0;
        momentum = 0;
        isTrending = false;
        isVolatile = false;
        volume = 0;
        spread = 0;
        h4Trend = 0;
        d1Trend = 0;
        w1Trend = 0;
        trendAlignment = 0;
        rsi = 50;
        macd = 0;
        macdSignal = 0;
        adx = 0;
        stochastic = 50;
        ema20 = 0;
        ema50 = 0;
        ema200 = 0;
        hasHarmonicPattern = false;
        harmonicType = "";
        harmonicEntry = 0;
        hasBullishDivergence = false;
        hasBearishDivergence = false;
        divergenceType = "";
        nearestSupport = 0;
        nearestResistance = 0;
        pivotPoint = 0;
        r1 = r2 = r3 = 0;
        s1 = s2 = s3 = 0;
        volumeSpike = 1.0;
        volumeBreakout = false;
        session = "";
        isBadTradingDay = false;
    }
};

// Trade signal (comprehensive)
struct TradeSignal {
    // Basic signal data
    ENUM_SIGNAL_DIRECTION direction;
    bool isValid;
    int score;                  // Composite score 0-100
    double confidence;          // ML-based confidence 0.0-1.0
    string reason;              // Human-readable reason

    // Entry and exit levels
    double entryPrice;
    double stopLoss;
    double takeProfit;
    double lotSize;
    double riskRewardRatio;

    // Score breakdown (max 20 points each)
    int trendScore;             // Trend alignment score
    int momentumScore;          // Momentum indicators score
    int harmonicScore;          // Harmonic patterns score
    int divergenceScore;        // Divergence score
    int volumeScore;            // Volume analysis score

    // Multi-timeframe confirmation
    bool h4Confirmed;           // H4 timeframe agrees
    bool d1Confirmed;           // D1 timeframe agrees
    bool w1Confirmed;           // W1 timeframe agrees
    int mtfConfirmations;       // Count of confirmed timeframes

    // Strategy source
    ENUM_STRATEGY_MODE source;  // Which strategy generated this

    // Scalping-specific (if applicable)
    bool isScalpSignal;         // Is this a scalping signal?
    double microMomentum;       // Tick-based momentum
    int scalpPositions;         // How many scalp positions to open

    void Reset() {
        direction = SIGNAL_NONE;
        isValid = false;
        score = 0;
        confidence = 0;
        reason = "";
        entryPrice = 0;
        stopLoss = 0;
        takeProfit = 0;
        lotSize = 0;
        riskRewardRatio = 0;
        trendScore = 0;
        momentumScore = 0;
        harmonicScore = 0;
        divergenceScore = 0;
        volumeScore = 0;
        h4Confirmed = false;
        d1Confirmed = false;
        w1Confirmed = false;
        mtfConfirmations = 0;
        source = STRATEGY_AUTO;
        isScalpSignal = false;
        microMomentum = 0;
        scalpPositions = 0;
    }

    // Calculate composite score from breakdown
    void CalculateScore() {
        score = trendScore + momentumScore + harmonicScore +
                divergenceScore + volumeScore;

        // Bonus for multi-timeframe confirmation
        if(h4Confirmed) score += 5;
        if(d1Confirmed) score += 5;
        if(w1Confirmed) score += 5;

        mtfConfirmations = (h4Confirmed ? 1 : 0) +
                          (d1Confirmed ? 1 : 0) +
                          (w1Confirmed ? 1 : 0);

        // Cap at 100
        if(score > 100) score = 100;
    }
};

// Performance statistics (enhanced)
struct PerformanceStats {
    // Basic stats
    int totalTrades;
    int winningTrades;
    int losingTrades;
    double totalProfit;
    double totalLoss;
    double winRate;             // Percentage
    double profitFactor;        // Gross profit / Gross loss

    // Advanced metrics
    double sharpeRatio;
    double maxDrawdown;
    double maxDrawdownPercent;
    double avgWin;
    double avgLoss;
    double avgRR;               // Average R:R ratio
    double expectancy;          // Expected value per trade

    // Consecutive stats
    int maxConsecutiveWins;
    int maxConsecutiveLosses;
    int currentConsecutiveWins;
    int currentConsecutiveLosses;

    // Per-strategy breakdown
    int forexTrades;
    int metalTrades;
    int cryptoTrades;
    int harmonicTrades;
    int elliottTrades;
    int scalpingTrades;

    double forexWinRate;
    double metalWinRate;
    double cryptoWinRate;
    double harmonicWinRate;
    double elliottWinRate;
    double scalpingWinRate;

    // Time-based stats
    datetime firstTradeTime;
    datetime lastTradeTime;
    double tradingDays;
    double avgTradesPerDay;

    void Reset() {
        totalTrades = 0;
        winningTrades = 0;
        losingTrades = 0;
        totalProfit = 0;
        totalLoss = 0;
        winRate = 0;
        profitFactor = 0;
        sharpeRatio = 0;
        maxDrawdown = 0;
        maxDrawdownPercent = 0;
        avgWin = 0;
        avgLoss = 0;
        avgRR = 0;
        expectancy = 0;
        maxConsecutiveWins = 0;
        maxConsecutiveLosses = 0;
        currentConsecutiveWins = 0;
        currentConsecutiveLosses = 0;
        forexTrades = 0;
        metalTrades = 0;
        cryptoTrades = 0;
        harmonicTrades = 0;
        elliottTrades = 0;
        scalpingTrades = 0;
        forexWinRate = 0;
        metalWinRate = 0;
        cryptoWinRate = 0;
        harmonicWinRate = 0;
        elliottWinRate = 0;
        scalpingWinRate = 0;
        firstTradeTime = 0;
        lastTradeTime = 0;
        tradingDays = 0;
        avgTradesPerDay = 0;
    }

    void Update(bool isWin, double profit, ENUM_STRATEGY_MODE strategy) {
        totalTrades++;
        lastTradeTime = TimeCurrent();

        if(firstTradeTime == 0) {
            firstTradeTime = TimeCurrent();
        }

        if(isWin) {
            winningTrades++;
            totalProfit += profit;
            avgWin = totalProfit / winningTrades;
            currentConsecutiveWins++;
            currentConsecutiveLosses = 0;
            if(currentConsecutiveWins > maxConsecutiveWins) {
                maxConsecutiveWins = currentConsecutiveWins;
            }
        } else {
            losingTrades++;
            totalLoss += MathAbs(profit);
            avgLoss = totalLoss / losingTrades;
            currentConsecutiveLosses++;
            currentConsecutiveWins = 0;
            if(currentConsecutiveLosses > maxConsecutiveLosses) {
                maxConsecutiveLosses = currentConsecutiveLosses;
            }
        }

        // Recalculate metrics
        winRate = (totalTrades > 0) ? (double)winningTrades / totalTrades * 100.0 : 0;
        profitFactor = (totalLoss > 0) ? totalProfit / totalLoss : 0;
        expectancy = (totalTrades > 0) ? (totalProfit - totalLoss) / totalTrades : 0;

        // Update per-strategy stats
        UpdateStrategyStats(strategy, isWin);

        // Calculate trading days
        if(firstTradeTime > 0) {
            tradingDays = (TimeCurrent() - firstTradeTime) / 86400.0;
            avgTradesPerDay = (tradingDays > 0) ? totalTrades / tradingDays : 0;
        }
    }

private:
    void UpdateStrategyStats(ENUM_STRATEGY_MODE strategy, bool isWin) {
        switch(strategy) {
            case STRATEGY_FOREX:
                forexTrades++;
                if(isWin) forexWinRate = UpdateWinRate(forexWinRate, forexTrades);
                break;
            case STRATEGY_METAL:
                metalTrades++;
                if(isWin) metalWinRate = UpdateWinRate(metalWinRate, metalTrades);
                break;
            case STRATEGY_CRYPTO:
                cryptoTrades++;
                if(isWin) cryptoWinRate = UpdateWinRate(cryptoWinRate, cryptoTrades);
                break;
            case STRATEGY_HARMONIC:
                harmonicTrades++;
                if(isWin) harmonicWinRate = UpdateWinRate(harmonicWinRate, harmonicTrades);
                break;
            case STRATEGY_ELLIOTT:
                elliottTrades++;
                if(isWin) elliottWinRate = UpdateWinRate(elliottWinRate, elliottTrades);
                break;
            case STRATEGY_SCALPING:
                scalpingTrades++;
                if(isWin) scalpingWinRate = UpdateWinRate(scalpingWinRate, scalpingTrades);
                break;
        }
    }

    double UpdateWinRate(double currentRate, int numTrades) {
        double wins = (currentRate / 100.0) * (numTrades - 1);
        wins += 1.0;  // Add current win
        return (wins / numTrades) * 100.0;
    }
};

// System state
struct SystemState {
    bool isInitialized;
    bool autoTradingEnabled;
    bool emergencyStop;
    datetime startTime;
    datetime lastTickTime;
    int tickCount;

    // Risk state
    double dailyStartBalance;
    double currentBalance;
    double peakBalance;
    double currentDrawdown;
    double dailyProfitLoss;

    // Position state
    int openPositions;
    int openScalpPositions;
    double totalVolume;
    double floatingPL;

    void Reset() {
        isInitialized = false;
        autoTradingEnabled = true;
        emergencyStop = false;
        startTime = TimeCurrent();
        lastTickTime = 0;
        tickCount = 0;
        dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        currentBalance = dailyStartBalance;
        peakBalance = dailyStartBalance;
        currentDrawdown = 0;
        dailyProfitLoss = 0;
        openPositions = 0;
        openScalpPositions = 0;
        totalVolume = 0;
        floatingPL = 0;
    }
};

// Scalping position (for micro account scalping)
struct ScalpPosition {
    ulong ticket;
    datetime openTime;
    double openPrice;
    double lotSize;
    double targetProfit;        // In USD
    double targetPips;
    int retryCount;
    bool isActive;

    void Reset() {
        ticket = 0;
        openTime = 0;
        openPrice = 0;
        lotSize = 0;
        targetProfit = 0;
        targetPips = 0;
        retryCount = 0;
        isActive = false;
    }
};

// ML weights for adaptive scoring
struct MLWeights {
    double trendWeight;         // Default: 1.0
    double momentumWeight;      // Default: 1.0
    double harmonicWeight;      // Default: 1.0
    double divergenceWeight;    // Default: 1.0
    double volumeWeight;        // Default: 1.0

    // Performance tracking for each component
    double trendPerformance;    // Win rate for trend signals
    double momentumPerformance;
    double harmonicPerformance;
    double divergencePerformance;
    double volumePerformance;

    void Reset() {
        trendWeight = 1.0;
        momentumWeight = 1.0;
        harmonicWeight = 1.0;
        divergenceWeight = 1.0;
        volumeWeight = 1.0;
        trendPerformance = 0.5;
        momentumPerformance = 0.5;
        harmonicPerformance = 0.5;
        divergencePerformance = 0.5;
        volumePerformance = 0.5;
    }

    void UpdateWeights(double overallWinRate) {
        // Adaptive ML: Increase weight if performance > overall
        // Decrease if performance < overall

        trendWeight = CalculateNewWeight(trendPerformance, overallWinRate);
        momentumWeight = CalculateNewWeight(momentumPerformance, overallWinRate);
        harmonicWeight = CalculateNewWeight(harmonicPerformance, overallWinRate);
        divergenceWeight = CalculateNewWeight(divergencePerformance, overallWinRate);
        volumeWeight = CalculateNewWeight(volumePerformance, overallWinRate);

        // Normalize to sum = 5.0
        NormalizeWeights();
    }

private:
    double CalculateNewWeight(double performance, double baseline) {
        if(performance > baseline) {
            return 1.0 + ((performance - baseline) * 2.0);  // Max 2.0
        } else {
            return 1.0 - ((baseline - performance) * 1.0);  // Min 0.5
        }
    }

    void NormalizeWeights() {
        double sum = trendWeight + momentumWeight + harmonicWeight +
                     divergenceWeight + volumeWeight;

        if(sum > 0) {
            double factor = 5.0 / sum;
            trendWeight *= factor;
            momentumWeight *= factor;
            harmonicWeight *= factor;
            divergenceWeight *= factor;
            volumeWeight *= factor;
        }
    }
};

//+------------------------------------------------------------------+
//|                        GLOBAL VARIABLES                           |
//+------------------------------------------------------------------+

// Trading objects (from standard library)
CTrade             g_trade;
CPositionInfo      g_position;
CSymbolInfo        g_symbol;
CAccountInfo       g_account;

// Global structures
SystemState        g_state;
PerformanceStats   g_performance;
MLWeights          g_mlWeights;

// Indicator handles
int g_handle_atr;
int g_handle_rsi;
int g_handle_macd;
int g_handle_adx;
int g_handle_ema20;
int g_handle_ema50;
int g_handle_ema200;
int g_handle_bb;
int g_handle_stoch;
int g_handle_volumes;

// Indicator buffers (preallocated for performance)
double g_buffer_atr[];
double g_buffer_rsi[];
double g_buffer_macd_main[];
double g_buffer_macd_signal[];
double g_buffer_adx[];
double g_buffer_ema20[];
double g_buffer_ema50[];
double g_buffer_ema200[];
double g_buffer_bb_upper[];
double g_buffer_bb_middle[];
double g_buffer_bb_lower[];
double g_buffer_stoch_main[];
double g_buffer_stoch_signal[];
double g_buffer_volumes[];

// Cache for performance optimization
struct SystemCache {
    double lastATR;
    datetime atrCheckTime;
    double lastSpread;
    datetime spreadCheckTime;
    ENUM_INSTRUMENT_TYPE instrumentType;
    datetime lastInstrumentCheck;
    string session;
    datetime lastSessionCheck;

    void Reset() {
        lastATR = 0;
        atrCheckTime = 0;
        lastSpread = 0;
        spreadCheckTime = 0;
        instrumentType = INSTRUMENT_UNKNOWN;
        lastInstrumentCheck = 0;
        session = "";
        lastSessionCheck = 0;
    }
};

SystemCache g_cache;

// Signal management
int g_totalSignals = 0;
int g_executedSignals = 0;
int g_rejectedSignals = 0;

//+------------------------------------------------------------------+
//|                         UTILITY FUNCTIONS                         |
//+------------------------------------------------------------------+

// Initialize indicator buffers as series
void PrepareBuffers() {
    ArraySetAsSeries(g_buffer_atr, true);
    ArraySetAsSeries(g_buffer_rsi, true);
    ArraySetAsSeries(g_buffer_macd_main, true);
    ArraySetAsSeries(g_buffer_macd_signal, true);
    ArraySetAsSeries(g_buffer_adx, true);
    ArraySetAsSeries(g_buffer_ema20, true);
    ArraySetAsSeries(g_buffer_ema50, true);
    ArraySetAsSeries(g_buffer_ema200, true);
    ArraySetAsSeries(g_buffer_bb_upper, true);
    ArraySetAsSeries(g_buffer_bb_middle, true);
    ArraySetAsSeries(g_buffer_bb_lower, true);
    ArraySetAsSeries(g_buffer_stoch_main, true);
    ArraySetAsSeries(g_buffer_stoch_signal, true);
    ArraySetAsSeries(g_buffer_volumes, true);
}

// Get deinit reason as string
string GetDeInitReason(int reason) {
    switch(reason) {
        case REASON_PROGRAM:     return "Program stopped";
        case REASON_REMOVE:      return "Program removed from chart";
        case REASON_RECOMPILE:   return "Program recompiled";
        case REASON_CHARTCHANGE: return "Chart symbol or period changed";
        case REASON_CHARTCLOSE:  return "Chart closed";
        case REASON_PARAMETERS:  return "Input parameters changed";
        case REASON_ACCOUNT:     return "Account changed";
        case REASON_TEMPLATE:    return "New template applied";
        case REASON_INITFAILED:  return "Init failed";
        case REASON_CLOSE:       return "Terminal closed";
        default:                 return "Unknown reason";
    }
}

// Detect instrument type
ENUM_INSTRUMENT_TYPE DetectInstrumentType(string symbol) {
    // Check cache (valid for 60 seconds)
    if(TimeCurrent() - g_cache.lastInstrumentCheck < 60 &&
       g_cache.instrumentType != INSTRUMENT_UNKNOWN) {
        return g_cache.instrumentType;
    }

    // Convert to uppercase for comparison
    string sym = symbol;
    StringToUpper(sym);

    ENUM_INSTRUMENT_TYPE type = INSTRUMENT_UNKNOWN;

    // Metal detection
    if(StringFind(sym, "XAU") >= 0 || StringFind(sym, "GOLD") >= 0) {
        type = INSTRUMENT_METAL;
    }
    else if(StringFind(sym, "XAG") >= 0 || StringFind(sym, "SILVER") >= 0) {
        type = INSTRUMENT_METAL;
    }
    // Crypto detection
    else if(StringFind(sym, "BTC") >= 0 || StringFind(sym, "BITCOIN") >= 0) {
        type = INSTRUMENT_CRYPTO;
    }
    else if(StringFind(sym, "ETH") >= 0 || StringFind(sym, "ETHEREUM") >= 0) {
        type = INSTRUMENT_CRYPTO;
    }
    else if(StringFind(sym, "XRP") >= 0 || StringFind(sym, "LTC") >= 0 ||
            StringFind(sym, "BCH") >= 0) {
        type = INSTRUMENT_CRYPTO;
    }
    // Index detection
    else if(StringFind(sym, "SPX") >= 0 || StringFind(sym, "NDX") >= 0 ||
            StringFind(sym, "DJI") >= 0 || StringFind(sym, "NAS") >= 0) {
        type = INSTRUMENT_INDEX;
    }
    // Commodity detection
    else if(StringFind(sym, "WTI") >= 0 || StringFind(sym, "BRENT") >= 0 ||
            StringFind(sym, "OIL") >= 0) {
        type = INSTRUMENT_COMMODITY;
    }
    // Forex detection (contains USD, EUR, GBP, JPY, etc.)
    else if(StringFind(sym, "USD") >= 0 || StringFind(sym, "EUR") >= 0 ||
            StringFind(sym, "GBP") >= 0 || StringFind(sym, "JPY") >= 0 ||
            StringFind(sym, "CHF") >= 0 || StringFind(sym, "AUD") >= 0 ||
            StringFind(sym, "CAD") >= 0 || StringFind(sym, "NZD") >= 0) {
        type = INSTRUMENT_FOREX;
    }

    // Update cache
    g_cache.instrumentType = type;
    g_cache.lastInstrumentCheck = TimeCurrent();

    return type;
}

// Normalize lot size to broker requirements
double NormalizeLot(double lot) {
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

    if(lot < minLot) lot = minLot;
    if(lot > maxLot) lot = maxLot;

    lot = MathFloor(lot / lotStep) * lotStep;

    return lot;
}

// Get point value in account currency
double GetPointValue() {
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

    if(tickSize > 0) {
        return tickValue * _Point / tickSize;
    }

    return 1.0; // Fallback
}

// Calculate pip distance between two prices
double GetPipDistance(double price1, double price2) {
    return MathAbs(price1 - price2) / (_Point * 10);
}

// Check if it's a new bar
bool IsNewBar() {
    static datetime lastBarTime = 0;
    datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);

    if(currentBarTime != lastBarTime) {
        lastBarTime = currentBarTime;
        return true;
    }

    return false;
}

// Get current trading session
string GetCurrentSession() {
    // Check cache (valid for 60 seconds)
    if(TimeCurrent() - g_cache.lastSessionCheck < 60 && g_cache.session != "") {
        return g_cache.session;
    }

    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    int hour = dt.hour;

    string session = "Unknown";

    // GMT-based sessions
    if(hour >= 0 && hour < 8) {
        session = "Asian";
    }
    else if(hour >= 8 && hour < 13) {
        session = "London";
    }
    else if(hour >= 13 && hour < 17) {
        session = "Overlap";  // London/NY overlap
    }
    else if(hour >= 17 && hour < 22) {
        session = "NewYork";
    }
    else {
        session = "OffHours";
    }

    // Update cache
    g_cache.session = session;
    g_cache.lastSessionCheck = TimeCurrent();

    return session;
}

// Debug print helper
void DEBUG_MSG(ENUM_DEBUG_LEVEL requiredLevel, string category, string message) {
    // This will be implemented by diagnostics manager
    // For now, basic Print()
    Print("[", category, "] ", message);
}

#endif // UT_CORE_MQH
