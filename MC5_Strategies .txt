//+------------------------------------------------------------------+
//|                                              MC5_Strategies.mqh  |
//|                    Wszystkie strategie - POPRAWIONE SL/TP        |
//+------------------------------------------------------------------+
#ifndef MC5_STRATEGIES_MQH
#define MC5_STRATEGIES_MQH

#include "MC5_Core.mqh"
#include "MC5_Utils.mqh"

//+------------------------------------------------------------------+
//|                      BAZOWA KLASA STRATEGII                      |
//+------------------------------------------------------------------+
class CBaseStrategy {
protected:
    string m_name;
    ENUM_STRATEGY_TYPE m_type;
    bool m_initialized;
    
    int m_minScore;
    double m_minRR;
    
    TradeSignal m_lastSignal;
    
    // POPRAWIONA FUNKCJA - WŁAŚCIWY STOP LOSS
    virtual double CalculateStopLoss(ENUM_SIGNAL_DIRECTION direction, double entryPrice) {
        double atr = 0;
        if(ArraySize(g_buffer_atr_m15) > 0) {
            atr = g_buffer_atr_m15[0];
        }
        
        if(atr <= 0) {
            atr = 100 * _Point;
        }
        
        // WŁAŚCIWY SL - domyślnie 1.5x ATR (było 3x)
        double slDistance = atr * 1.5;
        
        // Dodatkowe zabezpieczenie minimalne
        double minSL = 30 * _Point;
        if(DetectInstrumentType(_Symbol) == INSTRUMENT_CRYPTO) {
            minSL = entryPrice * 0.005; // 0.5% dla crypto
        } else if(DetectInstrumentType(_Symbol) == INSTRUMENT_METAL) {
            minSL = 100 * _Point; // 100 punktów dla metali
        }
        
        slDistance = MathMax(minSL, slDistance);
        
        if(direction == SIGNAL_BUY) {
            return entryPrice - slDistance;
        } else {
            return entryPrice + slDistance;
        }
    }
    
    // POPRAWIONA FUNKCJA - WŁAŚCIWY TAKE PROFIT
    virtual double CalculateTakeProfit(ENUM_SIGNAL_DIRECTION direction, double entryPrice, double stopLoss) {
        double slDistance = MathAbs(entryPrice - stopLoss);
        
        // TP = SL * 2.0 (domyślnie 1:2 Risk:Reward)
        double tpMultiplier = 2.0;
        
        // Adaptacyjne TP w zależności od siły trendu
        if(ArraySize(g_buffer_adx) > 0) {
            double adx = g_buffer_adx[0];
            if(adx > 40) {
                tpMultiplier = 2.5;  // Większe TP w silnym trendzie
            } else if(adx > 25) {
                tpMultiplier = 2.0;  // Standardowe TP
            } else {
                tpMultiplier = 1.5;  // Mniejsze TP w konsolidacji
            }
        }
        
        double tpDistance = slDistance * tpMultiplier;
        
        // Minimalne TP
        double minTP = 50 * _Point;
        if(DetectInstrumentType(_Symbol) == INSTRUMENT_CRYPTO) {
            minTP = entryPrice * 0.01; // 1% dla crypto
        } else if(DetectInstrumentType(_Symbol) == INSTRUMENT_METAL) {
            minTP = 200 * _Point; // 200 punktów dla metali
        }
        
        tpDistance = MathMax(minTP, tpDistance);
        
        if(direction == SIGNAL_BUY) {
            return entryPrice + tpDistance;
        } else {
            return entryPrice - tpDistance;
        }
    }
    
    virtual bool BasicValidation(TradeSignal& signal) {
        if(signal.strength < m_minScore) {
            return false;
        }
        
        // Właściwe R:R - minimum 1.5
        if(signal.riskRewardRatio < m_minRR) {
            return false;
        }
        
        return true;
    }
    
public:
    CBaseStrategy() {
        m_name = "Base Strategy";
        m_type = STRATEGY_ADAPTIVE;
        m_initialized = false;
        m_minScore = 60;  // Wyższe dla lepszej jakości
        m_minRR = 1.5;    // Właściwe R:R
        
        m_lastSignal.Reset();
    }
    
    virtual ~CBaseStrategy() {
    }
    
    virtual bool Initialize() {
        m_initialized = true;
        return true;
    }
    
    virtual TradeSignal CheckSignal() {
        TradeSignal signal;
        signal.Reset();
        return signal;
    }
    
    string GetName() { return m_name; }
    ENUM_STRATEGY_TYPE GetType() { return m_type; }
    bool IsInitialized() { return m_initialized; }
    
    void SetMinScore(int score) { m_minScore = MathMax(30, MathMin(100, score)); }
    void SetMinRR(double rr) { m_minRR = MathMax(1.0, MathMin(5.0, rr)); }
};

