//+------------------------------------------------------------------+
//|                                                 MC5_Managers.mqh |
//|                    Managery systemu - FIXED VERSION              |
//+------------------------------------------------------------------+
#ifndef MC5_MANAGERS_MQH
#define MC5_MANAGERS_MQH

#include "MC5_Core.mqh"
#include "MC5_Utils.mqh"

// Deklaracja zewnętrznej struktury performance
extern PerformanceStats g_performance;

//+------------------------------------------------------------------+
//|                      KLASA DATA MANAGER                          |
//+------------------------------------------------------------------+
class CDataManager {
private:
    bool m_initialized;
    datetime m_lastUpdate;
    int m_updateErrors;
    int m_maxUpdateErrors;
    
    // NOWE: Cache dla wskaźników
    struct IndicatorCache {
        datetime lastUpdate;
        bool needsRefresh;
    };
    IndicatorCache m_cache[10];  // Dla każdego timeframe
    
public:
    CDataManager() {
        m_initialized = false;
        m_lastUpdate = 0;
        m_updateErrors = 0;
        m_maxUpdateErrors = 10;
        
        // Inicjalizuj cache
        for(int i = 0; i < 10; i++) {
            m_cache[i].lastUpdate = 0;
            m_cache[i].needsRefresh = true;
        }
    }
    
    ~CDataManager() {
        Cleanup();
    }
    
    bool Initialize() {
        DEBUG_MSG(DEBUG_NORMAL, "DATA", "Initializing Data Manager...");
        
        // Inicjalizacja wskaźników M15 (główny timeframe)
        g_handle_atr_m15 = iATR(_Symbol, PERIOD_M15, 14);
        g_handle_rsi_m15 = iRSI(_Symbol, PERIOD_M15, 14, PRICE_CLOSE);
        g_handle_macd_m15 = iMACD(_Symbol, PERIOD_M15, 12, 26, 9, PRICE_CLOSE);
        g_handle_bb_m15 = iBands(_Symbol, PERIOD_M15, 20, 0, 2.0, PRICE_CLOSE);
        g_handle_ema_fast_m15 = iMA(_Symbol, PERIOD_M15, 20, 0, MODE_EMA, PRICE_CLOSE);
        g_handle_ema_slow_m15 = iMA(_Symbol, PERIOD_M15, 50, 0, MODE_EMA, PRICE_CLOSE);
        g_handle_adx_m15 = iADX(_Symbol, PERIOD_M15, 14);
        g_handle_stoch_m15 = iStochastic(_Symbol, PERIOD_M15, 14, 3, 3, MODE_SMA, STO_LOWHIGH);
        g_handle_cci_m15 = iCCI(_Symbol, PERIOD_M15, 14, PRICE_TYPICAL);
        g_handle_volumes_m15 = iVolumes(_Symbol, PERIOD_M15, VOLUME_TICK);
        
        // Sprawdź czy wszystkie wskaźniki zostały utworzone
        if(!IS_VALID_HANDLE(g_handle_atr_m15) || !IS_VALID_HANDLE(g_handle_rsi_m15)) {
            DEBUG_MSG(DEBUG_CRITICAL, "DATA", "Failed to create core indicators");
            return false;
        }
        
        // Inicjalizacja wskaźników H1
        g_handle_atr_h1 = iATR(_Symbol, PERIOD_H1, 14);
        g_handle_rsi_h1 = iRSI(_Symbol, PERIOD_H1, 14, PRICE_CLOSE);
        g_handle_ema_200_h1 = iMA(_Symbol, PERIOD_H1, 200, 0, MODE_EMA, PRICE_CLOSE);
        
        // Inicjalizacja wskaźników H4/D1
        g_handle_atr_h4 = iATR(_Symbol, PERIOD_H4, 14);
        g_handle_ema_200_d1 = iMA(_Symbol, PERIOD_D1, 200, 0, MODE_EMA, PRICE_CLOSE);
        
        PrepareBuffers();
        
        // Pierwsze ładowanie danych
        if(!RefreshAll()) {
            DEBUG_MSG(DEBUG_NORMAL, "DATA", "Initial data load will be done on first tick");
        }
        
        m_initialized = true;
        DEBUG_MSG(DEBUG_NORMAL, "DATA", "Data Manager initialized successfully");
        
        return true;
    }
    
    bool RefreshAll() {
        bool success = true;
        
        // OPTYMALIZACJA: Odśwież tylko jeśli minęło wystarczająco czasu
        if(TimeCurrent() - m_cache[2].lastUpdate >= 1) {  // M15 co sekundę
            success &= RefreshIndicatorData(PERIOD_M15);
            m_cache[2].lastUpdate = TimeCurrent();
        }
        
        if(TimeCurrent() - m_cache[4].lastUpdate >= 5) {  // H1 co 5 sekund
            success &= RefreshIndicatorData(PERIOD_H1);
            m_cache[4].lastUpdate = TimeCurrent();
        }
        
        if(TimeCurrent() - m_cache[5].lastUpdate >= 10) {  // H4 co 10 sekund
            success &= RefreshIndicatorData(PERIOD_H4);
            m_cache[5].lastUpdate = TimeCurrent();
        }
        
        m_lastUpdate = TimeCurrent();
        
        if(!success) {
            m_updateErrors++;
            if(m_updateErrors > m_maxUpdateErrors) {
                DEBUG_MSG(DEBUG_CRITICAL, "DATA", "Too many update errors, reinitializing...");
                ReInitialize();
            }
        } else {
            m_updateErrors = 0;
        }
        
        return success;
    }
    
    bool RefreshIndicatorData(ENUM_TIMEFRAMES tf) {
        int barsToLoad = INDICATOR_BUFFER;
        bool success = true;
        
        if(tf == PERIOD_M15) {
            if(IS_VALID_HANDLE(g_handle_atr_m15)) {
                if(CopyBuffer(g_handle_atr_m15, 0, 0, barsToLoad, g_buffer_atr_m15) <= 0) {
                    success = false;
                }
            }
            
            if(IS_VALID_HANDLE(g_handle_rsi_m15)) {
                if(CopyBuffer(g_handle_rsi_m15, 0, 0, barsToLoad, g_buffer_rsi_m15) <= 0) {
                    success = false;
                }
            }
            
            if(IS_VALID_HANDLE(g_handle_macd_m15)) {
                CopyBuffer(g_handle_macd_m15, 0, 0, barsToLoad, g_buffer_macd_main);
                CopyBuffer(g_handle_macd_m15, 1, 0, barsToLoad, g_buffer_macd_signal);
            }
            
            if(IS_VALID_HANDLE(g_handle_bb_m15)) {
                CopyBuffer(g_handle_bb_m15, 0, 0, barsToLoad, g_buffer_bb_middle);
                CopyBuffer(g_handle_bb_m15, 1, 0, barsToLoad, g_buffer_bb_upper);
                CopyBuffer(g_handle_bb_m15, 2, 0, barsToLoad, g_buffer_bb_lower);
            }
            
            if(IS_VALID_HANDLE(g_handle_ema_fast_m15)) {
                CopyBuffer(g_handle_ema_fast_m15, 0, 0, barsToLoad, g_buffer_ema_fast);
            }
            if(IS_VALID_HANDLE(g_handle_ema_slow_m15)) {
                CopyBuffer(g_handle_ema_slow_m15, 0, 0, barsToLoad, g_buffer_ema_slow);
            }
            
            if(IS_VALID_HANDLE(g_handle_adx_m15)) {
                CopyBuffer(g_handle_adx_m15, 0, 0, barsToLoad, g_buffer_adx);
                CopyBuffer(g_handle_adx_m15, 1, 0, barsToLoad, g_buffer_adx_plus);
                CopyBuffer(g_handle_adx_m15, 2, 0, barsToLoad, g_buffer_adx_minus);
            }
            
            if(IS_VALID_HANDLE(g_handle_stoch_m15)) {
                CopyBuffer(g_handle_stoch_m15, 0, 0, barsToLoad, g_buffer_stoch_main);
                CopyBuffer(g_handle_stoch_m15, 1, 0, barsToLoad, g_buffer_stoch_signal);
            }
            
            if(IS_VALID_HANDLE(g_handle_cci_m15)) {
                CopyBuffer(g_handle_cci_m15, 0, 0, barsToLoad, g_buffer_cci);
            }
            
            if(IS_VALID_HANDLE(g_handle_volumes_m15)) {
                CopyBuffer(g_handle_volumes_m15, 0, 0, barsToLoad, g_buffer_volumes);
            }
        }
        else if(tf == PERIOD_H1) {
            if(IS_VALID_HANDLE(g_handle_atr_h1)) {
                CopyBuffer(g_handle_atr_h1, 0, 0, barsToLoad, g_buffer_atr_h1);
            }
            if(IS_VALID_HANDLE(g_handle_rsi_h1)) {
                CopyBuffer(g_handle_rsi_h1, 0, 0, barsToLoad, g_buffer_rsi_h1);
            }
            if(IS_VALID_HANDLE(g_handle_ema_200_h1)) {
                CopyBuffer(g_handle_ema_200_h1, 0, 0, barsToLoad, g_buffer_ema_200_h1);
            }
        }
        else if(tf == PERIOD_H4) {
            if(IS_VALID_HANDLE(g_handle_atr_h4)) {
                CopyBuffer(g_handle_atr_h4, 0, 0, barsToLoad, g_buffer_atr_h4);
            }
        }
        else if(tf == PERIOD_D1) {
            if(IS_VALID_HANDLE(g_handle_ema_200_d1)) {
                CopyBuffer(g_handle_ema_200_d1, 0, 0, barsToLoad, g_buffer_ema_200_d1);
            }
        }
        
        return success;
    }
    
