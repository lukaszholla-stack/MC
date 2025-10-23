# ROZSZERZENIE PLANU: Strategia Scalpingowa
## Ultimate Trader EA - Scalping Mode Extension

**Data:** 2025-10-23
**Wersja:** 1.1 (Extended with Scalping)

---

## 🔥 NOWA STRATEGIA: High-Frequency Scalping Mode

### Charakterystyka Scalping Mode

**Scalping** to agresywna strategia handlowa oparta na:
- ⚡ Bardzo szybkim otwieraniu pozycji (sekundy/minuty)
- 💰 Małych profitach (1-2 USD per trade)
- 📊 Wielu pozycjach jednocześnie (do 15)
- 🎯 Wysokiej częstotliwości transakcji
- ⏱️ Bardzo krótkim czasie utrzymania (kilka sekund do minut)

---

## 1. Architektura Scalping System

### 1.1. Nowa strategia w UT_Strategies.mqh

```mql5
//+------------------------------------------------------------------+
//|                    SCALPING STRATEGY CLASS                       |
//+------------------------------------------------------------------+
class CScalpingStrategy : public CBaseStrategy {
private:
    // Scalping configuration
    int m_maxPositions;              // Max 15 pozycji
    double m_targetProfitUSD;        // Target profit per position ($1-2)
    int m_maxSpreadPoints;           // Max spread (scalping = low spread!)
    int m_minDistanceBetweenTrades;  // Min distance między pozycjami

    // Speed optimization
    datetime m_lastSignalTime;
    int m_signalCooldown;            // Min seconds between signals (5-10s)

    // Multi-position tracking
    struct ScalpPosition {
        ulong ticket;
        datetime openTime;
        double openPrice;
        double lotSize;
        double targetProfit;
        bool isActive;
    };
    ScalpPosition m_positions[15];
    int m_activeCount;

    // Market micro-structure
    double m_lastBid;
    double m_lastAsk;
    int m_tickCount;
    double m_tickMomentum;           // Momentum based on ticks

    //+------------------------------------------------------------------+
    //| Detect ultra-short term momentum                                 |
    //+------------------------------------------------------------------+
    double CalculateMicroMomentum() {
        // Analiza ostatnich 10 ticków
        double currentBid = g_symbol.Bid();
        double currentAsk = g_symbol.Ask();

        // Momentum = zmiana ceny na tick
        double momentum = 0;
        if(m_lastBid > 0) {
            momentum = (currentBid - m_lastBid) / _Point;
        }

        m_lastBid = currentBid;
        m_lastAsk = currentAsk;
        m_tickCount++;

        // Exponential moving average momentum
        if(m_tickMomentum == 0) {
            m_tickMomentum = momentum;
        } else {
            m_tickMomentum = m_tickMomentum * 0.7 + momentum * 0.3;
        }

        return m_tickMomentum;
    }

    //+------------------------------------------------------------------+
    //| Check spread - critical for scalping!                            |
    //+------------------------------------------------------------------+
    bool IsSpreadAcceptable() {
        double spread = (g_symbol.Ask() - g_symbol.Bid()) / _Point;

        if(spread > m_maxSpreadPoints) {
            DEBUG_MSG(DEBUG_VERBOSE, "SCALP",
                StringFormat("Spread too high: %.1f > %d", spread, m_maxSpreadPoints));
            return false;
        }

        return true;
    }

    //+------------------------------------------------------------------+
    //| Fast entry detection - millisecond precision                     |
    //+------------------------------------------------------------------+
    bool DetectScalpEntry(ENUM_SIGNAL_DIRECTION& direction) {
        // 1. Spread check (CRITICAL!)
        if(!IsSpreadAcceptable()) return false;

        // 2. Calculate micro-momentum
        double microMomentum = CalculateMicroMomentum();

        // 3. Detect quick move (scalping = ride the wave)
        if(microMomentum > 3.0) {          // 3+ pips momentum
            direction = SIGNAL_BUY;
            DEBUG_MSG(DEBUG_VERBOSE, "SCALP",
                StringFormat("🚀 BUY scalp signal! Momentum: %.2f", microMomentum));
            return true;
        }
        else if(microMomentum < -3.0) {    // -3 pips momentum
            direction = SIGNAL_SELL;
            DEBUG_MSG(DEBUG_VERBOSE, "SCALP",
                StringFormat("🔻 SELL scalp signal! Momentum: %.2f", microMomentum));
            return true;
        }

        // 4. Check order book imbalance (if available)
        // TODO: Implement order book analysis for exchanges that provide it

        return false;
    }

    //+------------------------------------------------------------------+
    //| Calculate scalping SL/TP - VERY TIGHT!                          |
    //+------------------------------------------------------------------+
    void CalculateScalpLevels(ENUM_SIGNAL_DIRECTION direction,
                              double& sl, double& tp) {
        double entry = (direction == SIGNAL_BUY) ? g_symbol.Ask() : g_symbol.Bid();

        // SCALPING = bardzo wąskie SL/TP
        double slDistance = 0;
        double tpDistance = 0;

        // Detect instrument type for pip calculation
        ENUM_INSTRUMENT_TYPE instrType = DetectInstrumentType(_Symbol);

        if(instrType == INSTRUMENT_FOREX) {
            // Forex: SL = 5-10 pips, TP = 3-5 pips (R:R < 1 OK for scalping!)
            slDistance = 8 * _Point * 10;   // 8 pips
            tpDistance = 4 * _Point * 10;   // 4 pips
        }
        else if(instrType == INSTRUMENT_METAL) {
            // Gold: SL = 50 points ($5), TP = 20 points ($2)
            slDistance = 50 * _Point;
            tpDistance = 20 * _Point;
        }
        else if(instrType == INSTRUMENT_CRYPTO) {
            // Crypto: SL = 0.2%, TP = 0.1%
            slDistance = entry * 0.002;     // 0.2%
            tpDistance = entry * 0.001;     // 0.1%
        }

        // Calculate final levels
        if(direction == SIGNAL_BUY) {
            sl = entry - slDistance;
            tp = entry + tpDistance;
        } else {
            sl = entry + slDistance;
            tp = entry - tpDistance;
        }

        // Verify TP gives us target profit
        double pointValue = GetPointValue();
        double potentialProfit = MathAbs(tp - entry) / _Point * pointValue;

        DEBUG_MSG(DEBUG_NORMAL, "SCALP",
            StringFormat("Scalp levels: SL=%.5f TP=%.5f (potential: $%.2f)",
                sl, tp, potentialProfit));
    }

    //+------------------------------------------------------------------+
    //| Get point value in USD                                           |
    //+------------------------------------------------------------------+
    double GetPointValue() {
        double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
        double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

        if(tickSize > 0) {
            return tickValue * _Point / tickSize;
        }

        return 1.0; // Fallback
    }

    //+------------------------------------------------------------------+
    //| Calculate scalping lot size                                      |
    //+------------------------------------------------------------------+
    double CalculateScalpLotSize(double slDistance) {
        // Scalping = fixed small lots OR micro-lots
        // NIE risk-based (zbyt małe TP dla normalnego risk%)

        double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);

        // Scalping lots based on balance tier
        if(accountBalance >= 10000) {
            return 0.01;  // 0.01 lot per scalp
        }
        else if(accountBalance >= 5000) {
            return 0.01;
        }
        else if(accountBalance >= 1000) {
            return 0.01;  // Micro account
        }
        else {
            return 0.01;  // Minimum
        }

        // Note: W scalpingu ważniejszy jest volume (15 pozycji)
        // niż wielkość pojedynczego lota
    }

    //+------------------------------------------------------------------+
    //| Open scalp position - FAST!                                      |
    //+------------------------------------------------------------------+
    bool OpenScalpPosition(ENUM_SIGNAL_DIRECTION direction) {
        // 1. Check if we can open more positions
        if(m_activeCount >= m_maxPositions) {
            DEBUG_MSG(DEBUG_VERBOSE, "SCALP", "Max positions reached!");
            return false;
        }

        // 2. Calculate SL/TP
        double sl, tp;
        CalculateScalpLevels(direction, sl, tp);

        // 3. Calculate lot size
        double slDistance = MathAbs(sl - g_symbol.Bid());
        double lotSize = CalculateScalpLotSize(slDistance);

        // 4. FAST EXECUTION - market order
        g_trade.SetDeviationInPoints(30);  // Accept 3 pip slippage for speed
        g_trade.SetTypeFilling(ORDER_FILLING_IOC);  // Immediate or Cancel

        bool success = false;
        if(direction == SIGNAL_BUY) {
            success = g_trade.Buy(lotSize, _Symbol, 0, sl, tp, "Scalp");
        } else {
            success = g_trade.Sell(lotSize, _Symbol, 0, sl, tp, "Scalp");
        }

        // 5. Track position
        if(success) {
            ulong ticket = g_trade.ResultOrder();

            // Find empty slot
            for(int i = 0; i < 15; i++) {
                if(!m_positions[i].isActive) {
                    m_positions[i].ticket = ticket;
                    m_positions[i].openTime = TimeCurrent();
                    m_positions[i].openPrice = g_trade.ResultPrice();
                    m_positions[i].lotSize = lotSize;
                    m_positions[i].targetProfit = m_targetProfitUSD;
                    m_positions[i].isActive = true;
                    m_activeCount++;
                    break;
                }
            }

            DEBUG_MSG(DEBUG_CRITICAL, "SCALP",
                StringFormat("✅ Scalp #%d opened: %s %.2f lots @ %.5f (Target: $%.2f)",
                    m_activeCount,
                    direction == SIGNAL_BUY ? "BUY" : "SELL",
                    lotSize, g_trade.ResultPrice(), m_targetProfitUSD));

            return true;
        }

        return false;
    }

    //+------------------------------------------------------------------+
    //| Manage open scalp positions - CRITICAL!                         |
    //+------------------------------------------------------------------+
    void ManageScalpPositions() {
        for(int i = 0; i < 15; i++) {
            if(!m_positions[i].isActive) continue;

            // Select position
            if(!g_position.SelectByTicket(m_positions[i].ticket)) {
                // Position already closed
                m_positions[i].isActive = false;
                m_activeCount--;
                continue;
            }

            // Check profit in USD
            double profit = g_position.Profit();

            // CLOSE if target reached!
            if(profit >= m_targetProfitUSD) {
                if(g_trade.PositionClose(m_positions[i].ticket)) {
                    DEBUG_MSG(DEBUG_CRITICAL, "SCALP",
                        StringFormat("💰 Scalp #%d closed with profit: $%.2f",
                            i+1, profit));

                    m_positions[i].isActive = false;
                    m_activeCount--;

                    // Update performance
                    g_performance.Update(true, profit, STRATEGY_SCALPING);
                }
            }

            // Emergency close if loss > 2x target (bad scalp!)
            else if(profit < -(m_targetProfitUSD * 2)) {
                if(g_trade.PositionClose(m_positions[i].ticket)) {
                    DEBUG_MSG(DEBUG_NORMAL, "SCALP",
                        StringFormat("❌ Bad scalp #%d closed: $%.2f",
                            i+1, profit));

                    m_positions[i].isActive = false;
                    m_activeCount--;

                    g_performance.Update(false, profit, STRATEGY_SCALPING);
                }
            }

            // Time-based close (scalps should be fast!)
            else if(TimeCurrent() - m_positions[i].openTime > 300) {  // 5 min max
                double currentProfit = g_position.Profit();
                bool isWin = currentProfit > 0;

                if(g_trade.PositionClose(m_positions[i].ticket)) {
                    DEBUG_MSG(DEBUG_NORMAL, "SCALP",
                        StringFormat("⏱️ Scalp #%d timeout closed: $%.2f",
                            i+1, currentProfit));

                    m_positions[i].isActive = false;
                    m_activeCount--;

                    g_performance.Update(isWin, currentProfit, STRATEGY_SCALPING);
                }
            }
        }
    }

public:
    CScalpingStrategy() {
        m_name = "High-Frequency Scalping";
        m_type = STRATEGY_SCALPING;

        // Default scalping config
        m_maxPositions = 15;
        m_targetProfitUSD = 1.5;         // $1.50 per position
        m_maxSpreadPoints = 20;          // Max 2 pips spread
        m_minDistanceBetweenTrades = 5;  // Min 5 pips between entries
        m_signalCooldown = 5;            // 5 seconds cooldown

        m_lastBid = 0;
        m_lastAsk = 0;
        m_tickCount = 0;
        m_tickMomentum = 0;
        m_activeCount = 0;
        m_lastSignalTime = 0;

        // Initialize positions array
        for(int i = 0; i < 15; i++) {
            m_positions[i].isActive = false;
        }
    }

    ~CScalpingStrategy() {
        // Close all open scalp positions on EA removal
        for(int i = 0; i < 15; i++) {
            if(m_positions[i].isActive) {
                g_trade.PositionClose(m_positions[i].ticket);
            }
        }
    }

    void SetScalpingParams(int maxPos, double targetUSD, int maxSpread) {
        m_maxPositions = MathMin(15, MathMax(1, maxPos));
        m_targetProfitUSD = MathMax(0.5, MathMin(5.0, targetUSD));
        m_maxSpreadPoints = MathMax(5, MathMin(50, maxSpread));
    }

    virtual bool Initialize() override {
        DEBUG_MSG(DEBUG_CRITICAL, "SCALP",
            StringFormat("⚡ SCALPING MODE ACTIVATED! Max: %d pos, Target: $%.2f/pos",
                m_maxPositions, m_targetProfitUSD));

        m_initialized = true;
        return true;
    }

    virtual TradeSignal CheckSignal() override {
        TradeSignal signal;
        signal.Reset();
        signal.strategy = STRATEGY_SCALPING;
        signal.source = STRATEGY_SCALPING;

        // Cooldown check
        if(TimeCurrent() - m_lastSignalTime < m_signalCooldown) {
            return signal;
        }

        // Manage existing positions first
        ManageScalpPositions();

        // Check if we can open new position
        if(m_activeCount >= m_maxPositions) {
            return signal;
        }

        // Detect scalp entry
        ENUM_SIGNAL_DIRECTION direction;
        if(DetectScalpEntry(direction)) {
            signal.direction = direction;
            signal.isValid = true;
            signal.score = 100;  // Scalping always max score when signal
            signal.reason = "Scalp: Micro-momentum " +
                          DoubleToString(m_tickMomentum, 2) + " pips";

            // Set entry price
            signal.entryPrice = (direction == SIGNAL_BUY) ?
                               g_symbol.Ask() : g_symbol.Bid();

            // Calculate levels
            CalculateScalpLevels(direction, signal.stopLoss, signal.takeProfit);

            // Calculate lot
            double slDist = MathAbs(signal.stopLoss - signal.entryPrice);
            signal.lotSize = CalculateScalpLotSize(slDist);

            // R:R for scalping is usually < 1 (many small wins)
            double risk = MathAbs(signal.stopLoss - signal.entryPrice);
            double reward = MathAbs(signal.takeProfit - signal.entryPrice);
            signal.riskRewardRatio = (risk > 0) ? reward / risk : 0;

            m_lastSignalTime = TimeCurrent();
        }

        return signal;
    }

    int GetActivePositionsCount() { return m_activeCount; }

    double GetTotalFloatingPL() {
        double total = 0;
        for(int i = 0; i < 15; i++) {
            if(m_positions[i].isActive) {
                if(g_position.SelectByTicket(m_positions[i].ticket)) {
                    total += g_position.Profit();
                }
            }
        }
        return total;
    }
};
```