//+------------------------------------------------------------------+
//|                      KLASA FOREX STRATEGY                        |
//+------------------------------------------------------------------+
class CForexStrategy : public CBaseStrategy {
private:
    TradeSignal CheckTrendSignal() {
        TradeSignal signal;
        signal.Reset();
        signal.strategy = STRATEGY_TREND;
        
        if(ArraySize(g_buffer_ema_fast) < 2 || ArraySize(g_buffer_ema_slow) < 2) {
            return signal;
        }
        
        double emaFast = g_buffer_ema_fast[0];
        double emaSlow = g_buffer_ema_slow[0];
        double emaFastPrev = g_buffer_ema_fast[1];
        double emaSlowPrev = g_buffer_ema_slow[1];
        
        bool goldenCross = (emaFast > emaSlow && emaFastPrev <= emaSlowPrev);
        bool deathCross = (emaFast < emaSlow && emaFastPrev >= emaSlowPrev);
        
        double adx = 0;
        if(ArraySize(g_buffer_adx) > 0) {
            adx = g_buffer_adx[0];
        }
        
        // Wyższy próg ADX dla lepszej jakości
        if(goldenCross && adx > 30) {  // Podwyższone z 25
            signal.direction = SIGNAL_BUY;
            signal.strength = 60 + (int)(adx / 2);
            signal.reason = "Forex Trend: EMA golden cross + ADX=" + DoubleToString(adx, 0);
            
            // Dodatkowe potwierdzenie z RSI
            if(ArraySize(g_buffer_rsi_m15) > 0) {
                double rsi = g_buffer_rsi_m15[0];
                if(rsi > 50 && rsi < 70) signal.strength += 10;
            }
        }
        else if(deathCross && adx > 30) {
            signal.direction = SIGNAL_SELL;
            signal.strength = 60 + (int)(adx / 2);
            signal.reason = "Forex Trend: EMA death cross + ADX=" + DoubleToString(adx, 0);
            
            if(ArraySize(g_buffer_rsi_m15) > 0) {
                double rsi = g_buffer_rsi_m15[0];
                if(rsi < 50 && rsi > 30) signal.strength += 10;
            }
        }
        
        return signal;
    }
    
    TradeSignal CheckMomentumSignal() {
        TradeSignal signal;
        signal.Reset();
        signal.strategy = STRATEGY_REVERSAL;
        
        if(ArraySize(g_buffer_rsi_m15) < 3) {
            return signal;
        }
        
        double rsi = g_buffer_rsi_m15[0];
        double rsiPrev = g_buffer_rsi_m15[1];
        double rsiPrev2 = g_buffer_rsi_m15[2];
        
        // Bardziej konserwatywne poziomy RSI
        if(rsi > 25 && rsi < 35 && rsi > rsiPrev && rsiPrev < rsiPrev2) {
            signal.direction = SIGNAL_BUY;
            signal.strength = 55 + (int)((35 - rsi) * 2);
            signal.reason = "Forex Momentum: RSI oversold bounce at " + DoubleToString(rsi, 1);
            
            if(ArraySize(g_buffer_macd_main) > 1 && ArraySize(g_buffer_macd_signal) > 1) {
                if(g_buffer_macd_main[0] > g_buffer_macd_signal[0] && 
                   g_buffer_macd_main[1] <= g_buffer_macd_signal[1]) {
                    signal.strength += 15;
                    signal.reason += " + MACD cross";
                }
            }
        }
        else if(rsi < 75 && rsi > 65 && rsi < rsiPrev && rsiPrev > rsiPrev2) {
            signal.direction = SIGNAL_SELL;
            signal.strength = 55 + (int)((rsi - 65) * 2);
            signal.reason = "Forex Momentum: RSI overbought reversal at " + DoubleToString(rsi, 1);
            
            if(ArraySize(g_buffer_macd_main) > 1 && ArraySize(g_buffer_macd_signal) > 1) {
                if(g_buffer_macd_main[0] < g_buffer_macd_signal[0] && 
                   g_buffer_macd_main[1] >= g_buffer_macd_signal[1]) {
                    signal.strength += 15;
                    signal.reason += " + MACD cross";
                }
            }
        }
        
        return signal;
    }
    
protected:
    // POPRAWIONA FUNKCJA DLA FOREX
    virtual double CalculateStopLoss(ENUM_SIGNAL_DIRECTION direction, double entryPrice) override {
        double atr = 0;
        if(ArraySize(g_buffer_atr_m15) > 0) {
            atr = g_buffer_atr_m15[0];
        }
        
        if(atr <= 0) {
            atr = 30 * _Point;
        }
        
        // Właściwy SL dla Forex - 1.2x ATR
        double slDistance = MathMax(atr * 1.2, 25 * _Point);
        
        if(direction == SIGNAL_BUY) {
            return entryPrice - slDistance;
        } else {
            return entryPrice + slDistance;
        }
    }
    
