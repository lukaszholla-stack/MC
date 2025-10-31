//+------------------------------------------------------------------+
//|                                       UT_MarketStructure.mqh     |
//|                    Ultimate Trader EA - Market Structure Analysis |
//|                            Smart Money Concepts v1.0             |
//+------------------------------------------------------------------+
#property copyright "Ultimate Trader Development Team"
#property version   "1.00"

#ifndef UT_MARKETSTRUCTURE_MQH
#define UT_MARKETSTRUCTURE_MQH

//+------------------------------------------------------------------+
//|                         ENUMERATIONS                             |
//+------------------------------------------------------------------+
enum ENUM_STRUCTURE_EVENT {
    STRUCTURE_NONE,         // No event
    STRUCTURE_BOS_BULLISH,  // Break of Structure (bullish continuation)
    STRUCTURE_BOS_BEARISH,  // Break of Structure (bearish continuation)
    STRUCTURE_CHOCH_BULLISH,// Change of Character (potential reversal to bullish)
    STRUCTURE_CHOCH_BEARISH // Change of Character (potential reversal to bearish)
};

enum ENUM_MARKET_TREND {
    TREND_BEARISH = -1,
    TREND_NEUTRAL = 0,
    TREND_BULLISH = 1
};

//+------------------------------------------------------------------+
//|                          STRUCTURES                              |
//+------------------------------------------------------------------+

// Swing point structure
struct SSwingPoint {
    datetime    time;
    double      price;
    bool        isHigh;         // true = swing high, false = swing low
    int         barIndex;

    SSwingPoint() {
        time = 0;
        price = 0;
        isHigh = false;
        barIndex = -1;
    }
};

//+------------------------------------------------------------------+
//|                    MARKET STRUCTURE CLASS                        |
//+------------------------------------------------------------------+
class CMarketStructure {
private:
    // Configuration
    string          m_symbol;
    ENUM_TIMEFRAMES m_timeframe;
    int             m_swingStrength;      // Bars on each side for swing detection

    // State
    ENUM_MARKET_TREND m_currentTrend;
    SSwingPoint     m_lastSwingHigh;
    SSwingPoint     m_lastSwingLow;
    SSwingPoint     m_prevSwingHigh;
    SSwingPoint     m_prevSwingLow;

    // Recent events
    ENUM_STRUCTURE_EVENT m_lastEvent;
    datetime        m_lastEventTime;

    // Helper methods
    bool            IsSwingHigh(int bar, int strength);
    bool            IsSwingLow(int bar, int strength);
    void            UpdateSwingPoints();

public:
    // Constructor
    CMarketStructure();

    // Initialization
    bool            Initialize(string symbol, ENUM_TIMEFRAMES tf, int swingStrength = 3);

    // Main analysis
    void            Analyze();
    ENUM_STRUCTURE_EVENT DetectStructureChange();

    // Accessors
    ENUM_MARKET_TREND GetTrend() { return m_currentTrend; }
    ENUM_STRUCTURE_EVENT GetLastEvent() { return m_lastEvent; }
    SSwingPoint     GetLastSwingHigh() { return m_lastSwingHigh; }
    SSwingPoint     GetLastSwingLow() { return m_lastSwingLow; }

    // Query methods
    bool            IsBOSDetected();
    bool            IsCHoCHDetected();
    double          GetDistanceToLastSwingHigh(double currentPrice);
    double          GetDistanceToLastSwingLow(double currentPrice);

