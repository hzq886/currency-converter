# 通貨換算アプリ 実装計画書

## 1. プロジェクト概要

| 項目 | 内容 |
|------|------|
| プロジェクト名 | Currency Converter |
| プラットフォーム | iOS (SwiftUI) |
| 最小対応バージョン | iOS 17.0+ |
| アーキテクチャ | MVVM (Model-View-ViewModel) |
| 言語 | Swift |
| UI フレームワーク | SwiftUI |

### 目的

電卓スタイルのUIを持つ、直感的でリアルタイムな通貨換算アプリを開発する。複数通貨の同時表示、四則演算機能、ライブ為替レート取得を主要機能とする。

## 2. アーキテクチャ設計

### ディレクトリ構成

```
currency-converter/
├── currency_converterApp.swift          # アプリエントリポイント
├── ContentView.swift                     # ルートビュー
├── Models/
│   ├── CalculatorState.swift            # 電卓状態管理モデル
│   ├── Currency.swift                   # 通貨情報モデル
│   └── ExchangeRateResponse.swift       # API レスポンスモデル
├── ViewModels/
│   └── CurrencyConverterViewModel.swift # メインViewModel
├── Views/
│   ├── CurrencyDisplayArea.swift        # 通貨表示エリア
│   ├── CurrencyPickerView.swift         # 通貨選択画面
│   ├── CurrencyRowView.swift            # 通貨行表示
│   ├── FlagImageView.swift              # 国旗画像表示
│   ├── KeypadButton.swift               # キーパッドボタン
│   ├── KeypadView.swift                 # キーパッド全体
│   └── RateInfoBar.swift                # 為替レート情報バー
├── Services/
│   └── ExchangeRateService.swift        # 為替レートAPI通信
├── Theme/
│   └── AppTheme.swift                   # テーマ・カラー定義
└── Assets.xcassets/                     # アセットカタログ
```

### MVVM データフロー

```
[ExchangeRateService] ←→ [ViewModel] ←→ [Views]
        ↑                      ↑              ↑
    API通信・キャッシュ    状態管理・変換ロジック   UI表示・ユーザー入力
```

## 3. データモデル設計

### 3.1 CurrencyInfo

通貨の基本情報を保持する構造体。

| プロパティ | 型 | 説明 |
|-----------|-----|------|
| `code` | `String` | 通貨コード (例: "USD", "JPY") |
| `name` | `String` | 英語名称 |
| `localizedName` | `String` | 日本語名称 |
| `flagCode` | `String` | 国旗用国コード |
| `region` | `CurrencyRegion` | 地域分類 |
| `flagURL` | `URL?` (computed) | flagcdn.com からの国旗画像URL |

### 3.2 CurrencyRegion

通貨の地域分類列挙型。

| 値 | 説明 | 通貨数 |
|----|------|--------|
| `asia` | アジア | 12 |
| `westernEurope` | 西ヨーロッパ | 6 |
| `northAmerica` | 北アメリカ | 3 |
| `oceania` | オセアニア | 2 |
| `other` | その他 | 2 |

### 3.3 CalculatorState

電卓の内部状態を管理する構造体。

| プロパティ | 型 | 説明 |
|-----------|-----|------|
| `displayText` | `String` | 現在の表示テキスト |
| `currentValue` | `Decimal` | 内部計算値 |
| `pendingOperator` | `Operator?` | 保留中の演算子 |
| `pendingOperand` | `Decimal` | 保留中のオペランド |
| `isEnteringNumber` | `Bool` | 数値入力中フラグ |
| `hasDecimalPoint` | `Bool` | 小数点入力済みフラグ |
| `justCalculated` | `Bool` | 計算直後フラグ |

対応演算子: `+`, `-`, `×`, `÷`

### 3.4 ExchangeRateResponse

API レスポンスの JSON マッピング構造体。

| プロパティ | 型 | 説明 |
|-----------|-----|------|
| `result` | `String` | API結果ステータス |
| `baseCode` | `String` | ベース通貨コード |
| `timeLastUpdateUnix` | `Int` | 最終更新Unix時刻 |
| `rates` | `[String: Double]` | 通貨コード→レート辞書 |

## 4. 対応通貨一覧 (25通貨)

### アジア (12通貨)
JPY (日本円), CNY (中国元), KRW (韓国ウォン), TWD (台湾ドル), HKD (香港ドル), SGD (シンガポールドル), THB (タイバーツ), VND (ベトナムドン), PHP (フィリピンペソ), MYR (マレーシアリンギット), IDR (インドネシアルピア), INR (インドルピー)

### 西ヨーロッパ (6通貨)
EUR (ユーロ), GBP (英ポンド), CHF (スイスフラン), SEK (スウェーデンクローナ), NOK (ノルウェークローネ), DKK (デンマーククローネ)

### 北アメリカ (3通貨)
USD (米ドル), CAD (カナダドル), MXN (メキシコペソ)

### オセアニア (2通貨)
AUD (オーストラリアドル), NZD (ニュージーランドドル)

### その他 (2通貨)
デフォルトでは非表示。トグルで表示切替可能。

**デフォルト選択**: JPY, CNY, USD

## 5. API 設計

### 為替レート取得

