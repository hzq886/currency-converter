# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

This is a native iOS SwiftUI app using an Xcode project (not SPM). No test targets exist.

```bash
# Build for simulator
xcodebuild -project currency-converter.xcodeproj -scheme currency-converter -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Open in Xcode (preferred for day-to-day development)
open currency-converter.xcodeproj
```

## Architecture

MVVM with SwiftUI + `@Observable` (Observation framework). Single-ViewModel design.

**Data flow:**
```
ExchangeRateService (Actor, 5-min cache)
        ↓ async/await
CurrencyConverterViewModel (@Observable, single source of truth)
        ↓ bindings
SwiftUI Views (stateless presenters)
```

- **`ExchangeRateService`** — Swift Actor; fetches rates from `open.er-api.com/v6/latest/USD` with in-memory 5-minute cache.
- **`CurrencyConverterViewModel`** — owns `CalculatorState`, selected currencies, fetched rates, and conversion logic. All conversions route through USD as the intermediate currency (e.g. JPY→CNY = JPY→USD→CNY).
- **`CalculatorState`** — value-type state machine for 4-operation calculator. Uses `Decimal` for precision. 12-digit input limit with comma formatting. Displays inline expressions (e.g. "5 × 3").
- **`KeypadKey`** enum lives in the ViewModel file and defines all keypad button types and their display labels.

## Key Design Decisions

- **USD intermediate**: all conversions go through USD. Rates are stored as `[String: Double]` keyed by currency code.
- **Dark mode only**: `AppTheme` defines the entire color palette and dimensions. No light mode.
- **Localization**: English and Japanese via `.xcstrings` string catalogs. Some UI labels are hardcoded in Japanese in `CurrencyPickerView`.
- **Flags**: loaded asynchronously from `flagcdn.com` via `AsyncImage`.
- **Concurrency**: `@MainActor` default actor isolation (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` in build settings). The rate service uses a Swift Actor for thread safety.
- **25 currencies** across 5 regions defined in `Currency.swift`. Default selection: JPY, CNY, USD.

## Git Workflow

- **新功能**：从 `main` 新建 `feature/<功能名>` 分支后开发，完成后提 PR 合并回 `main`。
- **Bug 修复**：从 `main` 新建 `fix/<问题描述>` 分支后修复，完成后提 PR 合并回 `main`。
- **GitHub CLI**: `gh` 位于 `/opt/homebrew/bin/gh`，用于创建 PR 等 GitHub 操作。
- **分支清理**：PR 合并后删除对应的 feature/fix 分支。
