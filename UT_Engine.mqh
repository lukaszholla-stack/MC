//+------------------------------------------------------------------+
//|                                                    UT_Engine.mqh |
//|                 Ultimate Trader EA - Engine, Managers & GUI       |
//|                                   Hybrid System v1.0.0            |
//+------------------------------------------------------------------+
#property copyright "Ultimate Trader Development Team"
#property version   "1.00"

#ifndef UT_ENGINE_MQH
#define UT_ENGINE_MQH

#include "UT_Core.mqh"
#include "UT_Analysis.mqh"
#include "UT_Strategies.mqh"

//+------------------------------------------------------------------+
//|                       RISK MANAGER CLASS                          |
//+------------------------------------------------------------------+
class CRiskManager {
private:
    double m_riskPerTrade;
    double m_maxDailyLoss;
    double m_maxTotalDrawdown;
    double m_dailyStartBalance;
    double m_peakBalance;
    int m_consecutiveLosses;
    int m_maxConsecutiveLosses;

public:
    CRiskManager() {
        m_riskPerTrade = 1.0;
        m_maxDailyLoss = 5.0;
        m_maxTotalDrawdown = 20.0;
        m_dailyStartBalance = 0;
        m_peakBalance = 0;
        m_consecutiveLosses = 0;
        m_maxConsecutiveLosses = 5;
    }

    bool Initialize(double riskPerTrade, double maxDailyLoss, double maxDD) {
        m_riskPerTrade = riskPerTrade;
        m_maxDailyLoss = maxDailyLoss;
        m_maxTotalDrawdown = maxDD;
        m_dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        m_peakBalance = m_dailyStartBalance;

        Print("✅ Risk Manager initialized");
        Print("   Risk per trade: ", m_riskPerTrade, "%");
        Print("   Max daily loss: ", m_maxDailyLoss, "%");
        Print("   Max total DD: ", m_maxTotalDrawdown, "%");

        return true;
    }

    bool CanTrade() {
        double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);

        // Check daily loss limit
        double dailyPL = currentBalance - m_dailyStartBalance;
        double dailyLossPct = (m_dailyStartBalance > 0) ?
                             (dailyPL / m_dailyStartBalance) * 100.0 : 0;

        if(dailyLossPct < -m_maxDailyLoss) {
            Print("⛔ DAILY LOSS LIMIT REACHED: ", dailyLossPct, "%");
            return false;
        }

        // Check total drawdown
        if(currentBalance > m_peakBalance) {
            m_peakBalance = currentBalance;
        }

        double totalDD = ((m_peakBalance - currentBalance) / m_peakBalance) * 100.0;
        if(totalDD > m_maxTotalDrawdown) {
            Print("⛔ TOTAL DRAWDOWN LIMIT REACHED: ", totalDD, "%");
            return false;
        }

        // Check consecutive losses
        if(m_consecutiveLosses >= m_maxConsecutiveLosses) {
            Print("⛔ TOO MANY CONSECUTIVE LOSSES: ", m_consecutiveLosses);
            return false;
        }

        return true;
    }

    double CalculatePositionSize(double slDistance) {
        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        double riskAmount = balance * (m_riskPerTrade / 100.0);

        double pointValue = GetPointValue();
        double pipDistance = slDistance / (_Point * 10);

        if(pipDistance <= 0 || pointValue <= 0) return 0;

        double lotSize = riskAmount / (pipDistance * pointValue * 10);

        return NormalizeLot(lotSize);
    }

    void OnTradeClosed(bool isWin) {
        if(isWin) {
            m_consecutiveLosses = 0;
        } else {
            m_consecutiveLosses++;
        }
    }

    void ResetDaily() {
        m_dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        Print("📅 Daily reset - New balance: $", m_dailyStartBalance);
    }
};

//+------------------------------------------------------------------+
//|                      SIGNAL MANAGER CLASS                         |
//+------------------------------------------------------------------+
class CSignalManager {
private:
    int m_minSignalScore;
    double m_minRiskReward;
    datetime m_lastSignalTime;
    int m_signalCooldown;

public:
    CSignalManager() {
        m_minSignalScore = 60;
        m_minRiskReward = 1.5;
        m_lastSignalTime = 0;
        m_signalCooldown = 30;  // 30 seconds between signals
    }