    // POPRAWIONA FUNKCJA DLA FOREX
    virtual double CalculateTakeProfit(ENUM_SIGNAL_DIRECTION direction, double entryPrice, double stopLoss) override {
        double slDistance = MathAbs(entryPrice - stopLoss);
        
        // TP = SL * 2.0 dla Forex
        double tpMultiplier = 2.0;
        
        // Adaptacyjne w zależności od siły trendu
        if(ArraySize(g_buffer_adx) > 0 && g_buffer_adx[0] > 35) {
            tpMultiplier = 2.5;  // Większe TP w silnym trendzie
        }
        
        double tpDistance = slDistance * tpMultiplier;
        
        if(direction == SIGNAL_BUY) {
            return entryPrice + tpDistance;
        } else {
            return entryPrice - tpDistance;
        }
    }
    
public:
    CForexStrategy() {
        m_name = "Forex Multi-Strategy";
        m_type = STRATEGY_ADAPTIVE;
        m_minScore = 60;  // Wyższe dla lepszej jakości
        m_minRR = 1.5;    // Właściwe R:R
    }
    
    virtual bool Initialize() override {
        DEBUG_MSG(DEBUG_NORMAL, "STRATEGY", "Initializing Forex Strategy with proper SL/TP ratio...");
        
        m_initialized = true;
        return true;
    }
    
    virtual TradeSignal CheckSignal() override {
        TradeSignal bestSignal;
        bestSignal.Reset();
        
        // Sprawdź czy to dobry czas na handel
        ENUM_MARKET_SESSION session = GetCurrentSession();
        if(session == SESSION_CLOSED) {
            return bestSignal;
        }
        
        TradeSignal trendSignal = CheckTrendSignal();
        TradeSignal momentumSignal = CheckMomentumSignal();
        
        if(trendSignal.strength > bestSignal.strength) {
            bestSignal = trendSignal;
        }
        
        if(momentumSignal.strength > bestSignal.strength) {
            bestSignal = momentumSignal;
        }
        
        if(bestSignal.direction != SIGNAL_NONE && bestSignal.strength >= m_minScore) {
            double entryPrice = bestSignal.direction == SIGNAL_BUY ? 
                               g_symbol.Ask() : g_symbol.Bid();
            
            bestSignal.entryPrice = entryPrice;
            bestSignal.stopLoss = CalculateStopLoss(bestSignal.direction, entryPrice);
            bestSignal.takeProfit = CalculateTakeProfit(bestSignal.direction, entryPrice, bestSignal.stopLoss);
            
            double risk = MathAbs(entryPrice - bestSignal.stopLoss);
            double reward = MathAbs(bestSignal.takeProfit - entryPrice);
            bestSignal.riskRewardRatio = reward / risk;
            
            if(BasicValidation(bestSignal)) {
                bestSignal.isValid = true;
                bestSignal.comment = m_name;
                bestSignal.expiry = TimeCurrent() + 300;
                
                m_lastSignal = bestSignal;
            }
        }
        
        return bestSignal;
    }
};

//+------------------------------------------------------------------+
//|                      KLASA METAL STRATEGY                        |
//+------------------------------------------------------------------+
class CMetalStrategy : public CBaseStrategy {
private:
    TradeSignal CheckSimpleRSISignal() {
        TradeSignal signal;
        signal.Reset();
        signal.strategy = STRATEGY_REVERSAL;
        
        if(ArraySize(g_buffer_rsi_m15) < 2) return signal;
        
        double rsi = g_buffer_rsi_m15[0];
        double rsiPrev = g_buffer_rsi_m15[1];
        
        // Konserwatywne zakresy dla metali
        if(rsi < 30 && rsi > rsiPrev) {
            signal.direction = SIGNAL_BUY;
            signal.strength = 60;
            signal.reason = "Gold RSI: Strong oversold bounce at " + DoubleToString(rsi, 1);
            
            if(rsi < 25) signal.strength += 15;
            if(rsi < 20) signal.strength += 10;
            
            if(ArraySize(g_buffer_ema_fast) > 0 && ArraySize(g_buffer_ema_slow) > 0) {
                if(g_buffer_ema_fast[0] > g_buffer_ema_slow[0]) {
                    signal.strength += 10;
                    signal.reason += " + Uptrend";
                }
            }
        }
        else if(rsi > 70 && rsi < rsiPrev) {
            signal.direction = SIGNAL_SELL;
            signal.strength = 60;
            signal.reason = "Gold RSI: Strong overbought reversal at " + DoubleToString(rsi, 1);
            
            if(rsi > 75) signal.strength += 15;
            if(rsi > 80) signal.strength += 10;
            
            if(ArraySize(g_buffer_ema_fast) > 0 && ArraySize(g_buffer_ema_slow) > 0) {
                if(g_buffer_ema_fast[0] < g_buffer_ema_slow[0]) {
                    signal.strength += 10;
                    signal.reason += " + Downtrend";
                }
            }
        }
        
        return signal;
    }
    
