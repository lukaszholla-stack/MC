//+------------------------------------------------------------------+
//|                                               UT_Strategies.mqh |
//|                    Ultimate Trader EA - Trading Strategies        |
//|                                   Hybrid System v1.0.0            |
//+------------------------------------------------------------------+
#property copyright "Ultimate Trader Development Team"
#property version   "1.00"

#ifndef UT_STRATEGIES_MQH
#define UT_STRATEGIES_MQH

#include "UT_Core.mqh"
#include "UT_Analysis.mqh"

//+------------------------------------------------------------------+
//|                      BASE STRATEGY CLASS                          |
//+------------------------------------------------------------------+
class CBaseStrategy {
protected:
    string m_name;
    ENUM_STRATEGY_MODE m_type;
    bool m_initialized;
    CMarketAnalyzer* m_marketAnalyzer;

public:
    CBaseStrategy() {
        m_initialized = false;
        m_marketAnalyzer = NULL;
    }

    virtual ~CBaseStrategy() {}

    void SetMarketAnalyzer(CMarketAnalyzer* analyzer) {
        m_marketAnalyzer = analyzer;
    }

    string GetName() { return m_name; }
    ENUM_STRATEGY_MODE GetType() { return m_type; }
    bool IsInitialized() { return m_initialized; }

    // Pure virtual functions (must be implemented by derived classes)
    virtual bool Initialize() = 0;
    virtual TradeSignal CheckSignal(MarketConditions& conditions) = 0;
    virtual double CalculateStopLoss(ENUM_SIGNAL_DIRECTION direction, double entry, double atr) = 0;
    virtual double CalculateTakeProfit(ENUM_SIGNAL_DIRECTION direction, double entry, double sl) = 0;
};

//+------------------------------------------------------------------+
//|                     FOREX STRATEGY CLASS                          |
//+------------------------------------------------------------------+
class CForexStrategy : public CBaseStrategy {
public:
    CForexStrategy() {
        m_name = "Forex Trend + Momentum";
        m_type = STRATEGY_FOREX;
    }

    virtual bool Initialize() override {
        m_initialized = true;
        Print("✅ Forex Strategy initialized");
        return true;
    }

    virtual TradeSignal CheckSignal(MarketConditions& conditions) override {
        TradeSignal signal;
        signal.Reset();
        signal.source = STRATEGY_FOREX;

        // Trend score (0-20)
        signal.trendScore = AnalyzeTrend(conditions);

        // Momentum score (0-20)
        signal.momentumScore = AnalyzeMomentum(conditions);

        // Volume score (0-20)
        signal.volumeScore = AnalyzeVolume(conditions);

        // Calculate composite score
        signal.CalculateScore();

        // Determine direction (simplified conditions)
        if(signal.score >= 40) {
            // Trade with the trend
            if(conditions.trendDirection > 0) {
                signal.direction = SIGNAL_BUY;
                signal.isValid = true;
                signal.reason = "Forex: Bullish trend confirmed";
            }
            else if(conditions.trendDirection < 0) {
                signal.direction = SIGNAL_SELL;
                signal.isValid = true;
                signal.reason = "Forex: Bearish trend confirmed";
            }
            // No clear trend - use RSI
            else if(conditions.rsi < 45) {
                signal.direction = SIGNAL_BUY;
                signal.isValid = true;
                signal.reason = "Forex: RSI low in range";
            }
            else if(conditions.rsi > 55) {
                signal.direction = SIGNAL_SELL;
                signal.isValid = true;
                signal.reason = "Forex: RSI high in range";
            }
        }

        return signal;
    }

    virtual double CalculateStopLoss(ENUM_SIGNAL_DIRECTION direction, double entry, double atr) override {
        // Forex: SL = 1.2x ATR
        double slDistance = atr * 1.2;

        if(direction == SIGNAL_BUY) {
            return entry - slDistance;
        } else {
            return entry + slDistance;
        }
    }

