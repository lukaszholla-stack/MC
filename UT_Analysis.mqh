//+------------------------------------------------------------------+
//|                                                  UT_Analysis.mqh |
//|                     Ultimate Trader EA - Market Analysis Engine  |
//|                                   Hybrid System v1.0.0            |
//+------------------------------------------------------------------+
#property copyright "Ultimate Trader Development Team"
#property version   "1.00"
#property strict

#ifndef UT_ANALYSIS_MQH
#define UT_ANALYSIS_MQH

#include "UT_Core.mqh"

//+------------------------------------------------------------------+
//|              TECHNICAL ANALYSIS CLASS                             |
//+------------------------------------------------------------------+
class CTechnicalAnalysis {
private:
    // Indicator handles
    int m_handleRSI;
    int m_handleMACD;
    int m_handleADX;
    int m_handleStoch;
    int m_handleBB;
    int m_handleEMA20;
    int m_handleEMA50;
    int m_handleEMA200;
    int m_handleATR;

    // Buffers
    double m_rsiBuffer[];
    double m_macdMain[];
    double m_macdSignal[];
    double m_adxBuffer[];
    double m_stochMain[];
    double m_stochSignal[];
    double m_bbUpper[];
    double m_bbMiddle[];
    double m_bbLower[];
    double m_ema20Buffer[];
    double m_ema50Buffer[];
    double m_ema200Buffer[];
    double m_atrBuffer[];

    bool m_initialized;

public:
    CTechnicalAnalysis() {
        m_initialized = false;
    }

    ~CTechnicalAnalysis() {
        if(m_initialized) {
            IndicatorRelease(m_handleRSI);
            IndicatorRelease(m_handleMACD);
            IndicatorRelease(m_handleADX);
            IndicatorRelease(m_handleStoch);
            IndicatorRelease(m_handleBB);
            IndicatorRelease(m_handleEMA20);
            IndicatorRelease(m_handleEMA50);
            IndicatorRelease(m_handleEMA200);
            IndicatorRelease(m_handleATR);
        }
    }

    bool Initialize() {
        // Create indicator handles
        m_handleRSI = iRSI(_Symbol, PERIOD_CURRENT, 14, PRICE_CLOSE);
        m_handleMACD = iMACD(_Symbol, PERIOD_CURRENT, 12, 26, 9, PRICE_CLOSE);
        m_handleADX = iADX(_Symbol, PERIOD_CURRENT, 14);
        m_handleStoch = iStochastic(_Symbol, PERIOD_CURRENT, 5, 3, 3, MODE_SMA, STO_LOWHIGH);
        m_handleBB = iBands(_Symbol, PERIOD_CURRENT, 20, 0, 2.0, PRICE_CLOSE);
        m_handleEMA20 = iMA(_Symbol, PERIOD_CURRENT, 20, 0, MODE_EMA, PRICE_CLOSE);
        m_handleEMA50 = iMA(_Symbol, PERIOD_CURRENT, 50, 0, MODE_EMA, PRICE_CLOSE);
        m_handleEMA200 = iMA(_Symbol, PERIOD_CURRENT, 200, 0, MODE_EMA, PRICE_CLOSE);
        m_handleATR = iATR(_Symbol, PERIOD_CURRENT, 14);

        // Verify all handles are valid
        if(m_handleRSI == INVALID_HANDLE || m_handleMACD == INVALID_HANDLE ||
           m_handleADX == INVALID_HANDLE || m_handleStoch == INVALID_HANDLE ||
           m_handleBB == INVALID_HANDLE || m_handleEMA20 == INVALID_HANDLE ||
           m_handleEMA50 == INVALID_HANDLE || m_handleEMA200 == INVALID_HANDLE ||
           m_handleATR == INVALID_HANDLE) {
            Print("ERROR: Failed to create indicator handles");
            return false;
        }

        // Set buffers as series
        ArraySetAsSeries(m_rsiBuffer, true);
        ArraySetAsSeries(m_macdMain, true);
        ArraySetAsSeries(m_macdSignal, true);
        ArraySetAsSeries(m_adxBuffer, true);
        ArraySetAsSeries(m_stochMain, true);
        ArraySetAsSeries(m_stochSignal, true);
        ArraySetAsSeries(m_bbUpper, true);
        ArraySetAsSeries(m_bbMiddle, true);
        ArraySetAsSeries(m_bbLower, true);
        ArraySetAsSeries(m_ema20Buffer, true);
        ArraySetAsSeries(m_ema50Buffer, true);
        ArraySetAsSeries(m_ema200Buffer, true);
        ArraySetAsSeries(m_atrBuffer, true);

        m_initialized = true;
        Print("✅ Technical Analysis initialized");
        return true;
    }