    TradeSignal CheckTrendSignal() {
        TradeSignal signal;
        signal.Reset();
        signal.strategy = STRATEGY_TREND;
        
        if(ArraySize(g_buffer_ema_fast) < 2 || ArraySize(g_buffer_ema_slow) < 2) {
            return signal;
        }
        
        double emaFast = g_buffer_ema_fast[0];
        double emaSlow = g_buffer_ema_slow[0];
        double emaFastPrev = g_buffer_ema_fast[1];
        double emaSlowPrev = g_buffer_ema_slow[1];
        
        // EMA crossover z dodatkowymi filtrami
        if(emaFast > emaSlow && emaFastPrev <= emaSlowPrev) {
            signal.direction = SIGNAL_BUY;
            signal.strength = 55;
            signal.reason = "Gold Trend: EMA bullish cross";
            
            // Wymagaj silniejszego ADX dla złota
            if(ArraySize(g_buffer_adx) > 0 && g_buffer_adx[0] > 30) {
                signal.strength += 20;
            }
            
            // Sprawdź wolumen
            if(ArraySize(g_buffer_volumes) > 1) {
                if(g_buffer_volumes[0] > g_buffer_volumes[1] * 1.3) {
                    signal.strength += 10;
                    signal.reason += " + Volume";
                }
            }
        }
        else if(emaFast < emaSlow && emaFastPrev >= emaSlowPrev) {
            signal.direction = SIGNAL_SELL;
            signal.strength = 55;
            signal.reason = "Gold Trend: EMA bearish cross";
            
            if(ArraySize(g_buffer_adx) > 0 && g_buffer_adx[0] > 30) {
                signal.strength += 20;
            }
            
            if(ArraySize(g_buffer_volumes) > 1) {
                if(g_buffer_volumes[0] > g_buffer_volumes[1] * 1.3) {
                    signal.strength += 10;
                    signal.reason += " + Volume";
                }
            }
        }
        
        return signal;
    }
    
protected:
    // POPRAWIONA FUNKCJA DLA METALI
    virtual double CalculateStopLoss(ENUM_SIGNAL_DIRECTION direction, double entryPrice) override {
        double atr = 0;
        if(ArraySize(g_buffer_atr_m15) > 0) {
            atr = g_buffer_atr_m15[0];
        }
        
        string symbol = _Symbol;
        StringToUpper(symbol);
        
        double slDistance;
        
        if(StringFind(symbol, "XAU") >= 0 || StringFind(symbol, "GOLD") >= 0) {
            // Dla złota - właściwy SL (1.5x ATR)
            double slMultiplier = 1.5;
            
            if(atr > 0) {
                slDistance = atr * slMultiplier;
                // Minimum 150 punktów dla złota
                slDistance = MathMax(150 * _Point, slDistance);
            } else {
                slDistance = 200 * _Point;  // Domyślnie 200 punktów
            }
        } else {
            // Dla innych metali
            if(atr > 0) {
                slDistance = atr * 1.3;
            } else {
                slDistance = 100 * _Point;
            }
        }
        
        if(direction == SIGNAL_BUY) {
            return entryPrice - slDistance;
        } else {
            return entryPrice + slDistance;
        }
    }
    
    // POPRAWIONA FUNKCJA DLA METALI
    virtual double CalculateTakeProfit(ENUM_SIGNAL_DIRECTION direction, double entryPrice, double stopLoss) override {
        double slDistance = MathAbs(entryPrice - stopLoss);
        
        string symbol = _Symbol;
        StringToUpper(symbol);
        
        double tpMultiplier;
        
        if(StringFind(symbol, "XAU") >= 0 || StringFind(symbol, "GOLD") >= 0) {
            // Dla złota - TP = SL * 2.0
            tpMultiplier = 2.0;
            
            // Adaptacyjne TP dla złota
            if(ArraySize(g_buffer_adx) > 0) {
                double adx = g_buffer_adx[0];
                if(adx > 40) {
                    tpMultiplier = 2.5;  // Większe TP w silnym trendzie
                } else if(adx < 20) {
                    tpMultiplier = 1.5;  // Mniejsze TP w konsolidacji
                }
            }
        } else {
            tpMultiplier = 1.8;  // Dla innych metali
        }
        
        double tpDistance = slDistance * tpMultiplier;
        
        // Minimalne TP dla złota
        if(StringFind(symbol, "XAU") >= 0 || StringFind(symbol, "GOLD") >= 0) {
            tpDistance = MathMax(300 * _Point, tpDistance);
        }
        
        if(direction == SIGNAL_BUY) {
            return entryPrice + tpDistance;
        } else {
            return entryPrice - tpDistance;
        }
    }
    
public:
    CMetalStrategy() {
        m_name = "Metal Specialist Strategy";
        m_type = STRATEGY_TREND;
        m_minScore = 60;  // Wyższe dla lepszej jakości
        m_minRR = 1.5;    // Właściwe R:R
    }
    
    virtual bool Initialize() override {
        DEBUG_MSG(DEBUG_NORMAL, "STRATEGY", "Initializing Metal Strategy with proper SL/TP...");
        
        string symbol = _Symbol;
        StringToUpper(symbol);
        
        if(StringFind(symbol, "XAU") >= 0 || StringFind(symbol, "GOLD") >= 0) {
            DEBUG_MSG(DEBUG_NORMAL, "STRATEGY", "Gold detected - optimizing for proper R:R");
            m_minScore = 55;  // Trochę niższe dla złota
            m_minRR = 1.5;    // Właściwe R:R
        }
        
        m_initialized = true;
        return true;
    }
    