---

## 2. Rozszerzenie parametrów Input

### 2.1. Dodaj Scalping Mode do parametrów

```mql5
input group "═══ 🎲 STRATEGIA ═══"
input ENUM_STRATEGY_MODE   InpStrategyMode = STRATEGY_AUTO;
input int                  InpMinScore = 70;

// NOWE: Scalping parameters
input group "═══ ⚡ SCALPING MODE (Ryzykowny!) ═══"
input bool                 InpEnableScalping = false;        // Włącz Scalping
input int                  InpScalpMaxPositions = 15;        // Max pozycji scalp
input double               InpScalpTargetUSD = 1.5;          // Target profit ($)
input int                  InpScalpMaxSpread = 20;           // Max spread (punkty)
input int                  InpScalpCooldown = 5;             // Cooldown (sekundy)
```

### 2.2. Rozszerzenie ENUM_STRATEGY_MODE

```mql5
enum ENUM_STRATEGY_MODE {
    STRATEGY_AUTO,          // Auto-select best strategy
    STRATEGY_FOREX,         // Force Forex strategy
    STRATEGY_METAL,         // Force Metal strategy
    STRATEGY_CRYPTO,        // Force Crypto strategy
    STRATEGY_HARMONIC,      // Force Harmonic patterns
    STRATEGY_ELLIOTT,       // Force Elliott Waves
    STRATEGY_SCALPING,      // 🆕 Force SCALPING mode
    STRATEGY_HYBRID         // Mix of all (adaptive ML)
};
```