    bool Initialize(int minScore, double minRR) {
        m_minSignalScore = minScore;
        m_minRiskReward = minRR;

        Print("✅ Signal Manager initialized");
        Print("   Default min signal score: ", m_minSignalScore);
        Print("   Strategy-specific thresholds: Crypto=20, Scalping=40, Others=60");
        Print("   Min R:R ratio: ", m_minRiskReward);

        return true;
    }

    // Get minimum score threshold for specific strategy
    int GetMinScoreForStrategy(ENUM_STRATEGY_MODE strategy) {
        switch(strategy) {
            case STRATEGY_CRYPTO:    return 20;  // Crypto: Low threshold due to high volatility
            case STRATEGY_SCALPING:  return 40;  // Scalping: Medium threshold for quick trades
            case STRATEGY_FOREX:     return 60;  // Forex: High threshold for quality signals
            case STRATEGY_METAL:     return 60;  // Metal: High threshold for stability
            case STRATEGY_HARMONIC:  return 55;  // Harmonic: Medium-high for pattern quality
            case STRATEGY_ELLIOTT:   return 55;  // Elliott: Medium-high for wave quality
            case STRATEGY_ADAPTIVE:  return 50;  // Adaptive: Medium threshold
            case STRATEGY_HYBRID:    return 50;  // Hybrid: Medium threshold
            default:                 return m_minSignalScore; // Default to configured value
        }
    }

    bool ValidateSignal(TradeSignal& signal) {
        // Check if signal is valid
        if(!signal.isValid) {
            Print("❌ Signal rejected: Invalid signal (direction=", EnumToString(signal.direction),
                  ", score=", signal.score, ", source=", EnumToString(signal.source), ")");
            return false;
        }

        // Check score - use strategy-specific threshold
        int requiredScore = GetMinScoreForStrategy(signal.source);
        if(signal.score < requiredScore) {
            Print("❌ Signal rejected: Score too low (", signal.score, " < ", requiredScore,
                  " for ", EnumToString(signal.source), ")");
            return false;
        }

        // Check cooldown (except for scalping)
        if(!signal.isScalpSignal) {
            if(TimeCurrent() - m_lastSignalTime < m_signalCooldown) {
                // Don't print cooldown messages (too spammy)
                return false;
            }
        }

        // Check R:R ratio
        if(signal.riskRewardRatio > 0 && signal.riskRewardRatio < m_minRiskReward) {
            Print("❌ Signal rejected: R:R too low (", signal.riskRewardRatio, " < ", m_minRiskReward, ")");
            return false;
        }

        m_lastSignalTime = TimeCurrent();
        Print("✅ Signal ACCEPTED: ", EnumToString(signal.direction), " | Score: ", signal.score,
              " | R:R: ", DoubleToString(signal.riskRewardRatio, 2));
        return true;
    }
};

//+------------------------------------------------------------------+
//|                     POSITION MANAGER CLASS                        |
//+------------------------------------------------------------------+
class CPositionManager {
private:
    bool m_useTrailing;
    bool m_useBreakeven;
    bool m_usePartialClose;

    double m_trailingActivation;  // % of TP to activate trailing
    double m_breakevenActivation; // % of TP to activate breakeven
    double m_partialCloseLevel;   // % of TP to partial close

public:
    CPositionManager() {
        m_useTrailing = true;
        m_useBreakeven = true;
        m_usePartialClose = true;
        m_trailingActivation = 0.5;    // 50%
        m_breakevenActivation = 0.3;   // 30%
        m_partialCloseLevel = 0.7;     // 70%
    }

    bool Initialize(bool trailing, bool breakeven, bool partial) {
        m_useTrailing = trailing;
        m_useBreakeven = breakeven;
        m_usePartialClose = partial;

        Print("✅ Position Manager initialized");
        Print("   Trailing: ", m_useTrailing ? "ON" : "OFF");
        Print("   Breakeven: ", m_useBreakeven ? "ON" : "OFF");
        Print("   Partial Close: ", m_usePartialClose ? "ON" : "OFF");

        return true;
    }

