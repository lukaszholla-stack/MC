//+------------------------------------------------------------------+
//|                                                    MC5_Utils.mqh |
//|                  Funkcje pomocnicze i diagnostyka                |
//+------------------------------------------------------------------+
#ifndef MC5_UTILS_MQH
#define MC5_UTILS_MQH

#include "MC5_Core.mqh"

//+------------------------------------------------------------------+
//|                    FUNKCJE MATEMATYCZNE                          |
//+------------------------------------------------------------------+
// Bezpieczne dzielenie
double SafeDivide(double numerator, double denominator) {
    if(denominator == 0) return 0;
    return numerator / denominator;
}

// Oblicz procent
double CalculatePercentage(double value, double total) {
    return SafeDivide(value * 100, total);
}

// Normalizacja ceny
double NormalizePrice(double price, int digits = -1) {
    if(digits < 0) digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    return NormalizeDouble(price, digits);
}

// Normalizacja lota
double NormalizeLot(double lot) {
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    
    // Zaokrąglij do kroku
    if(lotStep > 0) {
        lot = MathFloor(lot / lotStep) * lotStep;
    }
    
    // Ogranicz do min/max
    lot = MathMax(minLot, MathMin(maxLot, lot));
    
    // Określ precyzję
    int lotDigits = 2;
    if(lotStep == 0.001) lotDigits = 3;
    else if(lotStep == 0.01) lotDigits = 2;
    else if(lotStep == 0.1) lotDigits = 1;
    else if(lotStep == 1.0) lotDigits = 0;
    
    return NormalizeDouble(lot, lotDigits);
}

// Konwersja punktów na cenę
double PointsToPrice(int points) {
    return points * _Point;
}

// Konwersja ceny na punkty
int PriceToPoints(double price) {
    if(_Point == 0) return 0;
    return (int)(price / _Point);
}

// Konwersja pipsów na punkty
int PipsToPoints(double pips) {
    int multiplier = (_Digits == 5 || _Digits == 3) ? 10 : 1;
    return (int)(pips * multiplier);
}

// Konwersja punktów na pipsy
double PointsToPips(int points) {
    int multiplier = (_Digits == 5 || _Digits == 3) ? 10 : 1;
    return (double)points / multiplier;
}

// Clamp wartości
double Clamp(double value, double min, double max) {
    return MathMax(min, MathMin(max, value));
}

// Interpolacja liniowa
double Lerp(double a, double b, double t) {
    return a + (b - a) * Clamp(t, 0, 1);
}

//+------------------------------------------------------------------+
//|                    FUNKCJE CZASOWE                               |
//+------------------------------------------------------------------+
// Sprawdź czy nowy bar
bool IsNewBar(ENUM_TIMEFRAMES timeframe) {
    static datetime lastBarTime[];
    
    int tf_index = TimeframeToIndex(timeframe);
    if(tf_index < 0) return false;
    
    if(ArraySize(lastBarTime) <= tf_index) {
        ArrayResize(lastBarTime, tf_index + 1);
    }
    
    datetime currentBarTime = iTime(_Symbol, timeframe, 0);
    
    if(currentBarTime > lastBarTime[tf_index]) {
        lastBarTime[tf_index] = currentBarTime;
        return true;
    }
    
    return false;
}

// Konwersja timeframe na indeks
int TimeframeToIndex(ENUM_TIMEFRAMES timeframe) {
    switch(timeframe) {
        case PERIOD_M1:  return 0;
        case PERIOD_M5:  return 1;
        case PERIOD_M15: return 2;
        case PERIOD_M30: return 3;
        case PERIOD_H1:  return 4;
        case PERIOD_H4:  return 5;
        case PERIOD_D1:  return 6;
        case PERIOD_W1:  return 7;
        case PERIOD_MN1: return 8;
        default:         return -1;
    }
}

