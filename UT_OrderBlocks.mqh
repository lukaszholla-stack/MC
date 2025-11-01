//+------------------------------------------------------------------+
//|                                          UT_OrderBlocks.mqh      |
//|                    Ultimate Trader EA - Order Block Detection    |
//|                            Smart Money Concepts v1.0             |
//+------------------------------------------------------------------+
#property copyright "Ultimate Trader Development Team"
#property version   "1.00"

#ifndef UT_ORDERBLOCKS_MQH
#define UT_ORDERBLOCKS_MQH

//+------------------------------------------------------------------+
//|                         ENUMERATIONS                             |
//+------------------------------------------------------------------+
enum ENUM_OB_TYPE {
    OB_NONE,           // No order block
    OB_BULLISH,        // Bullish order block (last bearish candle before impulse up)
    OB_BEARISH         // Bearish order block (last bullish candle before impulse down)
};

enum ENUM_OB_STATUS {
    OB_ACTIVE,         // Active - awaiting retest
    OB_MITIGATED,      // Mitigated - price returned and reacted
    OB_BREACHED,       // Breached - price passed through without reaction
    OB_EXPIRED         // Expired - too old or too many touches
};

//+------------------------------------------------------------------+
//|                          STRUCTURES                              |
//+------------------------------------------------------------------+

// Order Block data structure
struct SOrderBlock {
    // Identification
    datetime    time;           // Time of OB candle
    int         barIndex;       // Bar index when detected
    ENUM_OB_TYPE type;          // Bullish or Bearish

    // Price levels
    double      priceHigh;      // Upper boundary of OB
    double      priceLow;       // Lower boundary of OB
    double      priceOpen;      // Open of OB candle
    double      priceClose;     // Close of OB candle

    // Quality metrics
    double      strength;       // 0.0-1.0 (based on impulse quality)
    double      impulseSize;    // Size of impulse that followed (in ATR)
    double      volumeRatio;    // Volume vs average

    // Status
    ENUM_OB_STATUS status;      // Current status
    int         touches;        // Number of retests
    datetime    lastTouch;      // Last time price entered zone
    bool        isRefined;      // Refined on lower TF

    // Context
    int         trendAlignment; // -1=counter-trend, 0=ranging, 1=with-trend
    bool        hasFVG;         // Has Fair Value Gap above/below
    bool        hadLiqSweep;    // Had liquidity sweep before formation

    // Constructor
    SOrderBlock() {
        Reset();
    }

    void Reset() {
        time = 0;
        barIndex = -1;
        type = OB_NONE;
        priceHigh = 0;
        priceLow = 0;
        priceOpen = 0;
        priceClose = 0;
        strength = 0;
        impulseSize = 0;
        volumeRatio = 1.0;
        status = OB_ACTIVE;
        touches = 0;
        lastTouch = 0;
        isRefined = false;
        trendAlignment = 0;
        hasFVG = false;
        hadLiqSweep = false;
    }
};

//+------------------------------------------------------------------+
//|                    ORDER BLOCK DETECTOR CLASS                    |
//+------------------------------------------------------------------+
class COrderBlockDetector {
private:
    // Configuration
    string          m_symbol;
    ENUM_TIMEFRAMES m_timeframe;
    int             m_maxOrderBlocks;
    int             m_lookbackBars;
    double          m_minImpulseATR;      // Minimum impulse size (% of ATR)
    double          m_minCandleBodyRatio; // Min body/total ratio for OB candle
    int             m_maxTouches;         // Max touches before expiry
    int             m_expiryBars;         // Bars until OB expires

    // Data
    SOrderBlock     m_orderBlocks[];      // Array of detected order blocks
    int             m_obCount;            // Current count of order blocks

    // Indicators
    int             m_atrHandle;
    double          m_atrBuffer[];
    int             m_volumeHandle;       // For volume analysis