    bool OpenPosition(TradeSignal& signal) {
        // Check if trading is allowed
        if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) {
            Print("❌ Trading not allowed in terminal");
            return false;
        }

        if(!MQLInfoInteger(MQL_TRADE_ALLOWED)) {
            Print("❌ Automated trading disabled for EA");
            return false;
        }

        // Refresh symbol prices before getting entry
        g_symbol.RefreshRates();

        double entry = (signal.direction == SIGNAL_BUY) ? g_symbol.Ask() : g_symbol.Bid();

        // Debug: verify we got valid prices
        if(entry <= 0) {
            Print("❌ CRITICAL: Invalid entry price (", entry, ")");
            Print("   g_symbol.Bid() = ", g_symbol.Bid());
            Print("   g_symbol.Ask() = ", g_symbol.Ask());
            Print("   g_symbol.Name() = ", g_symbol.Name());
            Print("   SymbolInfoDouble BID = ", SymbolInfoDouble(_Symbol, SYMBOL_BID));
            Print("   SymbolInfoDouble ASK = ", SymbolInfoDouble(_Symbol, SYMBOL_ASK));
            return false;
        }

        // Prepare trade request
        MqlTradeRequest request = {};
        MqlTradeResult result = {};

        request.action = TRADE_ACTION_DEAL;
        request.symbol = _Symbol;
        request.volume = signal.lotSize;
        request.type = (signal.direction == SIGNAL_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
        request.price = entry;
        request.sl = signal.stopLoss;
        request.tp = signal.takeProfit;
        request.deviation = 10;
        request.magic = 777001;
        request.comment = EnumToString(signal.source);

        // Pre-order diagnostics
        Print("📤 ORDER REQUEST:");
        Print("   Symbol: ", request.symbol);
        Print("   Type: ", (request.type == ORDER_TYPE_BUY ? "BUY" : "SELL"));
        Print("   Volume: ", request.volume);
        Print("   Entry: ", request.price);
        Print("   SL: ", request.sl, " (", DoubleToString(MathAbs(request.price - request.sl)/_Point, 1), " pips)");
        Print("   TP: ", request.tp, " (", DoubleToString(MathAbs(request.tp - request.price)/_Point, 1), " pips)");
        Print("   R:R: ", DoubleToString(signal.riskRewardRatio, 2));

        // Retry mechanism for TRADE_CONTEXT_BUSY
        int maxRetries = 3;
        for(int attempt = 0; attempt < maxRetries; attempt++) {
            if(attempt > 0) {
                Sleep(100); // Wait 100ms before retry
                Print("🔄 Retry attempt ", attempt + 1, "/", maxRetries);
            }

            bool success = OrderSend(request, result);

            // Detailed diagnostics
            Print("📋 Server response (attempt ", attempt + 1, "):");
            Print("   RetCode: ", result.retcode, " (", GetTradeRetcodeDescription(result.retcode), ")");
            Print("   Comment: ", result.comment);

            if(success && result.retcode == TRADE_RETCODE_DONE) {
                Print("✅ Position opened: ", signal.direction == SIGNAL_BUY ? "BUY" : "SELL");
                Print("   Ticket: ", result.order);
                Print("   Entry: ", entry, " | SL: ", signal.stopLoss, " | TP: ", signal.takeProfit);
                Print("   Lot: ", signal.lotSize, " | R:R: ", DoubleToString(signal.riskRewardRatio, 2));
                return true;
            }

            // Check if error is retriable
            if(result.retcode != TRADE_RETCODE_TIMEOUT &&
               result.retcode != TRADE_RETCODE_PRICE_CHANGED &&
               result.retcode != TRADE_RETCODE_REQUOTE) {
                break; // Don't retry for other errors
            }
        }

        Print("❌ Order FAILED after ", maxRetries, " attempts");
        Print("   Error: ", GetLastError());
        Print("   Final RetCode: ", result.retcode, " - ", result.comment);
        return false;
    }