    virtual double CalculateTakeProfit(ENUM_SIGNAL_DIRECTION direction, double entry, double sl) override {
        // Forex: TP = 2.0x SL distance (R:R = 2.0)
        double slDistance = MathAbs(entry - sl);
        double tpDistance = slDistance * 2.0;

        if(direction == SIGNAL_BUY) {
            return entry + tpDistance;
        } else {
            return entry - tpDistance;
        }
    }

private:
    int AnalyzeTrend(MarketConditions& conditions) {
        int score = 0;

        // EMA alignment (0-10)
        if(conditions.ema20 > conditions.ema50 && conditions.ema50 > conditions.ema200) {
            score += 10;  // Strong bullish
        }
        else if(conditions.ema20 < conditions.ema50 && conditions.ema50 < conditions.ema200) {
            score += 10;  // Strong bearish
        }
        else if(conditions.ema20 > conditions.ema50 || conditions.ema50 > conditions.ema200) {
            score += 5;   // Partial bullish
        }

        // ADX strength (0-10)
        if(conditions.adx > 40) {
            score += 10;  // Very strong trend
        }
        else if(conditions.adx > 25) {
            score += 7;   // Strong trend
        }
        else if(conditions.adx > 20) {
            score += 4;   // Moderate trend
        }

        return MathMin(20, score);
    }

    int AnalyzeMomentum(MarketConditions& conditions) {
        int score = 0;

        // RSI (0-10)
        if((conditions.rsi > 50 && conditions.rsi < 70) || (conditions.rsi < 50 && conditions.rsi > 30)) {
            score += 8;  // Good momentum zone
        }
        else if(conditions.rsi > 70 || conditions.rsi < 30) {
            score += 5;  // Extreme zone (careful)
        }

        // MACD (0-10)
        if(conditions.macd > conditions.macdSignal && conditions.macd > 0) {
            score += 10;  // Strong bullish momentum
        }
        else if(conditions.macd < conditions.macdSignal && conditions.macd < 0) {
            score += 10;  // Strong bearish momentum
        }
        else if(conditions.macd > conditions.macdSignal) {
            score += 6;   // Bullish momentum
        }

        return MathMin(20, score);
    }

    int AnalyzeVolume(MarketConditions& conditions) {
        int score = 0;

        // Volume spike confirmation
        if(conditions.volumeSpike > 1.5) {
            score += 15;  // Strong volume confirmation
        }
        else if(conditions.volumeSpike > 1.2) {
            score += 10;  // Moderate volume
        }
        else {
            score += 5;   // Normal volume
        }

        return MathMin(20, score);
    }
};

//+------------------------------------------------------------------+
//|                     METAL STRATEGY CLASS                          |
//+------------------------------------------------------------------+
class CMetalStrategy : public CBaseStrategy {
public:
    CMetalStrategy() {
        m_name = "Metal Support/Resistance";
        m_type = STRATEGY_METAL;
    }

    virtual bool Initialize() override {
        m_initialized = true;
        Print("✅ Metal Strategy initialized");
        return true;
    }

    virtual TradeSignal CheckSignal(MarketConditions& conditions) override {
        TradeSignal signal;
        signal.Reset();
        signal.source = STRATEGY_METAL;

        double currentPrice = g_symbol.Bid();

        // Check if near support/resistance
        bool nearSupport = (conditions.nearestSupport > 0 &&
                           MathAbs(currentPrice - conditions.nearestSupport) < conditions.volatility * 0.5);

        bool nearResistance = (conditions.nearestResistance > 0 &&
                              MathAbs(currentPrice - conditions.nearestResistance) < conditions.volatility * 0.5);

        // Volume score (0-20)
        signal.volumeScore = AnalyzeVolume(conditions);

        // Trend score (0-20)
        signal.trendScore = (conditions.isTrending) ? 15 : 5;

        // Support/Resistance score (0-20)
        if(nearSupport) {
            signal.harmonicScore = 20;  // Strong bounce potential
        }
        else if(nearResistance) {
            signal.harmonicScore = 20;  // Strong rejection potential
        }

        signal.CalculateScore();

        // Signal generation (lowered volume requirement)
        if(nearSupport && signal.score >= 40 && conditions.volumeSpike > 1.1) {
            signal.direction = SIGNAL_BUY;
            signal.isValid = true;
            signal.reason = "Metal: Bounce from support + volume";
        }
        else if(nearResistance && signal.score >= 40 && conditions.volumeSpike > 1.1) {
            signal.direction = SIGNAL_SELL;
            signal.isValid = true;
            signal.reason = "Metal: Rejection from resistance + volume";
        }

        return signal;
    }

    virtual double CalculateStopLoss(ENUM_SIGNAL_DIRECTION direction, double entry, double atr) override {
        // Metal: SL = 1.5x ATR (more volatile)
        double slDistance = atr * 1.5;

        if(direction == SIGNAL_BUY) {
            return entry - slDistance;
        } else {
            return entry + slDistance;
        }
    }