// Konwersja timeframe na string
string TimeframeToString(ENUM_TIMEFRAMES timeframe) {
    switch(timeframe) {
        case PERIOD_M1:  return "M1";
        case PERIOD_M5:  return "M5";
        case PERIOD_M15: return "M15";
        case PERIOD_M30: return "M30";
        case PERIOD_H1:  return "H1";
        case PERIOD_H4:  return "H4";
        case PERIOD_D1:  return "D1";
        case PERIOD_W1:  return "W1";
        case PERIOD_MN1: return "MN1";
        default:         return "Unknown";
    }
}

// Sprawdź sesję handlową
ENUM_MARKET_SESSION GetCurrentSession() {
    MqlDateTime time;
    TimeCurrent(time);
    
    int hour = time.hour;
    
    // Sydney: 22:00 - 07:00 GMT
    if(hour >= 22 || hour < 7) return SESSION_SYDNEY;
    
    // Tokyo: 00:00 - 09:00 GMT
    if(hour >= 0 && hour < 9) return SESSION_TOKYO;
    
    // London: 08:00 - 17:00 GMT
    if(hour >= 8 && hour < 17) return SESSION_LONDON;
    
    // New York: 13:00 - 22:00 GMT
    if(hour >= 13 && hour < 22) return SESSION_NEWYORK;
    
    return SESSION_CLOSED;
}

// Czy weekend
bool IsWeekend() {
    MqlDateTime time;
    TimeCurrent(time);
    return (time.day_of_week == 0 || time.day_of_week == 6);
}

// Czy czas letni
bool IsDST() {
    MqlDateTime time;
    TimeCurrent(time);
    
    // Uproszczona logika DST (marzec - listopad)
    if(time.mon >= 3 && time.mon <= 10) {
        return true;
    }
    
    return false;
}

// Pobierz nazwę dnia tygodnia
string GetDayOfWeekName(int day) {
    switch(day) {
        case 0: return "Sunday";
        case 1: return "Monday";
        case 2: return "Tuesday";
        case 3: return "Wednesday";
        case 4: return "Thursday";
        case 5: return "Friday";
        case 6: return "Saturday";
        default: return "Unknown";
    }
}

//+------------------------------------------------------------------+
//|                    FUNKCJE INSTRUMENTU                           |
//+------------------------------------------------------------------+
// Wykryj typ instrumentu
ENUM_INSTRUMENT_TYPE DetectInstrumentType(string symbol) {
    string sym = symbol;
    StringToUpper(sym);
    
    // Kryptowaluty
    if(StringFind(sym, "BTC") >= 0 || StringFind(sym, "BITCOIN") >= 0 ||
       StringFind(sym, "ETH") >= 0 || StringFind(sym, "ETHEREUM") >= 0 ||
       StringFind(sym, "LTC") >= 0 || StringFind(sym, "XRP") >= 0 ||
       StringFind(sym, "BNB") >= 0 || StringFind(sym, "ADA") >= 0 ||
       StringFind(sym, "DOGE") >= 0 || StringFind(sym, "CRYPTO") >= 0 ||
       StringFind(sym, "SOL") >= 0 || StringFind(sym, "MATIC") >= 0) {
        return INSTRUMENT_CRYPTO;
    }
    
    // Metale
    if(StringFind(sym, "GOLD") >= 0 || StringFind(sym, "XAU") >= 0 ||
       StringFind(sym, "SILVER") >= 0 || StringFind(sym, "XAG") >= 0 ||
       StringFind(sym, "PLATINUM") >= 0 || StringFind(sym, "XPT") >= 0 ||
       StringFind(sym, "PALLADIUM") >= 0 || StringFind(sym, "XPD") >= 0 ||
       StringFind(sym, "COPPER") >= 0) {
        return INSTRUMENT_METAL;
    }
    
    // Indeksy
    if(StringFind(sym, "US30") >= 0 || StringFind(sym, "US500") >= 0 ||
       StringFind(sym, "NAS100") >= 0 || StringFind(sym, "DAX") >= 0 ||
       StringFind(sym, "FTSE") >= 0 || StringFind(sym, "NIKKEI") >= 0 ||
       StringFind(sym, "DJ30") >= 0 || StringFind(sym, "SP500") >= 0 ||
       StringFind(sym, "NDX") >= 0) {
        return INSTRUMENT_INDEX;
    }
    
    // Akcje
    if(StringFind(sym, "AAPL") >= 0 || StringFind(sym, "GOOGL") >= 0 ||
       StringFind(sym, "MSFT") >= 0 || StringFind(sym, "AMZN") >= 0 ||
       StringFind(sym, "TSLA") >= 0 || StringFind(sym, "FB") >= 0 ||
       StringFind(sym, "NFLX") >= 0) {
        return INSTRUMENT_STOCK;
    }
    
    // Forex (domyślnie)
    return INSTRUMENT_FOREX;
}