    bool RefreshTick() {
        return g_symbol.RefreshRates();
    }
    
    bool IsDataFresh() {
        return (TimeCurrent() - m_lastUpdate < 60);
    }
    
    void ReInitialize() {
        Cleanup();
        Initialize();
    }
    
    void Cleanup() {
        CleanupGlobalVariables();
        m_initialized = false;
    }
    
    bool IsInitialized() { return m_initialized; }
    datetime GetLastUpdate() { return m_lastUpdate; }
    int GetUpdateErrors() { return m_updateErrors; }
};

//+------------------------------------------------------------------+
//|                      KLASA RISK MANAGER                          |
//+------------------------------------------------------------------+
class CRiskManager {
private:
    double m_riskPerTrade;
    double m_maxDailyLoss;
    double m_maxTotalDrawdown;
    
    RiskStatus m_currentStatus;
    
    double m_initialBalance;
    double m_dailyStartBalance;
    datetime m_dailyResetTime;
    
    int m_consecutiveLosses;
    int m_consecutiveWins;
    int m_maxConsecutiveLosses;
    int m_maxConsecutiveWins;
    
    double CalculateDrawdown() {
        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        double equity = AccountInfoDouble(ACCOUNT_EQUITY);
        
        if(balance <= 0) return 0;
        
        double drawdown = (balance - equity) / balance * 100;
        return drawdown;
    }
    
    double CalculateDailyPL() {
        double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        return currentBalance - m_dailyStartBalance;
    }
    
public:
    CRiskManager(double riskPerTrade = 1.0, double maxDailyLoss = 5.0, double maxDrawdown = 10.0) {
        m_riskPerTrade = riskPerTrade;
        m_maxDailyLoss = maxDailyLoss;
        m_maxTotalDrawdown = maxDrawdown;
        
        m_initialBalance = 0;
        m_dailyStartBalance = 0;
        m_dailyResetTime = 0;
        
        m_consecutiveLosses = 0;
        m_consecutiveWins = 0;
        
        if(g_isBTCMode) {
            m_maxConsecutiveLosses = 10;
            m_maxConsecutiveWins = 15;
        } else if(g_isCryptoMode) {
            m_maxConsecutiveLosses = 8;
            m_maxConsecutiveWins = 12;
        } else {
            m_maxConsecutiveLosses = 5;
            m_maxConsecutiveWins = 10;
        }
        
        m_currentStatus.Reset();
    }
    
    ~CRiskManager() {
    }
    
    bool Initialize() {
        DEBUG_MSG(DEBUG_NORMAL, "RISK", "Initializing Risk Manager...");
        
        m_initialBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        m_dailyStartBalance = m_initialBalance;
        m_dailyResetTime = TimeCurrent();
        
        if(g_isBTCMode) {
            m_maxConsecutiveLosses = 10;
            DEBUG_MSG(DEBUG_NORMAL, "RISK", "BTC Mode: Max consecutive losses set to 10");
        } else if(g_isCryptoMode) {
            m_maxConsecutiveLosses = 8;
            DEBUG_MSG(DEBUG_NORMAL, "RISK", "Crypto Mode: Max consecutive losses set to 8");
        } else {
            m_maxConsecutiveLosses = 5;
        }
        
        UpdateStatus();
        
        DEBUG_MSG(DEBUG_NORMAL, "RISK", 
            StringFormat("Risk initialized: %.2f%% per trade, %.2f%% daily limit, %.2f%% max DD, Max losses: %d",
                m_riskPerTrade, m_maxDailyLoss, m_maxTotalDrawdown, m_maxConsecutiveLosses));
        
        return true;
    }
    
    void UpdateStatus() {
        m_currentStatus.accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        m_currentStatus.accountEquity = AccountInfoDouble(ACCOUNT_EQUITY);
        m_currentStatus.freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
        m_currentStatus.marginLevel = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
        
        double dailyPL = CalculateDailyPL();
        if(dailyPL > 0) {
            m_currentStatus.dailyProfit = dailyPL;
            m_currentStatus.dailyLoss = 0;
        } else {
            m_currentStatus.dailyProfit = 0;
            m_currentStatus.dailyLoss = MathAbs(dailyPL);
        }
        
        m_currentStatus.dailyDrawdown = (m_currentStatus.dailyLoss / m_dailyStartBalance) * 100;
        m_currentStatus.maxDrawdown = CalculateDrawdown();
        
        // Sprawdź limity
        m_currentStatus.dailyLimitReached = (m_maxDailyLoss > 0 && m_currentStatus.dailyDrawdown >= m_maxDailyLoss);
        m_currentStatus.emergencyStop = (m_currentStatus.maxDrawdown >= m_maxTotalDrawdown);
        
        bool tooManyLosses = false;
        if(m_consecutiveLosses >= m_maxConsecutiveLosses) {
            DEBUG_MSG(DEBUG_NORMAL, "RISK", 
                StringFormat("⚠️ WARNING: %d consecutive losses (max: %d) - reducing risk", 
                    m_consecutiveLosses, m_maxConsecutiveLosses));
            tooManyLosses = false;  // NIE BLOKUJ
        }
        
        m_currentStatus.canTrade = !m_currentStatus.dailyLimitReached && 
                                   !m_currentStatus.emergencyStop &&
                                   !tooManyLosses &&
                                   m_currentStatus.freeMargin > 0;
        
        if(m_currentStatus.emergencyStop) {
            m_currentStatus.stopReason = "EMERGENCY STOP - Max drawdown reached";
        } else if(m_currentStatus.dailyLimitReached) {
            m_currentStatus.stopReason = "Daily loss limit reached";
        } else if(m_currentStatus.freeMargin <= 0) {
            m_currentStatus.stopReason = "No free margin";
        } else {
            m_currentStatus.stopReason = "";
        }
    }
    
    double CalculatePositionSize(double stopLossDistance) {
        if(stopLossDistance <= 0) {
            DEBUG_MSG(DEBUG_NORMAL, "RISK", "Invalid stop loss distance");
            return 0;
        }
        
        double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        
        // Podstawowe ryzyko
        double riskAmount = accountBalance * (m_riskPerTrade / 100);
        
        // Dostosuj do performance
        riskAmount = AdjustRiskByPerformance(riskAmount);
        
        // Dostosuj do drawdown
        riskAmount = AdjustRiskByDrawdown(riskAmount);
        
        ENUM_INSTRUMENT_TYPE instrumentType = DetectInstrumentType(_Symbol);
        
        double lotSize = 0;
        
        if(instrumentType == INSTRUMENT_CRYPTO) {
            double contractSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
            double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
            double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
            
            if(contractSize > 0 && tickValue > 0 && tickSize > 0) {
                lotSize = (riskAmount * tickSize) / (stopLossDistance * tickValue);
            }
        } else {
            double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
            double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
            
            if(tickValue > 0 && tickSize > 0) {
                double stopLossPoints = stopLossDistance / _Point;
                double pointValue = tickValue * _Point / tickSize;
                
                if(pointValue > 0 && stopLossPoints > 0) {
                    lotSize = riskAmount / (stopLossPoints * pointValue);
                }
            }
        }
        
        // Skalowanie lota w zależności od balansu
        if(accountBalance >= 10000) {
            lotSize = MathMax(0.1, MathMin(2.0, lotSize));
        } else if(accountBalance >= 5000) {
            lotSize = MathMax(0.05, MathMin(1.0, lotSize));
        } else if(accountBalance >= 2000) {
            lotSize = MathMax(0.02, MathMin(0.5, lotSize));
        } else if(accountBalance >= 1000) {
            lotSize = MathMax(0.01, MathMin(0.2, lotSize));
        } else {
            lotSize = MathMax(0.01, MathMin(0.1, lotSize));
        }
        
        return NormalizeLot(lotSize);
    }
    