    bool RefreshData() {
        if(!m_initialized) return false;

        // Copy indicator data
        if(CopyBuffer(m_handleRSI, 0, 0, 3, m_rsiBuffer) < 0) return false;
        if(CopyBuffer(m_handleMACD, 0, 0, 3, m_macdMain) < 0) return false;
        if(CopyBuffer(m_handleMACD, 1, 0, 3, m_macdSignal) < 0) return false;
        if(CopyBuffer(m_handleADX, 0, 0, 3, m_adxBuffer) < 0) return false;
        if(CopyBuffer(m_handleStoch, 0, 0, 3, m_stochMain) < 0) return false;
        if(CopyBuffer(m_handleStoch, 1, 0, 3, m_stochSignal) < 0) return false;
        if(CopyBuffer(m_handleBB, 0, 0, 3, m_bbUpper) < 0) return false;
        if(CopyBuffer(m_handleBB, 1, 0, 3, m_bbMiddle) < 0) return false;
        if(CopyBuffer(m_handleBB, 2, 0, 3, m_bbLower) < 0) return false;
        if(CopyBuffer(m_handleEMA20, 0, 0, 3, m_ema20Buffer) < 0) return false;
        if(CopyBuffer(m_handleEMA50, 0, 0, 3, m_ema50Buffer) < 0) return false;
        if(CopyBuffer(m_handleEMA200, 0, 0, 3, m_ema200Buffer) < 0) return false;
        if(CopyBuffer(m_handleATR, 0, 0, 3, m_atrBuffer) < 0) return false;

        return true;
    }

    // Get individual indicator values
    double GetRSI(int shift = 0) { return m_rsiBuffer[shift]; }
    double GetMACD(int shift = 0) { return m_macdMain[shift]; }
    double GetMACDSignal(int shift = 0) { return m_macdSignal[shift]; }
    double GetADX(int shift = 0) { return m_adxBuffer[shift]; }
    double GetStochastic(int shift = 0) { return m_stochMain[shift]; }
    double GetStochSignal(int shift = 0) { return m_stochSignal[shift]; }
    double GetBBUpper(int shift = 0) { return m_bbUpper[shift]; }
    double GetBBMiddle(int shift = 0) { return m_bbMiddle[shift]; }
    double GetBBLower(int shift = 0) { return m_bbLower[shift]; }
    double GetEMA20(int shift = 0) { return m_ema20Buffer[shift]; }
    double GetEMA50(int shift = 0) { return m_ema50Buffer[shift]; }
    double GetEMA200(int shift = 0) { return m_ema200Buffer[shift]; }
    double GetATR(int shift = 0) { return m_atrBuffer[shift]; }

    // Analysis functions
    int AnalyzeTrend() {
        double close = iClose(_Symbol, PERIOD_CURRENT, 0);
        double ema20 = GetEMA20();
        double ema50 = GetEMA50();
        double ema200 = GetEMA200();

        // Strong bullish: price > EMA20 > EMA50 > EMA200
        if(close > ema20 && ema20 > ema50 && ema50 > ema200) {
            return 2;  // Strong bullish
        }
        // Bullish: price > EMA20 > EMA50
        else if(close > ema20 && ema20 > ema50) {
            return 1;  // Bullish
        }
        // Strong bearish: price < EMA20 < EMA50 < EMA200
        else if(close < ema20 && ema20 < ema50 && ema50 < ema200) {
            return -2;  // Strong bearish
        }
        // Bearish: price < EMA20 < EMA50
        else if(close < ema20 && ema20 < ema50) {
            return -1;  // Bearish
        }

        return 0;  // Ranging
    }

