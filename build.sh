#!/bin/bash
# 下載並安裝 Flutter (指定使用最新的 stable 穩定版)
git clone https://github.com/flutter/flutter.git -b stable

# 把下載下來的 flutter 指令加到系統環境變數中
export PATH="$PATH:`pwd`/flutter/bin"

# 檢查版本並開始編譯網頁
flutter --version
flutter build web