    string GetTradeRetcodeDescription(uint retcode) {
        switch(retcode) {
            case TRADE_RETCODE_DONE: return "Request completed";
            case TRADE_RETCODE_PLACED: return "Order placed";
            case TRADE_RETCODE_DONE_PARTIAL: return "Partial fill";
            case TRADE_RETCODE_ERROR: return "Common error";
            case TRADE_RETCODE_TIMEOUT: return "Timeout";
            case TRADE_RETCODE_INVALID: return "Invalid request";
            case TRADE_RETCODE_REJECT: return "Request rejected";
            case TRADE_RETCODE_CANCEL: return "Request canceled";
            case TRADE_RETCODE_INVALID_VOLUME: return "Invalid volume";
            case TRADE_RETCODE_INVALID_PRICE: return "Invalid price";
            case TRADE_RETCODE_INVALID_STOPS: return "Invalid stops";
            case TRADE_RETCODE_TRADE_DISABLED: return "Trade disabled";
            case TRADE_RETCODE_MARKET_CLOSED: return "Market closed";
            case TRADE_RETCODE_NO_MONEY: return "Not enough money";
            case TRADE_RETCODE_PRICE_CHANGED: return "Price changed";
            case TRADE_RETCODE_PRICE_OFF: return "No prices";
            case TRADE_RETCODE_INVALID_EXPIRATION: return "Invalid expiration";
            case TRADE_RETCODE_ORDER_CHANGED: return "Order changed";
            case TRADE_RETCODE_TOO_MANY_REQUESTS: return "Too many requests";
            case TRADE_RETCODE_NO_CHANGES: return "No changes";
            case TRADE_RETCODE_SERVER_DISABLES_AT: return "AutoTrading disabled by server";
            case TRADE_RETCODE_CLIENT_DISABLES_AT: return "AutoTrading disabled by client";
            case TRADE_RETCODE_LOCKED: return "Request locked";
            case TRADE_RETCODE_FROZEN: return "Order frozen";
            case TRADE_RETCODE_INVALID_FILL: return "Invalid fill type";
            case TRADE_RETCODE_CONNECTION: return "No connection";
            case TRADE_RETCODE_ONLY_REAL: return "Only for real accounts";
            case TRADE_RETCODE_LIMIT_ORDERS: return "Orders limit reached";
            case TRADE_RETCODE_LIMIT_VOLUME: return "Volume limit reached";
            default: return "Unknown error";
        }
    }

    void ManagePositions() {
        for(int i = PositionsTotal() - 1; i >= 0; i--) {
            if(!g_position.SelectByIndex(i)) continue;
            if(g_position.Symbol() != _Symbol) continue;

            ulong ticket = g_position.Ticket();
            double openPrice = g_position.PriceOpen();
            double currentSL = g_position.StopLoss();
            double currentTP = g_position.TakeProfit();
            double volume = g_position.Volume();
            bool isBuy = (g_position.Type() == POSITION_TYPE_BUY);

            double currentPrice = isBuy ? g_symbol.Bid() : g_symbol.Ask();

            // Calculate profit in pips
            double profitPips = isBuy ?
                               (currentPrice - openPrice) / (_Point * 10) :
                               (openPrice - currentPrice) / (_Point * 10);

            double tpDistance = MathAbs(currentTP - openPrice) / (_Point * 10);
            double profitPercent = (tpDistance > 0) ? profitPips / tpDistance : 0;

            // Break-even logic
            if(m_useBreakeven && profitPercent >= m_breakevenActivation) {
                if((isBuy && currentSL < openPrice) || (!isBuy && currentSL > openPrice)) {
                    ModifyStopLoss(ticket, openPrice + (isBuy ? 10 : -10) * _Point);
                    Print("🔒 Breakeven activated for ticket ", ticket);
                }
            }

            // Trailing stop logic
            if(m_useTrailing && profitPercent >= m_trailingActivation) {
                double newSL = CalculateTrailingStop(isBuy, currentPrice, currentSL);

                if((isBuy && newSL > currentSL) || (!isBuy && newSL < currentSL)) {
                    ModifyStopLoss(ticket, newSL);
                }
            }

            // Partial close logic
            if(m_usePartialClose && profitPercent >= m_partialCloseLevel) {
                double closeVolume = volume * 0.5;  // Close 50%
                if(closeVolume >= g_symbol.LotsMin()) {
                    ClosePartialPosition(ticket, closeVolume);
                }
            }
        }
    }

private:
    bool ModifyStopLoss(ulong ticket, double newSL) {
        if(!g_position.SelectByTicket(ticket)) return false;

        MqlTradeRequest request = {};
        MqlTradeResult result = {};

        request.action = TRADE_ACTION_SLTP;
        request.position = ticket;
        request.symbol = g_position.Symbol();
        request.sl = newSL;
        request.tp = g_position.TakeProfit();

        return OrderSend(request, result);
    }

