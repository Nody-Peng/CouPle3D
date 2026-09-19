# 2D 家園：Render 部署與試玩

## 使用現有 Render 服務

1. 先備份既有共同存檔。保留原本的 persistent disk、掛載路徑及 `COUPLE_DATA_FILE` 設定，不要為了切換 2D 刪除磁碟或存檔。
2. 在 Render 的 Web Service 設定把 Branch 改為 `asset-2d-rebuild`，不要選 `main`。
3. Runtime 使用 Node，`NODE_VERSION=22`。Build Command 為 `npm install --omit=dev`，Start Command 為 `npm start`。
4. 設定 `HOST=0.0.0.0` 與你們自己的 `COUPLE_TEST_CODE`。不要使用開發預設通行碼。Render 提供的 `PORT` 不需覆寫。
5. 存檔必須放在已掛載的持久磁碟，例如掛載 `/var/data` 時使用 `COUPLE_DATA_FILE=/var/data/state.json`。只有環境變數、沒有磁碟，不能保證重新部署後保留資料。
6. 執行 Manual Deploy，完成後開啟服務的 HTTPS 網址。`/api/health` 可用來檢查服務健康狀態。

此分支已包含匯出的 `web/game`，Render 不需要安裝 Godot，也不需要上傳原始素材包。

## 新建服務

根目錄 `render.yaml` 提供 Blueprint 設定，建立 Node Web Service 與 1 GB 持久磁碟，並要求自行填入私人通行碼。它指定付費 Starter 方案；使用前請確認 Render 顯示的費用。已有服務時通常直接更換分支即可，不需另建重複服務。

部署設定依據：[Render Blueprint 規格](https://render.com/docs/blueprint-spec)。這份程式修改不會自動替你建立或付費部署 Render 服務。

## 兩人開始玩

1. 兩台電腦打開同一個 HTTPS 網址，分別選「第一位玩家」與「第二位玩家」，輸入相同私人通行碼。
2. 按「回到共同之家」。兩邊在線上都用 **WASD 移動、E 互動**，也可點附近互動按鈕。若按鍵沒反應，先點一下遊戲畫面。
3. 室內預設拉近鏡頭，室外切回較廣視野；上方鏡頭控制可調整。
4. 兩個角色的位置、便條、聊天與共同資料由同一台伺服器同步。重新整理頁面會恢復登入；左下角可登出換角色。
5. 同一台電腦測試時，使用不同瀏覽器或一般視窗加無痕視窗。只開兩個一般分頁會共用登入 Cookie，不能當成兩個獨立玩家。

此版以電腦鍵盤操作為主，尚未提供完整手機觸控移動。照片在瀏覽器版會下載 PNG。

## 本機試玩與開發

在專案目錄執行 `npm start`，打開 `http://127.0.0.1:8787`；正式對外服務務必先設定私人通行碼。原生 Godot 啟動方式見 `PLAY_HOME_2D.md`。

原始下載素材、壓縮檔及 Godot 執行檔留在本機，不隨 Git 散布。Git 裡的已匯出版本可直接部署；若要重新匯出，需先在本機放回原本 `assets/2d` 的素材目錄，安裝對應 Godot 與 Web export templates，再執行 `tools/build-web.ps1`。新增 preload 或動態載入素材時也要更新 `export_presets.cfg`，並重跑瀏覽器測試。

## 範圍與驗證

這是 2D 分支，不是將 Main 所有 3D 功能一對一移植。部分鎮上建築目前開啟功能面板，並非每棟都有可走入的室內場景；舊版部分遊戲仍未接入。Main 不會被本分支的 Push 覆蓋。

測試命令：`npm test`、`node tools/verify-home-network.mjs`、`node tools/verify-home-web.cjs`。最後一項需要 Playwright 與 Chrome，會啟動兩個隔離登入的真正 WebGL 客戶端。實際 Render 網址及你們兩地網路仍需部署後驗收。