    double AdjustRiskByPerformance(double baseRisk) {
        if(m_consecutiveLosses >= 8) {
            baseRisk *= 0.3;
            DEBUG_MSG(DEBUG_NORMAL, "RISK", "Risk reduced by 70% due to many losses");
        }
        else if(m_consecutiveLosses >= 5) {
            baseRisk *= 0.5;
            DEBUG_MSG(DEBUG_NORMAL, "RISK", "Risk reduced by 50% due to consecutive losses");
        }
        else if(m_consecutiveLosses >= 3) {
            baseRisk *= 0.7;
            DEBUG_MSG(DEBUG_NORMAL, "RISK", "Risk reduced by 30% due to consecutive losses");
        }
        else if(m_consecutiveWins >= 8) {
            baseRisk *= 1.3;
            DEBUG_MSG(DEBUG_NORMAL, "RISK", "Risk increased by 30% due to winning streak");
        }
        else if(m_consecutiveWins >= 5) {
            baseRisk *= 1.2;
            DEBUG_MSG(DEBUG_NORMAL, "RISK", "Risk increased by 20% due to consecutive wins");
        }
        else if(m_consecutiveWins >= 3) {
            baseRisk *= 1.1;
            DEBUG_MSG(DEBUG_NORMAL, "RISK", "Risk increased by 10% due to consecutive wins");
        }
        
        return baseRisk;
    }
    
    double AdjustRiskByDrawdown(double baseRisk) {
        double currentDD = m_currentStatus.maxDrawdown;
        
        if(currentDD > m_maxTotalDrawdown * 0.8) {
            baseRisk *= 0.3;
            DEBUG_MSG(DEBUG_NORMAL, "RISK", "Risk reduced by 70% - approaching max drawdown");
        }
        else if(currentDD > m_maxTotalDrawdown * 0.6) {
            baseRisk *= 0.5;
            DEBUG_MSG(DEBUG_NORMAL, "RISK", "Risk reduced by 50% - high drawdown");
        }
        else if(currentDD > m_maxTotalDrawdown * 0.4) {
            baseRisk *= 0.7;
            DEBUG_MSG(DEBUG_NORMAL, "RISK", "Risk reduced by 30% - moderate drawdown");
        }
        
        return baseRisk;
    }
    
    bool CanOpenNewPosition() {
        UpdateStatus();
        
        if(!m_currentStatus.canTrade) {
            DEBUG_MSG(DEBUG_NORMAL, "RISK", "Cannot open position: " + m_currentStatus.stopReason);
            return false;
        }
        
        double marginRequired = CalculateRequiredMargin();
        if(marginRequired > m_currentStatus.freeMargin * 0.8) {
            DEBUG_MSG(DEBUG_NORMAL, "RISK", "Insufficient free margin for safe trading");
            return false;
        }
        
        return true;
    }
    
    double CalculateRequiredMargin() {
        double lotSize = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
        double price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        double margin = 0;
        
        if(!OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, lotSize, price, margin)) {
            margin = 0;
            DEBUG_MSG(DEBUG_NORMAL, "RISK", "Cannot calculate margin");
        }
        
        return margin;
    }
    
    void ResetDaily() {
        MqlDateTime current;
        TimeCurrent(current);
        
        MqlDateTime lastReset;
        TimeToStruct(m_dailyResetTime, lastReset);
        
        if(current.day != lastReset.day) {
            m_dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
            m_dailyResetTime = TimeCurrent();
            m_currentStatus.dailyProfit = 0;
            m_currentStatus.dailyLoss = 0;
            m_currentStatus.dailyDrawdown = 0;
            m_currentStatus.dailyLimitReached = false;
            
            m_consecutiveLosses = 0;
            m_consecutiveWins = 0;
            
            DEBUG_MSG(DEBUG_NORMAL, "RISK", "Daily risk counters reset - new trading day");
        }
    }
    
    void RegisterTradeResult(double profit) {
        if(profit > 0) {
            m_consecutiveWins++;
            m_consecutiveLosses = 0;
            
            if(m_consecutiveWins > m_maxConsecutiveWins) {
                m_maxConsecutiveWins = m_consecutiveWins;
            }
        } else if(profit < 0) {
            m_consecutiveLosses++;
            m_consecutiveWins = 0;
            
            if(m_consecutiveLosses > m_maxConsecutiveLosses) {
                DEBUG_MSG(DEBUG_NORMAL, "RISK", 
                    StringFormat("⚠️ New max consecutive losses: %d", m_consecutiveLosses));
            }
        }
        
        UpdateStatus();
    }
    
    RiskStatus GetCurrentStatus() {
        UpdateStatus();
        return m_currentStatus;
    }
    
    double GetRiskPerTrade() { return m_riskPerTrade; }
    int GetConsecutiveLosses() { return m_consecutiveLosses; }
    int GetConsecutiveWins() { return m_consecutiveWins; }
    
    void SetRiskPerTrade(double risk) { 
        m_riskPerTrade = MathMax(0.1, MathMin(5.0, risk)); 
    }
    
    void SetMaxDailyLoss(double loss) {
        m_maxDailyLoss = MathMax(0, MathMin(20.0, loss));
    }
};

//+------------------------------------------------------------------+
//|                KLASA SIGNAL MANAGER - WITH HEDGING              |
//+------------------------------------------------------------------+
class CSignalManager {
private:
    int m_minSignalScore;
    double m_minRiskReward;
    bool m_allowHedging;
    
    TradeSignal m_signals[];
    int m_signalsCount;
    int m_maxSignalsHistory;
    
    datetime m_lastSignalTime;
    datetime m_lastBuySignal;
    datetime m_lastSellSignal;
    int m_signalCooldown;
    
    // NOWE: Cache dla sprawdzania spreadu
    double m_lastSpread;
    datetime m_lastSpreadCheck;
    
    bool IsSignalTooSoon(ENUM_SIGNAL_DIRECTION direction) {
        datetime lastSignal = (direction == SIGNAL_BUY) ? m_lastBuySignal : m_lastSellSignal;
        
        int cooldown = m_signalCooldown;
        
        if(g_isBTCMode) {
            cooldown = MathMax(60, cooldown);
        } else if(g_isCryptoMode) {
            cooldown = MathMax(45, cooldown);
        } else {
            cooldown = MathMax(90, cooldown);
        }
        
        return (TimeCurrent() - lastSignal < cooldown);
    }
    
    bool HasOpenPositionInDirection(ENUM_SIGNAL_DIRECTION direction) {
        for(int i = 0; i < PositionsTotal(); i++) {
            if(g_position.SelectByIndex(i)) {
                if(g_position.Symbol() == _Symbol) {
                    if(direction == SIGNAL_BUY && g_position.PositionType() == POSITION_TYPE_BUY) {
                        return true;
                    }
                    if(direction == SIGNAL_SELL && g_position.PositionType() == POSITION_TYPE_SELL) {
                        return true;
                    }
                }
            }
        }
        return false;
    }
    
    bool HasConflictingPosition(ENUM_SIGNAL_DIRECTION direction) {
        if(m_allowHedging) {
            return false;
        }
        
        for(int i = 0; i < PositionsTotal(); i++) {
            if(g_position.SelectByIndex(i)) {
                if(g_position.Symbol() == _Symbol) {
                    if(direction == SIGNAL_BUY && g_position.PositionType() == POSITION_TYPE_SELL) {
                        return true;
                    }
                    if(direction == SIGNAL_SELL && g_position.PositionType() == POSITION_TYPE_BUY) {
                        return true;
                    }
                }
            }
        }
        return false;
    }
    
    void CleanupOldSignals() {
        if(ArraySize(m_signals) > m_maxSignalsHistory) {
            int toRemove = ArraySize(m_signals) - m_maxSignalsHistory;
            for(int i = 0; i < ArraySize(m_signals) - toRemove; i++) {
                m_signals[i] = m_signals[i + toRemove];
            }
            ArrayResize(m_signals, m_maxSignalsHistory);
        }
    }
    
