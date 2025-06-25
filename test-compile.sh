#!/bin/bash
# Quick test script
echo "Testing compilation with detected settings..."

# Force verbose mode and show log
luatex-pdf -v --show-log test.tex 2>&1 | tee compile-test.log

echo ""
echo "Check compile-test.log for details"
