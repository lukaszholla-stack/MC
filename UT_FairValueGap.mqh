//+------------------------------------------------------------------+
//|                                          UT_FairValueGap.mqh     |
//|                    Ultimate Trader EA - Fair Value Gap Detection |
//|                            Smart Money Concepts v1.0             |
//+------------------------------------------------------------------+
#property copyright "Ultimate Trader Development Team"
#property version   "1.00"

#ifndef UT_FAIRVALUEGAP_MQH
#define UT_FAIRVALUEGAP_MQH

//+------------------------------------------------------------------+
//|                         ENUMERATIONS                             |
//+------------------------------------------------------------------+
enum ENUM_FVG_TYPE {
    FVG_NONE,           // No fair value gap
    FVG_BULLISH,        // Bullish FVG (gap up - inefficiency to downside)
    FVG_BEARISH         // Bearish FVG (gap down - inefficiency to upside)
};

enum ENUM_FVG_STATUS {
    FVG_UNFILLED,       // Not yet filled
    FVG_PARTIALLY_FILLED, // Partially filled
    FVG_FULLY_FILLED,   // Completely filled
    FVG_EXPIRED         // Too old, expired
};

//+------------------------------------------------------------------+
//|                          STRUCTURES                              |
//+------------------------------------------------------------------+

// Fair Value Gap data structure
struct SFairValueGap {
    // Identification
    datetime    time;           // Time of gap formation
    int         barIndex;       // Bar index when detected
    ENUM_FVG_TYPE type;         // Bullish or Bearish

    // Price levels
    double      gapHigh;        // Upper boundary of gap
    double      gapLow;         // Lower boundary of gap
    double      gapMid;         // Midpoint of gap
    double      gapSize;        // Size of gap (in pips)

    // Status
    ENUM_FVG_STATUS status;     // Current status
    double      filledPercent;  // 0-100% filled
    datetime    filledTime;     // Time when filled

    // Context
    bool        hasOrderBlock;  // Has OB above/below
    bool        inTrend;        // Formed during trend
    double      strength;       // 0-1.0 (based on gap size)

    // Constructor
    SFairValueGap() {
        Reset();
    }

    void Reset() {
        time = 0;
        barIndex = -1;
        type = FVG_NONE;
        gapHigh = 0;
        gapLow = 0;
        gapMid = 0;
        gapSize = 0;
        status = FVG_UNFILLED;
        filledPercent = 0;
        filledTime = 0;
        hasOrderBlock = false;
        inTrend = false;
        strength = 0;
    }
};

//+------------------------------------------------------------------+
//|                    FAIR VALUE GAP DETECTOR CLASS                 |
//+------------------------------------------------------------------+
class CFairValueGapDetector {
private:
    // Configuration
    string          m_symbol;
    ENUM_TIMEFRAMES m_timeframe;
    int             m_maxFVGs;
    int             m_lookbackBars;
    double          m_minGapPips;         // Minimum gap size in pips
    int             m_expiryBars;         // Bars until FVG expires

    // Data
    SFairValueGap   m_fairValueGaps[];    // Array of detected FVGs
    int             m_fvgCount;           // Current count of FVGs

    // Helper methods
    bool            DetectBullishFVG(int bar, SFairValueGap &fvg);
    bool            DetectBearishFVG(int bar, SFairValueGap &fvg);
    double          CalculateGapStrength(double gapSize, double atr);
    void            UpdateFVGStatus(double currentPrice);
    void            RemoveOldFVGs();
    double          PipsToPoints(double pips);
    double          PointsToPips(double points);

public:
    // Constructor/Destructor
    CFairValueGapDetector();
    ~CFairValueGapDetector();

    // Initialization
    bool            Initialize(string symbol, ENUM_TIMEFRAMES tf, int maxFVGs = 20);
    void            Deinitialize();

    // Configuration
    void            SetLookbackBars(int bars) { m_lookbackBars = bars; }
    void            SetMinGapPips(double pips) { m_minGapPips = pips; }
    void            SetExpiryBars(int bars) { m_expiryBars = bars; }