    double CalculateTrailingStop(bool isBuy, double currentPrice, double currentSL) {
        double atr = g_buffer_atr[0];
        double trailDistance = atr * 0.5;  // 50% of ATR

        if(isBuy) {
            return currentPrice - trailDistance;
        } else {
            return currentPrice + trailDistance;
        }
    }

    bool ClosePartialPosition(ulong ticket, double volume) {
        MqlTradeRequest request = {};
        MqlTradeResult result = {};

        if(!g_position.SelectByTicket(ticket)) return false;

        request.action = TRADE_ACTION_DEAL;
        request.position = ticket;
        request.symbol = g_position.Symbol();
        request.volume = volume;
        request.type = (g_position.Type() == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
        request.price = (g_position.Type() == POSITION_TYPE_BUY) ? g_symbol.Bid() : g_symbol.Ask();
        request.deviation = 10;

        if(OrderSend(request, result)) {
            Print("✂️ Partial close: ", volume, " lots from ticket ", ticket);
            return true;
        }

        return false;
    }
};

//+------------------------------------------------------------------+
//|                     SIMPLE DASHBOARD CLASS                        |
//+------------------------------------------------------------------+
class CDashboard {
private:
    bool m_enabled;
    string m_prefix;

public:
    CDashboard() {
        m_enabled = false;
        m_prefix = "UT_";
    }

    bool Initialize() {
        m_enabled = true;
        CreateLabels();
        Print("✅ Dashboard initialized");
        return true;
    }

    void Update(MarketConditions& conditions) {
        if(!m_enabled) return;

        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        double equity = AccountInfoDouble(ACCOUNT_EQUITY);
        double dailyPL = balance - g_state.dailyStartBalance;
        int openPos = PositionsTotal();

        // Update labels
        UpdateLabel("Title", "⚡ ULTIMATE TRADER v1.0 - " + _Symbol);
        UpdateLabel("Balance", StringFormat("Balance: $%.2f | Equity: $%.2f", balance, equity));
        UpdateLabel("DailyPL", StringFormat("Daily P/L: $%.2f (%.2f%%)",
                    dailyPL, (g_state.dailyStartBalance > 0) ? dailyPL / g_state.dailyStartBalance * 100 : 0));
        UpdateLabel("Positions", StringFormat("Open Positions: %d", openPos));
        UpdateLabel("Trend", StringFormat("Trend: %s | Strength: %.0f%%",
                    GetTrendText(conditions.trendDirection), conditions.trendStrength));
        UpdateLabel("Phase", "Phase: " + EnumToString(conditions.phase));
        UpdateLabel("Session", "Session: " + conditions.session);
        UpdateLabel("Performance", StringFormat("Win Rate: %.1f%% | PF: %.2f | Trades: %d",
                    g_performance.winRate, g_performance.profitFactor, g_performance.totalTrades));
    }

    void Destroy() {
        ObjectsDeleteAll(0, m_prefix);
        m_enabled = false;
    }

private:
    void CreateLabels() {
        int yPos = 20;
        int yStep = 20;

        CreateLabel("Title", 20, yPos, "⚡ ULTIMATE TRADER v1.0", clrGold, 12); yPos += yStep + 5;
        CreateLabel("Balance", 20, yPos, "", clrWhite, 10); yPos += yStep;
        CreateLabel("DailyPL", 20, yPos, "", clrWhite, 10); yPos += yStep;
        CreateLabel("Positions", 20, yPos, "", clrWhite, 10); yPos += yStep + 5;
        CreateLabel("Trend", 20, yPos, "", clrWhite, 10); yPos += yStep;
        CreateLabel("Phase", 20, yPos, "", clrWhite, 10); yPos += yStep;
        CreateLabel("Session", 20, yPos, "", clrWhite, 10); yPos += yStep + 5;
        CreateLabel("Performance", 20, yPos, "", clrWhite, 10);
    }

