//+------------------------------------------------------------------+
//|                                                 MC5_Analysis.mqh |
//|                    Analiza rynku - wszystko w jednym             |
//+------------------------------------------------------------------+
#ifndef MC5_ANALYSIS_MQH
#define MC5_ANALYSIS_MQH

#include "MC5_Core.mqh"
#include "MC5_Utils.mqh"

//+------------------------------------------------------------------+
//|                     KLASA MARKET ANALYZER                        |
//+------------------------------------------------------------------+
class CMarketAnalyzer {
private:
    MarketConditions m_conditions;
    PriceLevels m_levels;
    
    // Cache dla optymalizacji
    struct AnalysisCache {
        double lastATR;
        datetime atrCheckTime;
        double lastSpread;
        datetime spreadCheckTime;
        double lastVolume;
        datetime volumeCheckTime;
        double marketStrength;
        datetime strengthCheckTime;
    };
    AnalysisCache m_cache;
    
    // Techniczne sygnały
    int m_rsiSignal;
    int m_macdSignal;
    int m_bbSignal;
    int m_emaSignal;
    int m_stochSignal;
    int m_adxSignal;
    
    // Volume analysis
    double m_volumeRatio;
    double m_buyVolume;
    double m_sellVolume;
    double m_deltaVolume;
    
    double CalculateMarketStrength() {
        if(TimeCurrent() - m_cache.strengthCheckTime < 30) {
            return m_cache.marketStrength;
        }
        
        double strength = 50;
        
        if(m_conditions.isTrending) {
            strength += m_conditions.trendStrength * 0.3;
        }
        
        strength += (m_conditions.momentum + 100) * 0.15;
        
        if(m_conditions.volume > 0 && ArraySize(g_buffer_volumes) > 1) {
            if(g_buffer_volumes[1] > 0) {
                double volRatio = g_buffer_volumes[0] / g_buffer_volumes[1];
                strength += MathMin(20, volRatio * 10);
            } else {
                strength += 10;
            }
        }
        
        if(m_conditions.volatility > 0) {
            if(m_conditions.isVolatile) {
                strength += 10;
            } else if(m_conditions.volatility < 100) {
                strength -= 10;
            }
        }
        
        strength = MathMax(0, MathMin(100, strength));
        
        m_cache.marketStrength = strength;
        m_cache.strengthCheckTime = TimeCurrent();
        
        return strength;
    }
    
    void AnalyzeTrend() {
        if(ArraySize(g_buffer_ema_fast) > 1 && ArraySize(g_buffer_ema_slow) > 1) {
            double emaFast = g_buffer_ema_fast[0];
            double emaSlow = g_buffer_ema_slow[0];
            
            if(emaSlow > 0) {
                if(emaFast > emaSlow) {
                    m_conditions.trendDirection = 1;
                    m_conditions.trendStrength = ((emaFast - emaSlow) / emaSlow) * 1000;
                } else if(emaFast < emaSlow) {
                    m_conditions.trendDirection = -1;
                    m_conditions.trendStrength = ((emaSlow - emaFast) / emaSlow) * 1000;
                } else {
                    m_conditions.trendDirection = 0;
                    m_conditions.trendStrength = 0;
                }
            }
        }
        
        if(ArraySize(g_buffer_adx) > 0) {
            double adx = g_buffer_adx[0];
            
            if(adx > 40) {
                m_conditions.isTrending = true;
                m_conditions.trendStrength = MathMin(100, adx * 2);
                m_conditions.phase = (m_conditions.trendDirection > 0) ? PHASE_MARKUP : PHASE_DECLINE;
            } else if(adx > 25) {
                m_conditions.isTrending = true;
                m_conditions.trendStrength = MathMin(100, adx * 1.5);
            } else if(adx < 20) {
                m_conditions.isTrending = false;
                m_conditions.phase = PHASE_RANGING;
            }
        }
    }
    