    bool IsRSIOversold() {
        return GetRSI() < 30;
    }

    bool IsRSIOverbought() {
        return GetRSI() > 70;
    }

    bool IsMACDBullishCross() {
        return GetMACD(1) <= GetMACDSignal(1) && GetMACD(0) > GetMACDSignal(0);
    }

    bool IsMACDBearishCross() {
        return GetMACD(1) >= GetMACDSignal(1) && GetMACD(0) < GetMACDSignal(0);
    }

    bool IsStrongTrend() {
        return GetADX() > 25.0;
    }

    double GetTrendStrength() {
        double adx = GetADX();
        if(adx > 75) return 100;
        if(adx < 0) return 0;
        return (adx / 75.0) * 100.0;
    }
};

//+------------------------------------------------------------------+
//|           DIVERGENCE DETECTOR CLASS                              |
//+------------------------------------------------------------------+
class CDivergenceDetector {
private:
    CTechnicalAnalysis* m_techAnalysis;

    struct SwingPoint {
        int barIndex;
        double price;
        double indicatorValue;
        bool isHigh;  // true = high, false = low
    };

public:
    CDivergenceDetector(CTechnicalAnalysis* techAnalysis) {
        m_techAnalysis = techAnalysis;
    }

    bool DetectBullishDivergence(string& divergenceType) {
        // Find two recent lows in price
        SwingPoint lows[];
        if(!FindSwingLows(lows, 2)) return false;

        if(ArraySize(lows) < 2) return false;

        // Earlier low vs Later low
        SwingPoint earlier = lows[1];
        SwingPoint later = lows[0];

        // Bullish divergence: price makes lower low, but RSI makes higher low
        if(later.price < earlier.price) {
            // Check RSI
            double earlierRSI = m_techAnalysis->GetRSI(earlier.barIndex);
            double laterRSI = m_techAnalysis->GetRSI(later.barIndex);

            if(laterRSI > earlierRSI) {
                divergenceType = "RSI";
                return true;
            }

            // Check MACD
            double earlierMACD = m_techAnalysis->GetMACD(earlier.barIndex);
            double laterMACD = m_techAnalysis->GetMACD(later.barIndex);

            if(laterMACD > earlierMACD) {
                if(divergenceType == "RSI") {
                    divergenceType = "Both";
                } else {
                    divergenceType = "MACD";
                }
                return true;
            }
        }

        return false;
    }

    bool DetectBearishDivergence(string& divergenceType) {
        // Find two recent highs in price
        SwingPoint highs[];
        if(!FindSwingHighs(highs, 2)) return false;

        if(ArraySize(highs) < 2) return false;

        // Earlier high vs Later high
        SwingPoint earlier = highs[1];
        SwingPoint later = highs[0];

        // Bearish divergence: price makes higher high, but RSI makes lower high
        if(later.price > earlier.price) {
            // Check RSI
            double earlierRSI = m_techAnalysis->GetRSI(earlier.barIndex);
            double laterRSI = m_techAnalysis->GetRSI(later.barIndex);

            if(laterRSI < earlierRSI) {
                divergenceType = "RSI";
                return true;
            }

            // Check MACD
            double earlierMACD = m_techAnalysis->GetMACD(earlier.barIndex);
            double laterMACD = m_techAnalysis->GetMACD(later.barIndex);

            if(laterMACD < earlierMACD) {
                if(divergenceType == "RSI") {
                    divergenceType = "Both";
                } else {
                    divergenceType = "MACD";
                }
                return true;
            }
        }

        return false;
    }

private:
    bool FindSwingLows(SwingPoint& lows[], int count) {
        ArrayResize(lows, 0);
        MqlRates rates[];
        ArraySetAsSeries(rates, true);

        int copied = CopyRates(_Symbol, PERIOD_CURRENT, 0, 50, rates);
        if(copied < 20) return false;

        for(int i = 2; i < copied - 2 && ArraySize(lows) < count; i++) {
            if(rates[i].low < rates[i-1].low && rates[i].low < rates[i-2].low &&
               rates[i].low < rates[i+1].low && rates[i].low < rates[i+2].low) {
                SwingPoint point;
                point.barIndex = i;
                point.price = rates[i].low;
                point.indicatorValue = 0;  // Will be filled by caller
                point.isHigh = false;

                int size = ArraySize(lows);
                ArrayResize(lows, size + 1);
                lows[size] = point;
            }
        }

        return ArraySize(lows) >= count;
    }

