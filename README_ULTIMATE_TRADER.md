# Ultimate Trader EA v1.0 - User Guide

**Hybrid Trading System** łączący najlepsze cechy GoldTraderEA i Market Compass v5

---

## 📖 Spis Treści

1. [Przegląd](#przegląd)
2. [Funkcje](#funkcje)
3. [Wymagania systemowe](#wymagania-systemowe)
4. [Instalacja](#instalacja)
5. [Konfiguracja](#konfiguracja)
6. [Strategie](#strategie)
7. [Zarządzanie ryzykiem](#zarządzanie-ryzykiem)
8. [FAQ](#faq)
9. [Wsparcie](#wsparcie)

---

## Przegląd

**Ultimate Trader EA** to zaawansowany Expert Advisor dla MetaTrader 5, który łączy:
- 8 różnych strategii tradingowych
- Profesjonalne zarządzanie ryzykiem
- Machine Learning adaptive scoring
- Multi-timeframe analysis
- GUI dashboard z real-time stats

### Kluczowe Cechy

✅ **Uniwersalność** - Forex, Metals, Crypto, Indices
✅ **8 Strategii** - Forex, Metal, Crypto, Harmonic, Elliott, Scalping, Adaptive
✅ **Advanced Risk Management** - Daily limits, DD protection, Trailing/Breakeven/Partial
✅ **ML-Based Scoring** - Adaptive weights based on performance
✅ **Professional GUI** - Real-time dashboard
✅ **Micro Account Support** - Start from $10 with nano lots

---

## Funkcje

### Strategie Tradingowe

1. **Forex Strategy** - Trend + Momentum
   - EMA alignment (20/50/200)
   - RSI, MACD, ADX confirmation
   - Volume validation
   - R:R = 2.0

2. **Metal Strategy** - Support/Resistance
   - S/R level detection
   - Volume spike confirmation
   - Pivot points
   - R:R = 2.5

3. **Crypto Strategy** - High-Frequency Momentum
   - RSI oversold/overbought bounces
   - High volume requirement
   - Volatility-based
   - R:R = 3.0

4. **Scalping Strategy** - Ultra High-Frequency
   - Tick-by-tick momentum
   - 20 concurrent positions
   - $1.50 target per trade
   - Micro account optimization

5. **Harmonic Strategy** - Pattern Recognition
   - Gartley, Butterfly, Bat patterns
   - Fibonacci retracements
   - High R:R setups

6. **Elliott Strategy** - Wave Analysis
   - ABC corrections
   - Wave 5 detection
   - Trend confirmation

7. **Adaptive Strategy** - Auto-Select
   - Auto-detects instrument type
   - Selects best strategy
   - Dynamic adaptation

8. **Hybrid Strategy** - ML-Based Mix
   - Combines all strategies
   - Adaptive weights
   - Performance-based optimization

### Risk Management

- **Position Sizing** - Risk-based (0.5-2% per trade)
- **Daily Loss Limit** - Stops trading after max daily loss (3-10%)
- **Total Drawdown Protection** - Emergency stop at max DD (15-30%)
- **Consecutive Loss Protection** - Pauses after 5 losses in row
- **Trailing Stop** - ATR-based, activated at 50% profit
- **Break-Even** - Moves SL to entry at 30% profit
- **Partial Close** - Closes 50% at 70% of TP

### Advanced Features

- **Multi-Timeframe Analysis** - H4, D1, W1 confirmation
- **Divergence Detection** - RSI, MACD bullish/bearish divergences
- **Volume Analysis** - Spike, squeeze, breakout detection
- **Market Phase Detection** - Accumulation, Markup, Distribution, Markdown, Ranging
- **Session Awareness** - London, New York, Asian sessions
- **Bad Day Filter** - Avoids NFP, holidays, extreme volatility

---

## Wymagania Systemowe

### MetaTrader 5

- **Build:** 3661 lub nowszy
- **Platform:** Windows, Mac, Linux (via Wine)
- **RAM:** Minimum 2 GB
- **CPU:** Dual-core lub lepszy

### Konto Brokerskie

**Minimum:**
- $10 (micro account z nano lots)
- Spread: Im niższy tym lepiej (idealnie 0 dla scalpingu)
- Leverage: Zalecane 1:100 lub wyższe

**Zalecane:**
- $100+ (standard micro account)
- ECN broker z raw spread
- VPS w tym samym data center co broker (dla scalpingu)

---

## Instalacja

### Krok 1: Pobierz pliki

```bash
git clone https://github.com/lukaszholla-stack/MC
cd MC
```

### Krok 2: Skopiuj do MT5

Skopiuj następujące pliki do katalogu MT5:

```
MT5_DATA_FOLDER/
└── MQL5/
    └── Experts/
        ├── UltimateTrader.mq5
        └── Include/
            ├── UT_Core.mqh
            ├── UT_Analysis.mqh
            ├── UT_Strategies.mqh
            └── UT_Engine.mqh
```

**Jak znaleźć MT5 Data Folder:**
1. Otwórz MetaTrader 5
2. File → Open Data Folder
3. Otwórz folder `MQL5/Experts/`

### Krok 3: Kompilacja

1. Otwórz MetaEditor (F4 w MT5)
2. Znajdź `UltimateTrader.mq5` w Navigator
3. Prawy przycisk → Compile (F7)
4. Sprawdź Errors tab - powinno być 0 errors, 0 warnings

### Krok 4: Dodaj do wykresu

1. Otwórz wykres (np. EURUSD M15)
2. Navigator → Expert Advisors → UltimateTrader
3. Przeciągnij na wykres
4. Zaznacz "Allow Algo Trading"
5. Skonfiguruj parametry (patrz poniżej)
6. OK

---

## Konfiguracja

### Tryby Tradingu

#### MODE_SAFE (Bezpieczny)
```
Risk per trade: 0.5%
Max daily loss: 3%
Max drawdown: 15%
Min signal score: 70
```
**Dla kogo:** Początkujący, małe konta, konserwatywni traderzy

#### MODE_BALANCED (Zbalansowany) - DOMYŚLNY
```
Risk per trade: 1.0%
Max daily loss: 5%
Max drawdown: 20%
Min signal score: 60
```
**Dla kogo:** Większość traderów, średnie konta

#### MODE_AGGRESSIVE (Agresywny)
```
Risk per trade: 2.0%
Max daily loss: 10%
Max drawdown: 30%
Min signal score: 50
```
**Dla kogo:** Doświadczeni traderzy, duże konta, wysokie ryzyko

### Wybór Strategii

- **STRATEGY_AUTO/ADAPTIVE** - ⭐ Zalecane dla większości użytkowników
  - Auto-wykrywa instrument (Forex/Metal/Crypto)
  - Automatycznie dobiera najlepszą strategię

- **STRATEGY_FOREX** - Dla par walutowych (EURUSD, GBPUSD, etc.)
- **STRATEGY_METAL** - Dla metali (XAUUSD, XAGUSD)
- **STRATEGY_CRYPTO** - Dla krypto (BTCUSD, ETHUSD)
- **STRATEGY_SCALPING** - High-frequency scalping (20 pozycji)

### Scalping Mode (Opcjonalny)

**Parametry:**
```
InpEnableScalping = true
InpScalpMaxPositions = 20
InpScalpTargetUSD = 1.50
InpScalpMaxSpread = 20  // Max 2 pips
```

**UWAGA:** Scalping wymaga:
- ✅ Bardzo niski spread (idealnie 0)
- ✅ Szybkie wykonanie zleceń
- ✅ VPS (zalecane, ale nie wymagane)
- ✅ Ping < 50ms do serwera brokera

**Micro Account Scalping:**
Dla kont $10-100:
```
Tier 1 ($10-15): 0.001 lot, TP 3 pips, SL 15 pips
Tier 2 ($15-40): 0.002-0.003 lot, TP 4-5 pips, SL 12-10 pips
Tier 3 ($40-75): 0.005 lot, TP 5 pips, SL 10 pips
Tier 4 ($75+):   0.007 lot, TP 6 pips, SL 8 pips
```

---

## Strategie

### Forex Strategy - Szczegóły

**Wskaźniki:**
- EMA 20, 50, 200 (trend)
- RSI(14) (momentum, overbought/oversold)
- MACD(12,26,9) (momentum cross)
- ADX(14) (trend strength)
- Volume (confirmation)

**Warunki BUY:**
```
✅ EMA20 > EMA50 > EMA200 (strong bullish trend)
✅ ADX > 25 (strong trend)
✅ RSI > 50 and < 70 (bullish momentum)
✅ MACD > Signal (bullish)
✅ Volume spike > 1.2x average
Score >= 60
```

**Warunki SELL:**
```
✅ EMA20 < EMA50 < EMA200 (strong bearish trend)
✅ ADX > 25
✅ RSI < 50 and > 30
✅ MACD < Signal
✅ Volume spike > 1.2x average
Score >= 60
```

**SL/TP:**
- Stop Loss: 1.2x ATR
- Take Profit: 2.0x SL distance
- R:R = 2.0

### Metal Strategy - Szczegóły

**Wskaźniki:**
- Support/Resistance levels
- Pivot Points (Daily, Weekly, Monthly)
- Volume (spike detection)
- ATR (volatility)

**Warunki BUY:**
```
✅ Price near support (within 0.5x ATR)
✅ Volume spike > 1.3x average
✅ Bullish candle pattern
Score >= 50
```

**Warunki SELL:**
```
✅ Price near resistance
✅ Volume spike > 1.3x average
✅ Bearish candle pattern
Score >= 50
```

**SL/TP:**
- Stop Loss: 1.5x ATR (metals more volatile)
- Take Profit: 2.5x SL distance
- R:R = 2.5

### Scalping Strategy - Szczegóły

**Detekcja sygnału:**
```python
micro_momentum = EMA(tick_movement, 20 ticks)

if micro_momentum > 3.0 pips:
    SIGNAL_BUY
elif micro_momentum < -3.0 pips:
    SIGNAL_SELL
```

**Parametry:**
- Max positions: 20 concurrent
- Target profit: $1.50 per trade
- Cooldown: 5 seconds between signals
- Max spread: 20 points (2 pips)

**Zarządzanie pozycjami:**
- Exit at 90% of target (ping compensation)
- Max position age: 5 minutes
- Emergency close if loss > 2x target

---

## Zarządzanie Ryzykiem

### Daily Loss Limit

EA automatycznie przestanie tradować jeśli:
```
Daily Loss >= Max Daily Loss Limit
```

**Przykład:**
- Balance start: $1000
- Max daily loss: 5%
- Limit: $50

Jeśli balance spadnie do $950 lub niżej tego dnia, EA przestaje tradować do północy.

### Total Drawdown Protection

Emergency stop jeśli:
```
Current DD >= Max Total Drawdown
```

**Przykład:**
- Peak balance: $1200
- Current balance: $960
- DD: 20%
- Max DD: 20%

EA przestaje tradować całkowicie (wymaga restartu).

### Consecutive Losses

Stop trading po:
```
Consecutive Losses >= 5
```

Wznowienie następnego dnia o północy.

### Trailing Stop

**Aktywacja:** Po osiągnięciu 50% drogi do TP

**Distance:** 0.5x ATR (50% ATR)

**Przykład:**
```
Entry: 1.1000 (BUY)
TP: 1.1200 (+200 pips)
SL: 1.0900 (-100 pips)

Price osiąga 1.1100 (+100 pips = 50% TP)
→ Trailing stop activated
→ New SL: 1.1100 - 0.5*ATR

Price rośnie do 1.1150
→ SL moves to 1.1150 - 0.5*ATR
```

### Break-Even

**Aktywacja:** Po osiągnięciu 30% drogi do TP

**Offset:** +10 points

**Przykład:**
```
Entry: 1.1000 (BUY)
TP: 1.1200 (+200 pips)
SL: 1.0900 (-100 pips)

Price osiąga 1.1060 (+60 pips = 30% TP)
→ Breakeven activated
→ New SL: 1.1000 + 10 points = 1.1010
```

### Partial Close

**Aktywacja:** Po osiągnięciu 70% drogi do TP

**Volume:** 50% (połowa pozycji)

**Przykład:**
```
Entry: 1.1000 (BUY 0.10 lot)
TP: 1.1200 (+200 pips)

Price osiąga 1.1140 (+140 pips = 70% TP)
→ Partial close: 0.05 lot
→ Remaining: 0.05 lot
→ TP remains at 1.1200
```

---

## FAQ

### Q: Jaki broker polecacie?

**A:** Zalecamy brokera z:
- ✅ Niskim spreadem (< 1 pip dla głównych par)
- ✅ Szybkim wykonaniem (< 50ms)
- ✅ ECN/STP execution (nie Market Maker)
- ✅ Regulacją (FCA, ASIC, CySEC, etc.)

Dla **scalpingu** dodatkowo:
- ✅ Spread = 0 (raw spread)
- ✅ VPS w tym samym DC co broker
- ✅ Brak requotes

### Q: Czy mogę używać EA na wielu parach jednocześnie?

**A:** TAK, ale z zastrzeżeniami:
- Każda para = osobna instancja EA
- Ustaw różne Magic Numbers
- Monitoruj total risk (suma wszystkich pozycji)
- Zalecane max 3-5 par jednocześnie

### Q: Czy EA działa na demo?

**A:** TAK, zalecamy test na demo przez minimum:
- 1 tydzień dla MODE_SAFE
- 2 tygodnie dla MODE_BALANCED
- 1 miesiąc dla MODE_AGGRESSIVE lub SCALPING

### Q: Co zrobić jeśli EA nie otwiera pozycji?

**Sprawdź:**
1. ✅ Auto-trading enabled (przycisk w MT5)
2. ✅ InpAutoTrading = true
3. ✅ Spread nie jest za wysoki
4. ✅ Daily loss limit not reached
5. ✅ Consecutive losses < 5
6. ✅ Signal score >= min score
7. ✅ Check Experts tab w MT5 (logi)

### Q: Jak często aktualizuje się dashboard?

**A:** Dashboard aktualizuje się co 1 sekundę podczas aktywnego tradingu.

### Q: Czy EA wysyła powiadomienia?

**A:** Obecnie nie, ale planujemy dodać:
- Telegram alerts
- Email notifications
- Push notifications (MT5 mobile)

W wersji 1.1 (Coming soon!)

### Q: Jak wyłączyć scalping mode?

**A:**
```
InpEnableScalping = false
```

LUB ustaw:
```
InpStrategyMode = STRATEGY_ADAPTIVE
(zamiast STRATEGY_SCALPING)
```

### Q: Czy mogę zmodyfikować kod?

**A:** TAK! EA jest open-source. Możesz:
- Modyfikować strategie
- Dodawać nowe wskaźniki
- Zmieniać parametry
- Tworzyć własne wersje

Jeśli stworzysz coś ciekawego, prześlij Pull Request! 🚀

---

## Wsparcie

### Zgłaszanie błędów

https://github.com/lukaszholla-stack/MC/issues

### Dokumentacja techniczna

Zobacz plany implementacji:
- `PLAN_ULTIMATE_TRADER_EA.md` - główny plan
- `PLAN_SCALPING_EXTENSION.md` - scalping strategy
- `PLAN_SCALPING_MICRO_ACCOUNT.md` - micro account optimization
- `ANALIZA_SYSTEMOW_EA.md` - analiza GoldTraderEA
- `POROWNANIE_SYSTEMOW_EA.md` - porównanie systemów

### Community

- Discord: (Coming soon!)
- Telegram: (Coming soon!)

---

## Licencja

MIT License - możesz używać, modyfikować i dystrybuować zgodnie z licencją.

---

## Changelog

### v1.0.0 (2025-10-24)
- ✅ Initial release
- ✅ 8 trading strategies
- ✅ Advanced risk management
- ✅ ML-based adaptive scoring
- ✅ Professional GUI dashboard
- ✅ Micro account support ($10-100)
- ✅ Scalping mode (20 positions)

---

**Ultimate Trader EA v1.0**
*Hybrid Trading System for MetaTrader 5*

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