    void AnalyzeVolatility() {
        if(TimeCurrent() - m_cache.atrCheckTime > 10) {
            if(ArraySize(g_buffer_atr_m15) > 0) {
                m_cache.lastATR = g_buffer_atr_m15[0];
                m_cache.atrCheckTime = TimeCurrent();
            }
        }
        
        if(m_cache.lastATR <= 0) {
            if(DetectInstrumentType(_Symbol) == INSTRUMENT_CRYPTO) {
                m_conditions.volatility = 400;
                m_conditions.isVolatile = true;
            } else {
                m_conditions.volatility = 100;
                m_conditions.isVolatile = false;
            }
            return;
        }
        
        double currentATR = m_cache.lastATR;
        
        double avgATR = 0;
        int atrCount = MathMin(5, ArraySize(g_buffer_atr_m15));
        for(int i = 0; i < atrCount; i++) {
            avgATR += g_buffer_atr_m15[i];
        }
        if(atrCount > 0) avgATR /= atrCount;
        
        m_conditions.volatility = currentATR;
        
        double volatilityRatio = (avgATR > 0) ? currentATR / avgATR : 1.0;
        
        if(volatilityRatio > 1.5) {
            m_conditions.isVolatile = true;
            m_conditions.phase = PHASE_VOLATILE;
        } else if(volatilityRatio < 0.7) {
            m_conditions.isVolatile = false;
            m_conditions.phase = PHASE_QUIET;
        } else {
            m_conditions.isVolatile = (volatilityRatio > 1.2);
        }
        
        if(DetectInstrumentType(_Symbol) == INSTRUMENT_CRYPTO) {
            double price = g_symbol.Bid();
            if(price > 0) {
                m_conditions.volatility = (currentATR / price) * 10000;
            } else {
                m_conditions.volatility = 400;
            }
        }
    }
    
    void AnalyzeMomentum() {
        double momentum = 0;
        int signals = 0;
        
        if(ArraySize(g_buffer_rsi_m15) > 1) {
            double rsi = g_buffer_rsi_m15[0];
            double rsiPrev = g_buffer_rsi_m15[1];
            
            momentum += (rsi - 50);
            
            if(rsi > rsiPrev) momentum += 10;
            else momentum -= 10;
            
            signals++;
        }
        
        if(ArraySize(g_buffer_macd_main) > 1 && ArraySize(g_buffer_macd_signal) > 1) {
            double macdHist = g_buffer_macd_main[0] - g_buffer_macd_signal[0];
            double macdHistPrev = g_buffer_macd_main[1] - g_buffer_macd_signal[1];
            
            if(macdHist > 0) momentum += 20;
            else momentum -= 20;
            
            if(macdHist > macdHistPrev) momentum += 15;
            else momentum -= 15;
            
            signals++;
        }
        
        if(ArraySize(g_buffer_stoch_main) > 0) {
            double stoch = g_buffer_stoch_main[0];
            
            if(stoch > 80) momentum += 20;
            else if(stoch < 20) momentum -= 20;
            else momentum += (stoch - 50) * 0.4;
            
            signals++;
        }
        
        if(signals > 0) {
            momentum /= signals;
        }
        
        m_conditions.momentum = MathMax(-100, MathMin(100, momentum));
    }
    
