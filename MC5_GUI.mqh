//+------------------------------------------------------------------+
//|                                                      MC5_GUI.mqh |
//|                   GUI System - ONLY CLOSED DAILY P/L             |
//+------------------------------------------------------------------+
#ifndef MC5_GUI_MQH
#define MC5_GUI_MQH

#include "MC5_Core.mqh"
#include "MC5_Utils.mqh"

//+------------------------------------------------------------------+
//|                    CONSTANTS FOR GUI                             |
//+------------------------------------------------------------------+
#define GUI_UPDATE_INTERVAL    1000  // Interwał aktualizacji w ms
#define GUI_MAX_CACHE_TIME     5000  // Max czas cache w ms

// Nowoczesne ikony (Unicode) - dla nagłówków sekcji
#define ICON_STATUS      "⚡"    // Status systemu
#define ICON_ACCOUNT     "💰"    // Konto
#define ICON_POSITIONS   "📊"    // Pozycje
#define ICON_MARKET      "📈"    // Rynek
#define ICON_SIGNALS     "🎯"    // Sygnały
#define ICON_CONTROLS    "🎮"    // Kontrola
#define ICON_CHECK       "✓"     // OK
#define ICON_WARNING     "⚠"     // Ostrzeżenie
#define ICON_ERROR       "✗"     // Błąd
#define ICON_INFO        "ℹ"     // Info

// Deklaracja zewnętrznych zmiennych
extern int g_signalsGenerated;
extern int g_signalsExecuted;
extern PerformanceStats g_performance;

//+------------------------------------------------------------------+
//|                 KLASA KOMPONENTÓW GUI                            |
//+------------------------------------------------------------------+
class CGUIComponents {
private:
    string m_prefix;
    
public:
    CGUIComponents(string prefix = PREFIX_PANEL) {
        m_prefix = prefix;
    }
    
    ~CGUIComponents() {
        RemoveAll();
    }
    
    bool CreateRectangle(string name, int x, int y, int width, int height, 
                        color bgColor, color borderColor = clrNONE, 
                        int borderWidth = 0, ENUM_BASE_CORNER corner = CORNER_LEFT_UPPER) {
        string objName = m_prefix + name;
        
        if(ObjectFind(0, objName) >= 0) {
            ObjectDelete(0, objName);
        }
        
        if(!ObjectCreate(0, objName, OBJ_RECTANGLE_LABEL, 0, 0, 0)) {
            return false;
        }
        
        ObjectSetInteger(0, objName, OBJPROP_CORNER, corner);
        ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, x);
        ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, y);
        ObjectSetInteger(0, objName, OBJPROP_XSIZE, width);
        ObjectSetInteger(0, objName, OBJPROP_YSIZE, height);
        ObjectSetInteger(0, objName, OBJPROP_BGCOLOR, bgColor);
        ObjectSetInteger(0, objName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
        
        if(borderColor != clrNONE && borderWidth > 0) {
            ObjectSetInteger(0, objName, OBJPROP_COLOR, borderColor);
            ObjectSetInteger(0, objName, OBJPROP_WIDTH, borderWidth);
            ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);
        }
        
        ObjectSetInteger(0, objName, OBJPROP_BACK, false);
        ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, objName, OBJPROP_SELECTED, false);
        ObjectSetInteger(0, objName, OBJPROP_HIDDEN, false);
        ObjectSetInteger(0, objName, OBJPROP_ZORDER, 1);
        
        return true;
    }
    
    bool CreateLabel(string name, int x, int y, string text, 
                    color textColor = CLR_TEXT_PRIMARY, 
                    int fontSize = 10, string fontName = "Segoe UI",
                    ENUM_ANCHOR_POINT anchor = ANCHOR_LEFT_UPPER,
                    ENUM_BASE_CORNER corner = CORNER_LEFT_UPPER) {
        string objName = m_prefix + name;
        
        if(ObjectFind(0, objName) >= 0) {
            ObjectDelete(0, objName);
        }
        
        if(!ObjectCreate(0, objName, OBJ_LABEL, 0, 0, 0)) {
            return false;
        }
        
        ObjectSetInteger(0, objName, OBJPROP_CORNER, corner);
        ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, x);
        ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, y);
        ObjectSetString(0, objName, OBJPROP_TEXT, text);
        ObjectSetString(0, objName, OBJPROP_FONT, fontName);
        ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, fontSize);
        ObjectSetInteger(0, objName, OBJPROP_COLOR, textColor);
        ObjectSetInteger(0, objName, OBJPROP_ANCHOR, anchor);
        ObjectSetInteger(0, objName, OBJPROP_BACK, false);
        ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, objName, OBJPROP_SELECTED, false);
        ObjectSetInteger(0, objName, OBJPROP_HIDDEN, false);
        ObjectSetInteger(0, objName, OBJPROP_ZORDER, 2);
        
        return true;
    }
    
    bool CreateButton(string name, int x, int y, int width, int height,
                     string text, color bgColor = CLR_PRIMARY,
                     color textColor = CLR_TEXT_PRIMARY,
                     int fontSize = 10, string fontName = "Segoe UI Semibold",
                     ENUM_BASE_CORNER corner = CORNER_LEFT_UPPER) {
        string objName = m_prefix + name;
        
        if(ObjectFind(0, objName) >= 0) {
            ObjectDelete(0, objName);
        }
        
        if(!ObjectCreate(0, objName, OBJ_BUTTON, 0, 0, 0)) {
            return false;
        }
        
        ObjectSetInteger(0, objName, OBJPROP_CORNER, corner);
        ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, x);
        ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, y);
        ObjectSetInteger(0, objName, OBJPROP_XSIZE, width);
        ObjectSetInteger(0, objName, OBJPROP_YSIZE, height);
        ObjectSetString(0, objName, OBJPROP_TEXT, text);
        ObjectSetString(0, objName, OBJPROP_FONT, fontName);
        ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, fontSize);
        ObjectSetInteger(0, objName, OBJPROP_COLOR, textColor);
        ObjectSetInteger(0, objName, OBJPROP_BGCOLOR, bgColor);
        ObjectSetInteger(0, objName, OBJPROP_BORDER_COLOR, bgColor);
        ObjectSetInteger(0, objName, OBJPROP_BACK, false);
        ObjectSetInteger(0, objName, OBJPROP_STATE, false);
        ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, true);
        ObjectSetInteger(0, objName, OBJPROP_SELECTED, false);
        ObjectSetInteger(0, objName, OBJPROP_HIDDEN, false);
        ObjectSetInteger(0, objName, OBJPROP_ZORDER, 3);
        
        return true;
    }
    
    bool UpdateLabel(string name, string text, color textColor = clrNONE) {
        string objName = m_prefix + name;
        
        if(ObjectFind(0, objName) < 0) {
            return false;
        }
        
        ObjectSetString(0, objName, OBJPROP_TEXT, text);
        
        if(textColor != clrNONE) {
            ObjectSetInteger(0, objName, OBJPROP_COLOR, textColor);
        }
        
        return true;
    }
    
    bool UpdateButton(string name, string text, color bgColor = clrNONE) {
        string objName = m_prefix + name;
        
        if(ObjectFind(0, objName) < 0) {
            return false;
        }
        
        ObjectSetString(0, objName, OBJPROP_TEXT, text);
        
        if(bgColor != clrNONE) {
            ObjectSetInteger(0, objName, OBJPROP_BGCOLOR, bgColor);
        }
        
        return true;
    }
    
    bool UpdateColor(string name, color newColor) {
        string objName = m_prefix + name;
        
        if(ObjectFind(0, objName) < 0) {
            return false;
        }
        
        long objType = ObjectGetInteger(0, objName, OBJPROP_TYPE);
        
        if(objType == OBJ_RECTANGLE_LABEL || objType == OBJ_BUTTON) {
            ObjectSetInteger(0, objName, OBJPROP_BGCOLOR, newColor);
        } else {
            ObjectSetInteger(0, objName, OBJPROP_COLOR, newColor);
        }
        
        return true;
    }
    
    bool Remove(string name) {
        string objName = m_prefix + name;
        
        if(ObjectFind(0, objName) < 0) {
            return false;
        }
        
        return ObjectDelete(0, objName);
    }
    
    void RemoveAll() {
        ObjectsDeleteAll(0, m_prefix);
    }
    
    bool Exists(string name) {
        string objName = m_prefix + name;
        return (ObjectFind(0, objName) >= 0);
    }
};