    virtual double CalculateTakeProfit(ENUM_SIGNAL_DIRECTION direction, double entry, double sl) override {
        // Metal: TP = 2.5x SL distance (R:R = 2.5)
        double slDistance = MathAbs(entry - sl);
        double tpDistance = slDistance * 2.5;

        if(direction == SIGNAL_BUY) {
            return entry + tpDistance;
        } else {
            return entry - tpDistance;
        }
    }

private:
    int AnalyzeVolume(MarketConditions& conditions) {
        if(conditions.volumeSpike > 2.0) {
            return 20;  // Extreme volume
        }
        else if(conditions.volumeSpike > 1.5) {
            return 15;  // High volume
        }
        else if(conditions.volumeSpike > 1.2) {
            return 10;  // Moderate volume
        }
        return 5;  // Low volume
    }
};

//+------------------------------------------------------------------+
//|                    CRYPTO STRATEGY CLASS                          |
//+------------------------------------------------------------------+
class CCryptoStrategy : public CBaseStrategy {
public:
    CCryptoStrategy() {
        m_name = "Crypto High-Frequency Momentum";
        m_type = STRATEGY_CRYPTO;
    }

    virtual bool Initialize() override {
        m_initialized = true;
        Print("✅ Crypto Strategy initialized");
        return true;
    }

    virtual TradeSignal CheckSignal(MarketConditions& conditions) override {
        TradeSignal signal;
        signal.Reset();
        signal.source = STRATEGY_CRYPTO;

        // Momentum score (0-20)
        signal.momentumScore = AnalyzeMomentum(conditions);

        // Volume score (0-20) - critical for crypto
        signal.volumeScore = AnalyzeVolume(conditions);

        // Volatility score (0-20)
        signal.trendScore = AnalyzeVolatility(conditions);

        signal.CalculateScore();

        // Crypto: Trade with trend if score is good
        if(signal.score >= 40) {
            // Bullish conditions
            if(conditions.trendDirection > 0 && conditions.rsi < 70) {
                signal.direction = SIGNAL_BUY;
                signal.isValid = true;
                signal.reason = "Crypto: Bullish trend + momentum";
            }
            // Bearish conditions
            else if(conditions.trendDirection < 0 && conditions.rsi > 30) {
                signal.direction = SIGNAL_SELL;
                signal.isValid = true;
                signal.reason = "Crypto: Bearish trend + momentum";
            }
            // Neutral trend - use RSI extremes
            else if(conditions.rsi < 40 && conditions.macd > conditions.macdSignal) {
                signal.direction = SIGNAL_BUY;
                signal.isValid = true;
                signal.reason = "Crypto: RSI low + MACD bullish";
            }
            else if(conditions.rsi > 60 && conditions.macd < conditions.macdSignal) {
                signal.direction = SIGNAL_SELL;
                signal.isValid = true;
                signal.reason = "Crypto: RSI high + MACD bearish";
            }
        }

        return signal;
    }

    virtual double CalculateStopLoss(ENUM_SIGNAL_DIRECTION direction, double entry, double atr) override {
        // Crypto: SL = 2.0x ATR (very volatile!)
        double slDistance = atr * 2.0;

        if(direction == SIGNAL_BUY) {
            return entry - slDistance;
        } else {
            return entry + slDistance;
        }
    }

    virtual double CalculateTakeProfit(ENUM_SIGNAL_DIRECTION direction, double entry, double sl) override {
        // Crypto: TP = 3.0x SL distance (R:R = 3.0)
        double slDistance = MathAbs(entry - sl);
        double tpDistance = slDistance * 3.0;

        if(direction == SIGNAL_BUY) {
            return entry + tpDistance;
        } else {
            return entry - tpDistance;
        }
    }

private:
    int AnalyzeMomentum(MarketConditions& conditions) {
        int score = 0;

        // RSI extremes (crypto loves bounces)
        if(conditions.rsi < 25 || conditions.rsi > 75) {
            score += 12;
        }
        else if(conditions.rsi < 35 || conditions.rsi > 65) {
            score += 8;
        }

        // MACD histogram (fast momentum)
        double macdHistogram = conditions.macd - conditions.macdSignal;
        if(MathAbs(macdHistogram) > 0.001) {  // Significant move
            score += 8;
        }

        return MathMin(20, score);
    }