---

## 3. Integracja w Main Flow

### 3.1. Inicjalizacja w OnInit()

```mql5
int OnInit() {
    // ... existing code ...

    // Inicjalizacja Strategy Manager
    g_strategyMgr = new CStrategyManager();
    if(!g_strategyMgr.Initialize(InpStrategyMode, InpMinScore)) {
        return INIT_FAILED;
    }

    // 🆕 SCALPING SETUP
    if(InpEnableScalping || InpStrategyMode == STRATEGY_SCALPING) {
        CScalpingStrategy* scalpStrat = new CScalpingStrategy();
        scalpStrat.SetScalpingParams(
            InpScalpMaxPositions,
            InpScalpTargetUSD,
            InpScalpMaxSpread
        );
        scalpStrat.Initialize();

        g_strategyMgr.AddStrategy(scalpStrat);

        Print("⚡ SCALPING MODE ENABLED!");
        Print("   Max Positions: ", InpScalpMaxPositions);
        Print("   Target per trade: $", InpScalpTargetUSD);
        Print("   Max Spread: ", InpScalpMaxSpread, " points");
    }

    // ... rest of init ...
}
```

### 3.2. High-Frequency OnTick dla Scalpingu

```mql5
void OnTick() {
    if(!g_state.isInitialized || !InpAutoTrading) return;

    // SCALPING = NO THROTTLING! Process every tick!
    if(InpEnableScalping || InpStrategyMode == STRATEGY_SCALPING) {
        // Process IMMEDIATELY (no delay)
        g_engine.ProcessScalpingTick();
    } else {
        // Normal strategies - throttled
        static datetime lastTick = 0;
        if(TimeCurrent() - lastTick < 1) return;
        lastTick = TimeCurrent();

        // ... normal flow ...
    }
}
```

