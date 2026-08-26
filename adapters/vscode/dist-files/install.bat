@echo off
rem md-preview-kit インストーラ（Windows 用・ダブルクリックで実行）
rem このファイルは配布物の生成時に CP932(日本語 Windows の既定) + CRLF に変換されます。
setlocal
cd /d "%~dp0"

echo ============================================================
echo   md-preview-kit  インストール
echo   （Markdown の図を VS Code のプレビューに表示する拡張）
echo ============================================================
echo.

rem --- VS Code の code コマンドを探す ---------------------------
rem ★ code.cmd は中で "%~dp0..\Code.exe" を呼ぶ。PATH 経由(call "code")で起動すると
rem    %~dp0 がカレントディレクトリに解決されてしまい "...\..\Code.exe が無い" で失敗する。
rem    そのため where の出力からフルパスを取り、必ずフルパスで呼ぶ。
set "CODE="
for /f "delims=" %%i in ('where code.cmd 2^>nul') do if not defined CODE set "CODE=%%i"
if not defined CODE for /f "delims=" %%i in ('where code 2^>nul') do if not defined CODE set "CODE=%%i"
if not defined CODE if exist "%LOCALAPPDATA%\Programs\Microsoft VS Code\bin\code.cmd" set "CODE=%LOCALAPPDATA%\Programs\Microsoft VS Code\bin\code.cmd"
if not defined CODE if exist "%ProgramFiles%\Microsoft VS Code\bin\code.cmd" set "CODE=%ProgramFiles%\Microsoft VS Code\bin\code.cmd"
if not defined CODE if exist "%ProgramFiles(x86)%\Microsoft VS Code\bin\code.cmd" set "CODE=%ProgramFiles(x86)%\Microsoft VS Code\bin\code.cmd"
if not defined CODE goto no_code

rem --- vsix を探す ----------------------------------------------
set "VSIX="
for %%f in ("md-preview-kit-*.vsix") do set "VSIX=%%~ff"
if not defined VSIX goto no_vsix

echo 拡張本体をインストールします...
echo   %VSIX%
echo.
call "%CODE%" --install-extension "%VSIX%" --force
if errorlevel 1 goto failed

rem --- 関連拡張（任意）-----------------------------------------
echo.
echo ------------------------------------------------------------
echo  関連する拡張も入れますか？
echo    ・Markdown Preview Mermaid Support ... フローチャート等を表示
echo    ・Draw.io Integration ............... VS Code の中で作図
echo  （後から入れることもできます）
echo ------------------------------------------------------------
set "ANS="
set /p "ANS=入れる場合は y を入力して Enter [y/N]: "
if /i "%ANS%"=="y" (
    echo.
    echo 関連拡張をインストールします...
    call "%CODE%" --install-extension bierner.markdown-mermaid --force
    call "%CODE%" --install-extension hediet.vscode-drawio --force
)

echo.
echo ============================================================
echo   完了しました。
echo.
echo   このあとサンプル sample.md を VS Code で開きます。
echo   VS Code の中で  Ctrl+Shift+V  を押すとプレビューが出ます。
echo   （Ctrl+K を押してから V なら、左右に並べて表示）
echo.
echo   詳しい説明・困ったときは INSTALL.md をご覧ください。
echo ============================================================
echo.
if exist "sample.md" call "%CODE%" "%~dp0sample.md"
pause
exit /b 0

:no_code
echo [エラー] VS Code が見つかりませんでした。
echo.
echo   ・VS Code がまだ入っていない場合:
echo       https://code.visualstudio.com/ からインストールしてください。
echo       （インストール時の選択肢は既定のままで大丈夫です）
echo.
echo   ・すでに入っている場合は、お手数ですが手作業で入れてください:
echo       1) VS Code を開く
echo       2) Ctrl+Shift+X （拡張の一覧）
echo       3) 右上の ... （横三点） → 「VSIX からのインストール...」
echo       4) このフォルダの md-preview-kit-*.vsix を選ぶ
echo.
pause
exit /b 1

:no_vsix
echo [エラー] md-preview-kit-*.vsix がこのフォルダに見つかりません。
echo.
echo   zip を解凍せずに実行していませんか？
echo   いったんデスクトップなどに解凍し、その中の install.bat を実行してください。
echo.
pause
exit /b 1

:failed
echo.
echo [エラー] インストールに失敗しました。
echo.
echo   お手数ですが、手作業で入れてください:
echo       1) VS Code を開く
echo       2) Ctrl+Shift+X （拡張の一覧）
echo       3) 右上の ... （横三点） → 「VSIX からのインストール...」
echo       4) このフォルダの md-preview-kit-*.vsix を選ぶ
echo       5) 右下に「再読み込み」が出たら押す
echo.
echo   うまくいかない場合は、上に出ているメッセージを添えて連絡してください。
echo.
pause
exit /b 1