    // Helper methods
    bool            IsImpulsiveCandle(int bar, double atr, ENUM_OB_TYPE &impulseType);
    double          CalculateCandleBody(int bar);
    double          CalculateCandleRange(int bar);
    double          GetCandleBodyRatio(int bar);
    bool            IsBullishCandle(int bar);
    bool            IsBearishCandle(int bar);
    double          CalculateImpulseStrength(int obBar, int impulseBar, double atr);
    double          CalculateVolumeRatio(int bar, int period = 20);
    void            UpdateOrderBlockStatus(double currentPrice);
    int             GetTrendAlignment(int bar);
    void            RemoveOldOrderBlocks();

public:
    // Constructor/Destructor
    COrderBlockDetector();
    ~COrderBlockDetector();

    // Initialization
    bool            Initialize(string symbol, ENUM_TIMEFRAMES tf, int maxOBs = 10);
    void            Deinitialize();

    // Configuration
    void            SetLookbackBars(int bars) { m_lookbackBars = bars; }
    void            SetMinImpulseATR(double value) { m_minImpulseATR = value; }
    void            SetMinBodyRatio(double value) { m_minCandleBodyRatio = value; }
    void            SetMaxTouches(int value) { m_maxTouches = value; }
    void            SetExpiryBars(int bars) { m_expiryBars = bars; }

    // Main detection method
    bool            ScanForOrderBlocks();
    bool            DetectOrderBlock(int startBar);

    // Order Block queries
    int             GetOrderBlockCount() { return m_obCount; }
    bool            GetOrderBlock(int index, SOrderBlock &outOB);
    bool            GetNearestOrderBlock(double price, SOrderBlock &outOB, ENUM_OB_TYPE type = OB_NONE);
    bool            IsPriceInOrderBlock(double price, int &obIndex);
    bool            IsPriceNearOrderBlock(double price, double thresholdPips, int &obIndex);

    // Order Block management
    void            MarkAsMitigated(int index);
    void            MarkAsBreached(int index);
    void            UpdateOrderBlocks(double currentPrice);
    void            ClearOrderBlocks();

    // Analysis
    double          GetOrderBlockStrength(int index);
    bool            IsOrderBlockValid(int index);
    int             CountActiveOrderBlocks(ENUM_OB_TYPE type = OB_NONE);