    virtual TradeSignal CheckSignal() override {
        TradeSignal bestSignal;
        bestSignal.Reset();
        
        TradeSignal rsiSignal = CheckSimpleRSISignal();
        TradeSignal trendSignal = CheckTrendSignal();
        
        // Wybierz najsilniejszy sygnał
        if(rsiSignal.strength > bestSignal.strength) {
            bestSignal = rsiSignal;
        }
        
        if(trendSignal.strength > bestSignal.strength) {
            bestSignal = trendSignal;
        }
        
        if(bestSignal.direction != SIGNAL_NONE && bestSignal.strength >= m_minScore) {
            double entryPrice = bestSignal.direction == SIGNAL_BUY ? 
                               g_symbol.Ask() : g_symbol.Bid();
            
            bestSignal.entryPrice = entryPrice;
            bestSignal.stopLoss = CalculateStopLoss(bestSignal.direction, entryPrice);
            bestSignal.takeProfit = CalculateTakeProfit(bestSignal.direction, entryPrice, bestSignal.stopLoss);
            
            double risk = MathAbs(entryPrice - bestSignal.stopLoss);
            double reward = MathAbs(bestSignal.takeProfit - entryPrice);
            bestSignal.riskRewardRatio = reward / risk;
            
            if(bestSignal.riskRewardRatio >= m_minRR) {
                bestSignal.isValid = true;
                bestSignal.comment = m_name;
                bestSignal.expiry = TimeCurrent() + 300;
                
                m_lastSignal = bestSignal;
            }
        }
        
        return bestSignal;
    }
};

//+------------------------------------------------------------------+
//|                      KLASA CRYPTO STRATEGY                       |
//+------------------------------------------------------------------+
class CCryptoStrategy : public CBaseStrategy {
private:
    double m_volatilityMultiplier;
    int m_rsiOverbought;
    int m_rsiOversold;
    
    TradeSignal CheckCryptoMomentum() {
        TradeSignal signal;
        signal.Reset();
        signal.strategy = STRATEGY_REVERSAL;
        
        if(ArraySize(g_buffer_rsi_m15) < 3) {
            return signal;
        }
        
        double rsi = g_buffer_rsi_m15[0];
        double rsiPrev = g_buffer_rsi_m15[1];
        
        // Konserwatywne poziomy RSI dla crypto
        m_rsiOversold = 35;   
        m_rsiOverbought = 65;  
        
        if(rsi < m_rsiOversold && rsi > rsiPrev) {
            signal.direction = SIGNAL_BUY;
            signal.strength = 60 + (int)((m_rsiOversold - rsi));
            signal.reason = StringFormat("Crypto Momentum: Strong RSI reversal from %.1f", rsi);
            
            if(ArraySize(g_buffer_macd_main) > 1 && ArraySize(g_buffer_macd_signal) > 1) {
                double macdHist = g_buffer_macd_main[0] - g_buffer_macd_signal[0];
                double macdHistPrev = g_buffer_macd_main[1] - g_buffer_macd_signal[1];
                
                if(macdHist > macdHistPrev) {
                    signal.strength += 15;
                    signal.reason += " +MACD";
                }
            }
        }
        else if(rsi > m_rsiOverbought && rsi < rsiPrev) {
            signal.direction = SIGNAL_SELL;
            signal.strength = 60 + (int)((rsi - m_rsiOverbought));
            signal.reason = StringFormat("Crypto Momentum: Strong RSI reversal from %.1f", rsi);
            
            if(ArraySize(g_buffer_macd_main) > 1 && ArraySize(g_buffer_macd_signal) > 1) {
                double macdHist = g_buffer_macd_main[0] - g_buffer_macd_signal[0];
                double macdHistPrev = g_buffer_macd_main[1] - g_buffer_macd_signal[1];
                
                if(macdHist < macdHistPrev) {
                    signal.strength += 15;
                    signal.reason += " +MACD";
                }
            }
        }
        
        return signal;
    }
    