    // Debug
    void            PrintStructure();
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CMarketStructure::CMarketStructure() {
    m_symbol = "";
    m_timeframe = PERIOD_CURRENT;
    m_swingStrength = 3;
    m_currentTrend = TREND_NEUTRAL;
    m_lastEvent = STRUCTURE_NONE;
    m_lastEventTime = 0;
}

//+------------------------------------------------------------------+
//| Initialize                                                        |
//+------------------------------------------------------------------+
bool CMarketStructure::Initialize(string symbol, ENUM_TIMEFRAMES tf, int swingStrength = 3) {
    m_symbol = symbol;
    m_timeframe = tf;
    m_swingStrength = swingStrength;

    // Initialize swing points
    UpdateSwingPoints();

    Print("✅ Market Structure initialized: ", m_symbol, " ", EnumToString(m_timeframe));
    return true;
}

//+------------------------------------------------------------------+
//| Main analysis method                                              |
//+------------------------------------------------------------------+
void CMarketStructure::Analyze() {
    UpdateSwingPoints();
    m_lastEvent = DetectStructureChange();
}

//+------------------------------------------------------------------+
//| Update swing points                                               |
//+------------------------------------------------------------------+
void CMarketStructure::UpdateSwingPoints() {
    int bars = Bars(m_symbol, m_timeframe);
    if(bars < m_swingStrength * 2 + 10) return;

    // Scan for most recent swing high
    for(int i = m_swingStrength + 1; i < 50 && i < bars - m_swingStrength; i++) {
        if(IsSwingHigh(i, m_swingStrength)) {
            double high = iHigh(m_symbol, m_timeframe, i);
            datetime time = iTime(m_symbol, m_timeframe, i);

            // Only update if this is a new swing high
            if(time != m_lastSwingHigh.time) {
                m_prevSwingHigh = m_lastSwingHigh;
                m_lastSwingHigh.time = time;
                m_lastSwingHigh.price = high;
                m_lastSwingHigh.isHigh = true;
                m_lastSwingHigh.barIndex = i;
            }
            break;
        }
    }

    // Scan for most recent swing low
    for(int i = m_swingStrength + 1; i < 50 && i < bars - m_swingStrength; i++) {
        if(IsSwingLow(i, m_swingStrength)) {
            double low = iLow(m_symbol, m_timeframe, i);
            datetime time = iTime(m_symbol, m_timeframe, i);

            if(time != m_lastSwingLow.time) {
                m_prevSwingLow = m_lastSwingLow;
                m_lastSwingLow.time = time;
                m_lastSwingLow.price = low;
                m_lastSwingLow.isHigh = false;
                m_lastSwingLow.barIndex = i;
            }
            break;
        }
    }
}

//+------------------------------------------------------------------+
//| Check if bar is a swing high                                     |
//+------------------------------------------------------------------+
bool CMarketStructure::IsSwingHigh(int bar, int strength) {
    if(bar < strength || bar >= Bars(m_symbol, m_timeframe) - strength) {
        return false;
    }

    double centerHigh = iHigh(m_symbol, m_timeframe, bar);

    // Check bars to the left
    for(int i = 1; i <= strength; i++) {
        if(iHigh(m_symbol, m_timeframe, bar - i) >= centerHigh) {
            return false;
        }
    }

    // Check bars to the right
    for(int i = 1; i <= strength; i++) {
        if(iHigh(m_symbol, m_timeframe, bar + i) >= centerHigh) {
            return false;
        }
    }

    return true;
}

//+------------------------------------------------------------------+
//| Check if bar is a swing low                                      |
//+------------------------------------------------------------------+
bool CMarketStructure::IsSwingLow(int bar, int strength) {
    if(bar < strength || bar >= Bars(m_symbol, m_timeframe) - strength) {
        return false;
    }

    double centerLow = iLow(m_symbol, m_timeframe, bar);

    // Check bars to the left
    for(int i = 1; i <= strength; i++) {
        if(iLow(m_symbol, m_timeframe, bar - i) <= centerLow) {
            return false;
        }
    }

    // Check bars to the right
    for(int i = 1; i <= strength; i++) {
        if(iLow(m_symbol, m_timeframe, bar + i) <= centerLow) {
            return false;
        }
    }

    return true;
}

//+------------------------------------------------------------------+
//| Detect structure change (BOS or CHoCH)                           |
//+------------------------------------------------------------------+
ENUM_STRUCTURE_EVENT CMarketStructure::DetectStructureChange() {
    double currentPrice = SymbolInfoDouble(m_symbol, SYMBOL_BID);

    // BOS Bullish: In uptrend, break previous swing high
    if(m_currentTrend == TREND_BULLISH || m_currentTrend == TREND_NEUTRAL) {
        if(m_lastSwingHigh.price > 0 && currentPrice > m_lastSwingHigh.price) {
            if(m_currentTrend != TREND_BULLISH) {
                m_currentTrend = TREND_BULLISH;
                m_lastEventTime = TimeCurrent();
                return STRUCTURE_BOS_BULLISH;
            }
            // Continuation in uptrend
            m_lastEventTime = TimeCurrent();
            return STRUCTURE_BOS_BULLISH;
        }
    }

    // BOS Bearish: In downtrend, break previous swing low
    if(m_currentTrend == TREND_BEARISH || m_currentTrend == TREND_NEUTRAL) {
        if(m_lastSwingLow.price > 0 && currentPrice < m_lastSwingLow.price) {
            if(m_currentTrend != TREND_BEARISH) {
                m_currentTrend = TREND_BEARISH;
                m_lastEventTime = TimeCurrent();
                return STRUCTURE_BOS_BEARISH;
            }
            m_lastEventTime = TimeCurrent();
            return STRUCTURE_BOS_BEARISH;
        }
    }

    // CHoCH Bullish: In downtrend, break previous swing high (potential reversal)
    if(m_currentTrend == TREND_BEARISH) {
        if(m_lastSwingHigh.price > 0 && currentPrice > m_lastSwingHigh.price) {
            m_currentTrend = TREND_NEUTRAL; // Transition to neutral, waiting for confirmation
            m_lastEventTime = TimeCurrent();
            return STRUCTURE_CHOCH_BULLISH;
        }
    }

    // CHoCH Bearish: In uptrend, break previous swing low (potential reversal)
    if(m_currentTrend == TREND_BULLISH) {
        if(m_lastSwingLow.price > 0 && currentPrice < m_lastSwingLow.price) {
            m_currentTrend = TREND_NEUTRAL;
            m_lastEventTime = TimeCurrent();
            return STRUCTURE_CHOCH_BEARISH;
        }
    }

    return STRUCTURE_NONE;
}

//+------------------------------------------------------------------+
//| Check if BOS detected                                             |
//+------------------------------------------------------------------+
bool CMarketStructure::IsBOSDetected() {
    return (m_lastEvent == STRUCTURE_BOS_BULLISH || m_lastEvent == STRUCTURE_BOS_BEARISH);
}

//+------------------------------------------------------------------+
//| Check if CHoCH detected                                           |
//+------------------------------------------------------------------+
bool CMarketStructure::IsCHoCHDetected() {
    return (m_lastEvent == STRUCTURE_CHOCH_BULLISH || m_lastEvent == STRUCTURE_CHOCH_BEARISH);
}

//+------------------------------------------------------------------+
//| Get distance to last swing high                                  |
//+------------------------------------------------------------------+
double CMarketStructure::GetDistanceToLastSwingHigh(double currentPrice) {
    if(m_lastSwingHigh.price == 0) return DBL_MAX;
    return MathAbs(currentPrice - m_lastSwingHigh.price);
}

//+------------------------------------------------------------------+
//| Get distance to last swing low                                   |
//+------------------------------------------------------------------+
double CMarketStructure::GetDistanceToLastSwingLow(double currentPrice) {
    if(m_lastSwingLow.price == 0) return DBL_MAX;
    return MathAbs(currentPrice - m_lastSwingLow.price);
}

//+------------------------------------------------------------------+
//| Print structure for debugging                                    |
//+------------------------------------------------------------------+
void CMarketStructure::PrintStructure() {
    Print("🏗️ === MARKET STRUCTURE ===");
    Print("  Trend: ", EnumToString(m_currentTrend));
    Print("  Last Swing High: ", DoubleToString(m_lastSwingHigh.price, Digits()),
          " @ ", TimeToString(m_lastSwingHigh.time));
    Print("  Last Swing Low: ", DoubleToString(m_lastSwingLow.price, Digits()),
          " @ ", TimeToString(m_lastSwingLow.time));
    Print("  Last Event: ", EnumToString(m_lastEvent),
          " @ ", TimeToString(m_lastEventTime));
}

#endif // UT_MARKETSTRUCTURE_MQH