//+------------------------------------------------------------------+
//|                    ELEGANCKI DASHBOARD                           |
//+------------------------------------------------------------------+
class CDashboard {
private:
    CGUIComponents* m_components;
    ENUM_LANGUAGE m_language;
    
    // Pozycja i wymiary
    int m_x, m_y;
    int m_width, m_height;
    
    // Stany
    bool m_isVisible;
    bool m_isInitialized;
    datetime m_lastRefresh;
    int m_refreshErrors;
    
    // Dane
    DashboardData m_data;
    
    // Cache dla Daily P/L - TYLKO ZAMKNIĘTE POZYCJE
    struct DailyPLCache {
        double closedPL;      // Tylko zamknięte transakcje
        datetime lastUpdate;
        datetime dayStart;
        double lastBalance;
    };
    DailyPLCache m_dailyPLCache;
    
    // STAŁA POZYCJA PRZYCISKÓW
    int m_controlsY;
    
    // Pobierz tekst w odpowiednim języku
    string GetText(string key) {
        if(m_language == LANG_POLISH) {
            // Polski
            if(key == "TITLE") return "MARKET COMPASS";
            if(key == "STATUS") return "STATUS SYSTEMU";
            if(key == "ACCOUNT") return "KONTO";
            if(key == "BALANCE") return "Saldo";
            if(key == "EQUITY") return "Kapitał";
            if(key == "FREE_MARGIN") return "Wolny depozyt";
            if(key == "DAILY_PL") return "Dzienny P/L";
            if(key == "POSITIONS") return "POZYCJE";
            if(key == "OPEN_POSITIONS") return "Otwarte";
            if(key == "TOTAL_VOLUME") return "Wolumen";
            if(key == "FLOATING_PL") return "Bieżący P/L";
            if(key == "MARKET") return "RYNEK";
            if(key == "TREND") return "Trend";
            if(key == "SPREAD") return "Spread";
            if(key == "RSI") return "RSI";
            if(key == "SESSION") return "Sesja";
            if(key == "SIGNAL") return "SYGNAŁY";
            if(key == "GENERATED") return "Wygenerowane";
            if(key == "EXECUTED") return "Wykonane";
            if(key == "WIN_RATE") return "Skuteczność";
            if(key == "CONTROLS") return "KONTROLA";
            if(key == "ACTIVE") return "AKTYWNY";
            if(key == "INACTIVE") return "NIEAKTYWNY";
            if(key == "STOPPED") return "ZATRZYMANY";
            if(key == "START") return "START";
            if(key == "STOP") return "STOP";
            if(key == "DIAGNOSTIC") return "DIAGNOSTYKA";
            if(key == "MODE") return "Tryb";
            if(key == "INSTRUMENT") return "Instrument";
        } else {
            // English (default)
            if(key == "TITLE") return "MARKET COMPASS";
            if(key == "STATUS") return "SYSTEM STATUS";
            if(key == "ACCOUNT") return "ACCOUNT";
            if(key == "BALANCE") return "Balance";
            if(key == "EQUITY") return "Equity";
            if(key == "FREE_MARGIN") return "Free Margin";
            if(key == "DAILY_PL") return "Daily P/L";
            if(key == "POSITIONS") return "POSITIONS";
            if(key == "OPEN_POSITIONS") return "Open";
            if(key == "TOTAL_VOLUME") return "Volume";
            if(key == "FLOATING_PL") return "Floating P/L";
            if(key == "MARKET") return "MARKET";
            if(key == "TREND") return "Trend";
            if(key == "SPREAD") return "Spread";
            if(key == "RSI") return "RSI";
            if(key == "SESSION") return "Session";
            if(key == "SIGNAL") return "SIGNALS";
            if(key == "GENERATED") return "Generated";
            if(key == "EXECUTED") return "Executed";
            if(key == "WIN_RATE") return "Win Rate";
            if(key == "CONTROLS") return "CONTROLS";
            if(key == "ACTIVE") return "ACTIVE";
            if(key == "INACTIVE") return "INACTIVE";
            if(key == "STOPPED") return "STOPPED";
            if(key == "START") return "START";
            if(key == "STOP") return "STOP";
            if(key == "DIAGNOSTIC") return "DIAGNOSTIC";
            if(key == "MODE") return "Mode";
            if(key == "INSTRUMENT") return "Instrument";
        }
        
        return key;
    }
    