    TradeSignal CheckCryptoTrend() {
        TradeSignal signal;
        signal.Reset();
        signal.strategy = STRATEGY_TREND;
        
        if(ArraySize(g_buffer_ema_fast) < 3 || ArraySize(g_buffer_ema_slow) < 3) {
            return signal;
        }
        
        double emaFast = g_buffer_ema_fast[0];
        double emaSlow = g_buffer_ema_slow[0];
        
        // Trend following dla crypto z większym progiem
        if(emaFast > emaSlow * 1.003) {  // 0.3% powyżej
            signal.direction = SIGNAL_BUY;
            signal.strength = 55;
            signal.reason = "Crypto Trend: Strong bullish EMA alignment";
            
            // Sprawdź siłę trendu
            double trendStrength = (emaFast - emaSlow) / emaSlow * 100;
            if(trendStrength > 0.5) {
                signal.strength += 20;
            }
            
            // Dodatkowe potwierdzenie z ADX
            if(ArraySize(g_buffer_adx) > 0 && g_buffer_adx[0] > 30) {
                signal.strength += 15;
            }
        }
        else if(emaFast < emaSlow * 0.997) {  // 0.3% poniżej
            signal.direction = SIGNAL_SELL;
            signal.strength = 55;
            signal.reason = "Crypto Trend: Strong bearish EMA alignment";
            
            double trendStrength = (emaSlow - emaFast) / emaSlow * 100;
            if(trendStrength > 0.5) {
                signal.strength += 20;
            }
            
            if(ArraySize(g_buffer_adx) > 0 && g_buffer_adx[0] > 30) {
                signal.strength += 15;
            }
        }
        
        return signal;
    }
    
protected:
    // POPRAWIONA FUNKCJA DLA CRYPTO
    virtual double CalculateStopLoss(ENUM_SIGNAL_DIRECTION direction, double entryPrice) override {
        double atr = 0;
        if(ArraySize(g_buffer_atr_m15) > 0) {
            atr = g_buffer_atr_m15[0];
        }
        
        double slMultiplier;
        if(g_isBTCMode) {
            slMultiplier = 1.2;  // Mniejszy SL dla BTC
        } else {
            slMultiplier = 1.5;  // Standardowy dla altcoinów
        }
        
        double slDistance = atr * slMultiplier;
        
        // Limity procentowe dla crypto
        if(g_isBTCMode) {
            double maxSL = entryPrice * 0.015;  // Max 1.5% dla BTC
            double minSL = entryPrice * 0.005;  // Min 0.5%
            slDistance = MathMin(maxSL, MathMax(minSL, slDistance));
        } else {
            double maxSL = entryPrice * 0.02;   // Max 2% dla innych
            double minSL = entryPrice * 0.008;  // Min 0.8%
            slDistance = MathMin(maxSL, MathMax(minSL, slDistance));
        }
        
        if(direction == SIGNAL_BUY) {
            return entryPrice - slDistance;
        } else {
            return entryPrice + slDistance;
        }
    }
    
    // POPRAWIONA FUNKCJA DLA CRYPTO
    virtual double CalculateTakeProfit(ENUM_SIGNAL_DIRECTION direction, double entryPrice, double stopLoss) override {
        double slDistance = MathAbs(entryPrice - stopLoss);
        
        // TP = SL * 2.0 dla crypto
        double tpMultiplier = 2.0;
        
        // Adaptacyjne TP dla crypto
        if(ArraySize(g_buffer_adx) > 0) {
            double adx = g_buffer_adx[0];
            if(adx > 40) {
                tpMultiplier = 3.0;  // Większe TP w silnym trendzie crypto
            } else if(adx > 25) {
                tpMultiplier = 2.0;  // Standardowe TP
            } else {
                tpMultiplier = 1.5;  // Mniejsze TP w konsolidacji
            }
        }
        
        // Dla BTC w silnym trendzie
        if(g_isBTCMode && tpMultiplier > 2.0) {
            tpMultiplier = 2.5;  // Ograniczone TP dla BTC
        }
        
        double tpDistance = slDistance * tpMultiplier;
        
        // Minimalne TP
        double minTP;
        if(g_isBTCMode) {
            minTP = entryPrice * 0.01;   // Min 1% dla BTC
        } else {
            minTP = entryPrice * 0.015;  // Min 1.5% dla innych
        }
        
        tpDistance = MathMax(minTP, tpDistance);
        
        if(direction == SIGNAL_BUY) {
            return entryPrice + tpDistance;
        } else {
            return entryPrice - tpDistance;
        }
    }
    
public:
    CCryptoStrategy() {
        m_name = "Crypto Adaptive Strategy";
        m_type = STRATEGY_ADAPTIVE;
        m_minScore = 58;  // Wyższe dla lepszej jakości
        m_minRR = 1.2;    // Właściwe R:R
        
        m_volatilityMultiplier = 1.0;
        m_rsiOverbought = 65;
        m_rsiOversold = 35;
    }
    
    virtual bool Initialize() override {
        DEBUG_MSG(DEBUG_NORMAL, "STRATEGY", "Initializing Crypto Strategy with proper SL/TP...");
        
        string symbol = _Symbol;
        StringToUpper(symbol);
        
        if(StringFind(symbol, "BTC") >= 0) {
            m_volatilityMultiplier = 1.2;
            m_minRR = 1.5;    // Właściwe R:R dla BTC
            m_minScore = 55;  // Trochę niższe dla większej liczby sygnałów
            DEBUG_MSG(DEBUG_NORMAL, "STRATEGY", "BTC detected - adjusted for proper R:R");
        }
        else if(StringFind(symbol, "ETH") >= 0) {
            m_volatilityMultiplier = 1.5;
            m_minRR = 1.8;
            m_minScore = 60;
            DEBUG_MSG(DEBUG_NORMAL, "STRATEGY", "ETH detected - balanced settings");
        }
        else {
            m_volatilityMultiplier = 2.0;
            m_minRR = 2.0;
            m_minScore = 65;
            DEBUG_MSG(DEBUG_NORMAL, "STRATEGY", "Altcoin detected - conservative settings");
        }
        
        m_initialized = true;
        return true;
    }
    