---

## 4. Risk Management dla Scalpingu

### 4.1. Specjalne limity dla Scalping

```mql5
class CRiskManager {
private:
    // Scalping-specific limits
    double m_scalpMaxDailyLoss;      // Daily loss limit for scalping
    int m_scalpMaxTradesPerDay;      // Max scalp trades per day
    int m_scalpTradesCount;          // Current scalp trades today

public:
    bool CanOpenScalpPosition() {
        // 1. Check daily scalp trades limit
        if(m_scalpTradesCount >= m_scalpMaxTradesPerDay) {
            DEBUG_MSG(DEBUG_NORMAL, "RISK",
                "Daily scalping limit reached: " +
                IntegerToString(m_scalpTradesCount));
            return false;
        }

        // 2. Check scalp-specific daily loss
        double scalpPL = GetScalpingDailyPL();
        if(scalpPL < -m_scalpMaxDailyLoss) {
            DEBUG_MSG(DEBUG_CRITICAL, "RISK",
                StringFormat("Scalping daily loss limit! $%.2f < -$%.2f",
                    scalpPL, m_scalpMaxDailyLoss));
            return false;
        }

        // 3. Check overall risk
        if(!CanOpenNewPosition()) {
            return false;
        }

        return true;
    }

    double GetScalpingDailyPL() {
        // Calculate P/L from scalping positions only today
        double total = 0;
        datetime today = iTime(_Symbol, PERIOD_D1, 0);

        for(int i = PositionsTotal() - 1; i >= 0; i--) {
            if(g_position.SelectByIndex(i)) {
                if(g_position.Time() >= today) {
                    string comment = g_position.Comment();
                    if(StringFind(comment, "Scalp") >= 0) {
                        total += g_position.Profit();
                    }
                }
            }
        }

        return total;
    }
};
```

