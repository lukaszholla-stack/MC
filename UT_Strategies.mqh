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
        if(signal.score >= 20) {
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

        // Volume score (0-20) - critical for metals
        signal.volumeScore = AnalyzeVolume(conditions);

        // Trend score (0-20)
        signal.trendScore = (conditions.isTrending) ? 15 : 5;

        // Momentum score (0-20)
        signal.momentumScore = AnalyzeMomentum(conditions);

        signal.CalculateScore();

        // IMPROVED LOGIC: Gold/Silver respond well to RSI + momentum
        if(signal.score >= 40) {  // Raised from 20 to 40 for better quality

            // STRATEGY 1: Mean reversion on RSI extremes (conservative for metals)
            if(conditions.rsi < 25 && conditions.trendDirection >= 0) {
                signal.direction = SIGNAL_BUY;
                signal.isValid = true;
                signal.reason = "Metal: Oversold bounce";
                Print("🔍 Metal: BUY (oversold) | Score=", signal.score, " | RSI=", DoubleToString(conditions.rsi, 1),
                      " | Trend=", conditions.trendDirection);
            }
            else if(conditions.rsi > 75 && conditions.trendDirection <= 0) {
                signal.direction = SIGNAL_SELL;
                signal.isValid = true;
                signal.reason = "Metal: Overbought reversal";
                Print("🔍 Metal: SELL (overbought) | Score=", signal.score, " | RSI=", DoubleToString(conditions.rsi, 1),
                      " | Trend=", conditions.trendDirection);
            }

            // STRATEGY 2: Strong trend following (metals love momentum)
            else if(conditions.trendDirection > 0 && conditions.rsi >= 35 && conditions.rsi <= 65 &&
                    conditions.isTrending) {
                signal.direction = SIGNAL_BUY;
                signal.isValid = true;
                signal.reason = "Metal: Bullish momentum";
                Print("🔍 Metal: BUY (trend) | Score=", signal.score, " | RSI=", DoubleToString(conditions.rsi, 1),
                      " | Trend=", conditions.trendDirection);
            }
            else if(conditions.trendDirection < 0 && conditions.rsi >= 35 && conditions.rsi <= 65 &&
                    conditions.isTrending) {
                signal.direction = SIGNAL_SELL;
                signal.isValid = true;
                signal.reason = "Metal: Bearish momentum";
                Print("🔍 Metal: SELL (trend) | Score=", signal.score, " | RSI=", DoubleToString(conditions.rsi, 1),
                      " | Trend=", conditions.trendDirection);
            }

            // STRATEGY 3: Volume breakouts (high-volume moves in metals are significant)
            else if(conditions.volumeSpike > 1.8 && signal.momentumScore > 10) {
                // Use MACD for momentum direction
                double macdHistogram = conditions.macd - conditions.macdSignal;
                if(macdHistogram > 0) {
                    signal.direction = SIGNAL_BUY;
                    signal.isValid = true;
                    signal.reason = "Metal: Volume breakout UP";
                    Print("🔍 Metal: BUY (breakout) | Score=", signal.score, " | Volume=", DoubleToString(conditions.volumeSpike, 2));
                }
                else if(macdHistogram < 0) {
                    signal.direction = SIGNAL_SELL;
                    signal.isValid = true;
                    signal.reason = "Metal: Volume breakout DOWN";
                    Print("🔍 Metal: SELL (breakout) | Score=", signal.score, " | Volume=", DoubleToString(conditions.volumeSpike, 2));
                }
            }
        }

        return signal;
    }

    virtual double CalculateStopLoss(ENUM_SIGNAL_DIRECTION direction, double entry, double atr) override {
        // Metal: Realistic SL = 1.0x ATR (was 1.5x - too wide!)
        // Gold/Silver are volatile but manageable with 1.0x ATR
        double slDistance = atr * 1.0;

        if(direction == SIGNAL_BUY) {
            return entry - slDistance;
        } else {
            return entry + slDistance;
        }
    }

    virtual double CalculateTakeProfit(ENUM_SIGNAL_DIRECTION direction, double entry, double sl) override {
        // Metal: Realistic TP = 1.5x SL distance (R:R = 1.5, was 2.5 - too far!)
        // Achievable targets for metals while still profitable
        double slDistance = MathAbs(entry - sl);
        double tpDistance = slDistance * 1.5;

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

    int AnalyzeMomentum(MarketConditions& conditions) {
        int score = 0;

        // RSI momentum (metals respond well to RSI)
        if(conditions.rsi < 25 || conditions.rsi > 75) {
            score += 12;  // Strong reversal potential
        }
        else if(conditions.rsi < 35 || conditions.rsi > 65) {
            score += 8;   // Moderate reversal potential
        }

        // MACD histogram (fast momentum for metals)
        double macdHistogram = conditions.macd - conditions.macdSignal;
        if(MathAbs(macdHistogram) > 0.001) {
            score += 8;
        }

        return MathMin(20, score);
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

        // IMPROVED LOGIC: Only trade clear setups with proper confirmation
        if(signal.score >= 30) {  // Raised from 20 to 30 for better quality

            // STRATEGY 1: Mean reversion on RSI extremes (high probability)
            if(conditions.rsi < 30 && conditions.trendDirection >= 0) {
                signal.direction = SIGNAL_BUY;
                signal.isValid = true;
                signal.reason = "Crypto: Oversold bounce";
                Print("🔍 Crypto: BUY (oversold) | Score=", signal.score, " | RSI=", DoubleToString(conditions.rsi, 1),
                      " | Trend=", conditions.trendDirection);
            }
            else if(conditions.rsi > 70 && conditions.trendDirection <= 0) {
                signal.direction = SIGNAL_SELL;
                signal.isValid = true;
                signal.reason = "Crypto: Overbought reversal";
                Print("🔍 Crypto: SELL (overbought) | Score=", signal.score, " | RSI=", DoubleToString(conditions.rsi, 1),
                      " | Trend=", conditions.trendDirection);
            }

            // STRATEGY 2: Strong trend with momentum (only if RSI not extreme)
            else if(conditions.trendDirection > 0 && conditions.rsi >= 40 && conditions.rsi <= 60) {
                signal.direction = SIGNAL_BUY;
                signal.isValid = true;
                signal.reason = "Crypto: Bullish momentum";
                Print("🔍 Crypto: BUY (trend) | Score=", signal.score, " | RSI=", DoubleToString(conditions.rsi, 1),
                      " | Trend=", conditions.trendDirection);
            }
            else if(conditions.trendDirection < 0 && conditions.rsi >= 40 && conditions.rsi <= 60) {
                signal.direction = SIGNAL_SELL;
                signal.isValid = true;
                signal.reason = "Crypto: Bearish momentum";
                Print("🔍 Crypto: SELL (trend) | Score=", signal.score, " | RSI=", DoubleToString(conditions.rsi, 1),
                      " | Trend=", conditions.trendDirection);
            }

            // STRATEGY 3: Volume breakout in direction of short-term momentum
            else if(conditions.volumeSpike > 2.0 && signal.momentumScore > 12) {
                // Use MACD for momentum direction
                double macdHistogram = conditions.macd - conditions.macdSignal;
                if(macdHistogram > 0) {
                    signal.direction = SIGNAL_BUY;
                    signal.isValid = true;
                    signal.reason = "Crypto: Volume breakout UP";
                    Print("🔍 Crypto: BUY (breakout) | Score=", signal.score, " | Volume=", DoubleToString(conditions.volumeSpike, 2));
                }
                else if(macdHistogram < 0) {
                    signal.direction = SIGNAL_SELL;
                    signal.isValid = true;
                    signal.reason = "Crypto: Volume breakout DOWN";
                    Print("🔍 Crypto: SELL (breakout) | Score=", signal.score, " | Volume=", DoubleToString(conditions.volumeSpike, 2));
                }
            }
        }

        return signal;
    }

    virtual double CalculateStopLoss(ENUM_SIGNAL_DIRECTION direction, double entry, double atr) override {
        // Crypto: More realistic SL = 1.0x ATR (was 2.0x - too wide!)
        // Still allows volatility but keeps it manageable
        double slDistance = atr * 1.0;

        if(direction == SIGNAL_BUY) {
            return entry - slDistance;
        } else {
            return entry + slDistance;
        }
    }

    virtual double CalculateTakeProfit(ENUM_SIGNAL_DIRECTION direction, double entry, double sl) override {
        // Crypto: More realistic TP = 1.5x SL distance (R:R = 1.5, was 3.0 - too far!)
        // This gives achievable targets while still profitable
        double slDistance = MathAbs(entry - sl);
        double tpDistance = slDistance * 1.5;

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

        // Set max spread based on instrument type
        ENUM_INSTRUMENT_TYPE instrType = DetectInstrumentType(_Symbol);
        switch(instrType) {
            case INSTRUMENT_FOREX:
                m_maxSpreadPoints = 20;    // 2 pips for forex
                break;
            case INSTRUMENT_METAL:
                m_maxSpreadPoints = 50;    // 5 pips for gold/silver
                break;
            case INSTRUMENT_CRYPTO:
                m_maxSpreadPoints = 2000;  // 20 USD for BTC (acceptable 0.02% spread)
                break;
            default:
                m_maxSpreadPoints = 50;
                break;
        }

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
        Print("   Max Spread: ", m_maxSpreadPoints, " points");
        Print("   Cooldown: ", m_signalCooldown, " seconds");
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
        double currentSpread = (g_symbol.Ask() - g_symbol.Bid()) / _Point;
        if(!IsSpreadAcceptable()) {
            static datetime lastSpreadLog = 0;
            if(TimeCurrent() - lastSpreadLog > 60) {  // Log once per minute
                Print("⚠️ Scalping: Spread too high (", DoubleToString(currentSpread, 1),
                      " > ", m_maxSpreadPoints, " points)");
                lastSpreadLog = TimeCurrent();
            }
            return signal;
        }

        // Calculate micro-momentum (tick-by-tick)
        double microMomentum = CalculateMicroMomentum();
        signal.microMomentum = microMomentum;

        // Also check recent price change as alternative momentum signal
        double recentChange = 0;
        MqlRates rates[];
        ArraySetAsSeries(rates, true);
        if(CopyRates(_Symbol, PERIOD_CURRENT, 0, 2, rates) == 2) {
            recentChange = (rates[0].close - rates[1].close) / _Point;  // Change in points
        }

        // Use the stronger of the two momentum signals
        double effectiveMomentum = (MathAbs(recentChange) > MathAbs(microMomentum)) ?
                                   recentChange : microMomentum;

        // Scalp signal threshold - VERY LOW for responsive scalping
        double threshold = 0.1;  // 0.1 pips minimum (was 0.5, originally 3.0)

        if(effectiveMomentum > threshold) {
            signal.direction = SIGNAL_BUY;
            signal.isValid = true;
            signal.score = 100;  // Scalping signals are binary (yes/no)
            signal.reason = StringFormat("Scalp BUY: Momentum %.2f pips", effectiveMomentum);
            m_lastSignalTime = TimeCurrent();
            Print("🔥 Scalping BUY: Momentum=", DoubleToString(effectiveMomentum, 2),
                  " pips (tick: ", DoubleToString(microMomentum, 2),
                  ", bar: ", DoubleToString(recentChange, 2), "), Spread=", DoubleToString(currentSpread, 1));
        }
        else if(effectiveMomentum < -threshold) {
            signal.direction = SIGNAL_SELL;
            signal.isValid = true;
            signal.score = 100;
            signal.reason = StringFormat("Scalp SELL: Momentum %.2f pips", MathAbs(effectiveMomentum));
            m_lastSignalTime = TimeCurrent();
            Print("🔥 Scalping SELL: Momentum=", DoubleToString(effectiveMomentum, 2),
                  " pips (tick: ", DoubleToString(microMomentum, 2),
                  ", bar: ", DoubleToString(recentChange, 2), "), Spread=", DoubleToString(currentSpread, 1));
        }
        else {
            // Log why no signal (momentum too low) - once per minute
            static datetime lastMomentumLog = 0;
            if(TimeCurrent() - lastMomentumLog > 60) {
                Print("⚠️ Scalping: Momentum too low (tick: ", DoubleToString(microMomentum, 2),
                      ", bar: ", DoubleToString(recentChange, 2),
                      " pips, need > ", DoubleToString(threshold, 1),
                      " or < ", DoubleToString(-threshold, 1), " | Spread: ",
                      DoubleToString(currentSpread, 1), " points)");
                lastMomentumLog = TimeCurrent();
            }
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
    bool m_scalpingEnabled;

public:
    CAdaptiveStrategy() {
        m_name = "Adaptive Auto-Select";
        m_type = STRATEGY_ADAPTIVE;

        m_forexStrategy = new CForexStrategy();
        m_metalStrategy = new CMetalStrategy();
        m_cryptoStrategy = new CCryptoStrategy();
        m_scalpStrategy = new CScalpingStrategy();
        m_scalpingEnabled = false;  // Disabled by default
    }

    void SetScalpingEnabled(bool enabled) {
        m_scalpingEnabled = enabled;
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
        // Check if scalping conditions are met (low spread + high volatility)
        // BUT ONLY if scalping is enabled by user
        if(m_scalpingEnabled) {
            double spread = (g_symbol.Ask() - g_symbol.Bid()) / _Point;
            bool isLowSpread = (spread <= 20);  // 20 points max
            bool isHighVolatility = conditions.isVolatile;

            // PRIORITY: Use scalping if conditions are favorable
            if(isLowSpread && isHighVolatility) {
                TradeSignal signal = (*m_scalpStrategy).CheckSignal(conditions);

                if(signal.isValid && signal.direction != SIGNAL_NONE) {
                    Print("📊 Scalping (adaptive): ", EnumToString(signal.direction),
                          " (score=", signal.score, ", spread=", DoubleToString(spread, 1), ")");
                }

                return signal;
            }
        }

        // Auto-detect instrument type for regular strategies
        ENUM_INSTRUMENT_TYPE instrType = DetectInstrumentType(_Symbol);

        // Select appropriate strategy
        CBaseStrategy* selectedStrategy = NULL;
        string strategyName = "";

        switch(instrType) {
            case INSTRUMENT_FOREX:
                selectedStrategy = m_forexStrategy;
                strategyName = "Forex";
                break;
            case INSTRUMENT_METAL:
                selectedStrategy = m_metalStrategy;
                strategyName = "Metal";
                break;
            case INSTRUMENT_CRYPTO:
                selectedStrategy = m_cryptoStrategy;
                strategyName = "Crypto";
                break;
            default:
                selectedStrategy = m_forexStrategy;  // Fallback
                strategyName = "Forex (fallback)";
                break;
        }

        // Generate signal from selected strategy
        TradeSignal signal = (*selectedStrategy).CheckSignal(conditions);

        // Only log valid signals to reduce spam
        if(signal.isValid && signal.direction != SIGNAL_NONE) {
            Print("📊 ", strategyName, ": ", EnumToString(signal.direction),
                  " (score=", signal.score, ", RSI=", DoubleToString(conditions.rsi, 1), ")");
        }

        // Keep original source for strategy-specific threshold validation
        // DO NOT overwrite signal.source - it's needed for proper validation

        return signal;
    }

    virtual double CalculateStopLoss(ENUM_SIGNAL_DIRECTION direction, double entry, double atr) override {
        // Use scalping SL/TP calculation ONLY if scalping is enabled by user
        if(m_scalpingEnabled) {
            double spread = (g_symbol.Ask() - g_symbol.Bid()) / _Point;
            bool isLowSpread = (spread <= 20);

            if(isLowSpread) {
                return (*m_scalpStrategy).CalculateStopLoss(direction, entry, atr);
            }
        }

        // Regular strategy selection based on instrument
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
        // Use scalping SL/TP calculation ONLY if scalping is enabled by user
        if(m_scalpingEnabled) {
            double spread = (g_symbol.Ask() - g_symbol.Bid()) / _Point;
            bool isLowSpread = (spread <= 20);

            if(isLowSpread) {
                return (*m_scalpStrategy).CalculateTakeProfit(direction, entry, sl);
            }
        }

        // Regular strategy selection based on instrument
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