// Pobierz nazwę typu instrumentu
string GetInstrumentTypeName(ENUM_INSTRUMENT_TYPE type) {
    switch(type) {
        case INSTRUMENT_FOREX: return "Forex";
        case INSTRUMENT_METAL: return "Metal";
        case INSTRUMENT_CRYPTO: return "Crypto";
        case INSTRUMENT_INDEX: return "Index";
        case INSTRUMENT_STOCK: return "Stock";
        default: return "Unknown";
    }
}

// Oblicz spread w pipsach
double GetSpreadInPips() {
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double spread = ask - bid;
    
    ENUM_INSTRUMENT_TYPE type = DetectInstrumentType(_Symbol);
    
    // Dla kryptowalut - zwróć spread w jednostkach
    if(type == INSTRUMENT_CRYPTO) {
        return spread;
    }
    
    // Dla metali - zwróć spread w punktach
    if(type == INSTRUMENT_METAL) {
        return spread / _Point;
    }
    
    // Dla Forex - konwertuj na pipsy
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    double pipSize = (digits == 5 || digits == 3) ? 0.0001 : 0.01;
    
    return spread / pipSize;
}

// Sprawdź czy można handlować
bool IsTradeAllowed() {
    // Sprawdź terminal
    if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) return false;
    
    // Sprawdź EA
    if(!MQLInfoInteger(MQL_TRADE_ALLOWED)) return false;
    
    // Sprawdź symbol
    long tradeMode = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE);
    if(tradeMode == SYMBOL_TRADE_MODE_DISABLED) return false;
    
    // Sprawdź czy rynek otwarty
    if(tradeMode == SYMBOL_TRADE_MODE_CLOSEONLY) return false;
    
    return true;
}

//+------------------------------------------------------------------+
//|                    FUNKCJE WALIDACJI                             |
//+------------------------------------------------------------------+
// Sprawdź czy cena jest prawidłowa
bool IsValidPrice(double price) {
    // Prosta walidacja
    if(price <= 0.0) return false;
    if(price >= 999999.0) return false;
    
    // Sprawdzenie czy nie jest NaN (Not a Number)
    // NaN != NaN zawsze zwraca true
    if(price != price) return false;
    
    return true;
}

// Sprawdź czy lot jest prawidłowy
bool IsValidLot(double lot) {
    if(lot <= 0) return false;
    
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    
    if(minLot <= 0 || maxLot <= 0) return false;
    
    return (lot >= minLot && lot <= maxLot);
}

// Sprawdź czy stop loss jest prawidłowy
bool IsValidStopLoss(double price, double stopLoss, bool isBuy) {
    if(stopLoss <= 0) return false;
    if(price <= 0) return false;
    
    int stopsLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
    double minDistance = stopsLevel * _Point;
    
    if(minDistance < 0) minDistance = 0;
    
    if(isBuy) {
        return (price - stopLoss >= minDistance);
    } else {
        return (stopLoss - price >= minDistance);
    }
}