    void CheckHedgingBalance() {
        if(!m_allowHedging) return;
        
        int buyCount = 0;
        int sellCount = 0;
        double buyVolume = 0;
        double sellVolume = 0;
        
        for(int i = 0; i < PositionsTotal(); i++) {
            if(g_position.SelectByIndex(i)) {
                if(g_position.Symbol() == _Symbol) {
                    if(g_position.PositionType() == POSITION_TYPE_BUY) {
                        buyCount++;
                        buyVolume += g_position.Volume();
                    } else {
                        sellCount++;
                        sellVolume += g_position.Volume();
                    }
                }
            }
        }
        
        if(buyCount > 0 && sellCount > 0) {
            DEBUG_MSG(DEBUG_NORMAL, "HEDGING", 
                StringFormat("Hedge positions: BUY=%d (%.2f lots) | SELL=%d (%.2f lots)",
                    buyCount, buyVolume, sellCount, sellVolume));
        }
    }
    
public:
    CSignalManager(int minScore = 60, double minRR = 1.5) {
        m_minSignalScore = minScore;
        m_minRiskReward = minRR;
        m_allowHedging = false;
        m_signalsCount = 0;
        m_maxSignalsHistory = 100;
        m_lastSignalTime = 0;
        m_lastBuySignal = 0;
        m_lastSellSignal = 0;
        m_signalCooldown = 90;
        m_lastSpread = 0;
        m_lastSpreadCheck = 0;
        
        ArrayResize(m_signals, 0);
    }
    
    ~CSignalManager() {
    }
    
    bool Initialize() {
        DEBUG_MSG(DEBUG_NORMAL, "SIGNAL", "Initializing Signal Manager...");
        
        DEBUG_MSG(DEBUG_NORMAL, "SIGNAL", 
            StringFormat("Min score: %d, Min R:R: %.2f, Cooldown: %d sec, Hedging: %s", 
                m_minSignalScore, m_minRiskReward, m_signalCooldown,
                m_allowHedging ? "ON" : "OFF"));
        
        return true;
    }
    
    bool ValidateSignal(TradeSignal& signal) {
        DEBUG_MSG(DEBUG_NORMAL, "SIGNAL", "════ VALIDATING SIGNAL ════");
        DEBUG_MSG(DEBUG_NORMAL, "SIGNAL", 
            StringFormat("Direction: %s | Strength: %d | R:R: %.2f",
                signal.direction == SIGNAL_BUY ? "BUY" : "SELL",
                signal.strength,
                signal.riskRewardRatio));
        
        // Walidacja siły sygnału
        if(signal.strength < m_minSignalScore) {
            DEBUG_MSG(DEBUG_NORMAL, "SIGNAL", 
                StringFormat("❌ REJECTED: Signal too weak: %d < %d", signal.strength, m_minSignalScore));
            return false;
        }
        DEBUG_MSG(DEBUG_VERBOSE, "SIGNAL", "✓ Strength OK");
        
        // Walidacja Risk:Reward
        if(signal.riskRewardRatio < m_minRiskReward) {
            DEBUG_MSG(DEBUG_NORMAL, "SIGNAL", 
                StringFormat("❌ REJECTED: R:R too low: %.2f < %.2f", signal.riskRewardRatio, m_minRiskReward));
            return false;
        }
        DEBUG_MSG(DEBUG_VERBOSE, "SIGNAL", "✓ R:R OK");
        
        // Sprawdź cooldown
        datetime currentTime = TimeCurrent();
        datetime lastSignal = (signal.direction == SIGNAL_BUY) ? m_lastBuySignal : m_lastSellSignal;
        int timeSinceLast = (int)(currentTime - lastSignal);
        
        int requiredCooldown = m_signalCooldown;
        if(g_isBTCMode) {
            requiredCooldown = 60;
        } else if(g_isCryptoMode) {
            requiredCooldown = 45;
        } else if(DetectInstrumentType(_Symbol) == INSTRUMENT_METAL) {
            requiredCooldown = 45;
        } else {
            requiredCooldown = 60;
        }
        
        if(timeSinceLast < requiredCooldown) {
            DEBUG_MSG(DEBUG_NORMAL, "SIGNAL", 
                StringFormat("❌ REJECTED: Cooldown active (%d < %d seconds)", timeSinceLast, requiredCooldown));
            return false;
        }
        DEBUG_MSG(DEBUG_VERBOSE, "SIGNAL", StringFormat("✓ Cooldown OK (%d seconds passed)", timeSinceLast));
        
        // Sprawdź konfliktujące pozycje (tylko gdy hedging wyłączony)
        if(HasConflictingPosition(signal.direction)) {
            if(m_allowHedging) {
                DEBUG_MSG(DEBUG_NORMAL, "SIGNAL", "ℹ️ Hedging mode: allowing opposite position");
            } else {
                DEBUG_MSG(DEBUG_NORMAL, "SIGNAL", "❌ REJECTED: Conflicting position exists (hedging disabled)");
                return false;
            }
        }
        DEBUG_MSG(DEBUG_VERBOSE, "SIGNAL", "✓ Position conflict check passed");
        
        // OPTYMALIZACJA: Sprawdź spread z cache
        double currentSpread = 0;
        if(TimeCurrent() - m_lastSpreadCheck < 2) {
            currentSpread = m_lastSpread;
        } else {
            currentSpread = GetSpreadInPips();
            m_lastSpread = currentSpread;
            m_lastSpreadCheck = TimeCurrent();
        }
        
        double maxSpread = GetMaxAcceptableSpread();
        
        if(g_isBTCMode) {
            maxSpread = 2000.0;
            DEBUG_MSG(DEBUG_VERBOSE, "SIGNAL", 
                StringFormat("BTC Mode: Spread %.1f units (max: %.1f)", currentSpread, maxSpread));
        } else if(g_isCryptoMode) {
            maxSpread = 1000.0;
        }
        
        DEBUG_MSG(DEBUG_VERBOSE, "SIGNAL", 
            StringFormat("Spread check: current=%.1f, max=%.1f", currentSpread, maxSpread));
        
        if(currentSpread > maxSpread) {
            DEBUG_MSG(DEBUG_NORMAL, "SIGNAL", 
                StringFormat("⚠️ WARNING: High spread %.1f > %.1f", currentSpread, maxSpread));
            if(!g_isBTCMode && !g_isCryptoMode) {
                return false;
            }
        }
        DEBUG_MSG(DEBUG_VERBOSE, "SIGNAL", "✓ Spread OK or ignored");
        
        // Wolumen - pomiń dla crypto
        if(!g_isCryptoMode && !g_isBTCMode) {
            if(ArraySize(g_buffer_volumes) > 1) {
                double currentVolume = g_buffer_volumes[0];
                double avgVolume = 0;
                for(int i = 1; i < MathMin(5, ArraySize(g_buffer_volumes)); i++) {
                    avgVolume += g_buffer_volumes[i];
                }
                avgVolume /= 4;
                
                if(currentVolume < avgVolume * 0.05) {
                    DEBUG_MSG(DEBUG_NORMAL, "SIGNAL", 
                        StringFormat("⚠️ WARNING: Very low volume (%.2f < %.2f)", 
                            currentVolume, avgVolume * 0.05));
                }
            }
        }
        DEBUG_MSG(DEBUG_VERBOSE, "SIGNAL", "✓ Volume OK or ignored");
        
        // Walidacja poziomów cenowych
        if(!IsValidPrice(signal.entryPrice)) {
            DEBUG_MSG(DEBUG_NORMAL, "SIGNAL", 
                StringFormat("❌ REJECTED: Invalid entry price: %.5f", signal.entryPrice));
            return false;
        }
        if(!IsValidPrice(signal.stopLoss)) {
            DEBUG_MSG(DEBUG_NORMAL, "SIGNAL", 
                StringFormat("❌ REJECTED: Invalid stop loss: %.5f", signal.stopLoss));
            return false;
        }
        if(!IsValidPrice(signal.takeProfit)) {
            DEBUG_MSG(DEBUG_NORMAL, "SIGNAL", 
                StringFormat("❌ REJECTED: Invalid take profit: %.5f", signal.takeProfit));
            return false;
        }
        DEBUG_MSG(DEBUG_VERBOSE, "SIGNAL", "✓ Price levels OK");
        
        // Walidacja odległości SL/TP
        bool isBuy = (signal.direction == SIGNAL_BUY);
        if(!IsValidStopLoss(signal.entryPrice, signal.stopLoss, isBuy)) {
            int stopsLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
            DEBUG_MSG(DEBUG_NORMAL, "SIGNAL", 
                StringFormat("❌ REJECTED: Invalid SL distance (stops level: %d)", stopsLevel));
            return false;
        }
        
        if(!IsValidTakeProfit(signal.entryPrice, signal.takeProfit, isBuy)) {
            int stopsLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
            DEBUG_MSG(DEBUG_NORMAL, "SIGNAL", 
                StringFormat("❌ REJECTED: Invalid TP distance (stops level: %d)", stopsLevel));
            return false;
        }
        DEBUG_MSG(DEBUG_VERBOSE, "SIGNAL", "✓ SL/TP distances OK");
        
        // WSZYSTKO OK - SYGNAŁ ZATWIERDZONY
        signal.isValid = true;
        
        // Dodaj do historii
        AddSignalToHistory(signal);
        
        // Aktualizuj czasy
        m_lastSignalTime = TimeCurrent();
        g_lastSignalTime = TimeCurrent();
        
        if(signal.direction == SIGNAL_BUY) {
            m_lastBuySignal = TimeCurrent();
        } else {
            m_lastSellSignal = TimeCurrent();
        }
        
        // Sprawdź balans hedgingu
        CheckHedgingBalance();
        
        DEBUG_MSG(DEBUG_CRITICAL, "SIGNAL", 
            StringFormat("✅✅✅ SIGNAL VALIDATED! %s @ %.5f | SL: %.5f | TP: %.5f %s",
                signal.direction == SIGNAL_BUY ? "BUY" : "SELL",
                signal.entryPrice,
                signal.stopLoss,
                signal.takeProfit,
                m_allowHedging ? "[HEDGE]" : ""));
        
        return true;
    }
    