| 項目 | 内容 |
|------|------|
| エンドポイント | `https://open.er-api.com/v6/latest/{base}` |
| ベース通貨 | USD (固定) |
| メソッド | GET |
| レスポンス形式 | JSON |
| キャッシュ期間 | 5分 |
| スレッド安全性 | Swift Actor で保証 |

### 変換ロジック

全ての通貨変換はUSDを中間通貨として経由する:

```
元通貨の金額 → USD換算 → 目標通貨に変換
```

## 6. UI 設計

### 6.1 全体レイアウト

```
┌──────────────────────────┐
│   通貨表示エリア           │  CurrencyDisplayArea
│  ┌──────────────────────┐│
│  │ 🇯🇵 JPY    ¥1,000.00 ││  CurrencyRowView (active)
│  │ 🇨🇳 CNY      ¥48.52  ││  CurrencyRowView
│  │ 🇺🇸 USD       $6.85  ││  CurrencyRowView
│  └──────────────────────┘│
│   1 USD = 145.82 JPY ...  │  RateInfoBar
│──────────────────────────│
│   ┌───┬───┬───┬───┐      │
│   │ C │ ← │ ↑↓│ ÷ │      │  KeypadView
│   ├───┼───┼───┼───┤      │
│   │ 7 │ 8 │ 9 │ × │      │
│   ├───┼───┼───┼───┤      │
│   │ 4 │ 5 │ 6 │ − │      │
│   ├───┼───┼───┼───┤      │
│   │ 1 │ 2 │ 3 │ + │      │
│   ├───┼───┼───┼───┤      │
│   │+/-│ 0 │ . │ = │      │
│   └───┴───┴───┴───┘      │
└──────────────────────────┘
```

### 6.2 テーマ (ダークモード)

| 要素 | カラー | RGB |
|------|--------|-----|
| 背景 | ダークネイビー | (0.08, 0.08, 0.12) |
| カード背景 | ライトネイビー | (0.12, 0.12, 0.18) |
| ボタン背景 | ミディアムネイビー | (0.15, 0.15, 0.22) |
| ボタン押下時 | ダーク | (0.18, 0.18, 0.26) |
| アクセント | パープル | (0.55, 0.35, 0.85) |
| アクセント明 | ブライトパープル | (0.65, 0.45, 0.95) |
| テキスト主色 | ホワイト | - |
| テキスト副色 | グレー (55%白) | - |

| 寸法 | 値 |
|------|-----|
| キーパッドボタンサイズ | 68pt (円形) |
| キーパッド間隔 | 14pt |
| 国旗サイズ | 36pt (円形マスク) |
| 角丸半径 | 16pt |
| 金額フォント | 32pt ライトラウンド |
| ボタンフォント | 22pt セミボールドラウンド |

### 6.3 通貨選択画面 (CurrencyPickerView)

- モーダルシート表示
- 地域別グループ表示
- 検索機能 (通貨コード・英語名・日本語名)
- 「その他」地域のトグル表示/非表示
- ダークテーマ統一
- 日本語ラベル ("通貨", "検索")

### 6.4 国旗画像 (FlagImageView)

- ソース: flagcdn.com
- AsyncImage による非同期読み込み
- 読み込み中スピナー表示
- 失敗時は国コードテキストで代替表示
- 円形マスク (36pt)

## 7. 主要機能一覧

### 7.1 電卓スタイル入力
- 四則演算 (加算・減算・乗算・除算)
- 小数点入力対応
- バックスペース・全クリア
- 符号切替 (+/-)
- 桁数制限 (12桁)
- カンマ区切りフォーマット

### 7.2 複数通貨同時表示
- 最大3通貨以上の同時表示
- アクティブ通貨は電卓入力表示、非アクティブは変換結果表示
- タップで通貨切替
- ドラッグ&ドロップによる並び替え

### 7.3 通貨スワップ
- ↑↓ボタンで先頭2通貨を入れ替え
- 変換精度を維持

### 7.4 リアルタイム為替レート
- 無料API (open.er-api.com) からレート取得
- 5分間キャッシュで API 呼び出し最適化
- 手動リフレッシュボタン
- 最終更新時刻の経過表示 (30秒間隔で自動更新)
- エラーハンドリング

### 7.5 リアルタイム変換
- 入力と同時に全通貨の変換結果を即座に更新
- USD 中間通貨方式による高精度変換
- Decimal 型による精度保証

## 8. 技術仕様

| 項目 | 仕様 |
|------|------|
| 並行処理 | Swift Concurrency (async/await) |
| スレッド安全性 | Actor (ExchangeRateService) |
| 状態管理 | @Observable (Observation framework) |
| 精度 | Decimal 型 |
| 画像読み込み | AsyncImage |
| ナビゲーション | NavigationStack + Sheet |
| ローカライゼーション | 日本語UI (ハードコード) |

## 9. 今後の拡張候補

- [ ] オフラインモード (レートのローカル永続化)
- [ ] ウィジェット対応
- [ ] Apple Watch 対応
- [ ] 為替レートのグラフ表示
- [ ] 通貨選択の永続化 (UserDefaults)
- [ ] 多言語対応 (i18n)
- [ ] ライトモード対応