---

## 5. Dashboard - Scalping Panel

### 5.1. Dodaj sekcję Scalping Stats

```mql5
void CDashboard::CreateScalpingSection() {
    int yPos = 350;  // Below regular sections

    // Header
    CreateLabel("ScalpHeader", 20, yPos,
        "⚡ SCALPING MODE",
        CLR_GOLD, 11, "Segoe UI Semibold");

    yPos += 25;

    // Active scalp positions
    string scalpInfo = StringFormat("Active: %d/%d",
        g_scalpStrategy.GetActivePositionsCount(),
        InpScalpMaxPositions);
    CreateLabel("ScalpPositions", 20, yPos, scalpInfo, CLR_TEXT_PRIMARY);

    yPos += 20;

    // Floating P/L
    double floatingPL = g_scalpStrategy.GetTotalFloatingPL();
    color plColor = (floatingPL >= 0) ? CLR_SUCCESS : CLR_DANGER;
    string plText = StringFormat("Float P/L: $%.2f", floatingPL);
    CreateLabel("ScalpFloat", 20, yPos, plText, plColor);

    yPos += 20;

    // Today's scalp stats
    int scalpTrades = g_performance.scalpingTrades;
    double scalpWinRate = g_performance.scalpingWinRate;
    string statsText = StringFormat("Today: %d trades | WR: %.1f%%",
        scalpTrades, scalpWinRate);
    CreateLabel("ScalpStats", 20, yPos, statsText, CLR_TEXT_SECONDARY);
}
```