    double GetMaxAcceptableSpread() {
        ENUM_INSTRUMENT_TYPE instrumentType = DetectInstrumentType(_Symbol);
        
        switch(instrumentType) {
            case INSTRUMENT_FOREX:
                return 5.0;
            case INSTRUMENT_METAL:
                return 100.0;
            case INSTRUMENT_CRYPTO:
                if(g_isBTCMode) {
                    return 2000.0;
                }
                return 1000.0;
            default:
                return 10.0;
        }
    }
    
    void AddSignalToHistory(TradeSignal& signal) {
        int size = ArraySize(m_signals);
        
        if(size >= m_maxSignalsHistory) {
            CleanupOldSignals();
            size = ArraySize(m_signals);
        }
        
        ArrayResize(m_signals, size + 1);
        m_signals[size] = signal;
        m_signalsCount++;
    }
    
    TradeSignal GetLastSignal() {
        TradeSignal empty;
        empty.Reset();
        
        int size = ArraySize(m_signals);
        if(size > 0) {
            return m_signals[size - 1];
        }
        
        return empty;
    }
    
    int GetSignalHistorySize() {
        return ArraySize(m_signals);
    }
    
    void SetHedgingMode(bool allow) { 
        m_allowHedging = allow;
        DEBUG_MSG(DEBUG_NORMAL, "SIGNAL", 
            StringFormat("Hedging mode %s", allow ? "ENABLED" : "DISABLED"));
    }
    
    bool IsHedgingAllowed() { return m_allowHedging; }
    
    void SetMinSignalScore(int score) { 
        m_minSignalScore = MathMax(30, MathMin(100, score)); 
    }
    
    void SetMinRiskReward(double rr) { 
        m_minRiskReward = MathMax(1.0, MathMin(5.0, rr));
    }
    
    void SetSignalCooldown(int seconds) { 
        m_signalCooldown = MathMax(10, seconds);
    }
    
    int GetMinSignalScore() { return m_minSignalScore; }
    double GetMinRiskReward() { return m_minRiskReward; }
    datetime GetLastSignalTime() { return m_lastSignalTime; }
    int GetTotalSignalsCount() { return m_signalsCount; }
};

//+------------------------------------------------------------------+
//|                    KLASA POSITION MANAGER - FIXED               |
//+------------------------------------------------------------------+
class CPositionManager {
private:
    ulong m_magicNumber;
    int m_maxPositions;
    
    // Parametry trailing stop
    bool m_useTrailing;
    double m_trailingActivation;
    double m_trailingDistance;
    double m_trailingStep;
    
    // POPRAWIONE: Uproszczony cache bez blokad
    struct TrailingCache {
        ulong ticket;
        double lastSL;
        datetime lastUpdate;
        int updateCount;
    };
    TrailingCache m_trailingCache[];
    int m_maxCacheSize;
    
    // Parametry breakeven
    bool m_useBreakeven;
    double m_breakevenActivation;
    double m_breakevenOffset;
    
    // Parametry partial close
    bool m_usePartialClose;
    double m_partialClosePercent;
    double m_partialCloseActivation;
    
    bool IsOurPosition(CPositionInfo& pos) {
        return (pos.Symbol() == _Symbol && pos.Magic() == m_magicNumber);
    }
    
    ENUM_ORDER_TYPE_FILLING GetFillingMode() {
        int filling = (int)SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
        
        if((filling & SYMBOL_FILLING_IOC) == SYMBOL_FILLING_IOC) {
            return ORDER_FILLING_IOC;
        } else if((filling & SYMBOL_FILLING_FOK) == SYMBOL_FILLING_FOK) {
            return ORDER_FILLING_FOK;
        } else {
            return ORDER_FILLING_RETURN;
        }
    }
    
    int FindTrailingCache(ulong ticket) {
        for(int i = 0; i < ArraySize(m_trailingCache); i++) {
            if(m_trailingCache[i].ticket == ticket) {
                return i;
            }
        }
        return -1;
    }
    
    void AddToTrailingCache(ulong ticket, double sl) {
        if(ArraySize(m_trailingCache) >= m_maxCacheSize) {
            CleanupTrailingCache();
        }
        
        int size = ArraySize(m_trailingCache);
        ArrayResize(m_trailingCache, size + 1);
        m_trailingCache[size].ticket = ticket;
        m_trailingCache[size].lastSL = sl;
        m_trailingCache[size].lastUpdate = TimeCurrent();
        m_trailingCache[size].updateCount = 0;
    }
    
    void UpdatePerformanceStats(double profit) {
        g_performance.totalTrades++;
        
        if(profit > 0) {
            g_performance.winningTrades++;
            g_performance.grossProfit += profit;
            
            if(profit > g_performance.bestTrade) {
                g_performance.bestTrade = profit;
            }
            
            g_performance.maxConsecutiveLosses = 0;
            g_performance.maxConsecutiveWins++;
        } else if(profit < 0) {
            g_performance.losingTrades++;
            g_performance.grossLoss += MathAbs(profit);
            
            if(profit < g_performance.worstTrade) {
                g_performance.worstTrade = profit;
            }
            
            g_performance.maxConsecutiveWins = 0;
            g_performance.maxConsecutiveLosses++;
        }
        
        // Oblicz metryki
        g_performance.totalProfit = g_performance.grossProfit - g_performance.grossLoss;
        
        if(g_performance.totalTrades > 0) {
            g_performance.winRate = (double)g_performance.winningTrades / g_performance.totalTrades * 100;
        }
        
        if(g_performance.grossLoss > 0) {
            g_performance.profitFactor = g_performance.grossProfit / g_performance.grossLoss;
        }
        
        if(g_performance.winningTrades > 0) {
            g_performance.avgWin = g_performance.grossProfit / g_performance.winningTrades;
        }
        
        if(g_performance.losingTrades > 0) {
            g_performance.avgLoss = g_performance.grossLoss / g_performance.losingTrades;
        }
        
        if(g_performance.avgLoss > 0) {
            g_performance.avgRR = g_performance.avgWin / g_performance.avgLoss;
        }
        
        g_performance.lastTradeTime = TimeCurrent();
        
        // Informuj Risk Manager
        if(g_riskManager != NULL) {
            g_riskManager.RegisterTradeResult(profit);
        }
        
        DEBUG_MSG(DEBUG_NORMAL, "PERFORMANCE", 
            StringFormat("Trade closed: %.2f | Total: %d | Win rate: %.1f%%",
                profit, g_performance.totalTrades, g_performance.winRate));
    }
    
public:
    CPositionManager(ulong magicNumber = 500001, int maxPositions = 5) {
        m_magicNumber = magicNumber;
        m_maxPositions = maxPositions;
        m_maxCacheSize = 100;
        
        // POPRAWIONE: Bardziej agresywne domyślne ustawienia
        m_useTrailing = true;
        m_trailingActivation = 0.3;  // Szybsza aktywacja (było 0.5)
        m_trailingDistance = 0.2;    // Bliżej ceny (było 0.3)
        m_trailingStep = 0.03;        // Mniejszy krok (było 0.05)
        
        m_useBreakeven = true;
        m_breakevenActivation = 0.2;  // Szybsza aktywacja (było 0.3)
        m_breakevenOffset = 5;         // Mniejszy offset (było 10)
        
        m_usePartialClose = true;
        m_partialClosePercent = 50;
        m_partialCloseActivation = 0.6;  // Wcześniejsze zamknięcie (było 0.7)
        
        ArrayResize(m_trailingCache, 0);
    }
    