    // Utwórz główny panel
    void CreateMainPanel() {
        if(m_components == NULL) {
            m_components = new CGUIComponents(PREFIX_PANEL);
        }
        
        m_components.RemoveAll();
        
        // Efekt cienia
        m_components.CreateRectangle("shadow", m_x + 3, m_y + 3, m_width, m_height, 
                                     C'10,10,10', clrNONE, 0);
        
        // Główne tło ze złotą ramką
        m_components.CreateRectangle("main_bg", m_x, m_y, m_width, m_height, 
                                     CLR_BACKGROUND, CLR_GOLD, 3);
        
        int contentY = m_y + 10;
        int sectionSpacing = 15;
        
        // TYTUŁ
        CreateTitleSection(m_x + 16, contentY);
        contentY += 50;
        
        // Status systemu (3 wiersze)
        CreateStatusSection(m_x + 16, contentY);
        contentY += 95 + sectionSpacing;
        
        // Konto (4 wiersze)
        CreateAccountSection(m_x + 16, contentY);
        contentY += 120 + sectionSpacing;
        
        // Pozycje (3 wiersze)
        CreatePositionsSection(m_x + 16, contentY);
        contentY += 95 + sectionSpacing;
        
        // Rynek (4 wiersze)
        CreateMarketSection(m_x + 16, contentY);
        contentY += 120 + sectionSpacing;
        
        // Sygnały (3 wiersze)
        CreateSignalsSection(m_x + 16, contentY);
        contentY += 95 + sectionSpacing;
        
        // ZAPAMIĘTAJ POZYCJĘ DLA KONTROLI
        m_controlsY = contentY;
        
        // Kontrola
        CreateControlSection(m_x + 16, m_controlsY);
        contentY += 115;
        
        // Info o skrótach na samym dole
        CreateKeyboardInfo(m_x + 16, m_height + 15);
    }
    
    void CreateTitleSection(int x, int y) {
        m_components.CreateRectangle("title_bg", m_x + 3, m_y + 3, m_width - 6, 44,
                                     CLR_HEADER, clrNONE, 0);
        
        m_components.CreateRectangle("title_line_top", m_x + 3, m_y + 3, m_width - 6, 2,
                                     CLR_GOLD, clrNONE, 0);
        
        // Logo - ikona kompasu
        m_components.CreateLabel("logo", m_x + 15, m_y + 6,
                                "🧭", CLR_GOLD, 16, "Segoe UI Emoji");
        
        // Tytuł główny
        m_components.CreateLabel("title", m_x + 65, m_y + 8,
                                GetText("TITLE"), CLR_WHITE, 13, "Segoe UI Black");
        
        m_components.CreateRectangle("title_line_bottom", m_x + 3, m_y + 45, m_width - 6, 2,
                                     CLR_GOLD, clrNONE, 0);
    }
    
    void CreateStatusSection(int x, int y) {
        CreateEnhancedSectionHeader(x, y, GetText("STATUS"), ICON_STATUS);
        
        y += 37;
        
        CreateDataRow(x, y, "status_ea", "EA", GetText("ACTIVE"));
        y += 19;
        
        CreateDataRow(x, y, "status_mode", GetText("MODE"), "Standard");
        y += 19;
        
        CreateDataRow(x, y, "status_instrument", GetText("INSTRUMENT"), _Symbol);
    }
    
    void CreateAccountSection(int x, int y) {
        CreateEnhancedSectionHeader(x, y, GetText("ACCOUNT"), ICON_ACCOUNT);
        
        y += 37;
        
        CreateDataRow(x, y, "account_balance", GetText("BALANCE"), "0.00", true);
        y += 19;
        
        CreateDataRow(x, y, "account_equity", GetText("EQUITY"), "0.00");
        y += 19;
        
        CreateDataRow(x, y, "account_margin", GetText("FREE_MARGIN"), "0.00");
        y += 19;
        
        CreateDataRow(x, y, "account_daily", GetText("DAILY_PL"), "0.00", true);
    }
    
