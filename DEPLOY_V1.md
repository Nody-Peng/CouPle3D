# 心動之城 V1 部署筆記

V1 可以先部署成一個雙人測試版，讓兩個固定帳號登入遊玩。這個版本需要 Node.js 後端常駐，因為登入、即時位置、金幣、共同銀行、家具、海戰棋和存檔都由後端處理。

## V1 推薦上線方式

最省事的做法是使用支援 Node.js Web Service 和永久磁碟的平台，例如 Render、Railway、Fly.io 或一台 VPS。

部署設定：

```text
Build command: npm install
Start command: npm start
Node version: 22+
```

環境變數：

```text
HOST=0.0.0.0
PORT=由平台提供，若平台自動注入可不填
COUPLE_TEST_CODE=你們兩個才知道的登入代碼
COUPLE_DATA_FILE=/data/state.json
```

永久磁碟：

```text
Mount path: /data
```

如果平台的永久磁碟不是 `/data`，把 `COUPLE_DATA_FILE` 改成該磁碟底下的 `state.json` 即可。

## 上線前檢查

1. 重新建置 Godot Web 匯出：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/build-web.ps1
```

2. 本機跑後端測試：

```powershell
npm test
```

3. 本機啟動確認：

```powershell
npm start
```

開啟 `http://localhost:8787`，用兩個瀏覽器工作階段分別登入兩個帳號，確認能看到彼此、能進家、能玩海戰棋。

4. 部署後檢查健康狀態：

```text
https://你的網域/api/health
```

應回傳 `ok: true`。

## V1 目前適合的範圍

這一版適合你和女友先試玩、截圖、收集回饋，也適合拿來決定下一批小遊戲和場景方向。帳號目前仍是兩個固定測試帳號，登入代碼由 `COUPLE_TEST_CODE` 控制。

這一版不建議直接公開給很多人，原因是它還沒有正式註冊、密碼重設、資料庫、多房間配對、管理後台和正式防作弊。

## 未來擴充方向

可以持續擴充，而且目前架構已經有清楚的擴充點：

- 新增小遊戲：在 Web 介面新增玩法，再用後端 `Store.command()` 保存對局、獎勵和結果。
- 新增場景與設施：在 Godot 內擴充園區、室內、NPC、動物與互動點，重新匯出到 `web/game/`。
- 新增商品與家具：更新 `server/catalog.mjs`，再補對應預覽和場景模型。
- 擴成多對情侶：把固定 `a/b` 帳號改成正式使用者、情侶配對碼和每對獨立存檔。
- 正式營利：先用遊戲幣和裝飾驗證玩法，再接入付費方案、月卡、限定家具或造型包。
- App 版本：Web V1 穩定後，可用 PWA 或包成 WebView App；若要更原生，再評估 Godot Mobile 匯出。

## 資料備份

正式測試時最重要的是備份 `COUPLE_DATA_FILE` 指向的 `state.json`。它包含兩個帳號的金幣、背包、家具、共同銀行、家庭布置與海戰棋狀態。

建議 V1 期間每天備份一次，或在重大更新前先停機複製一份。