    ~CPositionManager() {
    }
    
    bool Initialize() {
        DEBUG_MSG(DEBUG_NORMAL, "POSITION", "Initializing Position Manager...");
        DEBUG_MSG(DEBUG_NORMAL, "POSITION", 
            StringFormat("Magic: %d, Max positions: %d", m_magicNumber, m_maxPositions));
        
        g_trade.SetExpertMagicNumber(m_magicNumber);
        g_trade.SetDeviationInPoints(MAX_SLIPPAGE);
        g_trade.SetTypeFilling(GetFillingMode());
        
        return true;
    }
    
    bool OpenPosition(TradeSignal& signal) {
        if(GetOpenPositionsCount() >= m_maxPositions) {
            DEBUG_MSG(DEBUG_NORMAL, "POSITION", "Max positions reached");
            return false;
        }
        
        ENUM_ORDER_TYPE orderType;
        double price;
        
        if(signal.direction == SIGNAL_BUY) {
            orderType = ORDER_TYPE_BUY;
            price = g_symbol.Ask();
        } else if(signal.direction == SIGNAL_SELL) {
            orderType = ORDER_TYPE_SELL;
            price = g_symbol.Bid();
        } else {
            DEBUG_MSG(DEBUG_NORMAL, "POSITION", "Invalid signal direction");
            return false;
        }
        
        signal.entryPrice = price;
        
        string comment = StringFormat("MC5|%s|S:%d|RR:%.1f",
            EnumToString(signal.strategy),
            signal.strength,
            signal.riskRewardRatio);
        
        g_trade.SetDeviationInPoints(MAX_SLIPPAGE);
        g_trade.SetTypeFilling(GetFillingMode());
        
        bool success = false;
        
        if(signal.direction == SIGNAL_BUY) {
            success = g_trade.Buy(signal.lotSize, _Symbol, price, 
                                 signal.stopLoss, signal.takeProfit, comment);
        } else {
            success = g_trade.Sell(signal.lotSize, _Symbol, price,
                                  signal.stopLoss, signal.takeProfit, comment);
        }
        
        if(success) {
            ulong ticket = g_trade.ResultOrder();
            
            // Dodaj do cache
            AddToTrailingCache(ticket, signal.stopLoss);
            
            DEBUG_MSG(DEBUG_CRITICAL, "POSITION", 
                StringFormat("✅ Position opened #%d: %s %.2f @ %.5f | SL: %.5f | TP: %.5f | R:R: %.2f",
                    ticket,
                    signal.direction == SIGNAL_BUY ? "BUY" : "SELL",
                    signal.lotSize,
                    price,
                    signal.stopLoss,
                    signal.takeProfit,
                    signal.riskRewardRatio));
            
            return true;
        } else {
            int error = GetLastError();
            string errorDesc = g_trade.ResultComment();
            
            DEBUG_MSG(DEBUG_CRITICAL, "POSITION", 
                StringFormat("❌ Failed to open position: %d - %s", error, errorDesc));
            
            return false;
        }
    }
    
    void ManageAll() {
        // Wyczyść stare wpisy z cache
        static datetime lastCacheClean = 0;
        if(TimeCurrent() - lastCacheClean > 60) {
            CleanupTrailingCache();
            lastCacheClean = TimeCurrent();
        }
        
        // Sprawdź zamknięte pozycje i zaktualizuj statystyki
        static int lastKnownPositions = -1;
        int currentPositions = GetOpenPositionsCount();
        
        if(lastKnownPositions > currentPositions && lastKnownPositions != -1) {
            CheckClosedPositions();
        }
        lastKnownPositions = currentPositions;
        
        // Zarządzaj otwartymi pozycjami
        for(int i = PositionsTotal() - 1; i >= 0; i--) {
            if(g_position.SelectByIndex(i)) {
                if(IsOurPosition(g_position)) {
                    ManagePosition(g_position);
                }
            }
        }
    }
    
    void CheckClosedPositions() {
        // Sprawdź ostatnie transakcje w historii
        if(HistorySelect(TimeCurrent() - 300, TimeCurrent())) {
            int total = HistoryDealsTotal();
            
            for(int i = total - 1; i >= 0; i--) {
                ulong dealTicket = HistoryDealGetTicket(i);
                
                if(dealTicket > 0) {
                    long dealMagic = HistoryDealGetInteger(dealTicket, DEAL_MAGIC);
                    long dealEntry = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
                    string dealSymbol = HistoryDealGetString(dealTicket, DEAL_SYMBOL);
                    
                    // Sprawdź czy to nasza transakcja zamykająca
                    if(dealMagic == m_magicNumber && 
                       dealSymbol == _Symbol &&
                       dealEntry == DEAL_ENTRY_OUT) {
                        
                        double profit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
                        double commission = HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
                        double swap = HistoryDealGetDouble(dealTicket, DEAL_SWAP);
                        
                        double totalProfit = profit + commission + swap;
                        
                        // Aktualizuj statystyki tylko raz dla każdej transakcji
                        static ulong lastProcessedDeal = 0;
                        if(dealTicket != lastProcessedDeal && totalProfit != 0) {
                            UpdatePerformanceStats(totalProfit);
                            lastProcessedDeal = dealTicket;
                        }
                    }
                }
            }
        }
    }
    
    void ManagePosition(CPositionInfo& pos) {
        CheckEmergencyClose(pos);
    }
    