    void CreatePositionsSection(int x, int y) {
        CreateEnhancedSectionHeader(x, y, GetText("POSITIONS"), ICON_POSITIONS);
        
        y += 37;
        
        CreateDataRow(x, y, "pos_open", GetText("OPEN_POSITIONS"), "0/" + IntegerToString(InpMaxPositions));
        y += 19;
        
        CreateDataRow(x, y, "pos_volume", GetText("TOTAL_VOLUME"), "0.00 lots");
        y += 19;
        
        CreateDataRow(x, y, "pos_pl", GetText("FLOATING_PL"), "0.00", true);
    }
    
    void CreateMarketSection(int x, int y) {
        CreateEnhancedSectionHeader(x, y, GetText("MARKET"), ICON_MARKET);
        
        y += 37;
        
        CreateTrendRow(x, y);
        y += 19;
        
        CreateDataRow(x, y, "market_spread", GetText("SPREAD"), "0.0");
        y += 19;
        
        CreateDataRow(x, y, "market_rsi", GetText("RSI"), "50.0");
        y += 19;
        
        CreateDataRow(x, y, "market_session", GetText("SESSION"), "---");
    }
    
    void CreateSignalsSection(int x, int y) {
        CreateEnhancedSectionHeader(x, y, GetText("SIGNAL"), ICON_SIGNALS);
        
        y += 37;
        
        CreateDataRow(x, y, "signal_generated", GetText("GENERATED"), "0");
        y += 19;
        
        CreateDataRow(x, y, "signal_executed", GetText("EXECUTED"), "0");
        y += 19;
        
        CreateDataRow(x, y, "signal_success", GetText("WIN_RATE"), "0.0%", true);
    }
    
    void CreateControlSection(int x, int y) {
        CreateEnhancedSectionHeader(x, y, GetText("CONTROLS"), ICON_CONTROLS);
        
        y += 40;
        
        // Przyciski zajmują 70% szerokości
        int btnWidth = (int)(m_width * 0.70);
        int btnHeight = 34;
        int btnX = m_x + (m_width - btnWidth) / 2;
        
        // START/STOP
        string startStopText = g_systemState.isActive ? GetText("STOP") : GetText("START");
        color startStopColor = g_systemState.isActive ? CLR_DANGER : CLR_SUCCESS;
        
        m_components.CreateButton("btn_startstop", btnX, y,
                                 btnWidth, btnHeight, startStopText,
                                 startStopColor, CLR_WHITE, 11, "Segoe UI Black");
        
        y += btnHeight + 10;
        
        // DIAGNOSTYKA
        m_components.CreateButton("btn_diagnostic", btnX, y,
                                 btnWidth, btnHeight, GetText("DIAGNOSTIC"),
                                 CLR_NAVY, CLR_GOLD, 11, "Segoe UI Black");
    }
    
    void CreateKeyboardInfo(int x, int y) {
        m_components.CreateLabel("shortcuts_info", m_x + m_width/2, y,
                                "[S] Start/Stop  [H] Hide  [D] Diagnostic",
                                CLR_SILVER, 8, "Segoe UI",
                                ANCHOR_CENTER);
    }
    
    // FUNKCJE POMOCNICZE
    
    void CreateEnhancedSectionHeader(int x, int y, string title, string icon) {
        // Górna linia
        m_components.CreateRectangle(title + "_line_top", x - 5, y - 2, m_width - 22, 1,
                                     CLR_GOLD, clrNONE, 0);
        
        // Tło nagłówka
        m_components.CreateRectangle(title + "_header_bg", x - 5, y, m_width - 22, 29,
                                     C'30,30,55', clrNONE, 0);
        
        // Ikona
        if(icon != "") {
            m_components.CreateLabel(title + "_icon", x, y + 1,
                                    icon, CLR_GOLD, 12, "Segoe UI Emoji");
        }
        
        // Tytuł
        int titleX = (icon != "") ? x + 45 : x;
        m_components.CreateLabel(title + "_title", titleX, y + 2,
                                title, CLR_GOLD, 11, "Segoe UI Black");
        
        // Dolna linia
        m_components.CreateRectangle(title + "_line_bottom", x - 5, y + 30, m_width - 22, 1,
                                     CLR_GOLD, clrNONE, 0);
    }
    
    void CreateDataRow(int x, int y, string name, string label, string value, bool highlight = false) {
        m_components.CreateLabel(name + "_label", x, y,
                                label + ":", CLR_SILVER, 9, "Segoe UI");
        
        color valueColor = highlight ? CLR_GOLD : CLR_WHITE;
        m_components.CreateLabel(name + "_value", x + m_width - 48, y,
                                value, valueColor, 9, "Segoe UI Semibold",
                                ANCHOR_RIGHT_UPPER);
    }
    
    void CreateTrendRow(int x, int y) {
        m_components.CreateLabel("market_trend_label", x, y,
                                GetText("TREND") + ":", CLR_SILVER, 9, "Segoe UI");
        
        m_components.CreateLabel("market_trend_value", x + m_width - 48, y,
                                "→ NEUTRAL", CLR_SILVER, 9, "Segoe UI Semibold",
                                ANCHOR_RIGHT_UPPER);
    }
    