    // Main detection method
    bool            ScanForFairValueGaps();
    bool            DetectFairValueGap(int bar);

    // FVG queries
    int             GetFVGCount() { return m_fvgCount; }
    bool            GetFVG(int index, SFairValueGap &outFVG);
    bool            GetNearestFVG(double price, SFairValueGap &outFVG, ENUM_FVG_TYPE type = FVG_NONE);
    bool            IsPriceInFVG(double price, int &fvgIndex);
    bool            HasUnfilledFVG(ENUM_FVG_TYPE type, double &targetPrice);

    // FVG management
    void            UpdateFVGs(double currentPrice);
    void            ClearFVGs();

    // Analysis
    int             CountUnfilledFVGs(ENUM_FVG_TYPE type = FVG_NONE);
    bool            IsFVGValid(int index);

    // Debug
    void            PrintFVGs();
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CFairValueGapDetector::CFairValueGapDetector() {
    m_symbol = "";
    m_timeframe = PERIOD_CURRENT;
    m_maxFVGs = 20;
    m_lookbackBars = 50;
    m_minGapPips = 5.0;
    m_expiryBars = 100;
    m_fvgCount = 0;

    ArrayResize(m_fairValueGaps, m_maxFVGs);
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CFairValueGapDetector::~CFairValueGapDetector() {
    Deinitialize();
}

//+------------------------------------------------------------------+
//| Initialize detector                                               |
//+------------------------------------------------------------------+
bool CFairValueGapDetector::Initialize(string symbol, ENUM_TIMEFRAMES tf, int maxFVGs = 20) {
    m_symbol = symbol;
    m_timeframe = tf;
    m_maxFVGs = maxFVGs;

    ArrayResize(m_fairValueGaps, m_maxFVGs);
    m_fvgCount = 0;

    Print("✅ Fair Value Gap Detector initialized: ", m_symbol, " ", EnumToString(m_timeframe));
    return true;
}

//+------------------------------------------------------------------+
//| Deinitialize detector                                             |
//+------------------------------------------------------------------+
void CFairValueGapDetector::Deinitialize() {
    // Cleanup if needed
}

//+------------------------------------------------------------------+
//| Scan for fair value gaps in recent history                       |
//+------------------------------------------------------------------+
bool CFairValueGapDetector::ScanForFairValueGaps() {
    // Clear old FVGs
    RemoveOldFVGs();

    // Scan recent bars for new FVGs
    for(int i = 1; i < m_lookbackBars && i < Bars(m_symbol, m_timeframe) - 2; i++) {
        DetectFairValueGap(i);
    }

    // Update status of existing FVGs
    double currentPrice = SymbolInfoDouble(m_symbol, SYMBOL_BID);
    UpdateFVGStatus(currentPrice);

    return true;
}

//+------------------------------------------------------------------+
//| Detect fair value gap at specific bar                            |
//+------------------------------------------------------------------+
bool CFairValueGapDetector::DetectFairValueGap(int bar) {
    if(m_fvgCount >= m_maxFVGs) {
        return false;
    }

    if(bar < 1 || bar >= Bars(m_symbol, m_timeframe) - 1) {
        return false;
    }

    SFairValueGap fvg;

    // Check for bullish FVG
    if(DetectBullishFVG(bar, fvg)) {
        // Check if FVG already exists
        datetime fvgTime = iTime(m_symbol, m_timeframe, bar);
        bool exists = false;
        for(int i = 0; i < m_fvgCount; i++) {
            if(m_fairValueGaps[i].time == fvgTime && m_fairValueGaps[i].type == FVG_BULLISH) {
                exists = true;
                break;
            }
        }

        if(!exists && m_fvgCount < m_maxFVGs) {
            m_fairValueGaps[m_fvgCount] = fvg;
            m_fvgCount++;

            Print("📊 Bullish FVG detected @ ", TimeToString(fvg.time),
                  ", Gap: ", DoubleToString(fvg.gapLow, Digits()),
                  " - ", DoubleToString(fvg.gapHigh, Digits()),
                  ", Size: ", DoubleToString(fvg.gapSize, 1), " pips");

            return true;
        }
    }

    // Check for bearish FVG
    if(DetectBearishFVG(bar, fvg)) {
        datetime fvgTime = iTime(m_symbol, m_timeframe, bar);
        bool exists = false;
        for(int i = 0; i < m_fvgCount; i++) {
            if(m_fairValueGaps[i].time == fvgTime && m_fairValueGaps[i].type == FVG_BEARISH) {
                exists = true;
                break;
            }
        }

        if(!exists && m_fvgCount < m_maxFVGs) {
            m_fairValueGaps[m_fvgCount] = fvg;
            m_fvgCount++;

            Print("📊 Bearish FVG detected @ ", TimeToString(fvg.time),
                  ", Gap: ", DoubleToString(fvg.gapLow, Digits()),
                  " - ", DoubleToString(fvg.gapHigh, Digits()),
                  ", Size: ", DoubleToString(fvg.gapSize, 1), " pips");

            return true;
        }
    }

    return false;
}

//+------------------------------------------------------------------+
//| Detect bullish FVG                                                |
//| Condition: candle[i-1].low > candle[i+1].high                   |
//+------------------------------------------------------------------+
bool CFairValueGapDetector::DetectBullishFVG(int bar, SFairValueGap &fvg) {
    // Need 3 candles: bar-1, bar, bar+1
    if(bar < 1) return false;

    double prevLow = iLow(m_symbol, m_timeframe, bar - 1);
    double nextHigh = iHigh(m_symbol, m_timeframe, bar + 1);

    // Bullish FVG: previous candle's low > next candle's high
    if(prevLow > nextHigh) {
        double gapSize = prevLow - nextHigh;
        double gapSizePips = PointsToPips(gapSize);

        // Check minimum gap size
        if(gapSizePips < m_minGapPips) {
            return false;
        }

        // Create FVG
        fvg.Reset();
        fvg.time = iTime(m_symbol, m_timeframe, bar);
        fvg.barIndex = bar;
        fvg.type = FVG_BULLISH;
        fvg.gapHigh = prevLow;
        fvg.gapLow = nextHigh;
        fvg.gapMid = (fvg.gapHigh + fvg.gapLow) / 2.0;
        fvg.gapSize = gapSizePips;
        fvg.status = FVG_UNFILLED;
        fvg.strength = CalculateGapStrength(gapSize, 0); // TODO: pass ATR

        return true;
    }

    return false;
}

//+------------------------------------------------------------------+
//| Detect bearish FVG                                                |
//| Condition: candle[i-1].high < candle[i+1].low                   |
//+------------------------------------------------------------------+
bool CFairValueGapDetector::DetectBearishFVG(int bar, SFairValueGap &fvg) {
    if(bar < 1) return false;

    double prevHigh = iHigh(m_symbol, m_timeframe, bar - 1);
    double nextLow = iLow(m_symbol, m_timeframe, bar + 1);

    // Bearish FVG: previous candle's high < next candle's low
    if(prevHigh < nextLow) {
        double gapSize = nextLow - prevHigh;
        double gapSizePips = PointsToPips(gapSize);

        if(gapSizePips < m_minGapPips) {
            return false;
        }

        fvg.Reset();
        fvg.time = iTime(m_symbol, m_timeframe, bar);
        fvg.barIndex = bar;
        fvg.type = FVG_BEARISH;
        fvg.gapHigh = nextLow;
        fvg.gapLow = prevHigh;
        fvg.gapMid = (fvg.gapHigh + fvg.gapLow) / 2.0;
        fvg.gapSize = gapSizePips;
        fvg.status = FVG_UNFILLED;
        fvg.strength = CalculateGapStrength(gapSize, 0);

        return true;
    }

    return false;
}

//+------------------------------------------------------------------+
//| Calculate gap strength (0-1.0)                                   |
//+------------------------------------------------------------------+
double CFairValueGapDetector::CalculateGapStrength(double gapSize, double atr) {
    // Simple strength based on gap size
    // Larger gaps = stronger (more significant imbalance)
    double gapPips = PointsToPips(gapSize);

    if(gapPips < 10) return 0.3;
    else if(gapPips < 20) return 0.5;
    else if(gapPips < 30) return 0.7;
    else if(gapPips < 50) return 0.9;
    else return 1.0;
}

//+------------------------------------------------------------------+
//| Update FVG status based on current price                         |
//+------------------------------------------------------------------+
void CFairValueGapDetector::UpdateFVGStatus(double currentPrice) {
    for(int i = 0; i < m_fvgCount; i++) {
        if(m_fairValueGaps[i].status == FVG_FULLY_FILLED) continue;

        double gapSize = m_fairValueGaps[i].gapHigh - m_fairValueGaps[i].gapLow;

        // Check if price entered the gap
        if(currentPrice >= m_fairValueGaps[i].gapLow &&
           currentPrice <= m_fairValueGaps[i].gapHigh) {

            // Calculate filled percentage
            if(m_fairValueGaps[i].type == FVG_BULLISH) {
                // For bullish FVG, price fills from bottom (gapLow) to top (gapHigh)
                double filled = currentPrice - m_fairValueGaps[i].gapLow;
                m_fairValueGaps[i].filledPercent = (filled / gapSize) * 100.0;
            }
            else if(m_fairValueGaps[i].type == FVG_BEARISH) {
                // For bearish FVG, price fills from top (gapHigh) to bottom (gapLow)
                double filled = m_fairValueGaps[i].gapHigh - currentPrice;
                m_fairValueGaps[i].filledPercent = (filled / gapSize) * 100.0;
            }

            if(m_fairValueGaps[i].filledPercent >= 100.0) {
                m_fairValueGaps[i].status = FVG_FULLY_FILLED;
                m_fairValueGaps[i].filledTime = TimeCurrent();
            }
            else if(m_fairValueGaps[i].filledPercent > 0) {
                m_fairValueGaps[i].status = FVG_PARTIALLY_FILLED;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Remove old FVGs                                                   |
//+------------------------------------------------------------------+
void CFairValueGapDetector::RemoveOldFVGs() {
    for(int i = m_fvgCount - 1; i >= 0; i--) {
        int barAge = iBarShift(m_symbol, m_timeframe, m_fairValueGaps[i].time);

        // Remove if fully filled, expired, or too old
        if(m_fairValueGaps[i].status == FVG_FULLY_FILLED ||
           m_fairValueGaps[i].status == FVG_EXPIRED ||
           barAge > m_expiryBars) {

            // Shift array
            for(int j = i; j < m_fvgCount - 1; j++) {
                m_fairValueGaps[j] = m_fairValueGaps[j + 1];
            }
            m_fvgCount--;
        }
    }
}

//+------------------------------------------------------------------+
//| Get nearest FVG to price                                          |
//+------------------------------------------------------------------+
bool CFairValueGapDetector::GetNearestFVG(double price, SFairValueGap &outFVG, ENUM_FVG_TYPE type) {
    double minDistance = DBL_MAX;
    int nearestIndex = -1;

    for(int i = 0; i < m_fvgCount; i++) {
        if(m_fairValueGaps[i].status == FVG_FULLY_FILLED) continue;
        if(type != FVG_NONE && m_fairValueGaps[i].type != type) continue;

        double distance = MathAbs(price - m_fairValueGaps[i].gapMid);

        if(distance < minDistance) {
            minDistance = distance;
            nearestIndex = i;
        }
    }

    if(nearestIndex >= 0) {
        outFVG = m_fairValueGaps[nearestIndex];
        return true;
    }

    return false;
}

//+------------------------------------------------------------------+
//| Check if price is in FVG                                          |
//+------------------------------------------------------------------+
bool CFairValueGapDetector::IsPriceInFVG(double price, int &fvgIndex) {
    for(int i = 0; i < m_fvgCount; i++) {
        if(m_fairValueGaps[i].status == FVG_FULLY_FILLED) continue;

        if(price >= m_fairValueGaps[i].gapLow && price <= m_fairValueGaps[i].gapHigh) {
            fvgIndex = i;
            return true;
        }
    }

    fvgIndex = -1;
    return false;
}

//+------------------------------------------------------------------+
//| Check if there's an unfilled FVG (for TP targeting)              |
//+------------------------------------------------------------------+
bool CFairValueGapDetector::HasUnfilledFVG(ENUM_FVG_TYPE type, double &targetPrice) {
    for(int i = 0; i < m_fvgCount; i++) {
        if(m_fairValueGaps[i].type == type &&
           m_fairValueGaps[i].status == FVG_UNFILLED) {
            targetPrice = m_fairValueGaps[i].gapMid;
            return true;
        }
    }

    return false;
}

//+------------------------------------------------------------------+
//| Count unfilled FVGs                                               |
//+------------------------------------------------------------------+
int CFairValueGapDetector::CountUnfilledFVGs(ENUM_FVG_TYPE type = FVG_NONE) {
    int count = 0;
    for(int i = 0; i < m_fvgCount; i++) {
        if(m_fairValueGaps[i].status == FVG_UNFILLED) {
            if(type == FVG_NONE || m_fairValueGaps[i].type == type) {
                count++;
            }
        }
    }
    return count;
}

//+------------------------------------------------------------------+
//| Helper: Convert pips to points                                   |
//+------------------------------------------------------------------+
double CFairValueGapDetector::PipsToPoints(double pips) {
    int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
    double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);

    if(digits == 3 || digits == 5) {
        return pips * 10 * point;
    }
    return pips * point;
}

//+------------------------------------------------------------------+
//| Helper: Convert points to pips                                   |
//+------------------------------------------------------------------+
double CFairValueGapDetector::PointsToPips(double points) {
    int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
    double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);

    if(point == 0) return 0;

    if(digits == 3 || digits == 5) {
        return points / (10 * point);
    }
    return points / point;
}

//+------------------------------------------------------------------+
//| Print FVGs for debugging                                          |
//+------------------------------------------------------------------+
void CFairValueGapDetector::PrintFVGs() {
    Print("📊 === FAIR VALUE GAPS (", m_fvgCount, " active) ===");
    for(int i = 0; i < m_fvgCount; i++) {
        Print("  [", i, "] ",
              EnumToString(m_fairValueGaps[i].type), " @ ",
              TimeToString(m_fairValueGaps[i].time),
              " | Gap: ", DoubleToString(m_fairValueGaps[i].gapLow, Digits()),
              " - ", DoubleToString(m_fairValueGaps[i].gapHigh, Digits()),
              " | Size: ", DoubleToString(m_fairValueGaps[i].gapSize, 1), " pips",
              " | Status: ", EnumToString(m_fairValueGaps[i].status),
              " | Filled: ", DoubleToString(m_fairValueGaps[i].filledPercent, 1), "%");
    }
}

//+------------------------------------------------------------------+
//| Get FVG by index                                                  |
//+------------------------------------------------------------------+
bool CFairValueGapDetector::GetFVG(int index, SFairValueGap &outFVG) {
    if(index < 0 || index >= m_fvgCount) return false;
    outFVG = m_fairValueGaps[index];
    return true;
}

//+------------------------------------------------------------------+
//| Update all FVGs                                                   |
//+------------------------------------------------------------------+
void CFairValueGapDetector::UpdateFVGs(double currentPrice) {
    UpdateFVGStatus(currentPrice);
    RemoveOldFVGs();
}

//+------------------------------------------------------------------+
//| Clear all FVGs                                                    |
//+------------------------------------------------------------------+
void CFairValueGapDetector::ClearFVGs() {
    m_fvgCount = 0;
}

#endif // UT_FAIRVALUEGAP_MQH