    bool FindSwingHighs(SwingPoint& highs[], int count) {
        ArrayResize(highs, 0);
        MqlRates rates[];
        ArraySetAsSeries(rates, true);

        int copied = CopyRates(_Symbol, PERIOD_CURRENT, 0, 50, rates);
        if(copied < 20) return false;

        for(int i = 2; i < copied - 2 && ArraySize(highs) < count; i++) {
            if(rates[i].high > rates[i-1].high && rates[i].high > rates[i-2].high &&
               rates[i].high > rates[i+1].high && rates[i].high > rates[i+2].high) {
                SwingPoint point;
                point.barIndex = i;
                point.price = rates[i].high;
                point.indicatorValue = 0;
                point.isHigh = true;

                int size = ArraySize(highs);
                ArrayResize(highs, size + 1);
                highs[size] = point;
            }
        }

        return ArraySize(highs) >= count;
    }
};

//+------------------------------------------------------------------+
//|                VOLUME ANALYSIS CLASS                              |
//+------------------------------------------------------------------+
class CVolumeAnalysis {
private:
    int m_handleVolumes;
    double m_volumeBuffer[];
    double m_volumeMA[];
    bool m_initialized;

public:
    CVolumeAnalysis() {
        m_initialized = false;
    }

    ~CVolumeAnalysis() {
        if(m_initialized && m_handleVolumes != INVALID_HANDLE) {
            IndicatorRelease(m_handleVolumes);
        }
    }

    bool Initialize() {
        m_handleVolumes = iVolumes(_Symbol, PERIOD_CURRENT, VOLUME_TICK);

        if(m_handleVolumes == INVALID_HANDLE) {
            Print("ERROR: Failed to create volume indicator");
            return false;
        }

        ArraySetAsSeries(m_volumeBuffer, true);
        ArraySetAsSeries(m_volumeMA, true);

        m_initialized = true;
        return true;
    }

    bool RefreshData() {
        if(!m_initialized) return false;

        if(CopyBuffer(m_handleVolumes, 0, 0, 20, m_volumeBuffer) < 0) {
            return false;
        }

        // Calculate volume MA
        ArrayResize(m_volumeMA, 20);
        for(int i = 0; i < 20; i++) {
            double sum = 0;
            int count = MathMin(20, ArraySize(m_volumeBuffer) - i);
            for(int j = 0; j < count; j++) {
                sum += m_volumeBuffer[i + j];
            }
            m_volumeMA[i] = (count > 0) ? sum / count : 0;
        }

        return true;
    }

    bool IsVolumeSpike() {
        if(ArraySize(m_volumeBuffer) < 2 || ArraySize(m_volumeMA) < 1) return false;

        double currentVolume = m_volumeBuffer[0];
        double avgVolume = m_volumeMA[0];

        return (avgVolume > 0 && currentVolume > avgVolume * 1.5);  // 150% spike
    }

    double GetVolumeRatio() {
        if(ArraySize(m_volumeBuffer) < 1 || ArraySize(m_volumeMA) < 1) return 1.0;

        double currentVolume = m_volumeBuffer[0];
        double avgVolume = m_volumeMA[0];

        return (avgVolume > 0) ? currentVolume / avgVolume : 1.0;
    }