    string GetInstrumentDetails() {
        string symbol = _Symbol;
        string details = "";
        
        ENUM_INSTRUMENT_TYPE type = DetectInstrumentType(_Symbol);
        
        switch(type) {
            case INSTRUMENT_CRYPTO:
                if(StringFind(symbol, "BTC") >= 0) {
                    details = symbol + " (Bitcoin)";
                } else if(StringFind(symbol, "ETH") >= 0) {
                    details = symbol + " (Ethereum)";
                } else {
                    details = symbol + " (Crypto)";
                }
                break;
                
            case INSTRUMENT_METAL:
                if(StringFind(symbol, "XAU") >= 0 || StringFind(symbol, "GOLD") >= 0) {
                    details = symbol + " (Gold)";
                } else if(StringFind(symbol, "XAG") >= 0 || StringFind(symbol, "SILVER") >= 0) {
                    details = symbol + " (Silver)";
                } else {
                    details = symbol + " (Metal)";
                }
                break;
                
            case INSTRUMENT_INDEX:
                details = symbol + " (Index)";
                break;
                
            case INSTRUMENT_FOREX:
                details = symbol + " (Forex)";
                break;
                
            default:
                details = symbol;
        }
        
        return details;
    }
    
public:
    // UPROSZCZONA FUNKCJA - TYLKO ZAMKNIĘTE TRANSAKCJE BEZ LOGÓW
    double CalculateDailyPLFromHistory() {
        // Sprawdź cache (odświeżaj co 10 sekund lub gdy zmieni się balans)
        double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        bool needsRefresh = false;
        
        // Sprawdź czy minęło 10 sekund
        if(TimeCurrent() - m_dailyPLCache.lastUpdate >= 10) {
            needsRefresh = true;
        }
        
        // Sprawdź czy zmienił się balans
        if(MathAbs(currentBalance - m_dailyPLCache.lastBalance) > 0.01) {
            needsRefresh = true;
        }
        
        // Sprawdź czy to nowy dzień
        MqlDateTime currentTime, cacheTime;
        TimeCurrent(currentTime);
        if(m_dailyPLCache.dayStart > 0) {
            TimeToStruct(m_dailyPLCache.dayStart, cacheTime);
            if(currentTime.day != cacheTime.day || 
               currentTime.mon != cacheTime.mon || 
               currentTime.year != cacheTime.year) {
                needsRefresh = true;
            }
        } else {
            needsRefresh = true;
        }
        
        // Jeśli nie trzeba odświeżać, zwróć z cache
        if(!needsRefresh) {
            return m_dailyPLCache.closedPL;
        }
        
        // OBLICZENIE DAILY P/L - TYLKO ZAMKNIĘTE TRANSAKCJE
        double dailyPL = 0;
        
        // Pobierz początek bieżącego dnia (00:00:00 czasu brokera)
        MqlDateTime today;
        TimeCurrent(today);
        today.hour = 0;
        today.min = 0;
        today.sec = 0;
        datetime todayStart = StructToTime(today);
        
        // Pobierz TYLKO zamknięte transakcje z dzisiejszego dnia
        if(HistorySelect(todayStart, TimeCurrent())) {
            int dealsTotal = HistoryDealsTotal();
            
            for(int i = 0; i < dealsTotal; i++) {
                ulong dealTicket = HistoryDealGetTicket(i);
                
                if(dealTicket > 0) {
                    // Sprawdź czy to transakcja z naszego EA
                    long dealMagic = HistoryDealGetInteger(dealTicket, DEAL_MAGIC);
                    string dealSymbol = HistoryDealGetString(dealTicket, DEAL_SYMBOL);
                    
                    // Filtruj tylko nasze transakcje
                    if(dealMagic == InpMagicNumber && dealSymbol == _Symbol) {
                        long dealEntry = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
                        
                        // Tylko transakcje zamykające (OUT)
                        if(dealEntry == DEAL_ENTRY_OUT) {
                            double profit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
                            double commission = HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
                            double swap = HistoryDealGetDouble(dealTicket, DEAL_SWAP);
                            
                            double totalDealProfit = profit + commission + swap;
                            dailyPL += totalDealProfit;
                        }
                    }
                }
            }
        }
        
        // Zapisz w cache (TYLKO zamknięte)
        m_dailyPLCache.closedPL = dailyPL;
        m_dailyPLCache.lastUpdate = TimeCurrent();
        m_dailyPLCache.dayStart = todayStart;
        m_dailyPLCache.lastBalance = currentBalance;
        
        // BEZ LOGÓW!
        
        return dailyPL;
    }

private:
    
public:
    CDashboard(ENUM_LANGUAGE language = LANG_POLISH) {
        m_language = language;
        m_components = new CGUIComponents(PREFIX_PANEL);
        
        // Pozycja i wymiary
        m_x = 20;
        m_y = 40;
        m_width = 320;
        m_height = 820;
        
        m_isVisible = true;
        m_isInitialized = false;
        m_lastRefresh = 0;
        m_refreshErrors = 0;
        
        // Inicjalizacja cache dla Daily P/L
        m_dailyPLCache.closedPL = 0;
        m_dailyPLCache.lastUpdate = 0;
        m_dailyPLCache.dayStart = 0;
        m_dailyPLCache.lastBalance = 0;
        
        // Stała pozycja kontroli
        m_controlsY = 0;
        
        // Reset danych
        m_data.balance = 0;
        m_data.equity = 0;
        m_data.freeMargin = 0;
        m_data.marginLevel = 0;
        m_data.openPositions = 0;
        m_data.totalVolume = 0;
        m_data.floatingPL = 0;
    }
    
    ~CDashboard() {
        if(m_components != NULL) {
            delete m_components;
            m_components = NULL;
        }
    }
    