    void AnalyzeTechnicalIndicators() {
        // RSI Analysis
        m_rsiSignal = 0;
        if(ArraySize(g_buffer_rsi_m15) > 2) {
            double rsi = g_buffer_rsi_m15[0];
            double rsiPrev = g_buffer_rsi_m15[1];
            
            if(rsi < 30 && rsi > rsiPrev) {
                m_rsiSignal = 1;
            } else if(rsi > 70 && rsi < rsiPrev) {
                m_rsiSignal = -1;
            }
        }
        
        // MACD Analysis
        m_macdSignal = 0;
        if(ArraySize(g_buffer_macd_main) > 1 && ArraySize(g_buffer_macd_signal) > 1) {
            double macdMain = g_buffer_macd_main[0];
            double macdSignal = g_buffer_macd_signal[0];
            double macdMainPrev = g_buffer_macd_main[1];
            double macdSignalPrev = g_buffer_macd_signal[1];
            
            if(macdMain > macdSignal && macdMainPrev <= macdSignalPrev) {
                m_macdSignal = 1;
                if(macdMain < 0) m_macdSignal = 2;
            } else if(macdMain < macdSignal && macdMainPrev >= macdSignalPrev) {
                m_macdSignal = -1;
                if(macdMain > 0) m_macdSignal = -2;
            }
        }
        
        // Bollinger Bands Analysis
        m_bbSignal = 0;
        if(ArraySize(g_buffer_bb_upper) > 1 && ArraySize(g_buffer_bb_lower) > 1) {
            double price = g_symbol.Bid();
            double bbUpper = g_buffer_bb_upper[0];
            double bbLower = g_buffer_bb_lower[0];
            
            double bbWidth = bbUpper - bbLower;
            double bbWidthPrev = g_buffer_bb_upper[1] - g_buffer_bb_lower[1];
            
            bool isSqueeze = (bbWidth < bbWidthPrev * 0.8);
            
            if(price <= bbLower) {
                m_bbSignal = 1;
                if(isSqueeze) m_bbSignal = 2;
            } else if(price >= bbUpper) {
                m_bbSignal = -1;
                if(isSqueeze) m_bbSignal = -2;
            }
        }
        
        // EMA Analysis
        m_emaSignal = 0;
        if(ArraySize(g_buffer_ema_fast) > 1 && ArraySize(g_buffer_ema_slow) > 1) {
            double emaFast = g_buffer_ema_fast[0];
            double emaSlow = g_buffer_ema_slow[0];
            double emaFastPrev = g_buffer_ema_fast[1];
            double emaSlowPrev = g_buffer_ema_slow[1];
            
            if(emaFast > emaSlow && emaFastPrev <= emaSlowPrev) {
                m_emaSignal = 1;
            } else if(emaFast < emaSlow && emaFastPrev >= emaSlowPrev) {
                m_emaSignal = -1;
            }
        }
        
        // Stochastic Analysis
        m_stochSignal = 0;
        if(ArraySize(g_buffer_stoch_main) > 1 && ArraySize(g_buffer_stoch_signal) > 1) {
            double stochMain = g_buffer_stoch_main[0];
            double stochSignal = g_buffer_stoch_signal[0];
            double stochMainPrev = g_buffer_stoch_main[1];
            double stochSignalPrev = g_buffer_stoch_signal[1];
            
            if(stochMain < 20 && stochMain > stochSignal && stochMainPrev <= stochSignalPrev) {
                m_stochSignal = 1;
            } else if(stochMain > 80 && stochMain < stochSignal && stochMainPrev >= stochSignalPrev) {
                m_stochSignal = -1;
            }
        }
        
        // ADX Analysis
        m_adxSignal = 0;
        if(ArraySize(g_buffer_adx) > 0 && ArraySize(g_buffer_adx_plus) > 0 && ArraySize(g_buffer_adx_minus) > 0) {
            double adx = g_buffer_adx[0];
            double diPlus = g_buffer_adx_plus[0];
            double diMinus = g_buffer_adx_minus[0];
            
            if(adx > 25) {
                if(diPlus > diMinus) {
                    m_adxSignal = 1;
                } else {
                    m_adxSignal = -1;
                }
                
                if(adx > 40) {
                    m_adxSignal *= 2;
                }
            }
        }
    }
    
    void AnalyzeVolume() {
        if(ArraySize(g_buffer_volumes) == 0) return;
        
        double volume = g_buffer_volumes[0];
        
        // Calculate average volume
        double avgVolume = 0;
        int period = MathMin(20, ArraySize(g_buffer_volumes));
        for(int i = 0; i < period; i++) {
            avgVolume += g_buffer_volumes[i];
        }
        if(period > 0) avgVolume /= period;
        
        if(avgVolume > 0) {
            m_volumeRatio = volume / avgVolume;
        } else {
            m_volumeRatio = 1.0;
        }
        
        // Estimate directional volume
        double close = iClose(_Symbol, PERIOD_M15, 0);
        double open = iOpen(_Symbol, PERIOD_M15, 0);
        double high = iHigh(_Symbol, PERIOD_M15, 0);
        double low = iLow(_Symbol, PERIOD_M15, 0);
        
        if(close > open) {
            double bullishRatio = (close - open) / (high - low + 0.00001);
            m_buyVolume = volume * (0.5 + bullishRatio * 0.5);
            m_sellVolume = volume - m_buyVolume;
        } else if(close < open) {
            double bearishRatio = (open - close) / (high - low + 0.00001);
            m_sellVolume = volume * (0.5 + bearishRatio * 0.5);
            m_buyVolume = volume - m_sellVolume;
        } else {
            m_buyVolume = volume * 0.5;
            m_sellVolume = volume * 0.5;
        }
        
        m_deltaVolume = m_buyVolume - m_sellVolume;
    }
    