    void CreateLabel(string name, int x, int y, string text, color clr, int size) {
        string objName = m_prefix + name;

        // Delete if exists
        if(ObjectFind(0, objName) >= 0) {
            ObjectDelete(0, objName);
        }

        // Create new
        if(!ObjectCreate(0, objName, OBJ_LABEL, 0, 0, 0)) {
            Print("ERROR: Failed to create label: ", objName);
            return;
        }

        ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, x);
        ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, y);
        ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
        ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, size);
        ObjectSetString(0, objName, OBJPROP_FONT, "Arial");
        ObjectSetString(0, objName, OBJPROP_TEXT, text);
        ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, objName, OBJPROP_BACK, false);  // Draw in foreground
        ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, objName, OBJPROP_SELECTED, false);
        ObjectSetInteger(0, objName, OBJPROP_HIDDEN, true);

        ChartRedraw(0);  // Force chart redraw
    }

    void UpdateLabel(string name, string text) {
        ObjectSetString(0, m_prefix + name, OBJPROP_TEXT, text);
    }

    string GetTrendText(int trend) {
        if(trend > 0) return "BULLISH ↗";
        if(trend < 0) return "BEARISH ↘";
        return "RANGING ↔";
    }
};

//+------------------------------------------------------------------+
//|                        MAIN ENGINE CLASS                          |
//+------------------------------------------------------------------+
class CEngine {
private:
    // Managers
    CRiskManager* m_riskManager;
    CSignalManager* m_signalManager;
    CPositionManager* m_positionManager;
    CMarketAnalyzer* m_marketAnalyzer;
    CDashboard* m_dashboard;

    // Active strategy
    CBaseStrategy* m_activeStrategy;

    // State
    bool m_initialized;
    datetime m_lastUpdate;

public:
    CEngine() {
        m_riskManager = new CRiskManager();
        m_signalManager = new CSignalManager();
        m_positionManager = new CPositionManager();
        m_marketAnalyzer = new CMarketAnalyzer();
        m_dashboard = new CDashboard();
        m_activeStrategy = NULL;
        m_initialized = false;
        m_lastUpdate = 0;
    }

    ~CEngine() {
        delete m_riskManager;
        delete m_signalManager;
        delete m_positionManager;
        delete m_marketAnalyzer;
        delete m_dashboard;
        if(m_activeStrategy != NULL) delete m_activeStrategy;
    }

    bool Initialize(ENUM_TRADING_MODE mode, ENUM_STRATEGY_MODE strategyMode) {
        Print("════════════════════════════════════════");
        Print("  ULTIMATE TRADER EA - INITIALIZING");
        Print("════════════════════════════════════════");

        // Initialize global symbol info
        if(!g_symbol.Name(_Symbol)) {
            Print("❌ Failed to initialize symbol: ", _Symbol);
            return false;
        }
        g_symbol.Refresh();
        g_symbol.RefreshRates();
        Print("✅ Symbol initialized: ", _Symbol);
        Print("   Bid: ", g_symbol.Bid(), " | Ask: ", g_symbol.Ask());
        Print("   Point: ", g_symbol.Point(), " | Digits: ", g_symbol.Digits());

        // Initialize managers
        double risk = (mode == MODE_SAFE) ? 0.5 : (mode == MODE_BALANCED) ? 1.0 : 2.0;
        double maxDaily = (mode == MODE_SAFE) ? 3.0 : (mode == MODE_BALANCED) ? 5.0 : 10.0;
        double maxDD = (mode == MODE_SAFE) ? 15.0 : (mode == MODE_BALANCED) ? 20.0 : 30.0;

        if(!(*m_riskManager).Initialize(risk, maxDaily, maxDD)) return false;

        int minScore = (mode == MODE_SAFE) ? 70 : (mode == MODE_BALANCED) ? 60 : 50;
        if(!(*m_signalManager).Initialize(minScore, 1.5)) return false;

        if(!(*m_positionManager).Initialize(true, true, true)) return false;

        if(!(*m_marketAnalyzer).Initialize()) return false;

        if(!(*m_dashboard).Initialize()) return false;

        // Initialize strategy
        if(!InitializeStrategy(strategyMode)) return false;

        // Prepare indicator buffers
        PrepareBuffers();

        // Initialize global state
        g_state.Reset();
        g_performance.Reset();
        g_mlWeights.Reset();

        m_initialized = true;

        Print("════════════════════════════════════════");
        Print("  ✅ ULTIMATE TRADER EA - READY!");
        Print("════════════════════════════════════════");

        return true;
    }