    virtual TradeSignal CheckSignal() override {
        TradeSignal bestSignal;
        bestSignal.Reset();
        
        TradeSignal momentumSignal = CheckCryptoMomentum();
        TradeSignal trendSignal = CheckCryptoTrend();
        
        // Wybierz najsilniejszy sygnał
        if(momentumSignal.strength > bestSignal.strength) {
            bestSignal = momentumSignal;
        }
        
        if(trendSignal.strength > bestSignal.strength) {
            bestSignal = trendSignal;
        }
        
        if(bestSignal.direction != SIGNAL_NONE && bestSignal.strength >= m_minScore) {
            double entryPrice = bestSignal.direction == SIGNAL_BUY ? 
                               g_symbol.Ask() : g_symbol.Bid();
            
            bestSignal.entryPrice = entryPrice;
            bestSignal.stopLoss = CalculateStopLoss(bestSignal.direction, entryPrice);
            bestSignal.takeProfit = CalculateTakeProfit(bestSignal.direction, entryPrice, bestSignal.stopLoss);
            
            double risk = MathAbs(entryPrice - bestSignal.stopLoss);
            double reward = MathAbs(bestSignal.takeProfit - entryPrice);
            bestSignal.riskRewardRatio = reward / risk;
            
            if(BasicValidation(bestSignal)) {
                bestSignal.isValid = true;
                bestSignal.comment = m_name;
                bestSignal.expiry = TimeCurrent() + 300;
                
                m_lastSignal = bestSignal;
            }
        }
        
        return bestSignal;
    }
};

//+------------------------------------------------------------------+
//|                    KLASA ADAPTIVE STRATEGY                       |
//+------------------------------------------------------------------+
class CAdaptiveStrategy : public CBaseStrategy {
public:
    CAdaptiveStrategy() {
        m_name = "Universal Adaptive";
        m_type = STRATEGY_ADAPTIVE;
        m_minScore = 60;  // Wyższe
        m_minRR = 1.5;    // Właściwe R:R
    }
    