    bool IsVolumeSqueeze() {
        // Volume squeeze: low volume for 3-6 bars, then spike
        if(ArraySize(m_volumeBuffer) < 7) return false;

        double avgVolume = m_volumeMA[0];

        // Check if last 3-6 bars had low volume
        int lowVolumeBars = 0;
        for(int i = 1; i <= 6; i++) {
            if(m_volumeBuffer[i] < avgVolume * 0.7) {
                lowVolumeBars++;
            }
        }

        // Now check if current bar has spike
        bool currentSpike = m_volumeBuffer[0] > avgVolume * 1.5;

        return (lowVolumeBars >= 3 && currentSpike);
    }
};

//+------------------------------------------------------------------+
//|             MULTI-TIMEFRAME ANALYSIS CLASS                        |
//+------------------------------------------------------------------+
class CMultiTimeframe {
private:
    struct TimeframeData {
        int trend;  // -1 bearish, 0 range, 1 bullish
        double ema20;
        double ema50;
        bool confirmed;
    };

    TimeframeData m_h4Data;
    TimeframeData m_d1Data;
    TimeframeData m_w1Data;

    int m_handleH4_EMA20, m_handleH4_EMA50;
    int m_handleD1_EMA20, m_handleD1_EMA50;
    int m_handleW1_EMA20, m_handleW1_EMA50;

    bool m_initialized;

public:
    CMultiTimeframe() {
        m_initialized = false;
    }

    ~CMultiTimeframe() {
        if(m_initialized) {
            if(m_handleH4_EMA20 != INVALID_HANDLE) IndicatorRelease(m_handleH4_EMA20);
            if(m_handleH4_EMA50 != INVALID_HANDLE) IndicatorRelease(m_handleH4_EMA50);
            if(m_handleD1_EMA20 != INVALID_HANDLE) IndicatorRelease(m_handleD1_EMA20);
            if(m_handleD1_EMA50 != INVALID_HANDLE) IndicatorRelease(m_handleD1_EMA50);
            if(m_handleW1_EMA20 != INVALID_HANDLE) IndicatorRelease(m_handleW1_EMA20);
            if(m_handleW1_EMA50 != INVALID_HANDLE) IndicatorRelease(m_handleW1_EMA50);
        }
    }

    bool Initialize() {
        // Create H4 handles
        m_handleH4_EMA20 = iMA(_Symbol, PERIOD_H4, 20, 0, MODE_EMA, PRICE_CLOSE);
        m_handleH4_EMA50 = iMA(_Symbol, PERIOD_H4, 50, 0, MODE_EMA, PRICE_CLOSE);

        // Create D1 handles
        m_handleD1_EMA20 = iMA(_Symbol, PERIOD_D1, 20, 0, MODE_EMA, PRICE_CLOSE);
        m_handleD1_EMA50 = iMA(_Symbol, PERIOD_D1, 50, 0, MODE_EMA, PRICE_CLOSE);

        // Create W1 handles
        m_handleW1_EMA20 = iMA(_Symbol, PERIOD_W1, 20, 0, MODE_EMA, PRICE_CLOSE);
        m_handleW1_EMA50 = iMA(_Symbol, PERIOD_W1, 50, 0, MODE_EMA, PRICE_CLOSE);

        if(m_handleH4_EMA20 == INVALID_HANDLE || m_handleH4_EMA50 == INVALID_HANDLE ||
           m_handleD1_EMA20 == INVALID_HANDLE || m_handleD1_EMA50 == INVALID_HANDLE ||
           m_handleW1_EMA20 == INVALID_HANDLE || m_handleW1_EMA50 == INVALID_HANDLE) {
            Print("ERROR: Failed to create multi-timeframe indicators");
            return false;
        }

        m_initialized = true;
        Print("✅ Multi-Timeframe Analysis initialized");
        return true;
    }