// Sprawdź czy take profit jest prawidłowy
bool IsValidTakeProfit(double price, double takeProfit, bool isBuy) {
    if(takeProfit <= 0) return false;
    if(price <= 0) return false;
    
    int stopsLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
    double minDistance = stopsLevel * _Point;
    
    if(minDistance < 0) minDistance = 0;
    
    if(isBuy) {
        return (takeProfit - price >= minDistance);
    } else {
        return (price - takeProfit >= minDistance);
    }
}

// Walidacja numeru magicznego
bool IsValidMagicNumber(ulong magic) {
    return (magic > 0 && magic <= ULONG_MAX);
}

//+------------------------------------------------------------------+
//|                POPRAWIONA KLASA DIAGNOSTYKI                      |
//+------------------------------------------------------------------+
class CDiagnostics {
private:
    ENUM_DEBUG_LEVEL m_debugLevel;
    bool             m_logToFile;
    string           m_logFileName;
    int              m_fileHandle;
    datetime         m_sessionStart;
    int              m_messagesLogged;
    ulong            m_maxFileSize;
    int              m_rotationCounter;
    
    // NOWE: Kontrola częstotliwości logów
    struct LogThrottle {
        string lastMessage;
        datetime lastTime;
        int repeatCount;
    };
    LogThrottle m_throttle[];
    int m_maxThrottleEntries;
    
    string FormatMessage(ENUM_DEBUG_LEVEL level, string component, string message) {
        string timestamp = TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS);
        string levelStr = EnumToString(level);
        StringReplace(levelStr, "DEBUG_", "");
        
        return StringFormat("[%s] [%-8s] [%-10s] %s", 
                           timestamp, levelStr, component, message);
    }
    
    string GetLogFileName() {
        string date = TimeToString(TimeCurrent(), TIME_DATE);
        StringReplace(date, ".", "_");
        return StringFormat("MC5_%s_%d.log", date, m_rotationCounter);
    }
    
    // NOWA FUNKCJA: Sprawdź czy wiadomość powinna być zalogowana
    bool ShouldLog(string component, string message) {
        // Zawsze loguj krytyczne
        if(m_debugLevel == DEBUG_CRITICAL) return true;
        
        // Specjalne traktowanie dla DAILY_PL
        if(component == "DAILY_PL") {
            // Znajdź w cache
            for(int i = 0; i < ArraySize(m_throttle); i++) {
                if(m_throttle[i].lastMessage == message) {
                    // Jeśli ta sama wiadomość w ciągu 30 sekund - pomiń
                    if(TimeCurrent() - m_throttle[i].lastTime < 30) {
                        m_throttle[i].repeatCount++;
                        return false;
                    }
                    // Aktualizuj czas
                    m_throttle[i].lastTime = TimeCurrent();
                    m_throttle[i].repeatCount = 0;
                    return true;
                }
            }
            
            // Dodaj nowy wpis
            int size = ArraySize(m_throttle);
            if(size >= m_maxThrottleEntries) {
                // Usuń najstarszy
                for(int i = 0; i < size - 1; i++) {
                    m_throttle[i] = m_throttle[i + 1];
                }
                size--;
            }
            
            ArrayResize(m_throttle, size + 1);
            m_throttle[size].lastMessage = message;
            m_throttle[size].lastTime = TimeCurrent();
            m_throttle[size].repeatCount = 0;
        }
        
        return true;
    }
    