    virtual TradeSignal CheckSignal() override {
        TradeSignal signal;
        signal.Reset();
        
        int bullishPoints = 0;
        int bearishPoints = 0;
        
        // RSI - konserwatywne zakresy
        if(ArraySize(g_buffer_rsi_m15) > 0) {
            double rsi = g_buffer_rsi_m15[0];
            if(rsi < 30) bullishPoints += 25;
            else if(rsi > 70) bearishPoints += 25;
            
            if(rsi < 20) bullishPoints += 20;
            else if(rsi > 80) bearishPoints += 20;
        }
        
        // MACD
        if(ArraySize(g_buffer_macd_main) > 1 && ArraySize(g_buffer_macd_signal) > 1) {
            double macdHist = g_buffer_macd_main[0] - g_buffer_macd_signal[0];
            double macdHistPrev = g_buffer_macd_main[1] - g_buffer_macd_signal[1];
            
            if(macdHist > 0 && macdHist > macdHistPrev) bullishPoints += 20;
            else if(macdHist < 0 && macdHist < macdHistPrev) bearishPoints += 20;
            
            // Dodatkowe punkty za siłę histogramu
            if(MathAbs(macdHist) > MathAbs(macdHistPrev) * 1.5) {
                if(macdHist > 0) bullishPoints += 15;
                else bearishPoints += 15;
            }
        }
        
        // Bollinger Bands
        if(ArraySize(g_buffer_bb_upper) > 0 && ArraySize(g_buffer_bb_lower) > 0) {
            double price = g_symbol.Bid();
            double bbUpper = g_buffer_bb_upper[0];
            double bbLower = g_buffer_bb_lower[0];
            double bbMiddle = g_buffer_bb_middle[0];
            
            if(price <= bbLower) bullishPoints += 25;
            else if(price >= bbUpper) bearishPoints += 25;
            
            // Dodatkowe punkty za pozycję względem środka
            if(price < bbMiddle * 0.98) bullishPoints += 10;
            else if(price > bbMiddle * 1.02) bearishPoints += 10;
        }
        
        // EMA Trend z większą wagą
        if(ArraySize(g_buffer_ema_fast) > 0 && ArraySize(g_buffer_ema_slow) > 0) {
            double emaFast = g_buffer_ema_fast[0];
            double emaSlow = g_buffer_ema_slow[0];
            
            if(emaFast > emaSlow) {
                bullishPoints += 15;
                // Dodatkowe punkty za siłę trendu
                double trendStrength = (emaFast - emaSlow) / emaSlow * 100;
                if(trendStrength > 0.5) bullishPoints += 15;
            }
            else {
                bearishPoints += 15;
                double trendStrength = (emaSlow - emaFast) / emaSlow * 100;
                if(trendStrength > 0.5) bearishPoints += 15;
            }
        }
        
        // Stochastic
        if(ArraySize(g_buffer_stoch_main) > 0) {
            double stoch = g_buffer_stoch_main[0];
            if(stoch < 20) bullishPoints += 20;
            else if(stoch > 80) bearishPoints += 20;
        }
        
        // ADX - dodatkowe punkty za siłę trendu
        if(ArraySize(g_buffer_adx) > 0) {
            double adx = g_buffer_adx[0];
            if(adx > 30) {
                if(bullishPoints > bearishPoints) bullishPoints += 20;
                else if(bearishPoints > bullishPoints) bearishPoints += 20;
            }
        }
        
        // Decision - wyższe progi
        if(bullishPoints >= 70 && bullishPoints > bearishPoints + 20) {
            signal.direction = SIGNAL_BUY;
            signal.strength = MathMin(100, bullishPoints);
            signal.reason = StringFormat("Adaptive BUY: %d points", bullishPoints);
        }
        else if(bearishPoints >= 70 && bearishPoints > bullishPoints + 20) {
            signal.direction = SIGNAL_SELL;
            signal.strength = MathMin(100, bearishPoints);
            signal.reason = StringFormat("Adaptive SELL: %d points", bearishPoints);
        }
        
        if(signal.direction != SIGNAL_NONE) {
            double entryPrice = signal.direction == SIGNAL_BUY ? 
                               g_symbol.Ask() : g_symbol.Bid();
            
            signal.entryPrice = entryPrice;
            signal.stopLoss = CalculateStopLoss(signal.direction, entryPrice);
            signal.takeProfit = CalculateTakeProfit(signal.direction, entryPrice, signal.stopLoss);
            
            double risk = MathAbs(entryPrice - signal.stopLoss);
            double reward = MathAbs(signal.takeProfit - entryPrice);
            signal.riskRewardRatio = reward / risk;
            
            if(signal.strength >= m_minScore && signal.riskRewardRatio >= m_minRR) {
                signal.isValid = true;
                signal.strategy = STRATEGY_ADAPTIVE;
                signal.comment = m_name;
                signal.expiry = TimeCurrent() + 300;
            }
        }
        
        return signal;
    }
    
protected:
    // POPRAWIONA FUNKCJA DLA ADAPTIVE
    virtual double CalculateStopLoss(ENUM_SIGNAL_DIRECTION direction, double entryPrice) override {
        double atr = 0;
        if(ArraySize(g_buffer_atr_m15) > 0) {
            atr = g_buffer_atr_m15[0];
        }
        
        if(atr <= 0) {
            atr = 50 * _Point;
        }
        
        // Właściwy SL dla adaptive - 1.5x ATR
        double slDistance = atr * 1.5;
        
        // Dostosowanie do typu instrumentu
        ENUM_INSTRUMENT_TYPE type = DetectInstrumentType(_Symbol);
        switch(type) {
            case INSTRUMENT_CRYPTO:
                slDistance = MathMin(entryPrice * 0.015, slDistance);  // Max 1.5%
                slDistance = MathMax(entryPrice * 0.005, slDistance);  // Min 0.5%
                break;
            case INSTRUMENT_METAL:
                slDistance = MathMax(150 * _Point, slDistance);  // Min 150 punktów
                break;
            case INSTRUMENT_FOREX:
                slDistance = MathMax(30 * _Point, slDistance);  // Min 30 punktów
                break;
        }
        
        if(direction == SIGNAL_BUY) {
            return entryPrice - slDistance;
        } else {
            return entryPrice + slDistance;
        }
    }
    
    // POPRAWIONA FUNKCJA DLA ADAPTIVE
    virtual double CalculateTakeProfit(ENUM_SIGNAL_DIRECTION direction, double entryPrice, double stopLoss) override {
        double slDistance = MathAbs(entryPrice - stopLoss);
        
        // TP = SL * 2.0
        double tpMultiplier = 2.0;
        
        // Adaptacyjne TP w zależności od ADX
        if(ArraySize(g_buffer_adx) > 0) {
            double adx = g_buffer_adx[0];
            if(adx > 40) {
                tpMultiplier = 2.5;  // Większe TP w silnym trendzie
            } else if(adx > 25) {
                tpMultiplier = 2.0;  // Standardowe TP
            } else {
                tpMultiplier = 1.5;  // Mniejsze TP w konsolidacji
            }
        }
        
        double tpDistance = slDistance * tpMultiplier;
        
        // Minimalne TP
        ENUM_INSTRUMENT_TYPE type = DetectInstrumentType(_Symbol);
        switch(type) {
            case INSTRUMENT_CRYPTO:
                tpDistance = MathMax(entryPrice * 0.01, tpDistance);  // Min 1%
                break;
            case INSTRUMENT_METAL:
                tpDistance = MathMax(300 * _Point, tpDistance);  // Min 300 punktów
                break;
            case INSTRUMENT_FOREX:
                tpDistance = MathMax(60 * _Point, tpDistance);  // Min 60 punktów
                break;
        }
        
        if(direction == SIGNAL_BUY) {
            return entryPrice + tpDistance;
        } else {
            return entryPrice - tpDistance;
        }
    }
};

#endif // MC5_STRATEGIES_MQH