    bool Analyze() {
        if(!m_initialized) return false;

        // Analyze H4
        m_h4Data.trend = AnalyzeTimeframe(PERIOD_H4, m_handleH4_EMA20, m_handleH4_EMA50, m_h4Data.ema20, m_h4Data.ema50);
        m_h4Data.confirmed = (m_h4Data.trend != 0);

        // Analyze D1
        m_d1Data.trend = AnalyzeTimeframe(PERIOD_D1, m_handleD1_EMA20, m_handleD1_EMA50, m_d1Data.ema20, m_d1Data.ema50);
        m_d1Data.confirmed = (m_d1Data.trend != 0);

        // Analyze W1
        m_w1Data.trend = AnalyzeTimeframe(PERIOD_W1, m_handleW1_EMA20, m_handleW1_EMA50, m_w1Data.ema20, m_w1Data.ema50);
        m_w1Data.confirmed = (m_w1Data.trend != 0);

        return true;
    }

    int GetH4Trend() { return m_h4Data.trend; }
    int GetD1Trend() { return m_d1Data.trend; }
    int GetW1Trend() { return m_w1Data.trend; }

    int GetTrendAlignment() {
        return m_h4Data.trend + m_d1Data.trend + m_w1Data.trend;
    }

    bool IsH4Confirmed() { return m_h4Data.confirmed; }
    bool IsD1Confirmed() { return m_d1Data.confirmed; }
    bool IsW1Confirmed() { return m_w1Data.confirmed; }

private:
    int AnalyzeTimeframe(ENUM_TIMEFRAMES tf, int handleEMA20, int handleEMA50, double& ema20, double& ema50) {
        double buffer20[], buffer50[];
        ArraySetAsSeries(buffer20, true);
        ArraySetAsSeries(buffer50, true);

        if(CopyBuffer(handleEMA20, 0, 0, 1, buffer20) < 0) return 0;
        if(CopyBuffer(handleEMA50, 0, 0, 1, buffer50) < 0) return 0;

        ema20 = buffer20[0];
        ema50 = buffer50[0];

        double close = iClose(_Symbol, tf, 0);

        // Bullish: price > EMA20 > EMA50
        if(close > ema20 && ema20 > ema50) {
            return 1;
        }
        // Bearish: price < EMA20 < EMA50
        else if(close < ema20 && ema20 < ema50) {
            return -1;
        }

        return 0;  // Ranging
    }
};

//+------------------------------------------------------------------+
//|                    MARKET ANALYZER CLASS                          |
//+------------------------------------------------------------------+
class CMarketAnalyzer {
private:
    CTechnicalAnalysis* m_techAnalysis;
    CDivergenceDetector* m_divergenceDetector;
    CVolumeAnalysis* m_volumeAnalysis;
    CMultiTimeframe* m_mtfAnalysis;

    bool m_initialized;

public:
    CMarketAnalyzer() {
        m_techAnalysis = new CTechnicalAnalysis();
        m_divergenceDetector = new CDivergenceDetector(m_techAnalysis);
        m_volumeAnalysis = new CVolumeAnalysis();
        m_mtfAnalysis = new CMultiTimeframe();
        m_initialized = false;
    }

    ~CMarketAnalyzer() {
        delete m_techAnalysis;
        delete m_divergenceDetector;
        delete m_volumeAnalysis;
        delete m_mtfAnalysis;
    }

    bool Initialize() {
        if(!m_techAnalysis->Initialize()) {
            Print("ERROR: Technical Analysis initialization failed");
            return false;
        }

        if(!m_volumeAnalysis->Initialize()) {
            Print("ERROR: Volume Analysis initialization failed");
            return false;
        }

        if(!m_mtfAnalysis->Initialize()) {
            Print("ERROR: Multi-Timeframe Analysis initialization failed");
            return false;
        }

        m_initialized = true;
        Print("✅ Market Analyzer initialized successfully");
        return true;
    }

