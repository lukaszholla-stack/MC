# MetaEditor Cache Clearing Guide

## Problem

MetaEditor is reading OLD cached versions of your files instead of the updated files. This is why you see pragma errors on line 12 of UT_Analysis.mqh - that line currently contains `#include "UT_Core.mqh"`, NOT a pragma directive.

## Proof Files Are Correct

All pragma messages have been removed from the codebase:
- UT_Analysis.mqh line 12: `#include "UT_Core.mqh"` ✅
- UT_OrderBlocks.mqh: No pragma ✅
- UT_FairValueGap.mqh: No pragma ✅

All enums are properly defined in UT_OrderBlocks.mqh lines 15-26.

## Solution: Clear MetaEditor Cache

### Method 1: Complete Cache Clear (RECOMMENDED)

1. **Close MetaEditor completely** (File → Exit or Alt+F4)

2. **Close MetaTrader 5 completely** if it's running

3. **Navigate to MetaEditor cache folder**:
   ```
   C:\Users\[YourUsername]\AppData\Roaming\MetaQuotes\Terminal\[TerminalID]\MQL5
   ```

4. **Delete these folders**:
   - `Include\` (will be regenerated)
   - Any `.ex5` files in `Experts\` folder
   - Any `.ex5` files in `Include\` folder if they exist

5. **Alternative - Delete compiler cache directly**:
   Navigate to:
   ```
   C:\Users\[YourUsername]\AppData\Roaming\MetaQuotes\Terminal\Common\Files
   ```
   Delete temporary files.

6. **Restart your computer** (ensures all file handles are released)

7. **Reopen MetaEditor**

8. **Navigate to your EA folder** (`/home/user/MC` or wherever you have the files)

9. **Verify file contents**:
   - Open UT_Analysis.mqh
   - Check line 12 - should be: `#include "UT_Core.mqh"`
   - If you still see `#pragma message` → files are in wrong location

10. **Compile** (F7)

### Method 2: Force Recompilation

If Method 1 doesn't work:

1. Close MetaEditor
2. In your `/home/user/MC` folder, create a backup:
   ```bash
   cp UT_Analysis.mqh UT_Analysis.mqh.bak
   cp UT_OrderBlocks.mqh UT_OrderBlocks.mqh.bak
   ```

3. Delete the original files temporarily

4. Open MetaEditor - it will show errors (expected)

5. Close MetaEditor

6. Restore the files:
   ```bash
   mv UT_Analysis.mqh.bak UT_Analysis.mqh
   mv UT_OrderBlocks.mqh.bak UT_OrderBlocks.mqh
   ```

7. Reopen MetaEditor and compile

### Method 3: Copy Files Directly to MetaEditor Folder

If you're working in Linux/WSL but MetaEditor is in Windows:

1. Find where MetaEditor expects the files:
   ```
   C:\Users\[YourUsername]\AppData\Roaming\MetaQuotes\Terminal\[TerminalID]\MQL5\Experts\
   ```

2. **Copy ALL files from `/home/user/MC/`** to that folder

3. Make sure you're editing files in the MetaEditor folder, not the Linux folder

4. Compile in MetaEditor

## Verification Steps

Before compiling, verify these lines manually in MetaEditor:

**UT_Analysis.mqh line 12 should be:**
```cpp
#include "UT_Core.mqh"
```
NOT `#pragma message...`

**UT_OrderBlocks.mqh lines 15-19 should be:**
```cpp
enum ENUM_OB_TYPE {
    OB_NONE,
    OB_BULLISH,
    OB_BEARISH
};
```

If you see different content → you're editing different files than MetaEditor is compiling.

## Expected Result

After clearing cache, you should get **0 errors, 0 warnings**.

If you still get errors, the issue is that MetaEditor is reading files from a different location than where we've been editing them.

## Next Steps If Still Not Working

Please provide:
1. Full path where MetaEditor shows the file is located (visible in editor title bar)
2. Output of `pwd` command in terminal
3. Screenshot of MetaEditor showing UT_Analysis.mqh with line numbers visible