    void CalculateDynamicLevels() {
        double h = iHigh(_Symbol, PERIOD_D1, 1);
        double l = iLow(_Symbol, PERIOD_D1, 1);
        double c = iClose(_Symbol, PERIOD_D1, 1);
        
        m_levels.pivot = (h + l + c) / 3;
        m_levels.r1 = 2 * m_levels.pivot - l;
        m_levels.s1 = 2 * m_levels.pivot - h;
        m_levels.r2 = m_levels.pivot + (h - l);
        m_levels.s2 = m_levels.pivot - (h - l);
        m_levels.r3 = h + 2 * (m_levels.pivot - l);
        m_levels.s3 = l - 2 * (h - m_levels.pivot);
        
        if(DetectInstrumentType(_Symbol) == INSTRUMENT_CRYPTO) {
            double range = h - l;
            m_levels.r1 = c + range * 1.1 / 12;
            m_levels.r2 = c + range * 1.1 / 6;
            m_levels.r3 = c + range * 1.1 / 4;
            m_levels.s1 = c - range * 1.1 / 12;
            m_levels.s2 = c - range * 1.1 / 6;
            m_levels.s3 = c - range * 1.1 / 4;
        }
        
        m_levels.dailyHigh = iHigh(_Symbol, PERIOD_D1, 0);
        m_levels.dailyLow = iLow(_Symbol, PERIOD_D1, 0);
        m_levels.weeklyHigh = iHigh(_Symbol, PERIOD_W1, 0);
        m_levels.weeklyLow = iLow(_Symbol, PERIOD_W1, 0);
        m_levels.monthlyHigh = iHigh(_Symbol, PERIOD_MN1, 0);
        m_levels.monthlyLow = iLow(_Symbol, PERIOD_MN1, 0);
    }
    
public:
    CMarketAnalyzer() {
        m_conditions.Reset();
        m_levels.Reset();
        
        m_cache.lastATR = 0;
        m_cache.atrCheckTime = 0;
        m_cache.lastSpread = 0;
        m_cache.spreadCheckTime = 0;
        m_cache.lastVolume = 0;
        m_cache.volumeCheckTime = 0;
        m_cache.marketStrength = 50;
        m_cache.strengthCheckTime = 0;
        
        m_rsiSignal = 0;
        m_macdSignal = 0;
        m_bbSignal = 0;
        m_emaSignal = 0;
        m_stochSignal = 0;
        m_adxSignal = 0;
        
        m_volumeRatio = 1.0;
        m_buyVolume = 0;
        m_sellVolume = 0;
        m_deltaVolume = 0;
    }
    
    ~CMarketAnalyzer() {
    }
    
    bool Initialize() {
        DEBUG_MSG(DEBUG_NORMAL, "MARKET", "Initializing Market Analyzer...");
        
        Analyze();
        
        return true;
    }
    
    void Analyze() {
        m_conditions.session = GetCurrentSession();
        
        AnalyzeTrend();
        AnalyzeVolatility();
        AnalyzeMomentum();
        AnalyzeTechnicalIndicators();
        AnalyzeVolume();
        CalculateDynamicLevels();
        
        m_conditions.spread = GetSpreadInPips();
        
        if(ArraySize(g_buffer_volumes) > 0) {
            m_conditions.volume = g_buffer_volumes[0];
            
            if(TimeCurrent() - m_cache.volumeCheckTime > 5) {
                m_cache.lastVolume = m_conditions.volume;
                m_cache.volumeCheckTime = TimeCurrent();
            }
        }
        
        m_conditions.liquidity = 100;
        
        double maxSpread = GetMaxAcceptableSpread();
        if(m_conditions.spread > maxSpread) {
            m_conditions.liquidity -= 40;
        } else if(m_conditions.spread > maxSpread * 0.7) {
            m_conditions.liquidity -= 20;
        }
        
        if(m_cache.lastVolume > 0 && m_conditions.volume < m_cache.lastVolume * 0.5) {
            m_conditions.liquidity -= 30;
        }
        
        if(m_conditions.session == SESSION_CLOSED) {
            m_conditions.liquidity -= 50;
        }
        
        m_conditions.liquidity = MathMax(0, MathMin(100, m_conditions.liquidity));
        
        m_conditions.lastUpdate = TimeCurrent();
    }
    
    void UpdateKeyLevels() {
        CalculateDynamicLevels();
        
        DEBUG_MSG(DEBUG_VERBOSE, "LEVELS", 
            StringFormat("Updated - Pivot: %.5f, R1: %.5f, S1: %.5f", 
                m_levels.pivot, m_levels.r1, m_levels.s1));
    }
    
    double GetMaxAcceptableSpread() {
        ENUM_INSTRUMENT_TYPE type = DetectInstrumentType(_Symbol);
        
        switch(type) {
            case INSTRUMENT_CRYPTO:
                return g_isBTCMode ? 200.0 : 150.0;
            case INSTRUMENT_METAL:
                return 100.0;
            case INSTRUMENT_FOREX:
                return 5.0;
            default:
                return 10.0;
        }
    }
    
    MarketConditions GetCurrentConditions() {
        return m_conditions;
    }
    