    int AnalyzeVolume(MarketConditions& conditions) {
        // Crypto REQUIRES volume confirmation
        if(conditions.volumeSpike > 2.5) {
            return 20;  // Massive volume
        }
        else if(conditions.volumeSpike > 1.8) {
            return 15;  // Very high volume
        }
        else if(conditions.volumeSpike > 1.4) {
            return 10;  // High volume
        }
        return 0;  // Insufficient volume - reject!
    }

    int AnalyzeVolatility(MarketConditions& conditions) {
        if(conditions.isVolatile) {
            return 15;  // High volatility = good for crypto
        }
        return 8;
    }
};

//+------------------------------------------------------------------+
//|                   SCALPING STRATEGY CLASS                         |
//|        High-Frequency Scalping with Micro Account Support        |
//+------------------------------------------------------------------+
class CScalpingStrategy : public CBaseStrategy {
private:
    // Scalping configuration
    int m_maxPositions;
    double m_targetProfitUSD;
    int m_maxSpreadPoints;
    int m_signalCooldown;  // Seconds between signals

    // Multi-position tracking
    ScalpPosition m_positions[20];
    int m_activeCount;

    // Micro-momentum tracking
    double m_lastBid;
    double m_tickMomentum;
    datetime m_lastSignalTime;

    // Micro account parameters
    bool m_isMicroAccount;
    double m_accountBalance;

public:
    CScalpingStrategy() {
        m_name = "High-Frequency Scalping";
        m_type = STRATEGY_SCALPING;
        m_maxPositions = 20;
        m_targetProfitUSD = 1.50;
        m_maxSpreadPoints = 20;
        m_signalCooldown = 5;
        m_activeCount = 0;
        m_lastBid = 0;
        m_tickMomentum = 0;
        m_lastSignalTime = 0;
        m_isMicroAccount = false;
        m_accountBalance = 0;

        // Initialize positions array
        for(int i = 0; i < 20; i++) {
            m_positions[i].Reset();
        }
    }

    void SetScalpingParams(int maxPos, double targetUSD, int maxSpread) {
        m_maxPositions = MathMin(20, MathMax(1, maxPos));
        m_targetProfitUSD = MathMax(0.5, MathMin(5.0, targetUSD));
        m_maxSpreadPoints = MathMax(5, MathMin(50, maxSpread));
    }

    virtual bool Initialize() override {
        m_accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        m_isMicroAccount = (m_accountBalance < 100.0);

        Print("✅ Scalping Strategy initialized");
        Print("   Max Positions: ", m_maxPositions);
        Print("   Target per trade: $", m_targetProfitUSD);
        Print("   Micro Account Mode: ", m_isMicroAccount ? "YES" : "NO");

        m_initialized = true;
        return true;
    }

    virtual TradeSignal CheckSignal(MarketConditions& conditions) override {
        TradeSignal signal;
        signal.Reset();
        signal.source = STRATEGY_SCALPING;
        signal.isScalpSignal = true;

        // Cooldown check
        if(TimeCurrent() - m_lastSignalTime < m_signalCooldown) {
            return signal;
        }

        // Check spread
        if(!IsSpreadAcceptable()) {
            return signal;
        }

        // Calculate micro-momentum (tick-by-tick)
        double microMomentum = CalculateMicroMomentum();
        signal.microMomentum = microMomentum;

        // Scalp signal threshold
        double threshold = 3.0;  // 3 pips minimum momentum

        if(microMomentum > threshold) {
            signal.direction = SIGNAL_BUY;
            signal.isValid = true;
            signal.score = 100;  // Scalping signals are binary (yes/no)
            signal.reason = StringFormat("Scalp BUY: Momentum %.2f pips", microMomentum);
            m_lastSignalTime = TimeCurrent();
        }
        else if(microMomentum < -threshold) {
            signal.direction = SIGNAL_SELL;
            signal.isValid = true;
            signal.score = 100;
            signal.reason = StringFormat("Scalp SELL: Momentum %.2f pips", MathAbs(microMomentum));
            m_lastSignalTime = TimeCurrent();
        }

        return signal;
    }