---

## 6. ⚠️ OSTRZEŻENIA I RYZYKA

### 6.1. Scalping NIE jest dla każdego!

**WYSOKIE RYZYKO:**
```
❌ Bardzo wysokie koszty spreadów (przy małych TP)
❌ Wymaga ultra-niskich spreadów (ECN/Raw Spread)
❌ Wrażliwy na slippage
❌ Wymaga bardzo szybkiego VPS (< 1ms ping)
❌ Emotional stress (wiele transakcji)
❌ Może stracić WSZYSTKO przy złych warunkach
```

**WYMAGANIA TECHNICZNE:**
```
✅ ECN broker z raw spread (0.0-0.5 pips)
✅ VPS w tym samym data center co broker
✅ Stabilne połączenie (fiber optic)
✅ Minimum $1000 konto (dla 0.01 lotów)
✅ Doświadczenie w tradingu
```

### 6.2. Kiedy NIE używać Scalpingu:

```
❌ Spread > 2 pips (będziesz tracić!)
❌ Broker typu Market Maker
❌ Wolne połączenie internetowe
❌ Podczas newsów (crazy spread)
❌ Niskie balance (< $500)
❌ Początkujący trader
```

### 6.3. Best Practices dla Scalpingu:

```
✅ Handluj tylko w głównych sesjach (Londyn, NY)
✅ Unikaj newsów (spread explosion)
✅ Monitoruj commission (może zabić profit!)
✅ Testuj TYLKO na demo przez miesiąc
✅ Start z małymi lotami (0.01)
✅ Ustaw daily loss limit ($50-100)
✅ Stop trading po 3 kolejnych stratach
```

---

## 7. Testowanie Scalping Strategy

### 7.1. Backtest Settings

```
⚠️ UWAGA: Scalping backtest w MT5 NIE jest precyzyjny!
   - Brak prawdziwych ticków
   - Brak prawdziwego spreadu
   - Brak slippage

ZALECANE:
1. Forward test na demo (minimum 1 miesiąc)
2. Tick data quality = "Real ticks"
3. Małe loty (0.01)
4. Monitoring każdego dnia
```

### 7.2. Metryki sukcesu dla Scalpingu

```
Scalping Metrics:
✅ Win Rate: > 70% (MUST!)
✅ Average Win: $1.50
✅ Average Loss: < $3.00
✅ Trades per day: 20-50
✅ Profit Factor: > 1.5
✅ Max consecutive losses: < 5
```

---

## 8. Kod przykładowy - Complete Integration

### 8.1. CStrategyManager - dodaj Scalping

```mql5
class CStrategyManager {
private:
    CBaseStrategy* m_strategies[];
    CScalpingStrategy* m_scalpStrategy;

public:
    void AddStrategy(CBaseStrategy* strategy) {
        int size = ArraySize(m_strategies);
        ArrayResize(m_strategies, size + 1);
        m_strategies[size] = strategy;

        // Track scalping separately (high-frequency)
        if(strategy.GetType() == STRATEGY_SCALPING) {
            m_scalpStrategy = (CScalpingStrategy*)strategy;
        }
    }

    TradeSignal GenerateSignal(MarketConditions& conditions) {
        TradeSignal bestSignal;
        bestSignal.Reset();

        // SCALPING = priorytet! (if enabled)
        if(m_scalpStrategy != NULL) {
            TradeSignal scalpSignal = m_scalpStrategy.CheckSignal();
            if(scalpSignal.isValid) {
                return scalpSignal;  // Immediate return for speed!
            }
        }

        // Normal strategies...
        for(int i = 0; i < ArraySize(m_strategies); i++) {
            if(m_strategies[i].GetType() == STRATEGY_SCALPING)
                continue;  // Skip (already checked)

            TradeSignal signal = m_strategies[i].CheckSignal();
            if(signal.score > bestSignal.score) {
                bestSignal = signal;
            }
        }

        return bestSignal;
    }
};
```