public:
    CDiagnostics(ENUM_DEBUG_LEVEL debugLevel = DEBUG_NORMAL, bool logToFile = false) {
        m_debugLevel = debugLevel;
        m_logToFile = logToFile;
        m_fileHandle = INVALID_HANDLE;
        m_messagesLogged = 0;
        m_maxFileSize = 52428800UL;  // 50MB zamiast 10MB
        m_rotationCounter = 0;
        m_maxThrottleEntries = 100;
        
        ArrayResize(m_throttle, 0);
        
        if(m_logToFile) {
            InitializeLogFile();
        }
    }
    
    ~CDiagnostics() {
        if(m_fileHandle != INVALID_HANDLE) {
            FileWrite(m_fileHandle, "════════════════════════════════════════════════════════════════");
            FileWrite(m_fileHandle, "Session ended at: " + TimeToString(TimeCurrent()));
            FileWrite(m_fileHandle, "Total messages logged: " + IntegerToString(m_messagesLogged));
            
            // Pokaż powtórzone wiadomości
            for(int i = 0; i < ArraySize(m_throttle); i++) {
                if(m_throttle[i].repeatCount > 0) {
                    FileWrite(m_fileHandle, 
                        StringFormat("Message repeated %d times: %s", 
                            m_throttle[i].repeatCount, 
                            m_throttle[i].lastMessage));
                }
            }
            
            FileWrite(m_fileHandle, "════════════════════════════════════════════════════════════════");
            FileClose(m_fileHandle);
        }
    }
    
    void InitializeLogFile() {
        m_logFileName = GetLogFileName();
        
        m_fileHandle = FileOpen(m_logFileName, FILE_WRITE|FILE_READ|FILE_TXT|FILE_SHARE_READ);
        
        if(m_fileHandle != INVALID_HANDLE) {
            FileSeek(m_fileHandle, 0, SEEK_END);
            FileWrite(m_fileHandle, "════════════════════════════════════════════════════════════════");
            FileWrite(m_fileHandle, "    MARKET COMPASS v5.1 - LOG FILE");
            FileWrite(m_fileHandle, "    Started: " + TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS));
            FileWrite(m_fileHandle, "════════════════════════════════════════════════════════════════");
            FileWrite(m_fileHandle, "");
        }
    }
    
    void Log(ENUM_DEBUG_LEVEL level, string component, string message) {
        if(level > m_debugLevel) return;
        
        // NOWE: Sprawdź throttling
        if(!ShouldLog(component, message)) {
            return;
        }
        
        m_messagesLogged++;
        
        string formattedMsg = FormatMessage(level, component, message);
        
        // Print do terminala dla ważnych komunikatów
        // WYJĄTEK: Nie printuj DAILY_PL do terminala
        if(level <= DEBUG_NORMAL && component != "DAILY_PL") {
            Print(formattedMsg);
        }
        
        // Zapis do pliku
        if(m_logToFile && m_fileHandle != INVALID_HANDLE) {
            FileWrite(m_fileHandle, formattedMsg);
            FileFlush(m_fileHandle);
            
            // Sprawdź rozmiar pliku
            if(FileSize(m_fileHandle) > m_maxFileSize) {
                RotateLogs();
            }
        }
    }
    
    // Rotacja logów
    void RotateLogs() {
        if(!m_logToFile || m_fileHandle == INVALID_HANDLE) return;
        
        // Pokaż statystyki przed rotacją
        FileWrite(m_fileHandle, "");
        FileWrite(m_fileHandle, "LOG ROTATION SUMMARY:");
        for(int i = 0; i < ArraySize(m_throttle); i++) {
            if(m_throttle[i].repeatCount > 0) {
                FileWrite(m_fileHandle, 
                    StringFormat("- Suppressed %d repeats of: %s", 
                        m_throttle[i].repeatCount, 
                        m_throttle[i].lastMessage));
            }
        }
        
        // Zamknij obecny plik
        FileClose(m_fileHandle);
        
        // Zwiększ licznik rotacji
        m_rotationCounter++;
        
        // Wyczyść throttle
        ArrayResize(m_throttle, 0);
        
        // Utwórz nowy plik
        InitializeLogFile();
        
        Log(DEBUG_NORMAL, "SYSTEM", "Log file rotated: " + m_logFileName);
    }
    
    void StartSession() {
        m_sessionStart = TimeCurrent();
        Log(DEBUG_CRITICAL, "SYSTEM", "Session started");
    }
    
    void EndSession() {
        datetime sessionEnd = TimeCurrent();
        int sessionDuration = (int)(sessionEnd - m_sessionStart);
        
        string summary = StringFormat("Session ended. Duration: %d seconds, Messages: %d",
                                     sessionDuration, m_messagesLogged);
        
        Log(DEBUG_CRITICAL, "SYSTEM", summary);
    }
    
    void SaveState(SystemState& state) {
        if(!m_logToFile) return;
        
        string filename = "MC5_state.json";
        int handle = FileOpen(filename, FILE_WRITE|FILE_TXT);
        
        if(handle != INVALID_HANDLE) {
            FileWrite(handle, "{");
            FileWrite(handle, "  \"timestamp\": \"" + TimeToString(TimeCurrent()) + "\",");
            FileWrite(handle, "  \"isActive\": " + (state.isActive ? "true" : "false") + ",");
            FileWrite(handle, "  \"isInitialized\": " + (state.isInitialized ? "true" : "false") + ",");
            FileWrite(handle, "  \"isTrading\": " + (state.isTrading ? "true" : "false") + ",");
            FileWrite(handle, "  \"ticksProcessed\": " + IntegerToString(state.ticksProcessed) + ",");
            FileWrite(handle, "  \"barsProcessed\": " + IntegerToString(state.barsProcessed) + ",");
            FileWrite(handle, "  \"lastError\": \"" + state.lastError + "\"");
            FileWrite(handle, "}");
            
            FileClose(handle);
        }
    }
    
    void SaveFinalReport(PerformanceStats& stats) {
        string filename = "MC5_final_report_" + TimeToString(TimeCurrent(), TIME_DATE) + ".txt";
        StringReplace(filename, ".", "_");
        
        int handle = FileOpen(filename, FILE_WRITE|FILE_TXT);
        
        if(handle != INVALID_HANDLE) {
            FileWrite(handle, "════════════════════════════════════════════════════════════════");
            FileWrite(handle, "    MARKET COMPASS v5.1 - FINAL REPORT");
            FileWrite(handle, "    Generated: " + TimeToString(TimeCurrent()));
            FileWrite(handle, "════════════════════════════════════════════════════════════════");
            FileWrite(handle, "");
            FileWrite(handle, "PERFORMANCE SUMMARY");
            FileWrite(handle, "-------------------");
            FileWrite(handle, "Total Signals: " + IntegerToString(stats.totalSignals));
            FileWrite(handle, "Executed Signals: " + IntegerToString(stats.executedSignals));
            FileWrite(handle, "Total Trades: " + IntegerToString(stats.totalTrades));
            FileWrite(handle, "Winning Trades: " + IntegerToString(stats.winningTrades));
            FileWrite(handle, "Losing Trades: " + IntegerToString(stats.losingTrades));
            FileWrite(handle, "Win Rate: " + DoubleToString(stats.winRate, 2) + "%");
            FileWrite(handle, "");
            FileWrite(handle, "PROFIT SUMMARY");
            FileWrite(handle, "--------------");
            FileWrite(handle, "Total Profit: " + DoubleToString(stats.totalProfit, 2));
            FileWrite(handle, "Gross Profit: " + DoubleToString(stats.grossProfit, 2));
            FileWrite(handle, "Gross Loss: " + DoubleToString(stats.grossLoss, 2));
            FileWrite(handle, "Profit Factor: " + DoubleToString(stats.profitFactor, 2));
            FileWrite(handle, "");
            FileWrite(handle, "TRADE STATISTICS");
            FileWrite(handle, "----------------");
            FileWrite(handle, "Average Win: " + DoubleToString(stats.avgWin, 2));
            FileWrite(handle, "Average Loss: " + DoubleToString(stats.avgLoss, 2));
            FileWrite(handle, "Average R:R: " + DoubleToString(stats.avgRR, 2));
            FileWrite(handle, "Best Trade: " + DoubleToString(stats.bestTrade, 2));
            FileWrite(handle, "Worst Trade: " + DoubleToString(stats.worstTrade, 2));
            FileWrite(handle, "Max Consecutive Wins: " + DoubleToString(stats.maxConsecutiveWins, 0));
            FileWrite(handle, "Max Consecutive Losses: " + DoubleToString(stats.maxConsecutiveLosses, 0));
            FileWrite(handle, "");
            
            // Dodaj statystyki throttlingu
            FileWrite(handle, "LOGGING STATISTICS");
            FileWrite(handle, "------------------");
            FileWrite(handle, "Messages logged: " + IntegerToString(m_messagesLogged));
            FileWrite(handle, "Log rotations: " + IntegerToString(m_rotationCounter));
            
            int suppressedTotal = 0;
            for(int i = 0; i < ArraySize(m_throttle); i++) {
                suppressedTotal += m_throttle[i].repeatCount;
            }
            FileWrite(handle, "Messages suppressed: " + IntegerToString(suppressedTotal));
            
            FileWrite(handle, "");
            FileWrite(handle, "════════════════════════════════════════════════════════════════");
            
            FileClose(handle);
            
            Print("Final report saved to: " + filename);
        }
    }
    
    void SetDebugLevel(ENUM_DEBUG_LEVEL level) {
        m_debugLevel = level;
        Log(DEBUG_NORMAL, "SYSTEM", "Debug level changed to: " + EnumToString(level));
    }
    
    ENUM_DEBUG_LEVEL GetDebugLevel() {
        return m_debugLevel;
    }
    
    int GetMessagesLogged() {
        return m_messagesLogged;
    }
    
    // NOWA FUNKCJA: Pobierz liczbę pominiętych wiadomości
    int GetSuppressedCount() {
        int total = 0;
        for(int i = 0; i < ArraySize(m_throttle); i++) {
            total += m_throttle[i].repeatCount;
        }
        return total;
    }
    
    void PrintSystemInfo() {
        Log(DEBUG_NORMAL, "SYSTEM", "═══════════════════════════════════════");
        Log(DEBUG_NORMAL, "SYSTEM", "System Information:");
        Log(DEBUG_NORMAL, "SYSTEM", "Terminal: " + TerminalInfoString(TERMINAL_NAME));
        Log(DEBUG_NORMAL, "SYSTEM", "Company: " + TerminalInfoString(TERMINAL_COMPANY));
        Log(DEBUG_NORMAL, "SYSTEM", "Build: " + IntegerToString(TerminalInfoInteger(TERMINAL_BUILD)));
        Log(DEBUG_NORMAL, "SYSTEM", "Account: " + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)));
        Log(DEBUG_NORMAL, "SYSTEM", "Server: " + AccountInfoString(ACCOUNT_SERVER));
        Log(DEBUG_NORMAL, "SYSTEM", "Currency: " + AccountInfoString(ACCOUNT_CURRENCY));
        Log(DEBUG_NORMAL, "SYSTEM", "Leverage: 1:" + IntegerToString(AccountInfoInteger(ACCOUNT_LEVERAGE)));
        Log(DEBUG_NORMAL, "SYSTEM", "═══════════════════════════════════════");
    }
};

//+------------------------------------------------------------------+
//|                    FUNKCJE POMOCNICZE STRING                     |
//+------------------------------------------------------------------+
// Formatowanie pieniędzy
string FormatMoney(double amount, string currency = "") {
    if(currency == "") {
        currency = AccountInfoString(ACCOUNT_CURRENCY);
    }
    return DoubleToString(amount, 2) + " " + currency;
}

// Formatowanie procentów
string FormatPercent(double value) {
    return DoubleToString(value, 2) + "%";
}

// Formatowanie czasu
string FormatTime(datetime time) {
    return TimeToString(time, TIME_DATE|TIME_MINUTES);
}

// Skróć string
string TruncateString(string text, int maxLength) {
    if(StringLen(text) <= maxLength) {
        return text;
    }
    return StringSubstr(text, 0, maxLength - 3) + "...";
}

// Powtórz znak
string RepeatChar(string chr, int count) {
    string result = "";
    for(int i = 0; i < count; i++) {
        result += chr;
    }
    return result;
}

#endif // MC5_UTILS_MQH