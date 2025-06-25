# トラブルシューティングガイド

## よくあるエラーと解決方法

### コンパイルエラー

#### 症状: "Latexmk: Log file says no output from latex"

このエラーは通常、以下の原因で発生します：

1. **ドキュメントクラスの問題**
   ```latex
   % 間違い
   \documentclass{jarticle}  % upLaTeXでは使えない
   
   % 正しい
   \documentclass{ujarticle}  % upLaTeX用
   \documentclass{ujreport}   % upLaTeX用レポート
   ```

2. **エンコーディングの問題**
   - ファイルがUTF-8でない場合
   - 解決: ファイルをUTF-8で保存し直す

3. **必要なパッケージの不足**
   ```latex
   % upLaTeX/pLaTeXで日本語を使う場合
   \usepackage[dvipdfmx]{graphicx}  % dvipdfmxオプションが必要
   ```

#### デバッグ方法

1. **ログファイルを確認**
   ```bash
   # エラーの詳細を表示
   uplatex-pdf --show-log document.tex
   
   # 詳細モードで実行
   uplatex-pdf -v document.tex
   ```

2. **補助ファイルを保持して確認**
   ```bash
   uplatex-pdf -k document.tex
   cat document.log  # ログファイルを直接確認
   ```

### 日本語関連の問題

#### 各エンジンの使い分け

| エンジン | ドキュメントクラス | 特徴 |
|---------|------------------|------|
| upLaTeX | ujarticle, ujreport, ujbook | Unicode対応、高速 |
| pLaTeX | jarticle, jreport, jbook | 従来型、安定 |
| LuaLaTeX | ltjsarticle, ltjsreport, ltjsbook | 最新、フォント自由 |

#### サンプル: upLaTeX用文書

```latex
\documentclass[uplatex,dvipdfmx,a4paper]{jsarticle}
\usepackage[utf8]{inputenc}
\usepackage[dvipdfmx]{graphicx}
\usepackage[dvipdfmx]{hyperref}

\title{日本語文書}
\author{著者名}
\date{\today}

\begin{document}
\maketitle

\section{はじめに}
日本語のテキストです。

\end{document}
```

### ネットワーク関連の問題

#### SSH接続エラー

1. **ホスト名の確認**
   ```bash
   # 現在の設定を確認
   cat ~/.config/luatex/network-config
   
   # 手動でホストを指定
   luatex-pdf -H zeus-internal document.tex
   ```

2. **SSH鍵の設定**
   ```bash
   # SSH鍵をコピー
   ssh-copy-id zeus
   ssh-copy-id zeus-external
   ```

3. **ポート設定の確認**
   ```bash
   # カスタムポートが設定されている場合
   cat ~/.port_for_ssh
   
   # SSH設定を確認
   cat ~/.ssh/config
   ```

### Docker関連の問題

#### イメージが見つからない

```bash
# Dockerイメージを再構築
make build-docker

# または手動で
cd docker
ssh zeus "cd /tmp && docker build -t luatex:latest ."
```

#### 権限エラー

リモートホストでDockerグループに所属しているか確認：

```bash
ssh zeus "groups | grep docker"
# dockerグループに追加が必要な場合
ssh zeus "sudo usermod -aG docker $USER"
```

### ファイル同期の問題

#### スタイルファイルが見つからない

1. **ローカルスタイルファイル**
   - `.sty`ファイルを`.tex`ファイルと同じディレクトリに配置

2. **共有スタイルファイル**
   ```bash
   # 正しい場所に配置
   cp mystyle.sty ~/.config/luatex/styles/
   
   # 確認
   ls ~/.config/luatex/styles/
   ```

#### 画像ファイルが見つからない

対応フォーマット: PNG, JPG, JPEG, PDF, EPS, SVG, BMP, GIF

```latex
% 相対パスを使用
\includegraphics{figures/image.png}
\includegraphics{../images/graph.pdf}
```

### パフォーマンスの問題

#### コンパイルが遅い

1. **キャッシュをクリア**
   ```bash
   make clean
   ```

2. **より高速なエンジンを使用**
   ```bash
   # LuaLaTeXよりupLaTeXの方が高速
   uplatex-pdf document.tex
   ```

3. **ウォッチモードで開発**
   ```bash
   # ファイル変更時のみ再コンパイル
   luatex-pdf -w document.tex
   ```

## エラーメッセージ一覧

### LaTeX関連

| エラー | 原因 | 解決方法 |
|--------|------|----------|
| `! Undefined control sequence` | コマンドが定義されていない | 必要なパッケージを追加 |
| `! LaTeX Error: File '...' not found` | ファイルが見つからない | ファイルパスを確認 |
| `! Package babel Error` | 言語設定の問題 | babel設定を確認 |
| `! Font ... not found` | フォントが見つからない | フォント名を確認 |

### システム関連

| エラー | 原因 | 解決方法 |
|--------|------|----------|
| `Connection refused` | SSHが接続できない | ホスト名とポートを確認 |
| `Permission denied` | 権限不足 | SSH鍵を設定 |
| `rsync error` | ファイル同期失敗 | ディスク容量を確認 |

## さらなるヘルプ

問題が解決しない場合：

1. **詳細ログを取得**
   ```bash
   luatex-pdf -v --show-log document.tex 2>&1 | tee error.log
   ```

2. **環境情報を収集**
   ```bash
   echo "=== System Info ===" > debug-info.txt
   uname -a >> debug-info.txt
   echo "=== Config ===" >> debug-info.txt
   cat ~/.config/luatex/config >> debug-info.txt
   echo "=== Network Config ===" >> debug-info.txt
   cat ~/.config/luatex/network-config >> debug-info.txt
   ```

3. **イシューを報告**
   - エラーメッセージ
   - 使用したコマンド
   - 最小限の再現可能な例
   - 環境情報