    // Debug/Visualization
    void            PrintOrderBlocks();
    void            DrawOrderBlocks();
    void            RemoveDrawings();
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
COrderBlockDetector::COrderBlockDetector() {
    m_symbol = "";
    m_timeframe = PERIOD_CURRENT;
    m_maxOrderBlocks = 10;
    m_lookbackBars = 50;
    m_minImpulseATR = 0.4;        // 40% of ATR (was 0.5 - too strict for crypto M15)
    m_minCandleBodyRatio = 0.5;   // 50% body (not too much wick)
    m_maxTouches = 3;
    m_expiryBars = 100;
    m_obCount = 0;
    m_atrHandle = INVALID_HANDLE;
    m_volumeHandle = INVALID_HANDLE;

    ArrayResize(m_orderBlocks, m_maxOrderBlocks);
    ArrayResize(m_atrBuffer, 50);
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
COrderBlockDetector::~COrderBlockDetector() {
    Deinitialize();
}

//+------------------------------------------------------------------+
//| Initialize detector                                               |
//+------------------------------------------------------------------+
bool COrderBlockDetector::Initialize(string symbol, ENUM_TIMEFRAMES tf, int maxOBs = 10) {
    m_symbol = symbol;
    m_timeframe = tf;
    m_maxOrderBlocks = maxOBs;

    // Initialize ATR indicator
    m_atrHandle = iATR(m_symbol, m_timeframe, 14);
    if(m_atrHandle == INVALID_HANDLE) {
        Print("❌ Failed to create ATR indicator for Order Block detector");
        return false;
    }

    // Initialize volume indicator (tick volume)
    m_volumeHandle = iVolumes(m_symbol, m_timeframe, VOLUME_TICK);
    if(m_volumeHandle == INVALID_HANDLE) {
        Print("⚠️ Failed to create Volume indicator for Order Block detector");
        // Not critical, continue without volume
    }

    ArrayResize(m_orderBlocks, m_maxOrderBlocks);
    m_obCount = 0;

    Print("✅ Order Block Detector initialized: ", m_symbol, " ", EnumToString(m_timeframe));
    return true;
}

//+------------------------------------------------------------------+
//| Deinitialize detector                                             |
//+------------------------------------------------------------------+
void COrderBlockDetector::Deinitialize() {
    if(m_atrHandle != INVALID_HANDLE) {
        IndicatorRelease(m_atrHandle);
        m_atrHandle = INVALID_HANDLE;
    }
    if(m_volumeHandle != INVALID_HANDLE) {
        IndicatorRelease(m_volumeHandle);
        m_volumeHandle = INVALID_HANDLE;
    }
    RemoveDrawings();
}

//+------------------------------------------------------------------+
//| Scan for order blocks in recent history                          |
//+------------------------------------------------------------------+
bool COrderBlockDetector::ScanForOrderBlocks() {
    // Get fresh ATR data
    if(CopyBuffer(m_atrHandle, 0, 0, 50, m_atrBuffer) <= 0) {
        Print("❌ Failed to copy ATR data for OB detection");
        return false;
    }

    double currentATR = m_atrBuffer[0];
    if(currentATR <= 0) {
        Print("❌ Invalid ATR value: ", currentATR);
        return false;
    }

    // Clear old order blocks
    RemoveOldOrderBlocks();

    // Scan recent bars for new order blocks
    for(int i = 2; i < m_lookbackBars && i < Bars(m_symbol, m_timeframe) - 3; i++) {
        DetectOrderBlock(i);
    }

    // Update status of existing OBs
    double currentPrice = SymbolInfoDouble(m_symbol, SYMBOL_BID);
    UpdateOrderBlockStatus(currentPrice);

    // Diagnostic logging (once per minute)
    static datetime lastDiagLog = 0;
    if(TimeCurrent() - lastDiagLog > 60) {
        int barsScanned = MathMin(m_lookbackBars, Bars(m_symbol, m_timeframe) - 3) - 2;
        Print("🔍 OB Scan: ", m_obCount, " OBs found, scanned ", barsScanned,
              " bars, ATR: ", DoubleToString(currentATR, 2),
              ", Min impulse: ", DoubleToString(m_minImpulseATR * currentATR, 2));
        lastDiagLog = TimeCurrent();
    }

    return true;
}

//+------------------------------------------------------------------+
//| Detect order block at specific bar                               |
//+------------------------------------------------------------------+
bool COrderBlockDetector::DetectOrderBlock(int startBar) {
    // Don't detect if we already have max OBs
    if(m_obCount >= m_maxOrderBlocks) {
        return false;
    }

    double atr = m_atrBuffer[0];
    if(atr <= 0) return false;

    // Check if next candle is impulsive
    ENUM_OB_TYPE impulseType;
    if(!IsImpulsiveCandle(startBar - 1, atr, impulseType)) {
        return false;
    }

    // Check if current candle (startBar) is opposite color
    bool isOBCandle = false;
    if(impulseType == OB_BULLISH && IsBearishCandle(startBar)) {
        isOBCandle = true;
    }
    else if(impulseType == OB_BEARISH && IsBullishCandle(startBar)) {
        isOBCandle = true;
    }

    if(!isOBCandle) return false;

    // Check candle quality (body ratio)
    double bodyRatio = GetCandleBodyRatio(startBar);
    if(bodyRatio < m_minCandleBodyRatio) {
        return false;
    }

    // Check if OB already exists at this location
    datetime obTime = iTime(m_symbol, m_timeframe, startBar);
    for(int i = 0; i < m_obCount; i++) {
        if(m_orderBlocks[i].time == obTime) {
            return false; // Already exists
        }
    }

    // Create new Order Block
    SOrderBlock newOB;
    newOB.time = obTime;
    newOB.barIndex = startBar;
    newOB.type = impulseType;
    newOB.priceHigh = iHigh(m_symbol, m_timeframe, startBar);
    newOB.priceLow = iLow(m_symbol, m_timeframe, startBar);
    newOB.priceOpen = iOpen(m_symbol, m_timeframe, startBar);
    newOB.priceClose = iClose(m_symbol, m_timeframe, startBar);

    // Calculate quality metrics
    newOB.strength = CalculateImpulseStrength(startBar, startBar - 1, atr);
    newOB.impulseSize = CalculateCandleRange(startBar - 1) / atr;
    newOB.volumeRatio = CalculateVolumeRatio(startBar - 1);

    // Context
    newOB.trendAlignment = GetTrendAlignment(startBar);
    newOB.status = OB_ACTIVE;
    newOB.touches = 0;

    // Add to array
    if(m_obCount < m_maxOrderBlocks) {
        m_orderBlocks[m_obCount] = newOB;
        m_obCount++;

        Print("📦 New Order Block detected: ",
              EnumToString(newOB.type),
              " @ ", TimeToString(newOB.time),
              ", Strength: ", DoubleToString(newOB.strength, 2),
              ", Price: ", DoubleToString((newOB.priceHigh + newOB.priceLow)/2, Digits()));

        return true;
    }

    return false;
}

//+------------------------------------------------------------------+
//| Check if candle is impulsive                                     |
//+------------------------------------------------------------------+
bool COrderBlockDetector::IsImpulsiveCandle(int bar, double atr, ENUM_OB_TYPE &impulseType) {
    double candleRange = CalculateCandleRange(bar);
    double bodySize = CalculateCandleBody(bar);
    double bodyRatio = (candleRange > 0) ? (bodySize / candleRange) : 0;

    // Impulse criteria:
    // 1. Range > m_minImpulseATR * ATR
    // 2. Body > 55% of range (not too much wick)
    double minRange = m_minImpulseATR * atr;

    if(candleRange < minRange) {
        // Diagnostic (log first few failures)
        static int failureCount = 0;
        if(failureCount < 3) {
            Print("⚠️ OB: Bar ", bar, " failed impulse test: range=", DoubleToString(candleRange, 2),
                  " < min=", DoubleToString(minRange, 2), " (ATR=", DoubleToString(atr, 2), ")");
            failureCount++;
        }
        return false;
    }

    if(bodyRatio < 0.55) {
        return false;
    }

    // Determine direction
    if(IsBullishCandle(bar)) {
        impulseType = OB_BULLISH;
        return true;
    }
    else if(IsBearishCandle(bar)) {
        impulseType = OB_BEARISH;
        return true;
    }

    return false;
}

//+------------------------------------------------------------------+
//| Helper methods                                                    |
//+------------------------------------------------------------------+
double COrderBlockDetector::CalculateCandleBody(int bar) {
    double open = iOpen(m_symbol, m_timeframe, bar);
    double close = iClose(m_symbol, m_timeframe, bar);
    return MathAbs(close - open);
}

double COrderBlockDetector::CalculateCandleRange(int bar) {
    double high = iHigh(m_symbol, m_timeframe, bar);
    double low = iLow(m_symbol, m_timeframe, bar);
    return high - low;
}

double COrderBlockDetector::GetCandleBodyRatio(int bar) {
    double range = CalculateCandleRange(bar);
    if(range == 0) return 0;
    return CalculateCandleBody(bar) / range;
}

bool COrderBlockDetector::IsBullishCandle(int bar) {
    return iClose(m_symbol, m_timeframe, bar) > iOpen(m_symbol, m_timeframe, bar);
}

bool COrderBlockDetector::IsBearishCandle(int bar) {
    return iClose(m_symbol, m_timeframe, bar) < iOpen(m_symbol, m_timeframe, bar);
}

//+------------------------------------------------------------------+
//| Calculate impulse strength (0.0-1.0)                             |
//+------------------------------------------------------------------+
double COrderBlockDetector::CalculateImpulseStrength(int obBar, int impulseBar, double atr) {
    double impulseSize = CalculateCandleRange(impulseBar);
    double obSize = CalculateCandleRange(obBar);
    double volumeRatio = CalculateVolumeRatio(impulseBar);

    // Normalize
    double sizeScore = MathMin(impulseSize / (2.0 * atr), 1.0);      // 0-1
    double contrastScore = MathMin(impulseSize / (obSize * 2), 1.0); // 0-1
    double volScore = MathMin(volumeRatio / 2.0, 1.0);               // 0-1

    // Weighted average
    double strength = (sizeScore * 0.5) + (contrastScore * 0.3) + (volScore * 0.2);

    return MathMax(0, MathMin(1.0, strength));
}

//+------------------------------------------------------------------+
//| Calculate volume ratio (current vs average)                      |
//+------------------------------------------------------------------+
double COrderBlockDetector::CalculateVolumeRatio(int bar, int period = 20) {
    if(m_volumeHandle == INVALID_HANDLE) return 1.0;

    double volumeBuffer[];
    ArrayResize(volumeBuffer, period + bar + 1);

    if(CopyBuffer(m_volumeHandle, 0, bar, period, volumeBuffer) <= 0) {
        return 1.0;
    }

    long currentVolume = (long)volumeBuffer[0];
    double avgVolume = 0;
    for(int i = 0; i < period; i++) {
        avgVolume += volumeBuffer[i];
    }
    avgVolume /= period;

    if(avgVolume == 0) return 1.0;
    return currentVolume / avgVolume;
}

//+------------------------------------------------------------------+
//| Get trend alignment (-1, 0, 1)                                   |
//+------------------------------------------------------------------+
int COrderBlockDetector::GetTrendAlignment(int bar) {
    // Simple EMA-based trend detection
    int emaHandle = iMA(m_symbol, m_timeframe, 50, 0, MODE_EMA, PRICE_CLOSE);
    if(emaHandle == INVALID_HANDLE) return 0;

    double emaBuffer[1];
    if(CopyBuffer(emaHandle, 0, bar, 1, emaBuffer) <= 0) {
        IndicatorRelease(emaHandle);
        return 0;
    }

    double closePrice = iClose(m_symbol, m_timeframe, bar);
    int trend = (closePrice > emaBuffer[0]) ? 1 : -1;

    IndicatorRelease(emaHandle);
    return trend;
}

//+------------------------------------------------------------------+
//| Update order block status based on current price                 |
//+------------------------------------------------------------------+
void COrderBlockDetector::UpdateOrderBlockStatus(double currentPrice) {
    for(int i = 0; i < m_obCount; i++) {
        if(m_orderBlocks[i].status == OB_ACTIVE) {
            // Check if price is in OB zone
            if(currentPrice >= m_orderBlocks[i].priceLow &&
               currentPrice <= m_orderBlocks[i].priceHigh) {
                m_orderBlocks[i].touches++;
                m_orderBlocks[i].lastTouch = TimeCurrent();

                // Too many touches = expired
                if(m_orderBlocks[i].touches >= m_maxTouches) {
                    m_orderBlocks[i].status = OB_EXPIRED;
                    Print("⏰ Order Block expired (too many touches): ", TimeToString(m_orderBlocks[i].time));
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Remove old/invalid order blocks                                  |
//+------------------------------------------------------------------+
void COrderBlockDetector::RemoveOldOrderBlocks() {
    datetime currentTime = TimeCurrent();
    int barsInPeriod = m_expiryBars;

    for(int i = m_obCount - 1; i >= 0; i--) {
        int barAge = iBarShift(m_symbol, m_timeframe, m_orderBlocks[i].time);

        // Remove if expired or too old
        if(m_orderBlocks[i].status == OB_EXPIRED ||
           m_orderBlocks[i].status == OB_BREACHED ||
           barAge > barsInPeriod) {

            // Shift array
            for(int j = i; j < m_obCount - 1; j++) {
                m_orderBlocks[j] = m_orderBlocks[j + 1];
            }
            m_obCount--;
        }
    }
}

//+------------------------------------------------------------------+
//| Get nearest order block to price                                 |
//+------------------------------------------------------------------+
bool COrderBlockDetector::GetNearestOrderBlock(double price, SOrderBlock &outOB, ENUM_OB_TYPE type) {
    double minDistance = DBL_MAX;
    int nearestIndex = -1;

    for(int i = 0; i < m_obCount; i++) {
        if(m_orderBlocks[i].status != OB_ACTIVE) continue;
        if(type != OB_NONE && m_orderBlocks[i].type != type) continue;

        double obMidPrice = (m_orderBlocks[i].priceHigh + m_orderBlocks[i].priceLow) / 2.0;
        double distance = MathAbs(price - obMidPrice);

        if(distance < minDistance) {
            minDistance = distance;
            nearestIndex = i;
        }
    }

    if(nearestIndex >= 0) {
        outOB = m_orderBlocks[nearestIndex];
        return true;
    }

    return false;
}

//+------------------------------------------------------------------+
//| Check if price is in order block                                 |
//+------------------------------------------------------------------+
bool COrderBlockDetector::IsPriceInOrderBlock(double price, int &obIndex) {
    for(int i = 0; i < m_obCount; i++) {
        if(m_orderBlocks[i].status != OB_ACTIVE) continue;

        if(price >= m_orderBlocks[i].priceLow && price <= m_orderBlocks[i].priceHigh) {
            obIndex = i;
            return true;
        }
    }

    obIndex = -1;
    return false;
}

//+------------------------------------------------------------------+
//| Print order blocks for debugging                                 |
//+------------------------------------------------------------------+
void COrderBlockDetector::PrintOrderBlocks() {
    Print("📦 === ORDER BLOCKS (", m_obCount, " active) ===");
    for(int i = 0; i < m_obCount; i++) {
        Print("  [", i, "] ",
              EnumToString(m_orderBlocks[i].type), " @ ",
              TimeToString(m_orderBlocks[i].time),
              " | Range: ", DoubleToString(m_orderBlocks[i].priceLow, Digits()),
              " - ", DoubleToString(m_orderBlocks[i].priceHigh, Digits()),
              " | Strength: ", DoubleToString(m_orderBlocks[i].strength, 2),
              " | Status: ", EnumToString(m_orderBlocks[i].status),
              " | Touches: ", m_orderBlocks[i].touches);
    }
}

//+------------------------------------------------------------------+
//| Access order block by index                                      |
//+------------------------------------------------------------------+
bool COrderBlockDetector::GetOrderBlock(int index, SOrderBlock &outOB) {
    if(index < 0 || index >= m_obCount) return false;
    outOB = m_orderBlocks[index];
    return true;
}

//+------------------------------------------------------------------+
//| Clear all order blocks                                           |
//+------------------------------------------------------------------+
void COrderBlockDetector::ClearOrderBlocks() {
    m_obCount = 0;
    RemoveDrawings();
}

//+------------------------------------------------------------------+
//| Remove graphical drawings                                        |
//+------------------------------------------------------------------+
void COrderBlockDetector::RemoveDrawings() {
    // Implementation for drawing removal (if visualization is added)
    ObjectsDeleteAll(0, "OB_");
}

#endif // UT_ORDERBLOCKS_MQH
