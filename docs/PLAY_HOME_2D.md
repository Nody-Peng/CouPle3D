# 2D Private Home

瀏覽器與 Render 部署請先看 [DEPLOY_2D_RENDER.md](DEPLOY_2D_RENDER.md)。以下原生版需本機原始素材及 Godot；Git 內已匯出的網頁版不需要這些檔案。

## 中文快速開始

1. 房主雙擊 `start-home-server.cmd`，視窗會顯示這次使用的私人通行碼。遊玩期間保持視窗開啟。
2. 兩台電腦各自雙擊 `start-home-2d.cmd`，按上方「連線」。
3. 房主填 `http://127.0.0.1:8787`；另一台填房主可連線的 IP 或 HTTPS 網址。兩人輸入相同通行碼，分別選第一位與第二位玩家。
4. 連線後兩人都使用 WASD + E；未連線的同機雙人模式才是第一位 WASD + E、第二位方向鍵 + Enter。靠近冰箱可寫便條。
5. 上方提供聊天、共同日記、家具、約會、抱抱邀請、默契卡和合照。兩人的文字與家具存在伺服器，合照存在拍照者的「圖片/TogetherHome」。

不同城市不能直接使用房主的區域網路 IP，需要私人 VPN 或可連線的主機。
目前已測過本機的兩個獨立連線，尚未部署或驗證你們實際的兩個網路。
關閉伺服器不會刪除共同存檔，重開後使用新顯示的通行碼重新登入。

家具目前是五件、購買後擺在固定位置；抱抱目前是邀請和回覆，尚無角色接觸動畫。
原有海戰棋尚未接到新 2D 介面，這份版本仍是逐步完成中的私用版。

## Start

1. Double-click `start-home-2d.cmd` on each Windows computer. Both computers
   need this project and the bundled Godot executable. On a fresh copy, open
   `project.godot` in Godot once to import the assets before playing.
2. On the computer hosting the shared save, start PowerShell in the project:

```powershell
$env:COUPLE_TEST_CODE = 'choose-your-private-code'
$env:HOST = '0.0.0.0'
node server/server.mjs
```

3. Click Connect in the game. Enter `http://127.0.0.1:8787` on the host;
   the other computer uses the host's reachable IP address and port 8787.
   Enter the same private code and select different player slots.
4. Both connected players use WASD + E. Offline shared-keyboard player two uses arrow keys + Enter.
   Only your selected player is controlled while connected.

The server must remain running for shared features. Different home networks
require a reachable server address, for example through a private VPN or a
hosted HTTPS server. A LAN address alone does not work across the internet.
Internet deployment and testing on the couple's two networks are not completed.
Do not expose the default development code `together-local` publicly.

## Current Playable Features

- Shared 2D house and garden with collision and two player slots.
- Server-backed note with concurrent-edit protection.
- Persistent chat and shared diary (both partners can read these).
- Five furniture purchases placed in predefined spots, paid from shared coins.
- Daily activity rewards, once per player and activity per UTC day.
- Mutual invitation response, with no penalty for declining. This currently
  confirms the invitation with text; a physical hug animation is not implemented.
- Agreement cards: each player answers once; the other answer is hidden until
  both submit. Either player can start another card after completion.
- Shared date title and optional external link.
- Local PNG photo capture to Pictures/TogetherHome, without the HUD.
- Automatic retry after temporary network failure; server restart requires login.

Shared data lives in `server/data/state.json`, under `home2d`. Back up this file
while the server is stopped. Local trial notes and coins are separate and are
not uploaded when connecting. Photos remain on the computer that took them.

## Remaining Before Calling the Full Private Edition Complete

- Verify connectivity between the actual two networks and package distribution.
- Smooth remote animation, editable profile, seating/cooking/rest animations.
- Free furniture arrangement, shared photo album, and frame display.
- Connect the existing battleship game to the 2D interface.
- Add the small outdoor destination and test the complete daily play loop.

## Verification

```powershell
node --test tests/home2d.test.mjs tests/store.test.mjs
node tools/verify-home-network.mjs
```

The network verification creates an isolated temporary server and uses two Godot
HTTP clients. It does not change the playable shared save.