    void OnTick() {
        if(!m_initialized) return;

        // Throttle updates - check signals less frequently to reduce log spam
        // Crypto/scalping: every 5 seconds, others: every 10 seconds
        int throttleInterval = 10; // Default 10 seconds
        if(m_activeStrategy != NULL) {
            ENUM_STRATEGY_MODE strategyType = (*m_activeStrategy).GetType();
            if(strategyType == STRATEGY_CRYPTO || strategyType == STRATEGY_SCALPING) {
                throttleInterval = 5; // More frequent for fast strategies
            }
        }

        if(TimeCurrent() - m_lastUpdate < throttleInterval) return;
        m_lastUpdate = TimeCurrent();

        // Analyze market
        MarketConditions conditions = (*m_marketAnalyzer).Analyze();

        // Check if we can trade
        if(!(*m_riskManager).CanTrade()) {
            return;
        }

        // Manage existing positions
        (*m_positionManager).ManagePositions();

        // Check for new signals
        if(m_activeStrategy != NULL) {
            TradeSignal signal = (*m_activeStrategy).CheckSignal(conditions);

            // If signal is valid, calculate entry/SL/TP
            if(signal.isValid && signal.direction != SIGNAL_NONE) {
                // Set entry price
                signal.entryPrice = (signal.direction == SIGNAL_BUY) ? g_symbol.Ask() : g_symbol.Bid();

                // Calculate SL and TP
                double atr = (ArraySize(g_buffer_atr) > 0) ? g_buffer_atr[0] : 0.001;
                signal.stopLoss = (*m_activeStrategy).CalculateStopLoss(signal.direction, signal.entryPrice, atr);
                signal.takeProfit = (*m_activeStrategy).CalculateTakeProfit(signal.direction, signal.entryPrice, signal.stopLoss);

                // Calculate R:R ratio
                double slDistance = MathAbs(signal.entryPrice - signal.stopLoss);
                double tpDistance = MathAbs(signal.takeProfit - signal.entryPrice);
                signal.riskRewardRatio = (slDistance > 0) ? tpDistance / slDistance : 0;
            }

            if((*m_signalManager).ValidateSignal(signal)) {
                // Calculate position size
                double slDistance = MathAbs(signal.entryPrice - signal.stopLoss);
                signal.lotSize = (*m_riskManager).CalculatePositionSize(slDistance);

                // Open position
                if(signal.lotSize > 0) {
                    (*m_positionManager).OpenPosition(signal);
                }
            }
        }

        // Update dashboard
        (*m_dashboard).Update(conditions);
    }

    void OnDeinit() {
        (*m_dashboard).Destroy();
        Print("✅ Ultimate Trader EA - Shutdown complete");
    }

private:
    bool InitializeStrategy(ENUM_STRATEGY_MODE mode) {
        switch(mode) {
            case STRATEGY_FOREX:
                m_activeStrategy = new CForexStrategy();
                break;
            case STRATEGY_METAL:
                m_activeStrategy = new CMetalStrategy();
                break;
            case STRATEGY_CRYPTO:
                m_activeStrategy = new CCryptoStrategy();
                break;
            case STRATEGY_SCALPING:
                m_activeStrategy = new CScalpingStrategy();
                break;
            case STRATEGY_ADAPTIVE:
            case STRATEGY_AUTO:
            default:
                m_activeStrategy = new CAdaptiveStrategy();
                break;
        }

        if(m_activeStrategy == NULL) return false;

        (*m_activeStrategy).SetMarketAnalyzer(m_marketAnalyzer);
        return (*m_activeStrategy).Initialize();
    }
};

#endif // UT_ENGINE_MQH