    // POPRAWIONA FUNKCJA TRAILING STOP
    void CheckTrailingStops() {
        if(!m_useTrailing) return;
        
        // POPRAWIONE: Częstsze sprawdzanie (co 2 sekundy zamiast 5)
        static datetime lastTrailingUpdate = 0;
        if(TimeCurrent() - lastTrailingUpdate < 2) return;
        
        for(int i = PositionsTotal() - 1; i >= 0; i--) {
            if(!g_position.SelectByIndex(i)) continue;
            if(!IsOurPosition(g_position)) continue;
            
            ulong ticket = g_position.Ticket();
            
            double currentPrice = g_position.PositionType() == POSITION_TYPE_BUY ? 
                                  g_symbol.Bid() : g_symbol.Ask();
            double openPrice = g_position.PriceOpen();
            double currentSL = g_position.StopLoss();
            double currentTP = g_position.TakeProfit();
            
            // Pobierz ATR
            double atr = 0;
            if(ArraySize(g_buffer_atr_m15) > 0) atr = g_buffer_atr_m15[0];
            if(atr <= 0) atr = 100 * _Point;
            
            // POPRAWIONE: BARDZIEJ AGRESYWNE PARAMETRY
            double activationDistance, trailingDistance, minStep;
            
            ENUM_INSTRUMENT_TYPE instrumentType = DetectInstrumentType(_Symbol);
            
            if(g_isBTCMode) {
                // BTC - specjalne ustawienia
                activationDistance = MathMax(atr * 0.3, 200 * _Point);  // 30% ATR lub 200 punktów
                trailingDistance = MathMax(atr * 0.2, 150 * _Point);    // 20% ATR lub 150 punktów
                minStep = MathMax(atr * 0.05, 50 * _Point);             // 5% ATR lub 50 punktów
            }
            else if(g_isCryptoMode) {
                // Inne crypto
                activationDistance = atr * 0.35;  // 35% ATR
                trailingDistance = atr * 0.25;    // 25% ATR
                minStep = atr * 0.05;             // 5% ATR
            }
            else if(instrumentType == INSTRUMENT_METAL) {
                // Metale/Złoto
                activationDistance = MathMax(atr * 0.4, 100 * _Point);  // 40% ATR lub 100 punktów
                trailingDistance = MathMax(atr * 0.25, 80 * _Point);    // 25% ATR lub 80 punktów
                minStep = MathMax(atr * 0.05, 20 * _Point);             // 5% ATR lub 20 punktów
            }
            else {
                // Forex
                activationDistance = atr * 0.5;   // 50% ATR
                trailingDistance = atr * 0.3;     // 30% ATR
                minStep = atr * 0.05;              // 5% ATR
            }
            
            bool shouldModify = false;
            double newSL = currentSL;
            
            if(g_position.PositionType() == POSITION_TYPE_BUY) {
                double profitDistance = currentPrice - openPrice;
                
                // Sprawdź czy pozycja jest w wystarczającym zysku
                if(profitDistance >= activationDistance) {
                    // WAŻNE: Gwarantowany minimalny zysk
                    double minProfitOffset = atr * 0.1;  // 10% ATR gwarantowanego zysku
                    double suggestedSL = MathMax(
                        openPrice + minProfitOffset,      // Gwarantowany zysk
                        currentPrice - trailingDistance   // Trailing distance
                    );
                    suggestedSL = NormalizePrice(suggestedSL);
                    
                    // Upewnij się, że przesuwamy SL tylko do przodu
                    if(suggestedSL > currentSL + minStep) {
                        newSL = suggestedSL;
                        shouldModify = true;
                    }
                }
            } else { // SELL
                double profitDistance = openPrice - currentPrice;
                
                if(profitDistance >= activationDistance) {
                    // WAŻNE: Gwarantowany minimalny zysk
                    double minProfitOffset = atr * 0.1;  // 10% ATR gwarantowanego zysku
                    double suggestedSL = MathMin(
                        openPrice - minProfitOffset,      // Gwarantowany zysk
                        currentPrice + trailingDistance   // Trailing distance
                    );
                    suggestedSL = NormalizePrice(suggestedSL);
                    
                    // Upewnij się, że przesuwamy SL tylko do przodu
                    if(currentSL == 0 || suggestedSL < currentSL - minStep) {
                        newSL = suggestedSL;
                        shouldModify = true;
                    }
                }
            }
            
            if(shouldModify) {
                // Sprawdź minimalne wymagania brokera
                int stopsLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
                double minDistance = stopsLevel * _Point;
                
                bool validDistance = false;
                if(g_position.PositionType() == POSITION_TYPE_BUY) {
                    validDistance = (currentPrice - newSL >= minDistance);
                } else {
                    validDistance = (newSL - currentPrice >= minDistance);
                }
                
                if(!validDistance) {
                    continue;
                }
                
                // Wykonaj modyfikację
                if(g_trade.PositionModify(ticket, newSL, currentTP)) {
                    double guaranteedProfit = g_position.PositionType() == POSITION_TYPE_BUY ?
                                            newSL - openPrice : openPrice - newSL;
                    
                    DEBUG_MSG(DEBUG_NORMAL, "TRAILING", 
                        StringFormat("✅ Trailing updated #%d: SL %.5f -> %.5f (profit: %.2f pips)",
                            ticket, currentSL, newSL, guaranteedProfit / _Point));
                    
                    // Aktualizuj cache
                    int cacheIndex = FindTrailingCache(ticket);
                    if(cacheIndex >= 0) {
                        m_trailingCache[cacheIndex].lastSL = newSL;
                        m_trailingCache[cacheIndex].lastUpdate = TimeCurrent();
                        m_trailingCache[cacheIndex].updateCount++;
                    } else {
                        AddToTrailingCache(ticket, newSL);
                    }
                    
                    lastTrailingUpdate = TimeCurrent();
                }
            }
        }
    }
    