    virtual double CalculateStopLoss(ENUM_SIGNAL_DIRECTION direction, double entry, double atr) override {
        double slPips = 0;

        if(m_isMicroAccount) {
            // Micro account: tier-based SL
            if(m_accountBalance < 15.0) {
                slPips = 15.0;  // 15 pips for $10-15
            }
            else if(m_accountBalance < 40.0) {
                slPips = 12.0;  // 12 pips for $15-40
            }
            else if(m_accountBalance < 75.0) {
                slPips = 10.0;  // 10 pips for $40-75
            }
            else {
                slPips = 8.0;   // 8 pips for $75+
            }
        } else {
            // Regular account
            slPips = 8.0;
        }

        double slDistance = slPips * _Point * 10;

        if(direction == SIGNAL_BUY) {
            return entry - slDistance;
        } else {
            return entry + slDistance;
        }
    }

    virtual double CalculateTakeProfit(ENUM_SIGNAL_DIRECTION direction, double entry, double sl) override {
        double tpPips = 0;

        if(m_isMicroAccount) {
            // Micro account: ultra-tight TP (spread=0 advantage!)
            if(m_accountBalance < 15.0) {
                tpPips = 3.0;   // 3 pips TP for $10-15
            }
            else if(m_accountBalance < 40.0) {
                tpPips = 4.0;   // 4 pips for $15-40
            }
            else if(m_accountBalance < 75.0) {
                tpPips = 5.0;   // 5 pips for $40-75
            }
            else {
                tpPips = 6.0;   // 6 pips for $75+
            }
        } else {
            // Regular account
            tpPips = 5.0;
        }

        double tpDistance = tpPips * _Point * 10;

        if(direction == SIGNAL_BUY) {
            return entry + tpDistance;
        } else {
            return entry - tpDistance;
        }
    }

    int GetActivePositionsCount() {
        return m_activeCount;
    }

private:
    double CalculateMicroMomentum() {
        double currentBid = g_symbol.Bid();

        if(m_lastBid > 0) {
            double momentum = (currentBid - m_lastBid) / _Point;  // In points
            m_tickMomentum = m_tickMomentum * 0.7 + momentum * 0.3;  // EMA smoothing
        }

        m_lastBid = currentBid;
        return m_tickMomentum;
    }

    bool IsSpreadAcceptable() {
        double spread = (g_symbol.Ask() - g_symbol.Bid()) / _Point;
        return (spread <= m_maxSpreadPoints);
    }
};

//+------------------------------------------------------------------+
//|                   HARMONIC STRATEGY CLASS (Skeleton)              |
//+------------------------------------------------------------------+
class CHarmonicStrategy : public CBaseStrategy {
public:
    CHarmonicStrategy() {
        m_name = "Harmonic Patterns (Gartley, Butterfly, Bat)";
        m_type = STRATEGY_HARMONIC;
    }

    virtual bool Initialize() override {
        // TODO: Implement harmonic pattern detection
        // This would detect Gartley, Butterfly, Bat patterns
        m_initialized = true;
        Print("⚠️ Harmonic Strategy - skeleton only (TODO)");
        return true;
    }

    virtual TradeSignal CheckSignal(MarketConditions& conditions) override {
        TradeSignal signal;
        signal.Reset();
        signal.source = STRATEGY_HARMONIC;
        // TODO: Implement pattern detection logic from GoldTraderEA
        return signal;
    }

    virtual double CalculateStopLoss(ENUM_SIGNAL_DIRECTION direction, double entry, double atr) override {
        return (direction == SIGNAL_BUY) ? entry - atr * 1.0 : entry + atr * 1.0;
    }

    virtual double CalculateTakeProfit(ENUM_SIGNAL_DIRECTION direction, double entry, double sl) override {
        double slDistance = MathAbs(entry - sl);
        return (direction == SIGNAL_BUY) ? entry + slDistance * 2.0 : entry - slDistance * 2.0;
    }
};

//+------------------------------------------------------------------+
//|                   ELLIOTT WAVES STRATEGY (Skeleton)               |
//+------------------------------------------------------------------+
class CElliottStrategy : public CBaseStrategy {
public:
    CElliottStrategy() {
        m_name = "Elliott Waves (ABC, Wave 5)";
        m_type = STRATEGY_ELLIOTT;
    }

    virtual bool Initialize() override {
        // TODO: Implement Elliott Wave detection
        m_initialized = true;
        Print("⚠️ Elliott Strategy - skeleton only (TODO)");
        return true;
    }

    virtual TradeSignal CheckSignal(MarketConditions& conditions) override {
        TradeSignal signal;
        signal.Reset();
        signal.source = STRATEGY_ELLIOTT;
        // TODO: Implement Elliott Wave logic from GoldTraderEA
        return signal;
    }

