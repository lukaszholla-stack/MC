//+------------------------------------------------------------------+
//|                                             UltimateTrader.mq5 |
//|                  Ultimate Trader EA - Hybrid Trading System       |
//|                        Combining Best of GoldTrader + MC5         |
//+------------------------------------------------------------------+
#property copyright "Ultimate Trader Development Team"
#property link      "https://github.com/lukaszholla-stack/MC"
#property version   "1.00"
#property description "Ultimate hybrid EA combining 8 strategies"
#property description "Forex | Metals | Crypto | Scalping"
#property description "Professional risk management + GUI dashboard"
#property strict

#include "UT_Core.mqh"
#include "UT_Analysis.mqh"
#include "UT_Strategies.mqh"
#include "UT_Engine.mqh"

//+------------------------------------------------------------------+
//|                        INPUT PARAMETERS                           |
//+------------------------------------------------------------------+

input group "═══════ 🎯 GŁÓWNE USTAWIENIA ═══════"
input ENUM_TRADING_MODE    InpTradingMode = MODE_BALANCED;        // Tryb tradingu
input ENUM_STRATEGY_MODE   InpStrategyMode = STRATEGY_ADAPTIVE;   // Strategia
input bool                 InpAutoTrading = true;                 // Auto-trading
input int                  InpMagicNumber = 777001;               // Magic Number

input group "═══════ 💰 ZARZĄDZANIE RYZYKIEM ═══════"
input double               InpRiskPerTrade = 1.0;                 // Ryzyko per trade (%)
input double               InpMaxDailyLoss = 5.0;                 // Max dzienna strata (%)
input double               InpMaxDrawdown = 20.0;                 // Max total drawdown (%)
input int                  InpMaxPositions = 5;                   // Max pozycji

input group "═══════ 🎲 PARAMETRY STRATEGII ═══════"
input int                  InpMinSignalScore = 60;                // Min siła sygnału (0-100)
input double               InpMinRiskReward = 1.5;                // Min R:R ratio

input group "═══════ 🛡️ ZABEZPIECZENIA ═══════"
input bool                 InpUseTrailing = true;                 // Trailing Stop
input bool                 InpUseBreakeven = true;                // Break-Even
input bool                 InpUsePartialClose = true;             // Partial Close (50% @ 70%)

input group "═══════ ⚡ SCALPING MODE (Opcjonalny) ═══════"
input bool                 InpEnableScalping = false;             // Włącz scalping
input int                  InpScalpMaxPositions = 20;             // Max pozycji scalp
input double               InpScalpTargetUSD = 1.50;              // Target profit ($)
input int                  InpScalpMaxSpread = 20;                // Max spread (punkty)

input group "═══════ 🖥️ INTERFACE ═══════"
input bool                 InpShowDashboard = true;               // Pokaż GUI
input ENUM_LANGUAGE        InpLanguage = LANG_AUTO;               // Język

input group "═══════ 🔍 DIAGNOSTYKA ═══════"
input ENUM_DEBUG_LEVEL     InpDebugLevel = DEBUG_NORMAL;          // Poziom debugowania

//+------------------------------------------------------------------+
//|                       GLOBAL VARIABLES                            |
//+------------------------------------------------------------------+

// Main engine
CEngine* g_engine = NULL;

// Timer counter
int g_timerCount = 0;

//+------------------------------------------------------------------+
//|                     EXPERT INITIALIZATION                         |
//+------------------------------------------------------------------+
int OnInit() {
    Print("╔════════════════════════════════════════════════════════╗");
    Print("║                                                         ║");
    Print("║         ULTIMATE TRADER EA v1.0 - STARTING...          ║");
    Print("║                                                         ║");
    Print("║  Hybrid System: GoldTrader + Market Compass v5         ║");
    Print("║  Strategies: Forex | Metal | Crypto | Scalping         ║");
    Print("║  Features: ML Scoring | Advanced Risk Mgmt | GUI       ║");
    Print("║                                                         ║");
    Print("╚════════════════════════════════════════════════════════╝");
    Print("");

    // Initialize symbol info
    if(!g_symbol.Name(_Symbol)) {
        Print("❌ ERROR: Failed to initialize symbol info");
        return INIT_FAILED;
    }

    // Initialize trade object
    g_trade.SetExpertMagicNumber(InpMagicNumber);
    g_trade.SetDeviationInPoints(10);
    g_trade.SetTypeFilling(ORDER_FILLING_FOK);
    g_trade.LogLevel(LOG_LEVEL_ERRORS);

    // Create and initialize engine
    g_engine = new CEngine();

    if(g_engine == NULL) {
        Print("❌ ERROR: Failed to create engine");
        return INIT_FAILED;
    }

    if(!g_engine.Initialize(InpTradingMode, InpStrategyMode)) {
        Print("❌ ERROR: Engine initialization failed");
        delete g_engine;
        g_engine = NULL;
        return INIT_FAILED;
    }

    // Start timer (1 second interval)
    EventSetTimer(1);

    Print("");
    Print("╔════════════════════════════════════════════════════════╗");
    Print("║                                                         ║");
    Print("║         ✅ ULTIMATE TRADER EA - READY TO TRADE!        ║");
    Print("║                                                         ║");
    Print("╚════════════════════════════════════════════════════════╝");
    Print("");
    Print("📊 Configuration:");
    Print("   Symbol: ", _Symbol);
    Print("   Timeframe: ", EnumToString(PERIOD_CURRENT));
    Print("   Mode: ", EnumToString(InpTradingMode));
    Print("   Strategy: ", EnumToString(InpStrategyMode));
    Print("   Risk per trade: ", InpRiskPerTrade, "%");
    Print("   Max daily loss: ", InpMaxDailyLoss, "%");
    Print("   Max drawdown: ", InpMaxDrawdown, "%");
    Print("   Dashboard: ", InpShowDashboard ? "ON" : "OFF");
    Print("   Scalping: ", InpEnableScalping ? "ENABLED" : "DISABLED");
    Print("");

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//|                      EXPERT DEINITIALIZATION                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    EventKillTimer();

    Print("");
    Print("╔════════════════════════════════════════════════════════╗");
    Print("║                                                         ║");
    Print("║        ULTIMATE TRADER EA - SHUTTING DOWN...           ║");
    Print("║                                                         ║");
    Print("╚════════════════════════════════════════════════════════╝");
    Print("");
    Print("📊 Shutdown Reason: ", GetDeInitReason(reason));
    Print("");

    // Cleanup engine
    if(g_engine != NULL) {
        g_engine.OnDeinit();
        delete g_engine;
        g_engine = NULL;
    }

    // Final statistics
    if(g_performance.totalTrades > 0) {
        Print("╔════════════════════════════════════════════════════════╗");
        Print("║              FINAL PERFORMANCE STATISTICS              ║");
        Print("╠════════════════════════════════════════════════════════╣");
        Print("║ Total Trades:      ", g_performance.totalTrades, "                                 ║");
        Print("║ Winning Trades:    ", g_performance.winningTrades, "                                 ║");
        Print("║ Losing Trades:     ", g_performance.losingTrades, "                                 ║");
        Print("║ Win Rate:          ", DoubleToString(g_performance.winRate, 2), "%                           ║");
        Print("║ Profit Factor:     ", DoubleToString(g_performance.profitFactor, 2), "                             ║");
        Print("║ Total Profit:      $", DoubleToString(g_performance.totalProfit, 2), "                          ║");
        Print("╚════════════════════════════════════════════════════════╝");
    }

    Print("");
    Print("✅ Ultimate Trader EA shutdown complete");
    Print("");
}