    bool Initialize() {
        if(m_isInitialized) {
            return true;
        }
        
        // Inicjalizacja cache Daily P/L
        m_dailyPLCache.closedPL = 0;
        m_dailyPLCache.lastUpdate = 0;
        m_dailyPLCache.dayStart = 0;
        m_dailyPLCache.lastBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        
        CreateMainPanel();
        m_isInitialized = true;
        m_lastRefresh = TimeCurrent();
        m_refreshErrors = 0;
        
        DEBUG_MSG(DEBUG_NORMAL, "GUI", "Dashboard initialized successfully");
        
        return true;
    }
    
    void UpdateData(DashboardData& data) {
        m_data = data;
    }
    
    // LIVE UPDATE
    void Update() {
        if(!m_isVisible) return;
        
        if(!m_isInitialized || m_refreshErrors > 10) {
            m_isInitialized = false;
            Initialize();
            m_refreshErrors = 0;
            return;
        }
        
        if(TimeCurrent() - m_lastRefresh >= 1) {
            
            if(!m_components.Exists("status_ea_value")) {
                m_refreshErrors++;
                CreateMainPanel();
                return;
            }
            
            string currency = AccountInfoString(ACCOUNT_CURRENCY);
            
            // AKTUALIZACJA WSZYSTKICH SEKCJI
            UpdateStatusSection();
            UpdateAccountSection(currency);
            UpdatePositionsSection(currency);
            UpdateMarketSection();
            UpdateSignalsSection();
            UpdateControlSection();
            
            m_lastRefresh = TimeCurrent();
            m_refreshErrors = 0;
            ChartRedraw();
        }
    }
    
private:
    void UpdateStatusSection() {
        string statusText = g_systemState.isActive ? GetText("ACTIVE") : GetText("STOPPED");
        color statusColor = g_systemState.isActive ? CLR_SUCCESS : CLR_DANGER;
        m_components.UpdateLabel("status_ea_value", statusText, statusColor);
        
        string modeText = "Standard";
        color modeColor = CLR_WHITE;
        
        if(g_isBTCMode) {
            modeText = "BTC Ultra";
            modeColor = CLR_GOLD;
        } else if(g_isCryptoMode) {
            modeText = "Crypto Fast";
            modeColor = CLR_INFO;
        } else if(DetectInstrumentType(_Symbol) == INSTRUMENT_METAL) {
            modeText = "Metals";
            modeColor = CLR_SILVER;
        } else if(DetectInstrumentType(_Symbol) == INSTRUMENT_INDEX) {
            modeText = "Index";
            modeColor = CLR_WARNING;
        } else {
            modeText = "Forex";
            modeColor = CLR_SUCCESS;
        }
        
        m_components.UpdateLabel("status_mode_value", modeText, modeColor);
        
        string instrumentDetails = GetInstrumentDetails();
        m_components.UpdateLabel("status_instrument_value", instrumentDetails, CLR_WHITE);
    }
    
    void UpdateAccountSection(string currency) {
        // Balance
        string balanceText = FormatMoney(AccountInfoDouble(ACCOUNT_BALANCE), currency);
        m_components.UpdateLabel("account_balance_value", balanceText, CLR_GOLD);
        
        // Equity
        double equity = AccountInfoDouble(ACCOUNT_EQUITY);
        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        string equityText = FormatMoney(equity, currency);
        color equityColor = equity >= balance ? CLR_SUCCESS : CLR_DANGER;
        m_components.UpdateLabel("account_equity_value", equityText, equityColor);
        
        // Free Margin
        m_components.UpdateLabel("account_margin_value", 
                                FormatMoney(AccountInfoDouble(ACCOUNT_MARGIN_FREE), currency), CLR_WHITE);
        
        // Daily P/L - TYLKO ZAMKNIĘTE TRANSAKCJE
        double dailyPL = CalculateDailyPLFromHistory();
        string dailyPLText = FormatMoneyWithSign(dailyPL, currency);
        color dailyPLColor = dailyPL >= 0 ? CLR_SUCCESS : CLR_DANGER;
        m_components.UpdateLabel("account_daily_value", dailyPLText, dailyPLColor);
    }
    
    void UpdatePositionsSection(string currency) {
        // Otwarte pozycje
        int openPos = 0;
        if(g_positionManager != NULL) {
            openPos = g_positionManager.GetOpenPositionsCount();
        }
        string posText = IntegerToString(openPos) + "/" + IntegerToString(InpMaxPositions);
        color posColor = openPos >= InpMaxPositions ? CLR_WARNING : CLR_WHITE;
        m_components.UpdateLabel("pos_open_value", posText, posColor);
        
        // Wolumen
        double volume = 0;
        if(g_positionManager != NULL) {
            volume = g_positionManager.GetTotalVolume();
        }
        
        string volumeText = volume > 0 ? DoubleToString(volume, 2) + " lots" : "0.00 lots";
        m_components.UpdateLabel("pos_volume_value", volumeText, CLR_WHITE);
        
        // Floating P/L (to pozostaje - pokazuje bieżący wynik otwartych pozycji)
        double floatingPL = 0;
        if(g_positionManager != NULL) {
            floatingPL = g_positionManager.GetFloatingPL();
        }
        string plText = FormatMoneyWithSign(floatingPL, currency);
        color plColor = floatingPL >= 0 ? CLR_SUCCESS : CLR_DANGER;
        m_components.UpdateLabel("pos_pl_value", plText, plColor);
    }
    