    virtual double CalculateStopLoss(ENUM_SIGNAL_DIRECTION direction, double entry, double atr) override {
        return (direction == SIGNAL_BUY) ? entry - atr * 1.5 : entry + atr * 1.5;
    }

    virtual double CalculateTakeProfit(ENUM_SIGNAL_DIRECTION direction, double entry, double sl) override {
        double slDistance = MathAbs(entry - sl);
        return (direction == SIGNAL_BUY) ? entry + slDistance * 3.0 : entry - slDistance * 3.0;
    }
};

//+------------------------------------------------------------------+
//|                   ADAPTIVE STRATEGY CLASS                         |
//|               Auto-selects best strategy for current market       |
//+------------------------------------------------------------------+
class CAdaptiveStrategy : public CBaseStrategy {
private:
    CForexStrategy* m_forexStrategy;
    CMetalStrategy* m_metalStrategy;
    CCryptoStrategy* m_cryptoStrategy;
    CScalpingStrategy* m_scalpStrategy;

public:
    CAdaptiveStrategy() {
        m_name = "Adaptive Auto-Select";
        m_type = STRATEGY_ADAPTIVE;

        m_forexStrategy = new CForexStrategy();
        m_metalStrategy = new CMetalStrategy();
        m_cryptoStrategy = new CCryptoStrategy();
        m_scalpStrategy = new CScalpingStrategy();
    }

    ~CAdaptiveStrategy() {
        delete m_forexStrategy;
        delete m_metalStrategy;
        delete m_cryptoStrategy;
        delete m_scalpStrategy;
    }

    virtual bool Initialize() override {
        (*m_forexStrategy).Initialize();
        (*m_metalStrategy).Initialize();
        (*m_cryptoStrategy).Initialize();
        (*m_scalpStrategy).Initialize();

        m_initialized = true;
        Print("✅ Adaptive Strategy initialized");
        return true;
    }

    virtual TradeSignal CheckSignal(MarketConditions& conditions) override {
        // Auto-detect instrument type
        ENUM_INSTRUMENT_TYPE instrType = DetectInstrumentType(_Symbol);

        // Select appropriate strategy
        CBaseStrategy* selectedStrategy = NULL;

        switch(instrType) {
            case INSTRUMENT_FOREX:
                selectedStrategy = m_forexStrategy;
                break;
            case INSTRUMENT_METAL:
                selectedStrategy = m_metalStrategy;
                break;
            case INSTRUMENT_CRYPTO:
                selectedStrategy = m_cryptoStrategy;
                break;
            default:
                selectedStrategy = m_forexStrategy;  // Fallback
                break;
        }

        // Generate signal from selected strategy
        TradeSignal signal = (*selectedStrategy).CheckSignal(conditions);
        signal.source = STRATEGY_ADAPTIVE;  // Mark as adaptive

        return signal;
    }

    virtual double CalculateStopLoss(ENUM_SIGNAL_DIRECTION direction, double entry, double atr) override {
        ENUM_INSTRUMENT_TYPE instrType = DetectInstrumentType(_Symbol);

        switch(instrType) {
            case INSTRUMENT_FOREX:
                return (*m_forexStrategy).CalculateStopLoss(direction, entry, atr);
            case INSTRUMENT_METAL:
                return (*m_metalStrategy).CalculateStopLoss(direction, entry, atr);
            case INSTRUMENT_CRYPTO:
                return (*m_cryptoStrategy).CalculateStopLoss(direction, entry, atr);
            default:
                return (direction == SIGNAL_BUY) ? entry - atr * 1.5 : entry + atr * 1.5;
        }
    }

    virtual double CalculateTakeProfit(ENUM_SIGNAL_DIRECTION direction, double entry, double sl) override {
        ENUM_INSTRUMENT_TYPE instrType = DetectInstrumentType(_Symbol);

        switch(instrType) {
            case INSTRUMENT_FOREX:
                return (*m_forexStrategy).CalculateTakeProfit(direction, entry, sl);
            case INSTRUMENT_METAL:
                return (*m_metalStrategy).CalculateTakeProfit(direction, entry, sl);
            case INSTRUMENT_CRYPTO:
                return (*m_cryptoStrategy).CalculateTakeProfit(direction, entry, sl);
            default: {
                double slDistance = MathAbs(entry - sl);
                return (direction == SIGNAL_BUY) ? entry + slDistance * 2.0 : entry - slDistance * 2.0;
            }
        }
    }
};

#endif // UT_STRATEGIES_MQH
