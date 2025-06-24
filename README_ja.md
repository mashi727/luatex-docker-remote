# LuaTeX Docker Remote

リモートホストのDockerを使用したLuaTeXコンパイル環境。カスタム`.sty`ファイルと日本語組版を完全サポート。

## 概要

`luatex-docker-remote`は、リモートのDockerホスト上でLaTeXドキュメントをコンパイルできるツールです。ローカル環境をクリーンに保ちながら、強力なサーバーリソースを活用できます。

## 特徴

- 🚀 **リモートコンパイル**: 強力なリモートサーバーでコンパイル
- 🌐 **ネットワーク自動検出**: 内部/外部ホストを自動切り替え
- 📦 **自動`.sty`検出**: ローカルのスタイルファイルを自動同期
- 🇯🇵 **日本語サポート**: LuaTeX-jaによる完全な日本語組版
- 🎨 **整理された構造**: 設定、スタイル、キャッシュの明確な分離
- ⚡ **ウォッチモード**: ファイル変更時の自動再コンパイル
- 🔧 **簡単インストール**: シンプルなセットアッププロセス
- 🐳 **Dockerベース**: すべてのシステムで一貫した環境

## 必要要件

- Dockerホストへの SSH アクセス（内部および/または外部）
- ローカルに rsync がインストールされていること
- 基本的なUNIXツール（bash、make）
- curl（ネットワーク検出用）

## クイックスタート

### インストール

```bash
# リポジトリをクローン
git clone https://github.com/yourusername/luatex-docker-remote.git
cd luatex-docker-remote

# インストール
make install

# ネットワーク自動検出の設定（オプションだが推奨）
make setup-network

# シェルをリロード
source ~/.bashrc  # または ~/.zshrc
```

### ネットワーク設定

システムは自宅ネットワークにいるかどうかを自動検出し、内部/外部ホスト名を切り替えることができます：

```bash
# 初回設定
make setup-network

# 以下が作成されます：
# ~/.home_global_ip     - 自宅ネットワークのグローバルIP
# ~/.port_for_ssh       - 外部アクセス用のSSHポート（オプション）
# ~/.config/luatex/network-config - ネットワーク設定
```

### 基本的な使い方

```bash
# 異なるエンジンでコンパイル
luatex-pdf document.tex          # LuaLaTeX（デフォルト）
uplatex-pdf document.tex          # upLaTeX
platex-pdf document.tex           # pLaTeX
xelatex-pdf document.tex          # XeLaTeX
pdflatex-pdf document.tex         # pdfLaTeX

# または -e オプションを使用
luatex-pdf -e uplatex document.tex
luatex-pdf -e platex document.tex

# 任意のエンジンでウォッチモード
uplatex-pdf -w thesis.tex
```

## ディレクトリ構造

インストール後：

```
~/.local/bin/
    └── luatex-pdf          # メインコマンド

~/.config/luatex/
    ├── config              # 設定ファイル
    ├── styles/             # 共有.styファイル
    │   ├── common.sty
    │   └── japanese.sty
    └── templates/          # ドキュメントテンプレート
        └── article.tex

~/.cache/luatex/            # キャッシュディレクトリ
```

## カスタムスタイル

### プロジェクト固有のスタイル

`.sty`ファイルを`.tex`ファイルと同じディレクトリに配置：

```
my-project/
├── main.tex
├── mystyle.sty    # 自動的に検出される
└── figures/
```

### 共有スタイル

よく使用する`.sty`ファイルを`~/.config/luatex/styles/`に配置：

```bash
cp awesome-package.sty ~/.config/luatex/styles/
# すべてのプロジェクトで利用可能に
```

## 設定

`~/.config/luatex/config`を編集してカスタマイズ：

```bash
REMOTE_HOST="your-server"       # Dockerホスト
DOCKER_IMAGE="luatex:latest"    # Dockerイメージ
```

## 高度な使い方

### ネットワーク自動検出

システムはネットワークロケーションを自動検出します：

```bash
# 自宅: 内部ホスト名を使用（例：zeus）
luatex-pdf document.tex

# 外出先: 外部ホスト名を使用（例：zeus-soto）
luatex-pdf document.tex

# 特定のホストを強制
luatex-pdf -H zeus-internal document.tex

# 自動検出を無効化
luatex-pdf --no-auto-detect document.tex
```

### SSH設定

推奨される`~/.ssh/config`：

```ssh
# 内部アクセス
Host zeus
    HostName 192.168.1.100  # または zeus.local
    User yourusername
    
# 外部アクセス
Host zeus-soto
    HostName your.domain.com
    User yourusername
    Port 2222  # カスタムポートを使用する場合
```

### Gitとの使用

コンパイルプロセスはバージョン管理ファイルを無視し、LaTeX関連ファイルに焦点を当てます：

```
project/
├── .git/           # 無視される
├── main.tex        # 同期される
├── style.sty       # 同期される
├── fig.pdf         # 同期される
└── README.md       # 無視される
```

### ディレクトリ構造のサポート

複雑なディレクトリ構造も完全にサポート：

```latex
% main.tex
\input{chapters/introduction}
\includegraphics{figures/diagram}
\includegraphics{figures/results/graph1}
```

すべてのパスは変更なしで期待通りに動作します。

## 開発

### インストールの更新
```bash
make update
```

### Dockerイメージの再構築
```bash
make build-docker
```

### テストの実行
```bash
make test
```

### アンインストール
```bash
make uninstall
```

## トラブルシューティング

### コマンドが見つからない
```bash
export PATH="$HOME/.local/bin:$PATH"
source ~/.bashrc
```

### SSH接続の問題
```bash
ssh-copy-id your-docker-host
```

### スタイルファイルが見つからない
`.sty`ファイルが以下のいずれかにあることを確認：
- `.tex`ファイルと同じディレクトリ、または
- `~/.config/luatex/styles/`

### リモートファイルの確認
```bash
ssh your-host "ls -la /tmp/luatex-*"
```

## 動作の仕組み

1. **同期**: ローカルファイルをリモートの一時ディレクトリに同期
2. **コンパイル**: DockerコンテナがLuaTeXコンパイルを実行
3. **取得**: 生成されたPDFをローカルにコピー
4. **クリーンアップ**: リモートの一時ファイルを自動削除

## コントリビューション

プルリクエスト歓迎！イシューや機能強化のリクエストもお気軽にお寄せください。

## ライセンス

MITライセンス - 詳細はLICENSEファイルを参照してください。

## 謝辞

- LuaTeXおよびTeX Liveコミュニティ
- Dockerプロジェクト
- 日本語TeXユーザーグループ

---

詳細については、[プロジェクトリポジトリ](https://github.com/yourusername/luatex-docker-remote)をご覧ください。