    void UpdateMarketSection() {
        // Trend
        string trendSymbol = "→";
        string trendText = "BOCZNY";
        color trendColor = CLR_SILVER;
        
        if(m_data.marketConditions.trendDirection > 0) {
            trendSymbol = "↑";
            trendText = "WZROSTOWY";
            trendColor = CLR_SUCCESS;
        } 
        else if(m_data.marketConditions.trendDirection < 0) {
            trendSymbol = "↓";
            trendText = "SPADKOWY";
            trendColor = CLR_DANGER;
        }
        
        string fullTrendText = trendSymbol + " " + trendText;
        m_components.UpdateLabel("market_trend_value", fullTrendText, trendColor);
        
        // Spread
        double spread = GetSpreadInPips();
        string spreadText = DoubleToString(spread, 1);
        color spreadColor = CLR_WHITE;
        
        double maxSpread = GetMaxSpread();
        if(spread > maxSpread * 0.8) {
            spreadColor = CLR_DANGER;
        } else if(spread > maxSpread * 0.5) {
            spreadColor = CLR_WARNING;
        } else {
            spreadColor = CLR_SUCCESS;
        }
        
        m_components.UpdateLabel("market_spread_value", spreadText, spreadColor);
        
        // RSI
        double rsi = 50.0;
        if(ArraySize(g_buffer_rsi_m15) > 0) {
            rsi = g_buffer_rsi_m15[0];
        }
        
        string rsiText = DoubleToString(rsi, 1);
        color rsiColor = CLR_WHITE;
        
        if(rsi > 70) {
            rsiColor = CLR_DANGER;
        } else if(rsi > 60) {
            rsiColor = CLR_WARNING;
        } else if(rsi < 30) {
            rsiColor = CLR_SUCCESS;
        } else if(rsi < 40) {
            rsiColor = CLR_INFO;
        }
        
        m_components.UpdateLabel("market_rsi_value", rsiText, rsiColor);
        
        // Sesja
        string sessionText = GetSessionNamePolish(GetCurrentSession());
        color sessionColor = CLR_WHITE;
        ENUM_MARKET_SESSION session = GetCurrentSession();
        if(session == SESSION_LONDON || session == SESSION_NEWYORK) {
            sessionColor = CLR_SUCCESS;
        } else if(session == SESSION_CLOSED) {
            sessionColor = CLR_DANGER;
        }
        m_components.UpdateLabel("market_session_value", sessionText, sessionColor);
    }
    
    void UpdateSignalsSection() {
        // Generated
        string genText = IntegerToString(g_signalsGenerated);
        color genColor = CLR_WHITE;
        
        if(g_signalsGenerated > 0) {
            if(g_signalsGenerated < 10) {
                genColor = CLR_INFO;
            } else if(g_signalsGenerated < 50) {
                genColor = CLR_WARNING;
            } else {
                genColor = CLR_SUCCESS;
            }
        }
        
        m_components.UpdateLabel("signal_generated_value", genText, genColor);
        
        // Executed
        string execText = IntegerToString(g_signalsExecuted);
        color execColor = g_signalsExecuted > 0 ? CLR_SUCCESS : CLR_WHITE;
        m_components.UpdateLabel("signal_executed_value", execText, execColor);
        
        // WIN RATE
        string successText = "0.0%";
        color successColor = CLR_WHITE;
        
        if(g_performance.totalTrades > 0) {
            double winRate = (double)g_performance.winningTrades / g_performance.totalTrades * 100.0;
            successText = DoubleToString(winRate, 1) + "%";
            
            if(winRate >= 60) {
                successColor = CLR_SUCCESS;
            } else if(winRate >= 50) {
                successColor = CLR_GOLD;
            } else if(winRate >= 40) {
                successColor = CLR_WARNING;
            } else {
                successColor = CLR_DANGER;
            }
        }
        else if(g_positionManager != NULL && g_positionManager.GetOpenPositionsCount() > 0) {
            successText = "---";
            successColor = CLR_SILVER;
        }
        
        m_components.UpdateLabel("signal_success_value", successText, successColor);
    }
    
    void UpdateControlSection() {
        // Aktualizuj przycisk START/STOP
        string buttonText = g_systemState.isActive ? GetText("STOP") : GetText("START");
        color buttonColor = g_systemState.isActive ? CLR_DANGER : CLR_SUCCESS;
        
        m_components.UpdateButton("btn_startstop", buttonText, buttonColor);
    }
    
    string GetSessionNamePolish(ENUM_MARKET_SESSION session) {
        switch(session) {
            case SESSION_SYDNEY: return "Sydney";
            case SESSION_TOKYO: return "Tokio";
            case SESSION_LONDON: return "Londyn";
            case SESSION_NEWYORK: return "Nowy Jork";
            case SESSION_CLOSED: return "Zamknięte";
            default: return "---";
        }
    }
    