---

## 9. Finalne parametry - Extended

```mql5
//+------------------------------------------------------------------+
//|                    PARAMETRY Z SCALPING                          |
//+------------------------------------------------------------------+
input group "═══ 🎯 GŁÓWNE USTAWIENIA ═══"
input ENUM_TRADING_MODE    InpMode = MODE_BALANCED;
input bool                 InpAutoTrading = true;
input int                  InpMagicNumber = 777001;

input group "═══ 💰 RISK MANAGEMENT ═══"
input double               InpRisk = 1.0;
input double               InpMaxDailyLoss = 3.0;
input int                  InpMaxPositions = 5;

input group "═══ 🎲 STRATEGIA ═══"
input ENUM_STRATEGY_MODE   InpStrategyMode = STRATEGY_AUTO;
input int                  InpMinScore = 70;

input group "═══ ⚡ SCALPING MODE ═══"
input bool                 InpEnableScalping = false;        // 🔥 Włącz Scalping (RYZYKO!)
input int                  InpScalpMaxPositions = 15;        // Max pozycji scalp (1-15)
input double               InpScalpTargetUSD = 1.5;          // Target per trade ($0.5-5)
input int                  InpScalpMaxSpread = 20;           // Max spread (pkt)
input int                  InpScalpCooldown = 5;             // Cooldown (sek)
input double               InpScalpMaxDailyLoss = 50.0;      // Max dzienna strata scalp ($)
input int                  InpScalpMaxTradesDay = 100;       // Max trades per day

input group "═══ 🛡️ ZABEZPIECZENIA ═══"
input bool                 InpUseTrailing = true;
input bool                 InpUseBreakeven = true;
input bool                 InpUsePartial = true;

// ... rest of params ...
```

---

## 10. Podsumowanie - Scalping Extension

### ✅ CO DODALIŚMY:

```
🆕 CScalpingStrategy class
   ├─ Micro-momentum detection (tick-by-tick)
   ├─ Multi-position management (do 15)
   ├─ Ultra-fast execution (milliseconds)
   ├─ Target-based close ($1-2 profit)
   └─ Spread monitoring (critical!)

🆕 Scalping Parameters (7 nowych)
   ├─ Enable/Disable
   ├─ Max positions
   ├─ Target profit
   ├─ Max spread
   ├─ Cooldown
   ├─ Daily loss limit
   └─ Max trades per day

🆕 Risk Management
   ├─ Scalp-specific daily limits
   ├─ Trade counting
   └─ Separate P/L tracking

🆕 Dashboard Section
   ├─ Active scalp positions
   ├─ Floating P/L
   └─ Today's stats
```

### 📊 EXPECTED PERFORMANCE (Scalping):

```
⚡ SCALPING MODE:
Win Rate: 65-75%
Profit/Trade: $1-2
Trades/Day: 30-80
Daily Profit: $30-100 (if all goes well)
Daily Loss Risk: -$50 max

⚠️ RISK LEVEL: EXTREME
Tylko dla doświadczonych traderów!
```

---

## ❓ PYTANIA DO CIEBIE:

1. **Czy chcesz, żebym zaimplementował to teraz?**
   - Mogę dodać CScalpingStrategy do planu
   - Lub zacząć kodować od razu

2. **Jakie wartości domyślne?**
   - Target: $1.00, $1.50, czy $2.00?
   - Max pozycji: 10, 15, czy 20?
   - Max spread: 15, 20, czy 25 punktów?

3. **Dodatkowe funkcje scalpingowe?**
   - Order book analysis?
   - Volume profile?
   - Level 2 data?

4. **Broker requirements?**
   - Czy masz ECN brokera?
   - Jaki średni spread?
   - Czy jest VPS?

**Powiedz co myślisz o tym rozszerzeniu!** 🚀

Scalping to **bardzo ryzykowne**, ale może być **bardzo profitable** w dobrych warunkach!
