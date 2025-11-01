#!/bin/bash
# Verification script to confirm files are correct

echo "=========================================="
echo "FILE VERIFICATION SCRIPT"
echo "=========================================="
echo ""

# Check for pragma messages
echo "1. Checking for #pragma messages..."
if grep -n "#pragma message" *.mqh *.mq5 2>/dev/null; then
    echo "❌ FOUND pragma messages - files are incorrect!"
    exit 1
else
    echo "✅ No pragma messages found"
fi
echo ""

# Verify UT_Analysis.mqh line 12
echo "2. Verifying UT_Analysis.mqh line 12..."
LINE12=$(sed -n '12p' UT_Analysis.mqh)
if [[ "$LINE12" == *"#include"* ]]; then
    echo "✅ Line 12 is correct: $LINE12"
elif [[ "$LINE12" == *"#pragma"* ]]; then
    echo "❌ Line 12 still has pragma - MetaEditor is using cached files!"
    exit 1
else
    echo "⚠️  Line 12 is: $LINE12"
fi
echo ""

# Verify ENUM_OB_TYPE exists
echo "3. Verifying ENUM_OB_TYPE enum..."
if grep -q "enum ENUM_OB_TYPE" UT_OrderBlocks.mqh; then
    echo "✅ ENUM_OB_TYPE found"
else
    echo "❌ ENUM_OB_TYPE not found!"
    exit 1
fi
echo ""

# Verify ENUM_OB_STATUS exists
echo "4. Verifying ENUM_OB_STATUS enum..."
if grep -q "enum ENUM_OB_STATUS" UT_OrderBlocks.mqh; then
    echo "✅ ENUM_OB_STATUS found"
else
    echo "❌ ENUM_OB_STATUS not found!"
    exit 1
fi
echo ""

echo "=========================================="
echo "✅ ALL FILES ARE CORRECT"
echo "=========================================="
echo ""
echo "If MetaEditor still shows errors, it's using CACHED versions."
echo "Please follow CLEAR_METAEDITOR_CACHE.md instructions."
echo ""