    MarketConditions Analyze() {
        MarketConditions conditions;
        conditions.Reset();

        if(!m_initialized) {
            Print("ERROR: Market Analyzer not initialized");
            return conditions;
        }

        // Refresh all data
        if(!m_techAnalysis->RefreshData()) {
            Print("ERROR: Failed to refresh technical data");
            return conditions;
        }

        if(!m_volumeAnalysis->RefreshData()) {
            Print("WARNING: Failed to refresh volume data");
        }

        if(!m_mtfAnalysis->Analyze()) {
            Print("WARNING: Failed to analyze multi-timeframe");
        }

        // Populate technical indicators
        conditions.rsi = m_techAnalysis->GetRSI();
        conditions.macd = m_techAnalysis->GetMACD();
        conditions.macdSignal = m_techAnalysis->GetMACDSignal();
        conditions.adx = m_techAnalysis->GetADX();
        conditions.stochastic = m_techAnalysis->GetStochastic();
        conditions.ema20 = m_techAnalysis->GetEMA20();
        conditions.ema50 = m_techAnalysis->GetEMA50();
        conditions.ema200 = m_techAnalysis->GetEMA200();

        // Analyze trend
        conditions.trendDirection = m_techAnalysis->AnalyzeTrend();
        conditions.trendStrength = m_techAnalysis->GetTrendStrength();
        conditions.isTrending = m_techAnalysis->IsStrongTrend();

        // Volatility (ATR-based)
        conditions.volatility = m_techAnalysis->GetATR();
        double atrMA20 = CalculateATRAverage(20);
        conditions.isVolatile = (atrMA20 > 0 && conditions.volatility > atrMA20 * 1.5);

        // Volume analysis
        conditions.volume = m_volumeAnalysis->GetVolumeRatio();
        conditions.volumeSpike = conditions.volume;
        conditions.volumeBreakout = m_volumeAnalysis->IsVolumeSpike();

        // Divergence detection
        string divType = "";
        conditions.hasBullishDivergence = m_divergenceDetector->DetectBullishDivergence(divType);
        if(conditions.hasBullishDivergence) {
            conditions.divergenceType = divType;
        }

        divType = "";
        conditions.hasBearishDivergence = m_divergenceDetector->DetectBearishDivergence(divType);
        if(conditions.hasBearishDivergence) {
            conditions.divergenceType = divType;
        }

        // Multi-timeframe
        conditions.h4Trend = m_mtfAnalysis->GetH4Trend();
        conditions.d1Trend = m_mtfAnalysis->GetD1Trend();
        conditions.w1Trend = m_mtfAnalysis->GetW1Trend();
        conditions.trendAlignment = m_mtfAnalysis->GetTrendAlignment();

        // Market phase
        conditions.phase = DetermineMarketPhase(conditions);

        // Current spread
        conditions.spread = (g_symbol.Ask() - g_symbol.Bid()) / _Point;

        // Session
        conditions.session = GetCurrentSession();

        return conditions;
    }

private:
    double CalculateATRAverage(int period) {
        double sum = 0;
        for(int i = 0; i < period; i++) {
            sum += m_techAnalysis->GetATR(i);
        }
        return (period > 0) ? sum / period : 0;
    }

    ENUM_MARKET_PHASE DetermineMarketPhase(MarketConditions& conditions) {
        // Strong uptrend
        if(conditions.trendDirection >= 1 && conditions.adx > 30) {
            return PHASE_MARKUP;
        }
        // Strong downtrend
        else if(conditions.trendDirection <= -1 && conditions.adx > 30) {
            return PHASE_MARKDOWN;
        }
        // Ranging
        else if(conditions.adx < 20) {
            return PHASE_RANGING;
        }
        // Accumulation (after downtrend, low ADX)
        else if(conditions.trendDirection == 0 && conditions.d1Trend <= -1 && conditions.adx < 25) {
            return PHASE_ACCUMULATION;
        }
        // Distribution (after uptrend, low ADX)
        else if(conditions.trendDirection == 0 && conditions.d1Trend >= 1 && conditions.adx < 25) {
            return PHASE_DISTRIBUTION;
        }

        return PHASE_RANGING;
    }
};

#endif // UT_ANALYSIS_MQH