    PriceLevels GetPriceLevels() {
        return m_levels;
    }
    
    bool IsMarketSuitable() {
        if(m_conditions.liquidity < 30) {
            DEBUG_MSG(DEBUG_VERBOSE, "MARKET", "Market unsuitable: Low liquidity");
            return false;
        }
        
        if(m_conditions.spread > GetMaxAcceptableSpread() * 1.5) {
            DEBUG_MSG(DEBUG_VERBOSE, "MARKET", "Market unsuitable: High spread");
            return false;
        }
        
        if(DetectInstrumentType(_Symbol) == INSTRUMENT_CRYPTO) {
            return true;
        }
        
        if(m_conditions.session == SESSION_CLOSED) {
            DEBUG_MSG(DEBUG_VERBOSE, "MARKET", "Market unsuitable: Session closed");
            return false;
        }
        
        return true;
    }
    
    // Technical Analysis Functions
    int GetOverallSignal() {
        int totalSignal = 0;
        int signalCount = 0;
        
        if(m_rsiSignal != 0) {
            totalSignal += m_rsiSignal;
            signalCount++;
        }
        
        if(m_macdSignal != 0) {
            totalSignal += m_macdSignal;
            signalCount++;
        }
        
        if(m_bbSignal != 0) {
            totalSignal += m_bbSignal;
            signalCount++;
        }
        
        if(m_emaSignal != 0) {
            totalSignal += m_emaSignal;
            signalCount++;
        }
        
        if(m_stochSignal != 0) {
            totalSignal += m_stochSignal;
            signalCount++;
        }
        
        if(m_adxSignal != 0) {
            totalSignal += m_adxSignal;
            signalCount++;
        }
        
        if(signalCount == 0) return 0;
        
        double avgSignal = (double)totalSignal / signalCount;
        
        if(avgSignal > 0.5) return 1;
        if(avgSignal < -0.5) return -1;
        
        return 0;
    }
    
    int GetSignalStrength() {
        int confirmations = 0;
        
        if(m_rsiSignal != 0) confirmations++;
        if(m_macdSignal != 0) confirmations++;
        if(m_bbSignal != 0) confirmations++;
        if(m_emaSignal != 0) confirmations++;
        if(m_stochSignal != 0) confirmations++;
        if(m_adxSignal != 0) confirmations++;
        
        int strength = confirmations * 15;
        
        int overallSignal = GetOverallSignal();
        if(overallSignal != 0) {
            bool allAgree = true;
            
            if(m_rsiSignal != 0 && (m_rsiSignal > 0) != (overallSignal > 0)) allAgree = false;
            if(m_macdSignal != 0 && (m_macdSignal > 0) != (overallSignal > 0)) allAgree = false;
            if(m_bbSignal != 0 && (m_bbSignal > 0) != (overallSignal > 0)) allAgree = false;
            if(m_emaSignal != 0 && (m_emaSignal > 0) != (overallSignal > 0)) allAgree = false;
            if(m_stochSignal != 0 && (m_stochSignal > 0) != (overallSignal > 0)) allAgree = false;
            if(m_adxSignal != 0 && (m_adxSignal > 0) != (overallSignal > 0)) allAgree = false;
            
            if(allAgree) {
                strength += 10;
            }
        }
        
        return MathMin(100, strength);
    }
    
    // Volume Analysis Functions
    bool IsHighVolume() {
        return (m_volumeRatio > 1.5);
    }
    
    bool IsLowVolume() {
        return (m_volumeRatio < 0.5);
    }
    
    bool IsAccumulation() {
        return (m_deltaVolume > 0 && m_volumeRatio > 1.0);
    }
    
    bool IsDistribution() {
        return (m_deltaVolume < 0 && m_volumeRatio > 1.0);
    }
    
    double GetVolumeRatio() { return m_volumeRatio; }
    double GetDeltaVolume() { return m_deltaVolume; }
    
    int GetVolumeSignal() {
        if(IsAccumulation()) return 1;
        if(IsDistribution()) return -1;
        return 0;
    }
    
    int GetVolumeStrength() {
        if(m_volumeRatio < 1.0) return 0;
        
        int strength = (int)((m_volumeRatio - 1.0) * 50);
        
        if(MathAbs(m_deltaVolume) > 0) {
            double deltaRatio = MathAbs(m_deltaVolume) / (m_buyVolume + m_sellVolume + 0.00001);
            strength += (int)(deltaRatio * 30);
        }
        
        return MathMin(100, strength);
    }
};

#endif // MC5_ANALYSIS_MQH