    // POPRAWIONA FUNKCJA BREAKEVEN
    void CheckBreakeven() {
    if(!m_useBreakeven) return;
    
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(!g_position.SelectByIndex(i)) continue;
        if(!IsOurPosition(g_position)) continue;
        
        double openPrice = g_position.PriceOpen();
        double currentSL = g_position.StopLoss();
        
        // WAŻNE: Pobierz spread i commission
        double spread = g_symbol.Spread() * _Point;
        double commission = MathAbs(g_position.Commission());
        double swap = g_position.Swap();
        
        // Oblicz minimalny offset aby być na zero po wszystkich kosztach
        double totalCosts = spread + (commission / g_position.Volume()) + MathAbs(swap / g_position.Volume());
        
        // KLUCZOWE: Minimalny zysk który chcemy zabezpieczyć
        double minProfitToSecure = totalCosts * 2;  // 2x koszty = gwarantowany mały zysk
        
        // Sprawdź czy BE już ustawiony (z marginesem bezpieczeństwa)
        bool beAlreadySet = false;
        
        if(g_position.PositionType() == POSITION_TYPE_BUY) {
            // Dla BUY: SL musi być POWYŻEJ ceny otwarcia + koszty
            beAlreadySet = (currentSL >= openPrice + minProfitToSecure);
        } else {
            // Dla SELL: SL musi być PONIŻEJ ceny otwarcia - koszty
            beAlreadySet = (currentSL > 0 && currentSL <= openPrice - minProfitToSecure);
        }
        
        if(beAlreadySet) continue;
        
        double currentPrice = g_position.PositionType() == POSITION_TYPE_BUY ? 
                              g_symbol.Bid() : g_symbol.Ask();
        
        double atr = 0;
        if(ArraySize(g_buffer_atr_m15) > 0) atr = g_buffer_atr_m15[0];
        if(atr <= 0) atr = 100 * _Point;
        
        // PARAMETRY AKTYWACJI - dostosowane do instrumentu
        double activationDistance;
        double breakevenOffset;
        
        ENUM_INSTRUMENT_TYPE instrumentType = DetectInstrumentType(_Symbol);
        
        if(g_isBTCMode) {
            // BTC - większe wartości
            activationDistance = MathMax(atr * 0.3, 200 * _Point);  // 30% ATR lub 200 punktów
            
            // WAŻNE: Offset musi pokryć spread + zapewnić zysk
            double btcSpread = 100 * _Point;  // Typowy spread BTC
            breakevenOffset = MathMax(
                btcSpread * 1.5,     // 1.5x spread
                100 * _Point         // Minimum 100 punktów
            );
        }
        else if(g_isCryptoMode) {
            activationDistance = MathMax(atr * 0.35, 150 * _Point);
            
            // Dla crypto - większy offset ze względu na spread
            double cryptoSpread = 50 * _Point;
            breakevenOffset = MathMax(
                cryptoSpread * 1.5,
                50 * _Point
            );
        }
        else if(instrumentType == INSTRUMENT_METAL) {
            activationDistance = MathMax(atr * 0.35, 100 * _Point);
            
            // Dla złota - uwzględnij typowy spread
            double metalSpread = 30 * _Point;
            breakevenOffset = MathMax(
                metalSpread * 1.5,
                50 * _Point
            );
        }
        else {
            // Forex - mniejsze wartości ale bezpieczne
            activationDistance = atr * 0.4;
            
            // Dla Forex - spread zazwyczaj mały
            double forexSpread = 2 * _Point;
            breakevenOffset = MathMax(
                forexSpread * 2,     // 2x spread
                10 * _Point          // Minimum 10 punktów (1 pip)
            );
        }
        
        // DODATKOWE ZABEZPIECZENIE: Uwzględnij aktualny spread
        double currentSpread = g_symbol.Spread() * _Point;
        breakevenOffset = MathMax(breakevenOffset, currentSpread * 1.5);
        
        // Upewnij się, że offset jest większy niż wymagane minimum brokera
        int stopsLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
        double brokerMinDistance = stopsLevel * _Point;
        breakevenOffset = MathMax(breakevenOffset, brokerMinDistance + 10 * _Point);
        
        // FINALNE ZABEZPIECZENIE: Dodaj margines bezpieczeństwa
        breakevenOffset += totalCosts;  // Dodaj wszystkie koszty
        
        bool shouldSetBE = false;
        double newSL = currentSL;
        
        if(g_position.PositionType() == POSITION_TYPE_BUY) {
            double currentProfit = currentPrice - openPrice;
            
            if(currentProfit >= activationDistance) {
                // KLUCZOWE: Ustaw SL z GWARANTOWANYM ZYSKIEM
                newSL = openPrice + breakevenOffset;
                
                // Dodatkowa weryfikacja: sprawdź czy to da zysk
                double estimatedProfit = newSL - openPrice - spread - (commission / g_position.Volume());
                
                // Jeśli nie daje zysku, zwiększ offset
                if(estimatedProfit < 0) {
                    newSL = openPrice + breakevenOffset + MathAbs(estimatedProfit) + 5 * _Point;
                }
                
                // Upewnij się że przesuwamy SL tylko do przodu
                if(newSL > currentSL) {
                    shouldSetBE = true;
                }
            }
        } else { // SELL
            double currentProfit = openPrice - currentPrice;
            
            if(currentProfit >= activationDistance) {
                // KLUCZOWE: Ustaw SL z GWARANTOWANYM ZYSKIEM
                newSL = openPrice - breakevenOffset;
                
                // Dodatkowa weryfikacja: sprawdź czy to da zysk
                double estimatedProfit = openPrice - newSL - spread - (commission / g_position.Volume());
                
                // Jeśli nie daje zysku, zmniejsz SL (dla SELL)
                if(estimatedProfit < 0) {
                    newSL = openPrice - breakevenOffset - MathAbs(estimatedProfit) - 5 * _Point;
                }
                
                // Upewnij się że przesuwamy SL tylko do przodu
                if(currentSL == 0 || newSL < currentSL) {
                    shouldSetBE = true;
                }
            }
        }
        
        if(shouldSetBE) {
            newSL = NormalizePrice(newSL);
            
            // Ostateczna weryfikacja - SL nie może być zbyt blisko aktualnej ceny
            double safeDistance = g_position.PositionType() == POSITION_TYPE_BUY ?
                                 currentPrice - newSL : newSL - currentPrice;
            
            // Musi być przynajmniej 2x broker minimum
            if(safeDistance < brokerMinDistance * 2) {
                DEBUG_MSG(DEBUG_VERBOSE, "BREAKEVEN", 
                    StringFormat("Cannot set BE for #%d: too close to price (%.2f < %.2f)", 
                        g_position.Ticket(), safeDistance/_Point, (brokerMinDistance * 2)/_Point));
                continue;
            }
            
            if(g_trade.PositionModify(g_position.Ticket(), newSL, g_position.TakeProfit())) {
                // Oblicz rzeczywisty gwarantowany zysk
                double guaranteedProfit = g_position.PositionType() == POSITION_TYPE_BUY ?
                                        (newSL - openPrice - spread) : (openPrice - newSL - spread);
                
                // Przelicz na punkty dla czytelności
                double profitInPoints = guaranteedProfit / _Point;
                
                // Pokaż dokładnie co zostało ustawione
                DEBUG_MSG(DEBUG_CRITICAL, "BREAKEVEN", 
                    StringFormat("✅ BE SET #%d: Entry=%.5f, NewSL=%.5f, Guaranteed profit=%.1f points (after costs)", 
                        g_position.Ticket(), openPrice, newSL, profitInPoints));
                
                // OSTRZEŻENIE jeśli zysk jest bardzo mały
                if(profitInPoints < 5) {
                    DEBUG_MSG(DEBUG_NORMAL, "BREAKEVEN", 
                        StringFormat("⚠️ Warning: BE profit is minimal (%.1f points) for #%d", 
                            profitInPoints, g_position.Ticket()));
                }
            } else {
                int error = GetLastError();
                if(error != 0 && error != 1) {
                    DEBUG_MSG(DEBUG_NORMAL, "BREAKEVEN", 
                        StringFormat("Failed to set BE for #%d: error %d", g_position.Ticket(), error));
                }
            }
        }
    }
}
    
    // POPRAWIONA FUNKCJA PARTIAL CLOSE
    void CheckPartialClose() {
        if(!m_usePartialClose) return;
        
        for(int i = PositionsTotal() - 1; i >= 0; i--) {
            if(!g_position.SelectByIndex(i)) continue;
            if(!IsOurPosition(g_position)) continue;
            
            string comment = g_position.Comment();
            if(StringFind(comment, "partial") >= 0) continue;
            
            double openPrice = g_position.PriceOpen();
            double takeProfit = g_position.TakeProfit();
            
            if(takeProfit <= 0) continue;
            
            double tpDistance = MathAbs(takeProfit - openPrice);
            double currentPrice = g_position.PositionType() == POSITION_TYPE_BUY ? 
                                  g_symbol.Bid() : g_symbol.Ask();
            
            double profitDistance = 0;
            if(g_position.PositionType() == POSITION_TYPE_BUY) {
                profitDistance = currentPrice - openPrice;
            } else {
                profitDistance = openPrice - currentPrice;
            }
            
            double profitRatio = profitDistance / tpDistance;
            
            // POPRAWIONE: Wcześniejsze partial close (60% zamiast 70%)
            if(profitRatio >= 0.6) {
                double currentVolume = g_position.Volume();
                double closeVolume = NormalizeLot(currentVolume * 0.5);  // Zamknij 50%
                
                if(closeVolume >= g_instrumentConfig.minLot && 
                   closeVolume < currentVolume) {
                    
                    if(g_trade.PositionClosePartial(g_position.Ticket(), closeVolume)) {
                        DEBUG_MSG(DEBUG_NORMAL, "PARTIAL", 
                            StringFormat("✅ Partial close 50%% of #%d at %.1f%% of TP",
                                g_position.Ticket(), profitRatio * 100));
                    }
                }
            }
        }
    }
    
    bool CheckEmergencyClose(CPositionInfo& pos) {
        double profit = pos.Profit() + pos.Swap() + pos.Commission();
        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        
        // Emergency close przy dużej stracie
        double maxLossPercent = 0.02;  // 2% max strata na pozycję
        
        if(profit < 0 && MathAbs(profit) > balance * maxLossPercent) {
            g_trade.PositionClose(pos.Ticket());
            
            DEBUG_MSG(DEBUG_CRITICAL, "EMERGENCY", 
                StringFormat("Emergency close #%d, Loss: %.2f (%.2f%% of balance)", 
                    pos.Ticket(), profit, MathAbs(profit)/balance*100));
            
            return true;
        }
        
        return false;
    }
    
    // Czyszczenie cache
    void CleanupTrailingCache() {
        // Usuń wpisy dla nieistniejących pozycji
        for(int i = ArraySize(m_trailingCache) - 1; i >= 0; i--) {
            bool found = false;
            for(int j = 0; j < PositionsTotal(); j++) {
                if(g_position.SelectByIndex(j)) {
                    if(g_position.Ticket() == m_trailingCache[i].ticket) {
                        found = true;
                        break;
                    }
                }
            }
            
            if(!found) {
                // Usuń z cache
                for(int k = i; k < ArraySize(m_trailingCache) - 1; k++) {
                    m_trailingCache[k] = m_trailingCache[k + 1];
                }
                ArrayResize(m_trailingCache, ArraySize(m_trailingCache) - 1);
            }
        }
        
        // Ogranicz wielkość cache
        if(ArraySize(m_trailingCache) > m_maxCacheSize) {
            int toRemove = ArraySize(m_trailingCache) - m_maxCacheSize;
            for(int i = 0; i < ArraySize(m_trailingCache) - toRemove; i++) {
                m_trailingCache[i] = m_trailingCache[i + toRemove];
            }
            ArrayResize(m_trailingCache, m_maxCacheSize);
        }
    }
    
    int GetOpenPositionsCount() {
        int count = 0;
        
        for(int i = 0; i < PositionsTotal(); i++) {
            if(g_position.SelectByIndex(i)) {
                if(IsOurPosition(g_position)) {
                    count++;
                }
            }
        }
        
        return count;
    }
    
    double GetTotalVolume() {
        double volume = 0;
        
        for(int i = 0; i < PositionsTotal(); i++) {
            if(g_position.SelectByIndex(i)) {
                if(IsOurPosition(g_position)) {
                    volume += g_position.Volume();
                }
            }
        }
        
        return volume;
    }
    
    double GetFloatingPL() {
        double pl = 0;
        
        for(int i = 0; i < PositionsTotal(); i++) {
            if(g_position.SelectByIndex(i)) {
                if(IsOurPosition(g_position)) {
                    pl += g_position.Profit() + g_position.Swap() + g_position.Commission();
                }
            }
        }
        
        return pl;
    }
    
    void SetTrailingParams(bool use, double activation, double distance, double step) {
        m_useTrailing = use;
        m_trailingActivation = MathMax(0.1, activation);
        m_trailingDistance = MathMax(0.1, distance);
        m_trailingStep = MathMax(0.01, step);
        
        DEBUG_MSG(DEBUG_NORMAL, "POSITION", 
            StringFormat("Trailing params updated: Act=%.2f, Dist=%.2f, Step=%.3f",
                m_trailingActivation, m_trailingDistance, m_trailingStep));
    }
    
    void SetBreakevenParams(bool use, double activation, double offset) {
        m_useBreakeven = use;
        m_breakevenActivation = activation;
        m_breakevenOffset = offset;
    }
    
    void SetPartialCloseParams(bool use, double percent, double activation) {
        m_usePartialClose = use;
        m_partialClosePercent = percent;
        m_partialCloseActivation = activation;
    }
    
    int GetCacheSize() { return ArraySize(m_trailingCache); }
    int GetMaxPositions() { return m_maxPositions; }
    ulong GetMagicNumber() { return m_magicNumber; }
};

#endif // MC5_MANAGERS_MQH