    double GetMaxSpread() {
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
    
    string FormatMoney(double amount, string currency) {
        return DoubleToString(amount, 2) + " " + currency;
    }
    
    string FormatMoneyWithSign(double amount, string currency) {
        string sign = amount >= 0 ? "+" : "";
        return sign + DoubleToString(amount, 2) + " " + currency;
    }
    
public:
    void Show() {
        if(!m_isVisible) {
            m_isVisible = true;
            m_isInitialized = false;
            Initialize();
        }
    }
    
    void Hide() {
        if(m_isVisible) {
            m_isVisible = false;
            m_components.RemoveAll();
        }
    }
    
    bool IsVisible() { return m_isVisible; }
    bool IsInitialized() { return m_isInitialized; }
};

//+------------------------------------------------------------------+
//|                    OBSŁUGA PRZYCISKÓW GUI                        |
//+------------------------------------------------------------------+
void HandleGUIButtonClick(string buttonName) {
    StringReplace(buttonName, PREFIX_PANEL, "");
    
    if(buttonName == "btn_startstop") {
        g_systemState.isActive = !g_systemState.isActive;
        PlaySound("alert.wav");
        Print("System " + (g_systemState.isActive ? "STARTED" : "STOPPED"));
    }
    else if(buttonName == "btn_diagnostic") {
        PlaySound("ok.wav");
        ShowFullDiagnostic();
    }
    
    ChartRedraw();
}

//+------------------------------------------------------------------+
//|                    OBSŁUGA KLAWIATURY                            |
//+------------------------------------------------------------------+
void HandleKeyPress(int key) {
    switch(key) {
        case 83:  // S key - Start/Stop
        case 115: // s key
            g_systemState.isActive = !g_systemState.isActive;
            PlaySound("alert.wav");
            Print("System " + (g_systemState.isActive ? "STARTED" : "STOPPED"));
            break;
            
        case 72:  // H key - Hide/Show dashboard
        case 104: // h key
            if(g_dashboard != NULL) {
                if(g_dashboard.IsVisible()) {
                    g_dashboard.Hide();
                } else {
                    g_dashboard.Show();
                }
                PlaySound("tick.wav");
            }
            break;
            
        case 68:  // D key - Diagnostic
        case 100: // d key
            ShowFullDiagnostic();
            PlaySound("alert2.wav");
            break;
    }
    
    ChartRedraw();
}

// ROZSZERZONA FUNKCJA DIAGNOSTYCZNA
void ShowFullDiagnostic() {
    string currency = AccountInfoString(ACCOUNT_CURRENCY);
    
    Print("════════════════ FULL DIAGNOSTIC & REPORT ════════════════");
    
    // SEKCJA KONTA
    Print("📊 ACCOUNT STATUS:");
    Print("Balance: ", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2), " ", currency);
    Print("Equity: ", DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2), " ", currency);
    Print("Free Margin: ", DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_FREE), 2), " ", currency);
    Print("Margin Level: ", DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_LEVEL), 2), "%");
    
    // Daily P/L z historii (TYLKO ZAMKNIĘTE)
    if(g_dashboard != NULL) {
        double dailyPL = g_dashboard.CalculateDailyPLFromHistory();
        Print("Daily P/L (closed trades only): ", DoubleToString(dailyPL, 2), " ", currency);
    }
    
    // SEKCJA POZYCJI
    Print("📈 POSITIONS:");
    Print("Open: ", PositionsTotal(), "/", InpMaxPositions);
    if(g_positionManager != NULL) {
        Print("Total Volume: ", DoubleToString(g_positionManager.GetTotalVolume(), 2), " lots");
        Print("Floating P/L: ", DoubleToString(g_positionManager.GetFloatingPL(), 2), " ", currency);
    }
    
    // SEKCJA SYGNAŁÓW
    Print("🎯 SIGNALS & TRADES:");
    Print("Signals Generated: ", g_signalsGenerated);
    Print("Signals Executed: ", g_signalsExecuted);
    if(g_signalsGenerated > 0) {
        double signalExecRate = (double)g_signalsExecuted / g_signalsGenerated * 100;
        Print("Signal Execution Rate: ", DoubleToString(signalExecRate, 1), "%");
    }
    
    // STATYSTYKI TRANSAKCJI
    Print("📊 TRADING STATISTICS:");
    Print("Total Trades: ", g_performance.totalTrades);
    Print("Winning Trades: ", g_performance.winningTrades);
    Print("Losing Trades: ", g_performance.losingTrades);
    if(g_performance.totalTrades > 0) {
        Print("Win Rate: ", DoubleToString(g_performance.winRate, 1), "%");
        Print("Profit Factor: ", DoubleToString(g_performance.profitFactor, 2));
    }
    
    // SEKCJA RYNKU
    Print("📉 MARKET CONDITIONS:");
    Print("Spread: ", DoubleToString(GetSpreadInPips(), 1));
    double rsi = 50.0;
    if(ArraySize(g_buffer_rsi_m15) > 0) {
        rsi = g_buffer_rsi_m15[0];
    }
    Print("RSI: ", DoubleToString(rsi, 1));
    Print("Session: ", EnumToString(GetCurrentSession()));
    
    // SEKCJA USTAWIEŃ
    Print("⚙ SETTINGS:");
    Print("Risk per Trade: ", DoubleToString(InpRiskPerTrade, 2), "%");
    Print("Max Positions: ", InpMaxPositions);
    Print("Min Signal Score: ", InpMinSignalScore);
    Print("Min R:R: ", DoubleToString(InpMinRiskReward, 2));
    
    // INFORMACJE O KONTROLI SYGNAŁÓW
    Print("🎯 SIGNAL CONTROL:");
    Print("Check Interval: ", g_signalMgmt.signalCheckInterval, " seconds");
    Print("Max Signals per Bar: ", g_signalMgmt.maxSignalsPerBar);
    Print("Signals This Bar: ", g_signalMgmt.signalsGeneratedThisBar);
    
    // Informacja o typie instrumentu i częstotliwości
    if(g_isBTCMode) {
        Print("Mode: BTC ULTRA HIGH FREQUENCY");
    } else if(g_isCryptoMode) {
        Print("Mode: CRYPTO HIGH FREQUENCY");
    } else if(DetectInstrumentType(_Symbol) == INSTRUMENT_METAL) {
        Print("Mode: METAL MODERATE FREQUENCY");
    } else {
        Print("Mode: FOREX STANDARD FREQUENCY");
    }
    
    Print("══════════════════════════════════════════════════════════");
}

#endif // MC5_GUI_MQH