//+------------------------------------------------------------------+
//|                         EXPERT TICK FUNCTION                      |
//+------------------------------------------------------------------+
void OnTick() {
    // Check if engine is initialized
    if(g_engine == NULL || !InpAutoTrading) {
        return;
    }

    // Pass control to engine
    g_engine.OnTick();
}

//+------------------------------------------------------------------+
//|                        TIMER FUNCTION                             |
//+------------------------------------------------------------------+
void OnTimer() {
    g_timerCount++;

    // Daily reset at midnight
    static int lastDay = 0;
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);

    if(dt.day != lastDay) {
        lastDay = dt.day;
        g_state.dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        Print("📅 New day started - Daily stats reset");
    }

    // Health check every 60 seconds
    if(g_timerCount % 60 == 0) {
        PrintHealthCheck();
    }

    // ML weights update every 5 minutes
    if(g_timerCount % 300 == 0 && g_performance.totalTrades > 10) {
        g_mlWeights.UpdateWeights(g_performance.winRate);
        Print("🤖 ML weights updated based on performance");
    }
}

//+------------------------------------------------------------------+
//|                       HELPER FUNCTIONS                            |
//+------------------------------------------------------------------+
void PrintHealthCheck() {
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double margin = AccountInfoDouble(ACCOUNT_MARGIN);
    double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    double marginLevel = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);

    int openPositions = PositionsTotal();

    Print("╔════════════════════════════════════════════════════════╗");
    Print("║                   HEALTH CHECK                          ║");
    Print("╠════════════════════════════════════════════════════════╣");
    Print("║ Time:              ", TimeToString(TimeCurrent()), "                   ║");
    Print("║ Balance:           $", DoubleToString(balance, 2), "                         ║");
    Print("║ Equity:            $", DoubleToString(equity, 2), "                         ║");
    Print("║ Margin:            $", DoubleToString(margin, 2), "                         ║");
    Print("║ Free Margin:       $", DoubleToString(freeMargin, 2), "                         ║");
    Print("║ Margin Level:      ", DoubleToString(marginLevel, 2), "%                           ║");
    Print("║ Open Positions:    ", openPositions, "                                 ║");
    Print("╠════════════════════════════════════════════════════════╣");
    Print("║ Total Trades:      ", g_performance.totalTrades, "                                 ║");
    Print("║ Win Rate:          ", DoubleToString(g_performance.winRate, 2), "%                           ║");
    Print("║ Profit Factor:     ", DoubleToString(g_performance.profitFactor, 2), "                             ║");
    Print("╚════════════════════════════════════════════════════════╝");
}

//+------------------------------------------------------------------+
//|                                                                  |
//|                      ULTIMATE TRADER EA v1.0                     |
//|                                                                  |
//|  🌟 Features:                                                    |
//|  ✅ 8 Trading Strategies (Forex, Metal, Crypto, Scalping, etc.) |
//|  ✅ Advanced Risk Management (Daily limits, DD protection)       |
//|  ✅ ML-Based Adaptive Scoring                                   |
//|  ✅ Multi-Timeframe Analysis (H4, D1, W1)                       |
//|  ✅ Professional GUI Dashboard                                  |
//|  ✅ Trailing Stop + Break-Even + Partial Close                  |
//|  ✅ Micro Account Support ($10-100)                             |
//|  ✅ Scalping Mode (20 positions, $1.50 target)                  |
//|                                                                  |
//|  📖 Documentation: /MC/docs/                                    |
//|  🐛 Issues: https://github.com/lukaszholla-stack/MC/issues     |
//|                                                                  |
//|  Generated with Claude Code                                     |
//|  Co-Authored-By: Claude <noreply@anthropic.com>                |
//|                                                                  |
//+------------------------------------------------------------------+
