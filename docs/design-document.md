# 通貨換算アプリ 設計書

## 目次

1. [プロジェクト概要](#1-プロジェクト概要)
2. [アーキテクチャ設計](#2-アーキテクチャ設計)
   - [ディレクトリ構成](#ディレクトリ構成)
   - [MVVM データフロー](#mvvm-データフロー)
3. [データモデル設計](#3-データモデル設計)
   - [3.1 CurrencyInfo](#31-currencyinfo)
   - [3.2 CurrencyRegion](#32-currencyregion)
   - [3.3 CalculatorState](#33-calculatorstate)
   - [3.4 ExchangeRateResponse](#34-exchangerateresponse)
   - [3.5 KeypadKey](#35-keypadkey)
4. [対応通貨一覧 (23通貨)](#4-対応通貨一覧-23通貨)
5. [API 設計](#5-api-設計)
   - [ExchangeRateService (Actor)](#exchangerateservice-actor)
   - [変換ロジック](#変換ロジック)
6. [ViewModel 設計](#6-viewmodel-設計)
7. [UI 設計](#7-ui-設計)
   - [7.1 全体レイアウト](#71-全体レイアウト-contentview)
   - [7.2 テーマ](#72-テーマ-apptheme-ダークモード専用)
   - [7.3 通貨表示エリア](#73-通貨表示エリア-currencydisplayarea)
   - [7.4 通貨行](#74-通貨行-currencyrowview)
   - [7.5 キーパッドボタン](#75-キーパッドボタン-keypadbutton)
   - [7.6 レート情報バー](#76-レート情報バー-rateinfobar)
   - [7.7 通貨選択シート](#77-通貨選択シート-currencypickerview)
   - [7.8 国旗画像](#78-国旗画像-flagimageview)
8. [主要機能一覧](#8-主要機能一覧)
9. [技術仕様](#9-技術仕様)
10. [今後の拡張候補](#10-今後の拡張候補)

---

## 1. プロジェクト概要

| 項目 | 内容 |
|------|------|
| プロジェクト名 | Currency Converter |
| プラットフォーム | iOS (SwiftUI) |
| 最小対応バージョン | iOS 17.0+ |
| アーキテクチャ | MVVM (Model-View-ViewModel) |
| 言語 | Swift |
| UI フレームワーク | SwiftUI |
| 状態管理 | Observation framework (`@Observable`) |

### 目的

電卓スタイルのUIを持つ、直感的でリアルタイムな通貨換算アプリ。複数通貨の同時表示、四則演算機能、ライブ為替レート取得を主要機能とする。

## 2. アーキテクチャ設計

### ディレクトリ構成

```
currency-converter/
├── currency_converterApp.swift          # アプリエントリポイント
├── ContentView.swift                     # ルートビュー
├── Models/
│   ├── CalculatorState.swift            # 電卓状態管理モデル（値型）
│   ├── Currency.swift                   # 通貨情報モデル・全通貨定義
│   └── ExchangeRateResponse.swift       # API レスポンスモデル
├── ViewModels/
│   └── CurrencyConverterViewModel.swift # メインViewModel + KeypadKey定義
├── Views/
│   ├── CurrencyDisplayArea.swift        # 通貨表示エリア
│   ├── CurrencyPickerView.swift         # 通貨選択シート
│   ├── CurrencyRowView.swift            # 通貨行表示
│   ├── FlagImageView.swift              # 国旗画像表示
│   ├── KeypadButton.swift               # キーパッドボタン（アニメーション付き）
│   ├── KeypadView.swift                 # キーパッド全体レイアウト
│   └── RateInfoBar.swift                # 為替レート情報バー + TimeAgoText
├── Services/
│   └── ExchangeRateService.swift        # 為替レートAPI通信（Actor）
├── Theme/
│   └── AppTheme.swift                   # テーマ・カラー・寸法定義
└── Assets.xcassets/                     # アセットカタログ
```

### MVVM データフロー

```
ExchangeRateService (Actor, 5分キャッシュ)
        ↓ async/await
CurrencyConverterViewModel (@Observable, 単一ソース・オブ・トゥルース)
        ↓ bindings (@Bindable)
SwiftUI Views (ステートレスプレゼンター)
```

- **`ExchangeRateService`** — Swift Actor。`fxapi.app` から為替レートを取得し、5分間のインメモリキャッシュを持つ。
- **`CurrencyConverterViewModel`** — `CalculatorState`、選択通貨、レートデータ、変換ロジックを所有。全変換はUSD中間通貨方式。`UserDefaults` で通貨選択とアクティブ通貨を永続化。
- **`CalculatorState`** — 値型の状態マシン。四則演算を `Decimal` 精度で処理。12桁入力制限、カンマ区切りフォーマット、インライン式表示（例: "5 × 3"）。
- **`KeypadKey`** — ViewModel ファイル内に定義された列挙型。全キーパッドボタンの種類と表示ラベルを定義。

## 3. データモデル設計

### 3.1 CurrencyInfo

通貨の基本情報を保持する構造体。`Identifiable`, `Hashable`, `Codable`, `Sendable` に準拠。

| プロパティ | 型 | 説明 |
|-----------|-----|------|
| `code` | `String` | 通貨コード (例: "USD", "JPY")。`id` として使用 |
| `name` | `String` | 英語名称 |
| `localizedName` | `String` | 日本語名称 |
| `flagCode` | `String` | 国旗用国コード (例: "jp", "us") |
| `region` | `CurrencyRegion` | 地域分類 |
| `flagURL` | `URL?` (computed) | `flagcdn.com/w160/{flagCode}.png` の URL |

静的メンバ:
- `allCurrencies` — 全23通貨の配列
- `defaultCurrencies` — デフォルト選択: JPY, CNY, USD
- `find(_:)` — 通貨コードで検索

### 3.2 CurrencyRegion

通貨の地域分類列挙型。`CaseIterable`, `Codable`, `Sendable` に準拠。`rawValue` は日本語表示名。

| 値 | rawValue | 通貨数 |
|----|----------|--------|
| `asia` | "アジア" | 12 |
| `westernEurope` | "西ヨーロッパ" | 6 |
| `northAmerica` | "北米" | 3 |
| `oceania` | "オセアニア" | 2 |
| `other` | "その他" | 0 (定義のみ) |

### 3.3 CalculatorState

電卓の内部状態を管理する値型構造体。

| プロパティ | 型 | アクセス | 説明 |
|-----------|-----|---------|------|
| `displayText` | `String` | `private(set)` | 現在の数値表示テキスト |
| `expressionText` | `String` | `private(set)` | 計算式テキスト（例: "5 ×"） |
| `currentValue` | `Decimal` | `private` | 内部計算値 |
| `pendingOperator` | `Operator?` | `private` | 保留中の演算子 |
| `pendingOperand` | `Decimal` | `private` | 保留中のオペランド |
| `isEnteringNumber` | `Bool` | `private` | 数値入力中フラグ |
| `hasDecimalPoint` | `Bool` | `private` | 小数点入力済みフラグ |
| `justCalculated` | `Bool` | `private` | 計算直後フラグ（次の入力でクリア） |

| 算出プロパティ | 型 | 説明 |
|---------------|-----|------|
| `displayValue` | `Decimal` | `displayText` のカンマ除去後の数値変換 |
| `fullDisplayText` | `String` | UI表示用テキスト。演算子保留中は "式 + 入力値"、それ以外は `displayText` のみ |

対応演算子 (`Operator` 内部enum): `+`, `−`, `×`, `÷`

公開メソッド: `inputDigit(_:)`, `inputDecimal()`, `inputOperator(_:)`, `calculate()`, `clear()`, `backspace()`, `toggleSign()`, `formatNumber(_:)`

### 3.4 ExchangeRateResponse

API レスポンスの JSON マッピング構造体。`Codable`, `Sendable` に準拠。

| プロパティ | 型 | 説明 |
|-----------|-----|------|
| `base` | `String` | ベース通貨コード |
| `timestamp` | `String` | ISO 8601 形式の最終更新時刻 |
| `rates` | `[String: Double?]` | 通貨コード→レート辞書（`nil` 値を含む可能性あり） |

### 3.5 KeypadKey

キーパッドボタンを表す列挙型。`Hashable`, `Sendable` に準拠。

| ケース | 表示ラベル | 説明 |
|--------|-----------|------|
| `.digit(String)` | "0"〜"9" | 数字入力 |
| `.decimal` | "." | 小数点入力 |
| `.clear` | "C" | 全クリア |
| `.backspace` | "←" | 一文字削除 |
| `.doubleZero` | "00" | ゼロ2桁入力 |
| `.moveDown` | "↓" | アクティブ通貨を下に移動 |
| `.add` | "+" | 加算 |
| `.subtract` | "−" | 減算 |
| `.multiply` | "×" | 乗算 |
| `.divide` | "÷" | 除算 |
| `.equals` | "=" | 計算実行 |

算出プロパティ: `displayLabel` (表示文字列), `isOperator` (演算子判定)

## 4. 対応通貨一覧 (23通貨)

### アジア (12通貨)
JPY (日本円), CNY (中国人民元), KRW (韓国ウォン), TWD (新台湾ドル), HKD (香港ドル), SGD (シンガポールドル), THB (タイバーツ), VND (ベトナムドン), PHP (フィリピンペソ), MYR (マレーシアリンギット), IDR (インドネシアルピア), INR (インドルピー)

### 西ヨーロッパ (6通貨)
EUR (ユーロ), GBP (英ポンド), CHF (スイスフラン), SEK (スウェーデンクローナ), NOK (ノルウェークローネ), DKK (デンマーククローネ)

### 北米 (3通貨)
USD (米ドル), CAD (カナダドル), MXN (メキシコペソ)

### オセアニア (2通貨)
AUD (豪ドル), NZD (ニュージーランドドル)

**デフォルト選択**: JPY, CNY, USD

## 5. API 設計

### 為替レート取得

| 項目 | 内容 |
|------|------|
| エンドポイント | `https://fxapi.app/api/{base}.json` |
| ベース通貨 | USD (固定、小文字で送信) |
| メソッド | GET |
| レスポンス形式 | JSON (`ExchangeRateResponse`) |
| タイムスタンプ形式 | ISO 8601 (fractional seconds 対応) |
| キャッシュ期間 | 5分 (300秒) |
| スレッド安全性 | Swift Actor で保証 |
| キャッシュ無効化 | `invalidateCache()` メソッド |

### ExchangeRateService (Actor)

内部状態:
- `cachedRates: [String: Double]?` — キャッシュ済みレート
- `cachedFetchedAt: Date?` — 最後のフェッチ時刻（キャッシュ有効期限判定用）
- `cachedAPITimestamp: Date?` — APIが返した最終更新時刻（UI表示用）

レスポンス処理:
1. `rates` の `nil` 値を `compactMapValues` で除去
2. ベース通貨 (USD) のレートを `1.0` として追加
3. ISO 8601 タイムスタンプをパース（失敗時は現在日時にフォールバック）

### 変換ロジック

全ての通貨変換はUSDを中間通貨として経由する:

```
元通貨の金額 ÷ 元通貨のUSDレート → USD金額 × 目標通貨のUSDレート → 目標通貨金額
```

## 6. ViewModel 設計

### CurrencyConverterViewModel (`@Observable`)

#### 状態プロパティ

| プロパティ | 型 | 説明 |
|-----------|-----|------|
| `selectedCurrencies` | `[CurrencyInfo]` | 選択中の通貨リスト |
| `activeCurrencyIndex` | `Int` | 入力対象の通貨インデックス |
| `calculator` | `CalculatorState` | 電卓状態 |
| `amounts` | `[Decimal]` | 各通貨の変換金額 |
| `rates` | `[String: Double]` | 為替レート辞書 |
| `rateLastUpdated` | `Date?` | レート最終更新時刻 |
| `rateError` | `String?` | エラーメッセージ |
| `showingPicker` | `Bool` | 通貨選択シート表示フラグ |
| `pickerTargetIndex` | `Int` | 通貨選択対象インデックス |
| `showingAddCurrency` | `Bool` | 通貨追加表示フラグ |

#### 永続化 (UserDefaults)

| キー | 型 | 内容 |
|------|-----|------|
| `selectedCurrencies` | `Data` (JSON) | 選択通貨リスト |
| `activeCurrencyIndex` | `Int` | アクティブ通貨インデックス |

初期化時に `UserDefaults` から復元。保存がなければ `defaultCurrencies` を使用。

#### 主要メソッド

| メソッド | 説明 |
|---------|------|
| `onKeyPress(_:)` | キーパッド入力のディスパッチ。入力後に `updateConversions()` を呼ぶ |
| `updateConversions()` | アクティブ通貨の金額をUSD経由で全通貨に変換 |
| `moveActiveCurrencyDown()` | アクティブ通貨を1つ下に移動。末尾なら先頭に循環 |
| `setActiveCurrency(_:)` | アクティブ通貨を切り替え。現在の変換金額を電卓に反映 |
| `selectCurrency(_:for:)` | 指定インデックスの通貨を入れ替え |
| `openPicker(for:)` | 通貨選択シートを表示 |
| `fetchRates()` | 為替レートを非同期取得 |

#### 算出プロパティ

| プロパティ | 説明 |
|-----------|------|
| `rateInfoText` | "1 JPY = 0.05 CNY \| 1 JPY = 0.01 USD" 形式のレート表示テキスト |
| `timeAgoText` | "just now", "5m ago" 等の相対時刻テキスト |

## 7. UI 設計

### 7.1 全体レイアウト (ContentView)

```
┌──────────────────────────┐
│   通貨表示エリア           │  CurrencyDisplayArea
│  ┌──────────────────────┐│
│  │ 🇯🇵 JPY  500 × 2,000 ││  CurrencyRowView (active, 式表示)
│  │ 🇨🇳 CNY      ¥48.52  ││  CurrencyRowView
│  │ 🇺🇸 USD       $6.85  ││  CurrencyRowView
│  └──────────────────────┘│
│   1 JPY = 0.05 CNY | ... │  RateInfoBar + TimeAgoText
│─────────── divider ──────│
│   ┌───┬───┬───┬───┐      │
│   │ C │ ← │ ↓ │ ÷ │      │  KeypadView
│   ├───┼───┼───┼───┤      │
│   │ 7 │ 8 │ 9 │ × │      │
│   ├───┼───┼───┼───┤      │
│   │ 4 │ 5 │ 6 │ − │      │
│   ├───┼───┼───┼───┤      │
│   │ 1 │ 2 │ 3 │ + │      │
│   ├───┼───┼───┼───┤      │
│   │00 │ 0 │ . │ = │      │
│   └───┴───┴───┴───┘      │
└──────────────────────────┘
```

**画面遷移:**
- アプリ起動 → `ContentView` が `fetchRates()` を `.task` で呼び出し
- `scenePhase` が `.active` に変化する度にレートを再取得
- ダークモード固定 (`.preferredColorScheme(.dark)`)

### 7.2 テーマ (AppTheme, ダークモード専用)

| 要素 | カラー名 | RGB |
|------|----------|-----|
| 背景 | `background` | (0.08, 0.08, 0.12) |
| カード背景 | `cardBackground` | (0.12, 0.12, 0.18) |
| ボタン背景 | `buttonBackground` | (0.15, 0.15, 0.22) |
| ボタン押下時 | `buttonPressed` | (0.18, 0.18, 0.26) |
| アクセント | `accent` | (0.55, 0.35, 0.85) |
| アクセント明 | `accentBright` | (0.65, 0.45, 0.95) |
| テキスト主色 | `textPrimary` | Color.white |
| テキスト副色 | `textSecondary` | Color(white: 0.55) |
| 区切り線 | `divider` | Color(white: 0.2) |

| 寸法 | 値 |
|------|-----|
| `keypadButtonSize` | 76pt (円形) |
| `keypadSpacing` | 16pt |
| `flagSize` | 36pt (円形マスク) |
| `cornerRadius` | 16pt |

### 7.3 通貨表示エリア (CurrencyDisplayArea)

- `selectedCurrencies` を `ForEach` で表示
- 各行は `CurrencyRowView`
- アクティブ行: `fullDisplayText` (電卓入力/式) を表示、白テキスト、`cardBackground` 背景
- 非アクティブ行: 変換結果金額を小数2桁で表示、グレーテキスト、透明背景
- 行タップ: `setActiveCurrency()` で切り替え
- 国旗タップ: `openPicker()` で通貨選択シート表示

### 7.4 通貨行 (CurrencyRowView)

レイアウト: `[国旗] [通貨コード]   [金額テキスト (右寄せ)]`

- 金額フォント: `.system(size: 38, weight: .light, design: .rounded)`
- 通貨コードフォント: `.system(size: 14, weight: .medium)`
- `minimumScaleFactor(0.4)` で長い金額に対応
- 非アクティブ通貨の金額フォーマット: 小数2桁（0.01未満は6桁まで）

### 7.5 キーパッドボタン (KeypadButton)

- 円形デザイン (76pt)
- ニューモーフィズム風シャドウ: 外側ダーク + 内側ライト
- タップアニメーション: `scaleEffect(0.85)` + `spring(response: 0.3, dampingFraction: 0.5)`
- カラールール:
  - 演算子 (±×÷): `accent` 背景、白テキスト
  - イコール: `accentBright` 背景、白テキスト
  - C: デフォルト背景、`accent` テキスト
  - 数字/その他: `buttonBackground` 背景、白テキスト

### 7.6 レート情報バー (RateInfoBar)

- 左: `rateInfoText` (例: "1 JPY = 0.05 CNY | 1 JPY = 0.01 USD")
- 右: `TimeAgoText` — レート最終更新時刻を "MM/dd HH:mm" 形式で表示
- フォント: `.system(size: 11)`

### 7.7 通貨選択シート (CurrencyPickerView)

- `.sheet` モーダルで表示
- `.presentationDetents([.fraction(0.7)])` — 画面の70%高さ
- `.presentationCornerRadius(20)` — 角丸20pt
- `.presentationBackground(AppTheme.cardBackground)` — カード背景色
- `.presentationDragIndicator(.visible)` — ドラッグインジケーター表示
- `NavigationStack` + `.searchable` で検索機能
- 検索対象: 通貨コード、英語名、日本語名
- 地域別 `Section` グループ表示（`CurrencyRegion.allCases` 順）
- 既に選択済みの通貨は非表示
- 日本語UI: ナビゲーションタイトル "通貨"、検索プレースホルダー "検索"

### 7.8 国旗画像 (FlagImageView)

- ソース: `flagcdn.com/w160/{countryCode}.png`
- `AsyncImage` による非同期読み込み
- 読み込み中: `ProgressView` (0.5倍スケール) + 円形背景
- 失敗時: 国コードテキスト (大文字) + 円形背景
- 円形マスク、デフォルト36pt

## 8. 主要機能一覧

### 8.1 電卓スタイル入力
- 四則演算 (加算・減算・乗算・除算)
- 計算式のインライン表示（例: "5 × 5"、イコール押下で結果のみ表示）
- 連鎖計算対応（"5 + 3 ×" で中間結果を自動計算）
- 小数点入力対応
- バックスペース (1文字削除) ・全クリア (C)
- 00キー (ゼロ2桁入力)
- 桁数制限 (12桁)
- カンマ区切りフォーマット
- ゼロ除算時は結果0を返す

### 8.2 複数通貨同時表示
- 可変数の通貨同時表示（デフォルト3通貨）
- アクティブ通貨は電卓入力/式表示、非アクティブは変換結果表示
- タップで通貨切り替え（切り替え時に現在の変換金額を電卓に反映）
- 国旗タップで通貨選択シートを表示

### 8.3 通貨移動
- ↓ボタンでアクティブ通貨を1つ下に移動
- 末尾の場合は先頭に循環移動
- 通貨リストと金額配列を同期して入れ替え

### 8.4 リアルタイム為替レート
- `fxapi.app` API からレート取得
- 5分間インメモリキャッシュ (フェッチ時刻ベース)
- APIタイムスタンプとフェッチ時刻を分離管理
- アプリ起動時 + フォアグラウンド復帰時に自動取得
- エラーハンドリング (`ExchangeRateError.apiFailed`)

### 8.5 リアルタイム変換
- キーパッド入力の度に全通貨の変換結果を即時更新
- USD 中間通貨方式による変換
- `Decimal` 型による精度保証

### 8.6 通貨選択の永続化
- `UserDefaults` で選択通貨リストとアクティブインデックスを保存
- `Codable` による JSON エンコード/デコード
- 通貨変更・並び替え・アクティブ切り替え時に自動保存

## 9. 技術仕様

| 項目 | 仕様 |
|------|------|
| 並行処理 | Swift Concurrency (async/await) |
| スレッド安全性 | Actor (ExchangeRateService) |
| デフォルトアクター分離 | `@MainActor` (ビルド設定 `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`) |
| 状態管理 | `@Observable` (Observation framework) |
| View バインディング | `@Bindable` |
| 数値精度 | `Decimal` 型 |
| 画像読み込み | `AsyncImage` |
| ナビゲーション | `NavigationStack` + `.sheet` |
| ローカライゼーション | 英語・日本語 (`.xcstrings` String Catalogs)。一部UI ("通貨", "検索") はハードコード |
| データ永続化 | `UserDefaults` (通貨選択・アクティブインデックス) |

## 10. 今後の拡張候補

- [ ] オフラインモード (レートのローカル永続化)
- [ ] ウィジェット対応
- [ ] Apple Watch 対応
- [ ] 為替レートのグラフ表示
- [ ] 通貨の追加・削除機能 (3通貨以上の動的管理)
- [ ] ライトモード対応
- [ ] 「その他」地域の通貨追加
