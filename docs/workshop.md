# C4 架構工作坊：玩具預購抽選服務

[C4 Model](https://c4model.com) 的動手實作。你會替**代理商的玩具預購抽選服務**建模：六個步驟，得到五張彼此一致、寫在同一個文字檔裡的圖，再學一次手動排版；最後把一個關鍵決策寫成 ADR（架構決策記錄）。

你負責描述每一張圖「該說什麼」，**opencode** 負責寫 [Structurizr DSL](https://docs.structurizr.com/dsl/language) 並自我檢查。你不需要記語法，但一定會讀到它，所以文末附了速查表和疑難排解。

> **場景。** 你們是代理商的系統開發商。代理商**已經有一支實名制 App**，買家在那裡登入並完成實名驗證；也已經有**門市系統**。代理商想用**最小的成本**辦玩具預購：
>
> - 營運人員設定每次預購活動的**期間**，以及**每個買家可抽選的玩具總量**；
> - 買家在活動期間內，登記想抽選的項目；
> - 預購**截止時抽選**出結果；
> - 抽中的買家，選擇想去哪一間**門市**領取商品。
>
> 我們要做的是把這些**接在現有的實名制 App 上**，而不是另外做一個買家端 App，也不是重做門市系統。

---

## 目錄

- [六個步驟](#六個步驟)
- [驗證只看這幾件事](#驗證只看這幾件事)
- [事前準備（工作坊開始前做完）](#事前準備工作坊開始前做完)
- [Step 1：一張投影片，講清楚邊界](#step-1一張投影片講清楚邊界)
- [Step 2：我們自己寫什麼](#step-2我們自己寫什麼)
- [Step 3：打開 API](#step-3打開-api)
- [Step 4：一場預購活動的順序](#step-4一場預購活動的順序)
- [Step 5：每個東西跑在哪裡](#step-5每個東西跑在哪裡)
- [Step 6：拿掉 autoLayout，自己排](#step-6拿掉-autolayout自己排)
- [ADR：把「為什麼」寫下來](#adr把為什麼寫下來)
- [收尾](#收尾)
- [疑難排解](#疑難排解)
- [DSL 速查表（你不用寫，只用來讀）](#dsl-速查表你不用寫只用來讀)
- [參考資料](#參考資料)

---

## 六個步驟

C4 不是「畫五張圖」，而是**依序回答幾個問題，每一個都是把前一張圖的某個方塊放大來看**。五張圖住在同一個檔案 `structurizr/workspace.dsl`，每一步只是往裡面加內容，不會重寫、也不會刪掉前面的圖。

| Step | 圖 | 它回答的問題 |
| --- | --- | --- |
| 1 | System Context | 這套系統是誰在用？依賴什麼？哪些不是我們的？ |
| 2 | Containers | 我們自己寫什麼、借用什麼、跑什麼？ |
| 3 | Components | 新的業務規則（例如活動期間、每人總量）該放進哪裡？ |
| 4 | PreorderFlow（動態圖） | 一場預購活動從頭到尾依序發生什麼？ |
| 5 | Deployment | 每個東西實際跑在哪裡？ |
| 6 | （手動排版） | 自動排版擠成一團時怎麼辦？ |
| ADR | 決策記錄（文字，不畫圖） | 當初為什麼這樣決定？還考慮過什麼？ |

圖回答「是什麼」，ADR 回答「**為什麼**」。每個步驟結尾有一則 **ADR 候選**：那是你剛剛在圖上做下的一個決策。**現在不要討論**，只在筆記上記一行；最後挑一個寫成 ADR。

每一步的迴圈都一樣：

```
把 prompt 貼進 opencode  →  agent 驗證並展示新的圖  →  你看「驗證」那幾項  →  git commit
```

| 指令 | 用途 |
| --- | --- |
| `make up` | 啟動互動式檢視器 <http://localhost:8080>（重新整理瀏覽器才會重載） |
| `make validate` | 檢查檔案能不能解析 |
| `make export` | 輸出可分享的靜態網站到 `structurizr/static-site/` |
| `make export-saved` | 同上，但改用 `structurizr/workspace.json` 輸出，保留手動排版的位置 |
| `make down` | 關閉檢視器 |

## 驗證只看這幾件事

每一步的「驗證」只有 2 到 3 項，加上下面這三個每一步都一樣的底線：

| 底線 | 為什麼 | 怎麼確認 |
| --- | --- | --- |
| 檔案能解析 | 壞掉的檔案，後面什麼都做不了 | agent 回報 `validate` 拿到 `OK`（或自己跑 `make validate`） |
| 沒有空白方塊 | 沒有說明的方塊教不了任何人任何事 | `inspect` 報告裡沒有「missing a description」 |
| 前面的圖沒被改壞 | 五張圖是同一個 model 的不同視角 | 在導覽列把前面的圖點一遍，方塊與線沒變 |

品質報告裡其他的抱怨（缺少協定、缺少文件）**可以忽略**：人與同一行程內的呼叫本來就沒有協定可填，文件超出這次範圍。「缺少決策記錄」會在最後的 ADR 單元處理，掛上之後這項抱怨應該會消失。

---

## 事前準備（工作坊開始前做完）

你需要這個 repo，以及 [Docker](https://www.docker.com/) 或 [Podman](https://podman.io/)。所有指令都在 repo 根目錄執行；完整工具鏈寫在 [README](README.md)。

**1. Structurizr MCP server**（讓 agent 能自己驗證）

```bash
# 官方託管版
opencode mcp add structurizr --url https://mcp.structurizr.com/mcp

# 或本機版（只綁本機網卡，可離線；真實客戶專案建議用這個，避免模型內容送到第三方）
docker run -d --rm -p 127.0.0.1:3000:3000 -e PORT=3000 structurizr/mcp -dsl -mermaid
opencode mcp add structurizr --url http://localhost:3000/mcp
```

沒有 MCP 也做得完：agent 照既有風格寫 DSL，你用 `make validate` 驗證。沒有容器也沒有 MCP？下載 [Structurizr CLI](https://docs.structurizr.com/cli)（需要 Java），用 `structurizr.sh validate -workspace structurizr/workspace.dsl`。

**2. 規則檔 `AGENTS.md`**

每個 prompt 只寫這一步獨有的情境；每一步都一樣的規矩（不改名、不動前面的圖、每個元素都要說明、協定放哪、先 validate 再 inspect…）放在 repo 根目錄的 `AGENTS.md`，opencode 會在對話開始時讀它。規則檔是寫給 agent 看的，所以用英文，你不需要背。

```markdown
# Structurizr modeling rules

This project models a system as C4 diagrams in Structurizr DSL. Everything lives in one file: `structurizr/workspace.dsl`.

## Scope
- Only edit `structurizr/workspace.dsl` (and `structurizr/adrs/` when I ask for a decision record).
- Do only what this step asks. Do not add boxes, relationships or views that were not requested.
- Never rename existing elements (title or identifier). Do not touch existing views unless the step explicitly asks.
- When I say "do not edit files yet", only propose; do not edit.

## Syntax
- Include `configuration { scope softwaresystem }`.
- The opening `{` goes at the end of the declaration line, never on its own line.
- View keys may only contain `a-zA-Z0-9_-`. Titles may be in any language (Chinese is fine).
- `autoLayout` always needs a direction: `autoLayout lr`.
- A system context or container view with `include *` only shows elements directly connected to the system in scope. If a step says a person must appear even though they reach the system through an external system, add `include <person>` explicitly.

## Content
- Every element (person, softwareSystem, container, component, deploymentNode) needs a one-sentence description of its responsibility.
- Containers and components need a technology.
- Write relationships as verb phrases. For machine-to-machine relationships, put the protocol in the last quoted string: `a -> b "verb phrase" "HTTPS"`. Never put the protocol inside the verb phrase.
- People and in-process calls have no protocol; leave it out.
- Systems we do not own get the tag `"外部系統"` (keep this exact tag).
- In the first step, define one `styles` entry for the tag `"外部系統"` only (`#999999`, white text). The base colors for people, systems, containers and components come from the theme.
- Reference themes by their raw GitHub URL only. Never use `theme default`, never use a bare theme name (it does not resolve in this setup), and never create theme files.
- Default theme (base colors for people, systems, containers and components): `theme https://raw.githubusercontent.com/structurizr/themes/master/default/theme.json`
- Only in the deployment step, switch to `themes <default theme URL> <cloud theme URL>` using the cloud provider the user chose. Cloud theme URLs follow `https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/<directory>/theme.json`, where `<directory>` is `amazon-web-services-2025.07`, `microsoft-azure-2025.11`, `google-cloud-platform-2025.09`, `oracle-cloud-infrastructure-2023.04` or `kubernetes`. Pin to the release tag, never `main`.
- In deployment views, tag nodes with the exact tags defined by the cloud theme (see https://playground.structurizr.com/themes). For AWS, for example: `Amazon Web Services - Region`, `Amazon Web Services - Fargate`, `Amazon Web Services - RDS`, `Amazon Web Services - EventBridge`.
- In deployment views, relationships between containers appear automatically from the model. Do not redraw them between machines; only add relationships the model does not already have.
- Architecture decision records (ADRs) go in `structurizr/adrs/` in adr-tools Markdown format (title, Date, Status, Context, Decision, Consequences). Use lowercase English file names with hyphens, e.g. `0001-reuse-existing-realname-app.md` (non-ASCII file names fail to load in some environments), and attach them to the relevant element. An ADR must name the alternatives that were not chosen and at least one downside.

## Before you finish
- Run `validate` and wait for `OK` before saying you are done.
- Run `inspect` and report every finding to me.
- Use `parse` to count the boxes and lines of the new view; do not guess.
- Show me the new diagram.
- If you cannot reach the MCP server, say so honestly instead of claiming success.
```

如果你用的 agent 不會自動讀它，就在開新對話時把內容整份貼給它。

**3. 主題（theme）**

本教學的主題**一律用 GitHub 網址引用**。不要用 `theme default`：它會去下載 Structurizr 雲端服務的主題，而該服務已在 2026-09-30 結束，`make validate` 會因此 exit 1。也不要只寫資料夾名稱的簡寫（例如 `amazon-web-services-2025.07`），在我們的環境下無法載入。

- **預設主題**，提供人、系統、container、component 的基本顏色：

  ```text
  theme https://raw.githubusercontent.com/structurizr/themes/master/default/theme.json
  ```

- **雲端主題**（Step 5 的部署圖圖示），要和預設主題並用，所以改成複數的 `themes`，單數的 `theme` 只能放一個：

  ```text
  themes https://raw.githubusercontent.com/structurizr/themes/master/default/theme.json https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/amazon-web-services-2025.07/theme.json
  ```

**所有主題網址**（換雲端時，把 `themes` 那一行的第二個網址換掉）：

| 主題 | 網址 |
| --- | --- |
| 預設主題（人、系統、container、component 的基本顏色） | `https://raw.githubusercontent.com/structurizr/themes/master/default/theme.json` |
| AWS 2025.07（最新） | `https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/amazon-web-services-2025.07/theme.json` |
| AWS 2023.01 | `https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/amazon-web-services-2023.01/theme.json` |
| AWS 2022.04 | `https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/amazon-web-services-2022.04/theme.json` |
| AWS 2020.04 | `https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/amazon-web-services-2020.04/theme.json` |
| Azure 2025.11（最新） | `https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/microsoft-azure-2025.11/theme.json` |
| Azure 2024.07 | `https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/microsoft-azure-2024.07/theme.json` |
| Azure 2023.01 | `https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/microsoft-azure-2023.01/theme.json` |
| Azure 2021.01 | `https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/microsoft-azure-2021.01/theme.json` |
| Azure 2020.07 | `https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/microsoft-azure-2020.07/theme.json` |
| Azure 2019.09 | `https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/microsoft-azure-2019.09/theme.json` |
| GCP 2025.09（最新，約 40 個標籤） | `https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/google-cloud-platform-2025.09/theme.json` |
| GCP v1.5 | `https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/google-cloud-platform-v1.5/theme.json` |
| Oracle Cloud 2023.04（最新） | `https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/oracle-cloud-infrastructure-2023.04/theme.json` |
| Oracle Cloud 2021.04 | `https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/oracle-cloud-infrastructure-2021.04/theme.json` |
| Oracle Cloud 2020.04 | `https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/oracle-cloud-infrastructure-2020.04/theme.json` |
| Kubernetes | `https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/kubernetes/theme.json` |

預設主題網址指向 `master` 分支；想固定版本，可把 `master` 換成 commit，例如 `67da2b503abc708f941e5aa2ea35dd553f742c3a`。雲端主題已固定在版本標籤 `v2026.09.19`，不要改成 `main`，否則主題更新時你的圖會跟著變。

**圖示標籤因主題而異。** AWS 是 `Amazon Web Services - Fargate`，Azure 是 `Microsoft Azure - Container Instances`，GCP 的標籤又不同。請到[主題瀏覽器](https://playground.structurizr.com/themes)查確切字串。

> 網址寫法要連網：檢視器載入時會從 GitHub 讀主題與圖示。會場網路不穩的話，預設主題可以先下載成本機檔案備用（`curl -o structurizr/theme.json https://raw.githubusercontent.com/structurizr/themes/master/default/theme.json`，DSL 改寫 `theme "theme.json"`），但雲端圖示仍然需要連網。這份教學也不需要設定 `STRUCTURIZR_THEMES`，它只對資料夾名稱的簡寫有用。

**4. 版本控制**

一切都在 git 底下。每一步都 commit：`git add structurizr && git commit -m "step 1"`，`git diff` 就會精確顯示這一步加了什麼。想重來：`git checkout structurizr/workspace.dsl`。

---

## Step 1：一張投影片，講清楚邊界

> 產品經理要跟主管開個簡短的會：這套預購抽選系統誰在用？依賴什麼？哪些不是我們的責任？
>
> 陷阱：代理商**已經有**實名制 App 和門市系統，我們是**借用、呼叫**它們，不是重建它們。也不要在這一層就講 PostgreSQL；只畫人、我們的系統、以及我們不擁有的系統。

### Prompt

```text
讀 structurizr/workspace.dsl，把範例換成這個專案的 Level 1 系統脈絡圖，圖名 "SystemContext"，並讓它成為檔案裡唯一的一張圖。

情境：代理商要辦玩具預購抽選，希望用最小的成本做。營運人員設定每次預購活動的期間，以及每個買家可抽選的玩具總量；買家在代理商既有的實名制 App 裡登記想抽選的玩具（實名驗證由 App 負責）；截止時系統抽選出結果，並透過 App 推播通知；抽中的買家再選擇要去哪間門市領取，我們把抽中名單與取貨門市送給代理商既有的門市取貨系統。
我們不做買家端 App，也不做門市系統。買家不直接連到我們的系統，但要出現在圖上（他是透過實名制 App 使用我們的功能）。

外部系統：代理商實名制 App 和門市取貨系統是代理商既有的、不是我們的，請標記為「外部系統」，並用灰色顯示，和我們自己的系統（藍色）區分開。
讓這個 workspace 使用 Structurizr 官方預設主題，用網址引用：https://raw.githubusercontent.com/structurizr/themes/master/default/theme.json（人與系統的基本顏色由它提供）。不要用 theme default。
這一層不要出現任何技術名稱。
```

### 驗證

- [ ] **5 個方塊、5 條線**：買家、營運人員、預購抽選系統、兩個外部系統（實名制 App、門市取貨系統）；圖上沒有任何技術名稱（React、PostgreSQL 出現就代表畫成了容器圖）。
- [ ] **兩個外部系統是灰色，我們自己的系統是藍色，人是深藍色。** 從這張圖開始，「誰是我們的、誰不是」就一眼看得出來，之後每一張圖都沿用。

> **ADR 候選 1：預購登記入口借用實名制 App，不另做買家端 App。** —— 在筆記上記一行就好，先不要討論。

<details>
<summary>參考解答：Step 1 之後的完整 <code>workspace.dsl</code></summary>

```structurizr
workspace "玩具預購抽選服務" "C4 工作坊" {

    model {
        buyer = person "買家" "想預購熱門玩具的消費者，透過代理商實名制 App 登記預購。"
        operator = person "營運人員" "代理商的營運人員，設定預購活動的期間與每人可抽選的總量。"

        preorderSystem = softwareSystem "預購抽選系統" "讓買家登記想抽選的玩具，在截止時抽選出結果，並讓抽中的買家選擇取貨門市。"
        realnameApp = softwareSystem "代理商實名制 App" "代理商既有的 App，買家在這裡登入並完成實名驗證；預購登記入口與結果推播都借用它。" "外部系統"
        storeSystem = softwareSystem "門市取貨系統" "代理商既有的門市系統，依抽中名單與取貨門市核對並交付商品。" "外部系統"

        buyer -> realnameApp "在 App 內登記預購、查看結果、選擇取貨門市"
        realnameApp -> preorderSystem "轉交預購請求（已通過實名驗證）"
        preorderSystem -> realnameApp "推播抽選結果通知"
        operator -> preorderSystem "設定預購活動與抽選規則"
        preorderSystem -> storeSystem "傳送抽中名單與取貨門市"
    }

    configuration {
        scope softwaresystem
    }

    views {
        systemContext preorderSystem "SystemContext" {
            include *
            include buyer
            autoLayout lr
        }
        styles {
            element "外部系統" {
                background #999999
                color #ffffff
            }
        }
        theme https://raw.githubusercontent.com/structurizr/themes/master/default/theme.json
    }
}
```

</details>

---

## Step 2：我們自己寫什麼

> 主管問：「哪些東西是我們自己寫的、哪些是借用的？」打開「預購抽選系統」這個盒子。**container 是「可以獨立部署的單元」**（有自己的行程、可以單獨重啟），跟 Docker 容器是兩回事。

### Prompt

```text
讀 structurizr/workspace.dsl，加一張 Level 2 容器圖，圖名 "Containers"。SystemContext 不要動。

打開「預購抽選系統」，切成 4 個可獨立部署的 container：
  管理後台（【你喜歡的前端框架，例如 React】，營運人員設定活動用）
  預購 API（【你喜歡的後端語言與框架，例如 Node.js / Express】，接收實名制 App 轉交的登記與取貨門市選擇，也提供管理後台使用）
  抽選排程（【同一套後端語言】的排程工作，活動截止時抽選，並請實名制 App 推播結果）
  預購資料庫（【你熟悉的資料庫，例如 PostgreSQL】）

把原本指向「預購抽選系統」整體的連線，移到真正擁有它們的 container 上，機器對機器的連線要標協定。
實名制 App 和門市取貨系統留在系統盒子外面；買家仍然要出現在圖上。
```

> 【】裡請換成你們團隊真正熟悉的技術（參考解答用 React、Node.js、PostgreSQL）。agent 會把它們標在 container 上，Step 3 的元件與 Step 5 的部署都會沿用；如果你換了資料庫，Step 5 的託管服務也要跟著換。

### 驗證

- [ ] **系統盒子裡有 4 個 container，兩個外部系統在盒子外面。** 如果實名制 App 被畫進去，邊界就沒有意義了。
- [ ] **沒有任何箭頭還指向「預購抽選系統」整體。** 舊連線是被**移動**到 container 上，不是留在原處並排。
- [ ] 導覽列有 2 張圖，`SystemContext` 還是原來的樣子。

> Structurizr **預設**就會把子元素之間的關係自動「推論」給上層元素（隱含關係），不用另外設定：後面 Step 3 到 Step 5 沒有重畫的線，都靠它。延伸閱讀：[Implied relationships](https://docs.structurizr.com/dsl/cookbook/implied-relationships/)。
>
> **ADR 候選 2：抽選在截止時用排程工作批次執行**，而不是登記時即時決定。 —— 在筆記上記一行就好，先不要討論。

<details>
<summary>參考解答：這一步改了什麼（diff）</summary>

```diff
@@ -6,3 +6,8 @@
 
-        preorderSystem = softwareSystem "預購抽選系統" "讓買家登記想抽選的玩具，在截止時抽選出結果，並讓抽中的買家選擇取貨門市。"
+        preorderSystem = softwareSystem "預購抽選系統" "讓買家登記想抽選的玩具，在截止時抽選出結果，並讓抽中的買家選擇取貨門市。" {
+            adminWeb = container "管理後台" "讓營運人員設定預購活動的期間、每人可抽選的總量、可登記的玩具與可取貨的門市。" "React / Web 瀏覽器"
+            preorderApi = container "預購 API" "接收實名制 App 轉交的登記與取貨門市選擇，也提供管理後台讀寫活動設定。" "Node.js / Express REST API"
+            lotteryJob = container "抽選排程" "活動截止時讀取所有登記，依規則抽選並寫入結果，再請實名制 App 推播通知。" "Node.js / 排程工作"
+            preorderDb = container "預購資料庫" "儲存活動設定、買家登記、抽選結果與取貨門市。" "PostgreSQL"
+        }
         realnameApp = softwareSystem "代理商實名制 App" "代理商既有的 App，買家在這裡登入並完成實名驗證；預購登記入口與結果推播都借用它。" "外部系統"
@@ -11,6 +16,9 @@
         buyer -> realnameApp "在 App 內登記預購、查看結果、選擇取貨門市"
-        realnameApp -> preorderSystem "轉交預購請求（已通過實名驗證）"
-        preorderSystem -> realnameApp "推播抽選結果通知"
-        operator -> preorderSystem "設定預購活動與抽選規則"
-        preorderSystem -> storeSystem "傳送抽中名單與取貨門市"
+        realnameApp -> preorderApi "轉交預購請求（帶實名驗證憑證）" "HTTPS"
+        operator -> adminWeb "設定預購活動與抽選規則"
+        adminWeb -> preorderApi "讀寫活動設定" "HTTPS"
+        preorderApi -> preorderDb "讀寫活動、登記、抽選結果與取貨門市" "SQL"
+        lotteryJob -> preorderDb "讀取登記並寫入抽選結果" "SQL"
+        lotteryJob -> realnameApp "請 App 推播抽選結果" "HTTPS"
+        preorderApi -> storeSystem "傳送抽中名單與取貨門市" "HTTPS"
     }
@@ -24,2 +32,7 @@
             include *
+            include buyer
+            autoLayout lr
+        }
+        container preorderSystem "Containers" {
+            include *
             include buyer
```

</details>

<details>
<summary>參考解答：Step 2 之後的完整 <code>workspace.dsl</code></summary>

```structurizr
workspace "玩具預購抽選服務" "C4 工作坊" {

    model {
        buyer = person "買家" "想預購熱門玩具的消費者，透過代理商實名制 App 登記預購。"
        operator = person "營運人員" "代理商的營運人員，設定預購活動的期間與每人可抽選的總量。"

        preorderSystem = softwareSystem "預購抽選系統" "讓買家登記想抽選的玩具，在截止時抽選出結果，並讓抽中的買家選擇取貨門市。" {
            adminWeb = container "管理後台" "讓營運人員設定預購活動的期間、每人可抽選的總量、可登記的玩具與可取貨的門市。" "React / Web 瀏覽器"
            preorderApi = container "預購 API" "接收實名制 App 轉交的登記與取貨門市選擇，也提供管理後台讀寫活動設定。" "Node.js / Express REST API"
            lotteryJob = container "抽選排程" "活動截止時讀取所有登記，依規則抽選並寫入結果，再請實名制 App 推播通知。" "Node.js / 排程工作"
            preorderDb = container "預購資料庫" "儲存活動設定、買家登記、抽選結果與取貨門市。" "PostgreSQL"
        }
        realnameApp = softwareSystem "代理商實名制 App" "代理商既有的 App，買家在這裡登入並完成實名驗證；預購登記入口與結果推播都借用它。" "外部系統"
        storeSystem = softwareSystem "門市取貨系統" "代理商既有的門市系統，依抽中名單與取貨門市核對並交付商品。" "外部系統"

        buyer -> realnameApp "在 App 內登記預購、查看結果、選擇取貨門市"
        realnameApp -> preorderApi "轉交預購請求（帶實名驗證憑證）" "HTTPS"
        operator -> adminWeb "設定預購活動與抽選規則"
        adminWeb -> preorderApi "讀寫活動設定" "HTTPS"
        preorderApi -> preorderDb "讀寫活動、登記、抽選結果與取貨門市" "SQL"
        lotteryJob -> preorderDb "讀取登記並寫入抽選結果" "SQL"
        lotteryJob -> realnameApp "請 App 推播抽選結果" "HTTPS"
        preorderApi -> storeSystem "傳送抽中名單與取貨門市" "HTTPS"
    }

    configuration {
        scope softwaresystem
    }

    views {
        systemContext preorderSystem "SystemContext" {
            include *
            include buyer
            autoLayout lr
        }
        container preorderSystem "Containers" {
            include *
            include buyer
            autoLayout lr
        }
        styles {
            element "外部系統" {
                background #999999
                color #ffffff
            }
        }
        theme https://raw.githubusercontent.com/structurizr/themes/master/default/theme.json
    }
}
```

</details>

---

## Step 3：打開 API

> 新進工程師問：「活動期間和每人可抽選的總量，這些規則要寫在哪裡？」容器圖只說「預購 API 跟資料庫講話」，沒說是 API 的**哪一部分**負責。打開「預購 API」。這是本教學的最底層（C4 還有第四層 Code，但再往下就是 class diagram，通常直接讀程式碼就好）。

### Prompt

```text
讀 structurizr/workspace.dsl，加一張 Level 3 元件圖，圖名 "Components"。前兩張圖不要動。

打開「預購 API」，切成 4 個元件：
  憑證驗證中介層（驗證實名制 App 簽發的實名驗證憑證）
  活動規則服務（活動期間與每人可抽選總量的規則）
  登記服務（買家登記想抽選的玩具、查詢結果）
  取貨服務（抽中的買家選擇取貨門市，並通知門市取貨系統）
元件的技術沿用預購 API 的語言與框架。
來自實名制 App 的買家請求，都要先通過憑證驗證中介層，這是唯一入口；管理後台只會呼叫活動規則服務（營運人員的登入不在這張圖範圍）。
把原本指向「預購 API」整體的連線，移到真正擁有它們的元件上。
```

### 驗證

- [ ] **實名制 App 只有一條線進入 API，而且進的是憑證驗證中介層。** 如果它還直接連到別的元件，就等於畫出一條不用驗證憑證的後門。
- [ ] **沒有任何箭頭還指向「預購 API」整體**；「活動期間」與「每人可抽選總量」的規則只在**活動規則服務**一處，登記服務是去查它，不是自己判斷。你能回答：「如果新增一條規則（例如每場活動最多登記 3 個品項），要改哪裡？」
- [ ] 導覽列有 3 張圖，前兩張沒有增減方塊或線。

> 四個元件已經是上限；再往下加就是在畫 class diagram。把規則集中在一處只是一個取捨，不是標準答案 —— 你能說出理由就好。
>
> **ADR 候選 3：活動規則（期間、每人總量）集中在活動規則服務**，而不是散在登記與取貨服務裡。 —— 在筆記上記一行就好，先不要討論。

<details>
<summary>參考解答：這一步改了什麼（diff）</summary>

```diff
@@ -8,3 +8,8 @@
             adminWeb = container "管理後台" "讓營運人員設定預購活動的期間、每人可抽選的總量、可登記的玩具與可取貨的門市。" "React / Web 瀏覽器"
-            preorderApi = container "預購 API" "接收實名制 App 轉交的登記與取貨門市選擇，也提供管理後台讀寫活動設定。" "Node.js / Express REST API"
+            preorderApi = container "預購 API" "接收實名制 App 轉交的登記與取貨門市選擇，也提供管理後台讀寫活動設定。" "Node.js / Express REST API" {
+                authGuard = component "憑證驗證中介層" "驗證實名制 App 簽發的實名驗證憑證（簽章與有效期限），不通過就拒絕買家請求。" "TypeScript Middleware"
+                campaignService = component "活動規則服務" "管理預購活動，並檢查活動期間與每人可抽選的總量。" "TypeScript Service"
+                registrationService = component "登記服務" "接收買家登記想抽選的玩具，套用活動規則後寫入登記，並提供結果查詢。" "TypeScript Service"
+                pickupService = component "取貨服務" "讓抽中的買家選擇取貨門市，並把抽中名單與取貨門市送給門市取貨系統。" "TypeScript Service"
+            }
             lotteryJob = container "抽選排程" "活動截止時讀取所有登記，依規則抽選並寫入結果，再請實名制 App 推播通知。" "Node.js / 排程工作"
@@ -16,9 +21,15 @@
         buyer -> realnameApp "在 App 內登記預購、查看結果、選擇取貨門市"
-        realnameApp -> preorderApi "轉交預購請求（帶實名驗證憑證）" "HTTPS"
+        realnameApp -> authGuard "轉交預購請求（帶實名驗證憑證）" "HTTPS"
+        authGuard -> registrationService "憑證通過後轉交登記與結果查詢"
+        authGuard -> pickupService "憑證通過後轉交取貨門市選擇"
+        registrationService -> campaignService "查詢活動期間與每人可抽選總量"
+        pickupService -> campaignService "查詢可取貨的門市"
         operator -> adminWeb "設定預購活動與抽選規則"
-        adminWeb -> preorderApi "讀寫活動設定" "HTTPS"
-        preorderApi -> preorderDb "讀寫活動、登記、抽選結果與取貨門市" "SQL"
+        adminWeb -> campaignService "讀寫活動設定" "HTTPS"
+        campaignService -> preorderDb "讀寫活動設定" "SQL"
+        registrationService -> preorderDb "寫入登記並讀取抽選結果" "SQL"
+        pickupService -> preorderDb "寫入取貨門市" "SQL"
+        pickupService -> storeSystem "傳送抽中名單與取貨門市" "HTTPS"
         lotteryJob -> preorderDb "讀取登記並寫入抽選結果" "SQL"
         lotteryJob -> realnameApp "請 App 推播抽選結果" "HTTPS"
-        preorderApi -> storeSystem "傳送抽中名單與取貨門市" "HTTPS"
     }
@@ -39,2 +50,6 @@
             autoLayout lr
+        }
+        component preorderApi "Components" {
+            include *
+            autoLayout lr
         }
```

</details>

<details>
<summary>參考解答：Step 3 之後的完整 <code>workspace.dsl</code></summary>

```structurizr
workspace "玩具預購抽選服務" "C4 工作坊" {

    model {
        buyer = person "買家" "想預購熱門玩具的消費者，透過代理商實名制 App 登記預購。"
        operator = person "營運人員" "代理商的營運人員，設定預購活動的期間與每人可抽選的總量。"

        preorderSystem = softwareSystem "預購抽選系統" "讓買家登記想抽選的玩具，在截止時抽選出結果，並讓抽中的買家選擇取貨門市。" {
            adminWeb = container "管理後台" "讓營運人員設定預購活動的期間、每人可抽選的總量、可登記的玩具與可取貨的門市。" "React / Web 瀏覽器"
            preorderApi = container "預購 API" "接收實名制 App 轉交的登記與取貨門市選擇，也提供管理後台讀寫活動設定。" "Node.js / Express REST API" {
                authGuard = component "憑證驗證中介層" "驗證實名制 App 簽發的實名驗證憑證（簽章與有效期限），不通過就拒絕買家請求。" "TypeScript Middleware"
                campaignService = component "活動規則服務" "管理預購活動，並檢查活動期間與每人可抽選的總量。" "TypeScript Service"
                registrationService = component "登記服務" "接收買家登記想抽選的玩具，套用活動規則後寫入登記，並提供結果查詢。" "TypeScript Service"
                pickupService = component "取貨服務" "讓抽中的買家選擇取貨門市，並把抽中名單與取貨門市送給門市取貨系統。" "TypeScript Service"
            }
            lotteryJob = container "抽選排程" "活動截止時讀取所有登記，依規則抽選並寫入結果，再請實名制 App 推播通知。" "Node.js / 排程工作"
            preorderDb = container "預購資料庫" "儲存活動設定、買家登記、抽選結果與取貨門市。" "PostgreSQL"
        }
        realnameApp = softwareSystem "代理商實名制 App" "代理商既有的 App，買家在這裡登入並完成實名驗證；預購登記入口與結果推播都借用它。" "外部系統"
        storeSystem = softwareSystem "門市取貨系統" "代理商既有的門市系統，依抽中名單與取貨門市核對並交付商品。" "外部系統"

        buyer -> realnameApp "在 App 內登記預購、查看結果、選擇取貨門市"
        realnameApp -> authGuard "轉交預購請求（帶實名驗證憑證）" "HTTPS"
        authGuard -> registrationService "憑證通過後轉交登記與結果查詢"
        authGuard -> pickupService "憑證通過後轉交取貨門市選擇"
        registrationService -> campaignService "查詢活動期間與每人可抽選總量"
        pickupService -> campaignService "查詢可取貨的門市"
        operator -> adminWeb "設定預購活動與抽選規則"
        adminWeb -> campaignService "讀寫活動設定" "HTTPS"
        campaignService -> preorderDb "讀寫活動設定" "SQL"
        registrationService -> preorderDb "寫入登記並讀取抽選結果" "SQL"
        pickupService -> preorderDb "寫入取貨門市" "SQL"
        pickupService -> storeSystem "傳送抽中名單與取貨門市" "HTTPS"
        lotteryJob -> preorderDb "讀取登記並寫入抽選結果" "SQL"
        lotteryJob -> realnameApp "請 App 推播抽選結果" "HTTPS"
    }

    configuration {
        scope softwaresystem
    }

    views {
        systemContext preorderSystem "SystemContext" {
            include *
            include buyer
            autoLayout lr
        }
        container preorderSystem "Containers" {
            include *
            include buyer
            autoLayout lr
        }
        component preorderApi "Components" {
            include *
            autoLayout lr
        }
        styles {
            element "外部系統" {
                background #999999
                color #ffffff
            }
        }
        theme https://raw.githubusercontent.com/structurizr/themes/master/default/theme.json
    }
}
```

</details>

---

## Step 4：一場預購活動的順序

> 前三張圖都是「同時發生」的視圖，沒辦法表達「先…再…最後」。這張**動態圖**畫的是一場活動從頭到尾的旅程：營運人員設定、買家登記、截止時抽選、通知結果、抽中的買家選門市。它橫切所有層次，**完全不改 model**。

### Prompt

```text
讀 structurizr/workspace.dsl，加一張動態圖 "PreorderFlow"：一場預購活動從頭到尾依序發生什麼事 —— 營運人員設定活動、買家在期間內登記、截止時抽選、推播結果、抽中的買家選擇取貨門市，一直到門市取貨系統收到名單。
只能用檔案裡已經存在的元素，model 完全不要動；箭頭從 1 開始，依時間順序連續編號。
```

### 驗證

- [ ] **箭頭編號連續（參考解答是 1 到 9），先後順序合理**：設定活動 → 登記 → 截止抽選 → 推播 → 選門市 → 傳給門市。
- [ ] **Model 完全沒變。** `git diff` 只看得到新增一張 view，沒有新增任何元素或連線。

> **ADR 候選 4：抽選結果用實名制 App 推播通知**，而不是另外串簡訊。 —— 在筆記上記一行就好，先不要討論。

<details>
<summary>參考解答：這一步改了什麼（diff）</summary>

```diff
@@ -55,2 +55,14 @@
         }
+        dynamic preorderSystem "PreorderFlow" "一場預購活動從設定、登記、抽選到取貨門市的完整流程。" {
+            operator -> adminWeb "1. 設定活動期間與每人可抽選總量"
+            buyer -> realnameApp "2. 活動期間內登記想抽選的玩具"
+            realnameApp -> preorderApi "3. 轉交登記（帶實名驗證憑證）" "HTTPS"
+            preorderApi -> preorderDb "4. 檢查期間與總量上限，寫入登記" "SQL"
+            lotteryJob -> preorderDb "5. 截止時讀取登記、抽選並寫入結果" "SQL"
+            lotteryJob -> realnameApp "6. 請 App 推播抽選結果" "HTTPS"
+            buyer -> realnameApp "7. 抽中的買家選擇取貨門市"
+            realnameApp -> preorderApi "8. 轉交門市選擇（帶實名驗證憑證）" "HTTPS"
+            preorderApi -> storeSystem "9. 傳送抽中名單與取貨門市" "HTTPS"
+            autoLayout lr
+        }
         styles {
```

</details>

<details>
<summary>參考解答：Step 4 之後的完整 <code>workspace.dsl</code></summary>

```structurizr
workspace "玩具預購抽選服務" "C4 工作坊" {

    model {
        buyer = person "買家" "想預購熱門玩具的消費者，透過代理商實名制 App 登記預購。"
        operator = person "營運人員" "代理商的營運人員，設定預購活動的期間與每人可抽選的總量。"

        preorderSystem = softwareSystem "預購抽選系統" "讓買家登記想抽選的玩具，在截止時抽選出結果，並讓抽中的買家選擇取貨門市。" {
            adminWeb = container "管理後台" "讓營運人員設定預購活動的期間、每人可抽選的總量、可登記的玩具與可取貨的門市。" "React / Web 瀏覽器"
            preorderApi = container "預購 API" "接收實名制 App 轉交的登記與取貨門市選擇，也提供管理後台讀寫活動設定。" "Node.js / Express REST API" {
                authGuard = component "憑證驗證中介層" "驗證實名制 App 簽發的實名驗證憑證（簽章與有效期限），不通過就拒絕買家請求。" "TypeScript Middleware"
                campaignService = component "活動規則服務" "管理預購活動，並檢查活動期間與每人可抽選的總量。" "TypeScript Service"
                registrationService = component "登記服務" "接收買家登記想抽選的玩具，套用活動規則後寫入登記，並提供結果查詢。" "TypeScript Service"
                pickupService = component "取貨服務" "讓抽中的買家選擇取貨門市，並把抽中名單與取貨門市送給門市取貨系統。" "TypeScript Service"
            }
            lotteryJob = container "抽選排程" "活動截止時讀取所有登記，依規則抽選並寫入結果，再請實名制 App 推播通知。" "Node.js / 排程工作"
            preorderDb = container "預購資料庫" "儲存活動設定、買家登記、抽選結果與取貨門市。" "PostgreSQL"
        }
        realnameApp = softwareSystem "代理商實名制 App" "代理商既有的 App，買家在這裡登入並完成實名驗證；預購登記入口與結果推播都借用它。" "外部系統"
        storeSystem = softwareSystem "門市取貨系統" "代理商既有的門市系統，依抽中名單與取貨門市核對並交付商品。" "外部系統"

        buyer -> realnameApp "在 App 內登記預購、查看結果、選擇取貨門市"
        realnameApp -> authGuard "轉交預購請求（帶實名驗證憑證）" "HTTPS"
        authGuard -> registrationService "憑證通過後轉交登記與結果查詢"
        authGuard -> pickupService "憑證通過後轉交取貨門市選擇"
        registrationService -> campaignService "查詢活動期間與每人可抽選總量"
        pickupService -> campaignService "查詢可取貨的門市"
        operator -> adminWeb "設定預購活動與抽選規則"
        adminWeb -> campaignService "讀寫活動設定" "HTTPS"
        campaignService -> preorderDb "讀寫活動設定" "SQL"
        registrationService -> preorderDb "寫入登記並讀取抽選結果" "SQL"
        pickupService -> preorderDb "寫入取貨門市" "SQL"
        pickupService -> storeSystem "傳送抽中名單與取貨門市" "HTTPS"
        lotteryJob -> preorderDb "讀取登記並寫入抽選結果" "SQL"
        lotteryJob -> realnameApp "請 App 推播抽選結果" "HTTPS"
    }

    configuration {
        scope softwaresystem
    }

    views {
        systemContext preorderSystem "SystemContext" {
            include *
            include buyer
            autoLayout lr
        }
        container preorderSystem "Containers" {
            include *
            include buyer
            autoLayout lr
        }
        component preorderApi "Components" {
            include *
            autoLayout lr
        }
        dynamic preorderSystem "PreorderFlow" "一場預購活動從設定、登記、抽選到取貨門市的完整流程。" {
            operator -> adminWeb "1. 設定活動期間與每人可抽選總量"
            buyer -> realnameApp "2. 活動期間內登記想抽選的玩具"
            realnameApp -> preorderApi "3. 轉交登記（帶實名驗證憑證）" "HTTPS"
            preorderApi -> preorderDb "4. 檢查期間與總量上限，寫入登記" "SQL"
            lotteryJob -> preorderDb "5. 截止時讀取登記、抽選並寫入結果" "SQL"
            lotteryJob -> realnameApp "6. 請 App 推播抽選結果" "HTTPS"
            buyer -> realnameApp "7. 抽中的買家選擇取貨門市"
            realnameApp -> preorderApi "8. 轉交門市選擇（帶實名驗證憑證）" "HTTPS"
            preorderApi -> storeSystem "9. 傳送抽中名單與取貨門市" "HTTPS"
            autoLayout lr
        }
        styles {
            element "外部系統" {
                background #999999
                color #ffffff
            }
        }
        theme https://raw.githubusercontent.com/structurizr/themes/master/default/theme.json
    }
}
```

</details>

---

## Step 5：每個東西跑在哪裡

> 值班工程師問：「活動截止那一刻，抽選工作到底跑在哪裡？跟實名制 App 之間隔了什麼？」把每個 container 放到真實的基礎設施上，距離就會自己顯現：營運人員在辦公室，代理商的既有系統在另一間機房，我們的程式在雲端。

### Prompt

```text
讀 structurizr/workspace.dsl，加一張部署圖 "Deployment"（環境名稱「正式環境」），說明每個東西實際跑在哪裡：

  雲端區域（【你熟悉的雲端供應商與區域，例如 AWS ap-northeast-1，或 Azure、GCP 的對應區域】）：託管的容器服務跑預購 API；排程服務觸發容器任務跑抽選排程；託管的資料庫跑預購資料庫（單一可用區，節省成本）。請用該雲端的實際服務名稱（AWS 例：ECS Fargate、EventBridge、RDS）。
  代理商辦公室：營運人員電腦，用瀏覽器跑管理後台
  代理商既有系統環境：實名制 App 服務跑代理商實名制 App、門市取貨系統主機跑門市取貨系統

三個地點都要出現在同一張圖裡，每個地點和機器都要有一句說明。
container 之間的流量會從 model 自動出現，不用重複畫，也不需要補任何機器之間的連線。
再掛上該雲端的 Structurizr 預建主題，一律用網址引用，並和預設主題並用：
  AWS：https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/amazon-web-services-2025.07/theme.json
  Azure：https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/microsoft-azure-2025.11/theme.json
  GCP：https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/google-cloud-platform-2025.09/theme.json
並替雲端節點加上主題提供的圖示標籤（標籤名稱可在 https://playground.structurizr.com/themes 查到）。原本的預設主題要繼續保留。
其他圖和 model 不要動。
```

### 驗證

- [ ] **3 個地點、每個 container 都有一個執行中的實例**；管理後台跑在辦公室的營運人員電腦上，兩個外部系統在代理商既有系統環境，**只有預購 API、抽選排程、資料庫在雲端**；雲端節點有顯示你選的雲端的圖示。
- [ ] **跨越地點的線看得出來**：實名制 App → 預購 API、抽選排程 → 實名制 App、預購 API → 門市取貨系統，都是從一個地點跨到另一個地點，這就是這張圖存在的理由。
- [ ] 導覽列有 5 張圖，前四張沒變。

> **這張圖很可能會擠成一團，這是預期中的**（參考解答有 15 個方塊、6 條線，而且是「地點 → 機器 → 實例」三層巢狀）。原因和處理方式見下一步。
>
> 參考解答用 AWS；換成 Azure 或 GCP 時，節點名稱與圖示標籤會不同，結構完全一樣。主題網址與標籤怎麼查，見事前準備的「主題」。如果雲端節點沒有顯示圖示，先確認主題網址正確，而且檢視器連得到 GitHub（見事前準備）。
>
> **延伸閱讀：** [主題瀏覽器](https://playground.structurizr.com/themes)（查每個主題的圖示與標籤名稱）、[Themes 說明](https://docs.structurizr.com/ui/diagrams/themes)。
>
> **ADR 候選 5：用託管資料庫與單一可用區，排程用 EventBridge 觸發 Fargate 任務**，換取低成本。 —— 在筆記上記一行就好，先不要討論。

<details>
<summary>參考解答：這一步改了什麼（diff）</summary>

```diff
@@ -34,2 +34,33 @@
         lotteryJob -> realnameApp "請 App 推播抽選結果" "HTTPS"
+
+        production = deploymentEnvironment "正式環境" {
+            cloud = deploymentNode "雲端區域" "我們自建的雲端服務。" "AWS ap-northeast-1" {
+                tags "Amazon Web Services - Region"
+                ecs = deploymentNode "ECS Fargate" "以容器執行預購 API，不用自己管理伺服器。" "AWS Fargate" {
+                    tags "Amazon Web Services - Fargate"
+                    apiInstance = containerInstance preorderApi
+                }
+                scheduler = deploymentNode "EventBridge 排程任務" "在活動截止時間觸發抽選工作。" "AWS EventBridge + Fargate 任務" {
+                    tags "Amazon Web Services - EventBridge"
+                    jobInstance = containerInstance lotteryJob
+                }
+                rds = deploymentNode "RDS for PostgreSQL" "託管的關聯式資料庫，單一可用區以節省成本。" "PostgreSQL 16" {
+                    tags "Amazon Web Services - RDS"
+                    dbInstance = containerInstance preorderDb
+                }
+            }
+            office = deploymentNode "代理商辦公室" "營運人員工作的地方。" "辦公室網路" {
+                browser = deploymentNode "營運人員電腦" "以瀏覽器開啟管理後台。" "Web 瀏覽器" {
+                    adminInstance = containerInstance adminWeb
+                }
+            }
+            agentEnv = deploymentNode "代理商既有系統環境" "代理商自己維運的既有系統，我們只呼叫它們。" "代理商機房" {
+                appHost = deploymentNode "實名制 App 服務" "代理商既有的實名制 App 後端。" "既有系統" {
+                    realnameInstance = softwareSystemInstance realnameApp
+                }
+                storeHost = deploymentNode "門市取貨系統主機" "代理商既有的門市系統。" "既有系統" {
+                    storeInstance = softwareSystemInstance storeSystem
+                }
+            }
+        }
     }
@@ -67,2 +98,6 @@
         }
+        deployment * "正式環境" "Deployment" "每一項服務在正式環境中的實際位置。" {
+            include *
+            autoLayout lr
+        }
         styles {
@@ -73,3 +108,3 @@
         }
-        theme https://raw.githubusercontent.com/structurizr/themes/master/default/theme.json
+        themes https://raw.githubusercontent.com/structurizr/themes/master/default/theme.json https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/amazon-web-services-2025.07/theme.json
     }
```

</details>

<details>
<summary>參考解答：Step 5 之後的完整 <code>workspace.dsl</code></summary>

```structurizr
workspace "玩具預購抽選服務" "C4 工作坊" {

    model {
        buyer = person "買家" "想預購熱門玩具的消費者，透過代理商實名制 App 登記預購。"
        operator = person "營運人員" "代理商的營運人員，設定預購活動的期間與每人可抽選的總量。"

        preorderSystem = softwareSystem "預購抽選系統" "讓買家登記想抽選的玩具，在截止時抽選出結果，並讓抽中的買家選擇取貨門市。" {
            adminWeb = container "管理後台" "讓營運人員設定預購活動的期間、每人可抽選的總量、可登記的玩具與可取貨的門市。" "React / Web 瀏覽器"
            preorderApi = container "預購 API" "接收實名制 App 轉交的登記與取貨門市選擇，也提供管理後台讀寫活動設定。" "Node.js / Express REST API" {
                authGuard = component "憑證驗證中介層" "驗證實名制 App 簽發的實名驗證憑證（簽章與有效期限），不通過就拒絕買家請求。" "TypeScript Middleware"
                campaignService = component "活動規則服務" "管理預購活動，並檢查活動期間與每人可抽選的總量。" "TypeScript Service"
                registrationService = component "登記服務" "接收買家登記想抽選的玩具，套用活動規則後寫入登記，並提供結果查詢。" "TypeScript Service"
                pickupService = component "取貨服務" "讓抽中的買家選擇取貨門市，並把抽中名單與取貨門市送給門市取貨系統。" "TypeScript Service"
            }
            lotteryJob = container "抽選排程" "活動截止時讀取所有登記，依規則抽選並寫入結果，再請實名制 App 推播通知。" "Node.js / 排程工作"
            preorderDb = container "預購資料庫" "儲存活動設定、買家登記、抽選結果與取貨門市。" "PostgreSQL"
        }
        realnameApp = softwareSystem "代理商實名制 App" "代理商既有的 App，買家在這裡登入並完成實名驗證；預購登記入口與結果推播都借用它。" "外部系統"
        storeSystem = softwareSystem "門市取貨系統" "代理商既有的門市系統，依抽中名單與取貨門市核對並交付商品。" "外部系統"

        buyer -> realnameApp "在 App 內登記預購、查看結果、選擇取貨門市"
        realnameApp -> authGuard "轉交預購請求（帶實名驗證憑證）" "HTTPS"
        authGuard -> registrationService "憑證通過後轉交登記與結果查詢"
        authGuard -> pickupService "憑證通過後轉交取貨門市選擇"
        registrationService -> campaignService "查詢活動期間與每人可抽選總量"
        pickupService -> campaignService "查詢可取貨的門市"
        operator -> adminWeb "設定預購活動與抽選規則"
        adminWeb -> campaignService "讀寫活動設定" "HTTPS"
        campaignService -> preorderDb "讀寫活動設定" "SQL"
        registrationService -> preorderDb "寫入登記並讀取抽選結果" "SQL"
        pickupService -> preorderDb "寫入取貨門市" "SQL"
        pickupService -> storeSystem "傳送抽中名單與取貨門市" "HTTPS"
        lotteryJob -> preorderDb "讀取登記並寫入抽選結果" "SQL"
        lotteryJob -> realnameApp "請 App 推播抽選結果" "HTTPS"

        production = deploymentEnvironment "正式環境" {
            cloud = deploymentNode "雲端區域" "我們自建的雲端服務。" "AWS ap-northeast-1" {
                tags "Amazon Web Services - Region"
                ecs = deploymentNode "ECS Fargate" "以容器執行預購 API，不用自己管理伺服器。" "AWS Fargate" {
                    tags "Amazon Web Services - Fargate"
                    apiInstance = containerInstance preorderApi
                }
                scheduler = deploymentNode "EventBridge 排程任務" "在活動截止時間觸發抽選工作。" "AWS EventBridge + Fargate 任務" {
                    tags "Amazon Web Services - EventBridge"
                    jobInstance = containerInstance lotteryJob
                }
                rds = deploymentNode "RDS for PostgreSQL" "託管的關聯式資料庫，單一可用區以節省成本。" "PostgreSQL 16" {
                    tags "Amazon Web Services - RDS"
                    dbInstance = containerInstance preorderDb
                }
            }
            office = deploymentNode "代理商辦公室" "營運人員工作的地方。" "辦公室網路" {
                browser = deploymentNode "營運人員電腦" "以瀏覽器開啟管理後台。" "Web 瀏覽器" {
                    adminInstance = containerInstance adminWeb
                }
            }
            agentEnv = deploymentNode "代理商既有系統環境" "代理商自己維運的既有系統，我們只呼叫它們。" "代理商機房" {
                appHost = deploymentNode "實名制 App 服務" "代理商既有的實名制 App 後端。" "既有系統" {
                    realnameInstance = softwareSystemInstance realnameApp
                }
                storeHost = deploymentNode "門市取貨系統主機" "代理商既有的門市系統。" "既有系統" {
                    storeInstance = softwareSystemInstance storeSystem
                }
            }
        }
    }

    configuration {
        scope softwaresystem
    }

    views {
        systemContext preorderSystem "SystemContext" {
            include *
            include buyer
            autoLayout lr
        }
        container preorderSystem "Containers" {
            include *
            include buyer
            autoLayout lr
        }
        component preorderApi "Components" {
            include *
            autoLayout lr
        }
        dynamic preorderSystem "PreorderFlow" "一場預購活動從設定、登記、抽選到取貨門市的完整流程。" {
            operator -> adminWeb "1. 設定活動期間與每人可抽選總量"
            buyer -> realnameApp "2. 活動期間內登記想抽選的玩具"
            realnameApp -> preorderApi "3. 轉交登記（帶實名驗證憑證）" "HTTPS"
            preorderApi -> preorderDb "4. 檢查期間與總量上限，寫入登記" "SQL"
            lotteryJob -> preorderDb "5. 截止時讀取登記、抽選並寫入結果" "SQL"
            lotteryJob -> realnameApp "6. 請 App 推播抽選結果" "HTTPS"
            buyer -> realnameApp "7. 抽中的買家選擇取貨門市"
            realnameApp -> preorderApi "8. 轉交門市選擇（帶實名驗證憑證）" "HTTPS"
            preorderApi -> storeSystem "9. 傳送抽中名單與取貨門市" "HTTPS"
            autoLayout lr
        }
        deployment * "正式環境" "Deployment" "每一項服務在正式環境中的實際位置。" {
            include *
            autoLayout lr
        }
        styles {
            element "外部系統" {
                background #999999
                color #ffffff
            }
        }
        themes https://raw.githubusercontent.com/structurizr/themes/master/default/theme.json https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/amazon-web-services-2025.07/theme.json
    }
}
```

</details>

---

## Step 6：拿掉 autoLayout，自己排

> 簡報前，你發現 Deployment 圖擠成一團、線互相壓過。Structurizr 的自動排版在巢狀越深、跨框的線越多時越容易亂。這時候**不要再叫 agent 調整**，直接拿掉 `autoLayout`，自己拖。

**為什麼 Deployment 特別擠？** `autoLayout` 是把所有方塊先當成一張平面圖排好，再替每個巢狀的外框（地點、機器）畫上去；Deployment 圖的外框最多、最深，所以最容易互相壓到。（這是依 Structurizr 的排版方式做的判斷，請在現場拿掉 `autoLayout` 前後各看一次，確認它是不是原因。）

### 做法

**1. 請 agent 拿掉那一行（只這一張圖）：**

```text
把 structurizr/workspace.dsl 裡 "Deployment" 這張圖的 autoLayout 拿掉。其他圖維持原樣，其他都不要動。
```

**2. 重新整理 <http://localhost:8080>，打開 Deployment。** 沒有排版資訊時，方塊可能全部疊在一起，這是正常的，從這裡開始自己拖。

**3. 用滑鼠拖曳。** 建議：先拉開三個地點（代理商辦公室在左、雲端在中、代理商既有系統環境在右），再調整機器與實例，讓線不交錯。

**4. 位置會自動存進 `structurizr/workspace.json`**（DSL 描述「有什麼」，`workspace.json` 記錄「擺在哪」）。用 `git status` 確認它有變，然後 commit，這樣位置才會跟著版本走。之後要輸出靜態網站時，請用 **`make export-saved`** 取代 `make export`，位置才會被保留。

### 驗證

- [ ] `git diff structurizr/workspace.dsl` **只少了 Deployment 區塊裡的一行 `autoLayout lr`**；其他四張圖仍然是自動排版。
- [ ] `git status` 出現 **`structurizr/workspace.json` 有變更**。
- [ ] 重新整理瀏覽器，**位置還在**。

> **位置是怎麼被保留的？** x、y 位置不會寫在 DSL，而是存在 `workspace.json`；重新載入 DSL 時，Structurizr 會用**元素名稱**與 **view key** 把舊位置對回去。所以排好版之後，**不要隨便改元素名稱或 view key**（這也是 `AGENTS.md` 規定不改名的原因之一），否則那些位置會遺失。
>
> 之後想回到自動排版，把 `autoLayout lr` 加回去即可（手動位置會被覆蓋）。
>
> **延伸閱讀：** [Diagram editor](https://docs.structurizr.com/ui/diagrams/editor)（編輯器還能做什麼）、[Manual layout](https://docs.structurizr.com/ui/diagrams/manual-layout)（位置怎麼保存、為什麼有時會遺失）。

<details>
<summary>參考解答：這一步改了什麼（diff）</summary>

```diff
@@ -100,3 +100,2 @@
             include *
-            autoLayout lr
         }
```

</details>

<details>
<summary>參考解答：Step 6 之後的完整 <code>workspace.dsl</code></summary>

```structurizr
workspace "玩具預購抽選服務" "C4 工作坊" {

    model {
        buyer = person "買家" "想預購熱門玩具的消費者，透過代理商實名制 App 登記預購。"
        operator = person "營運人員" "代理商的營運人員，設定預購活動的期間與每人可抽選的總量。"

        preorderSystem = softwareSystem "預購抽選系統" "讓買家登記想抽選的玩具，在截止時抽選出結果，並讓抽中的買家選擇取貨門市。" {
            adminWeb = container "管理後台" "讓營運人員設定預購活動的期間、每人可抽選的總量、可登記的玩具與可取貨的門市。" "React / Web 瀏覽器"
            preorderApi = container "預購 API" "接收實名制 App 轉交的登記與取貨門市選擇，也提供管理後台讀寫活動設定。" "Node.js / Express REST API" {
                authGuard = component "憑證驗證中介層" "驗證實名制 App 簽發的實名驗證憑證（簽章與有效期限），不通過就拒絕買家請求。" "TypeScript Middleware"
                campaignService = component "活動規則服務" "管理預購活動，並檢查活動期間與每人可抽選的總量。" "TypeScript Service"
                registrationService = component "登記服務" "接收買家登記想抽選的玩具，套用活動規則後寫入登記，並提供結果查詢。" "TypeScript Service"
                pickupService = component "取貨服務" "讓抽中的買家選擇取貨門市，並把抽中名單與取貨門市送給門市取貨系統。" "TypeScript Service"
            }
            lotteryJob = container "抽選排程" "活動截止時讀取所有登記，依規則抽選並寫入結果，再請實名制 App 推播通知。" "Node.js / 排程工作"
            preorderDb = container "預購資料庫" "儲存活動設定、買家登記、抽選結果與取貨門市。" "PostgreSQL"
        }
        realnameApp = softwareSystem "代理商實名制 App" "代理商既有的 App，買家在這裡登入並完成實名驗證；預購登記入口與結果推播都借用它。" "外部系統"
        storeSystem = softwareSystem "門市取貨系統" "代理商既有的門市系統，依抽中名單與取貨門市核對並交付商品。" "外部系統"

        buyer -> realnameApp "在 App 內登記預購、查看結果、選擇取貨門市"
        realnameApp -> authGuard "轉交預購請求（帶實名驗證憑證）" "HTTPS"
        authGuard -> registrationService "憑證通過後轉交登記與結果查詢"
        authGuard -> pickupService "憑證通過後轉交取貨門市選擇"
        registrationService -> campaignService "查詢活動期間與每人可抽選總量"
        pickupService -> campaignService "查詢可取貨的門市"
        operator -> adminWeb "設定預購活動與抽選規則"
        adminWeb -> campaignService "讀寫活動設定" "HTTPS"
        campaignService -> preorderDb "讀寫活動設定" "SQL"
        registrationService -> preorderDb "寫入登記並讀取抽選結果" "SQL"
        pickupService -> preorderDb "寫入取貨門市" "SQL"
        pickupService -> storeSystem "傳送抽中名單與取貨門市" "HTTPS"
        lotteryJob -> preorderDb "讀取登記並寫入抽選結果" "SQL"
        lotteryJob -> realnameApp "請 App 推播抽選結果" "HTTPS"

        production = deploymentEnvironment "正式環境" {
            cloud = deploymentNode "雲端區域" "我們自建的雲端服務。" "AWS ap-northeast-1" {
                tags "Amazon Web Services - Region"
                ecs = deploymentNode "ECS Fargate" "以容器執行預購 API，不用自己管理伺服器。" "AWS Fargate" {
                    tags "Amazon Web Services - Fargate"
                    apiInstance = containerInstance preorderApi
                }
                scheduler = deploymentNode "EventBridge 排程任務" "在活動截止時間觸發抽選工作。" "AWS EventBridge + Fargate 任務" {
                    tags "Amazon Web Services - EventBridge"
                    jobInstance = containerInstance lotteryJob
                }
                rds = deploymentNode "RDS for PostgreSQL" "託管的關聯式資料庫，單一可用區以節省成本。" "PostgreSQL 16" {
                    tags "Amazon Web Services - RDS"
                    dbInstance = containerInstance preorderDb
                }
            }
            office = deploymentNode "代理商辦公室" "營運人員工作的地方。" "辦公室網路" {
                browser = deploymentNode "營運人員電腦" "以瀏覽器開啟管理後台。" "Web 瀏覽器" {
                    adminInstance = containerInstance adminWeb
                }
            }
            agentEnv = deploymentNode "代理商既有系統環境" "代理商自己維運的既有系統，我們只呼叫它們。" "代理商機房" {
                appHost = deploymentNode "實名制 App 服務" "代理商既有的實名制 App 後端。" "既有系統" {
                    realnameInstance = softwareSystemInstance realnameApp
                }
                storeHost = deploymentNode "門市取貨系統主機" "代理商既有的門市系統。" "既有系統" {
                    storeInstance = softwareSystemInstance storeSystem
                }
            }
        }
    }

    configuration {
        scope softwaresystem
    }

    views {
        systemContext preorderSystem "SystemContext" {
            include *
            include buyer
            autoLayout lr
        }
        container preorderSystem "Containers" {
            include *
            include buyer
            autoLayout lr
        }
        component preorderApi "Components" {
            include *
            autoLayout lr
        }
        dynamic preorderSystem "PreorderFlow" "一場預購活動從設定、登記、抽選到取貨門市的完整流程。" {
            operator -> adminWeb "1. 設定活動期間與每人可抽選總量"
            buyer -> realnameApp "2. 活動期間內登記想抽選的玩具"
            realnameApp -> preorderApi "3. 轉交登記（帶實名驗證憑證）" "HTTPS"
            preorderApi -> preorderDb "4. 檢查期間與總量上限，寫入登記" "SQL"
            lotteryJob -> preorderDb "5. 截止時讀取登記、抽選並寫入結果" "SQL"
            lotteryJob -> realnameApp "6. 請 App 推播抽選結果" "HTTPS"
            buyer -> realnameApp "7. 抽中的買家選擇取貨門市"
            realnameApp -> preorderApi "8. 轉交門市選擇（帶實名驗證憑證）" "HTTPS"
            preorderApi -> storeSystem "9. 傳送抽中名單與取貨門市" "HTTPS"
            autoLayout lr
        }
        deployment * "正式環境" "Deployment" "每一項服務在正式環境中的實際位置。" {
            include *
        }
        styles {
            element "外部系統" {
                background #999999
                color #ffffff
            }
        }
        themes https://raw.githubusercontent.com/structurizr/themes/master/default/theme.json https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/amazon-web-services-2025.07/theme.json
    }
}
```

</details>

---

## ADR：把「為什麼」寫下來

> **故事。** 三個月後的某個週一，新來的工程師盯著 Containers 圖問：「為什麼我們沒有自己的買家端 App？登記畫面老是卡在實名制 App 的發版週期，自己做一個不是更快嗎？」當初討論的人有一半已經調走，Slack 紀錄也早就找不到了。
>
> 圖告訴他「登記入口是實名制 App」，卻沒告訴他**為什麼這樣決定、當時還考慮過什麼**。這就是 ADR 的工作：每個重要決策一份短短的文件，跟著程式碼放在 git 裡。

### 什麼值得寫成 ADR

同時符合這三點才寫：**難以回頭**、**有真實的替代方案**、**半年後會有人問為什麼**。「用哪個 JSON 函式庫」不需要；「買家端入口放哪裡」需要。

一份 ADR 除了標題與日期，只有四個部分：

| 部分 | 寫什麼 |
| --- | --- |
| Status | 這個決策現在的狀態（例如 Accepted） |
| Context | 當時的限制與壓力，不是「我們想用 X」 |
| Decision | 我們決定怎麼做，以及**沒選什麼** |
| Consequences | 好處**和代價**，至少一個代價 |

### Prompt

回頭看你在每一步記下的 ADR 候選，挑一個你有話想說的，填進【】：

```text
在 structurizr/adrs/ 底下，用 adr-tools 的 Markdown 格式（標題、Date、Status、Context、Decision、Consequences）幫我寫一份架構決策記錄，編號 0001。

決策：【你選的 ADR 候選，例如：預購登記入口借用實名制 App，不另做買家端 App】
當時的限制：【例如：代理商要最小成本、買家已經在用實名制 App】
我們考慮過、但沒選的：【至少一個替代方案，以及沒選的理由】

Consequences 要同時寫出好處和代價，至少一個代價。用簡短的句子，不要長篇大論。
然後把這個資料夾掛到「預購抽選系統」上，讓檢視器看得到這份決策。
```

agent 起草的只是初稿：**Context 和代價要換成你們團隊真正的情況**，因為只有你們知道當時的限制。

### 驗證

- [ ] **Consequences 至少有一個代價。** 只有好處的 ADR 是廣告，不是記錄。
- [ ] **寫了至少一個沒選的替代方案，以及沒選的理由。** 沒有替代方案，就不是決策。
- [ ] **你能指著圖上某個方塊說「這個決策在這裡」**；`validate` 仍是 `OK`，`make up` 重新整理後，檢視器裡看得到這份決策。

> 檔名請用英文小寫與連字號（例如 `0001-reuse-existing-realname-app.md`），標題可以是中文。中文檔名在某些環境（特別是非 UTF-8 的 Java 環境）會讀取失敗。

<details>
<summary>參考解答：ADR 0001（<code>structurizr/adrs/0001-reuse-existing-realname-app.md</code>）</summary>

```markdown
# 1. 預購登記入口借用代理商既有的實名制 App

Date: 2026-10-07

## Status

Accepted

## Context

代理商希望用最小的成本上線預購抽選。買家本來就在使用代理商的實名制 App，登入、實名驗證與推播通知都已經在那裡。
如果自己再做一個買家端 App，要重做登入與實名驗證、處理上架審核，買家也得多裝一個 App。

## Decision

預購登記、結果查詢與取貨門市選擇，都放在代理商既有的實名制 App 內；我們只提供 API，不做買家端 App。
實名制 App 轉交請求時帶上它簽發的實名驗證憑證，我們只驗證憑證，不重做實名驗證。

我們考慮過、但沒有選擇：
- 自己開發買家端 App：畫面最有彈性，但成本高、要重做實名驗證，而且買家要多裝一個 App。

## Consequences

- 好處：不用做買家端 App 與實名驗證，開發成本與上線時間大幅降低；買家不必多裝 App。
- 代價：登記畫面與上線時程受限於實名制 App 的發版週期，需要和代理商的 App 團隊協調。
- 代價：我們依賴實名制 App 的可用性與憑證格式，格式變動時要一起調整。
- 之後：如果活動規則變得複雜、需要更彈性的畫面，重新評估自建買家端 App。
```

</details>

<details>
<summary>參考解答：workspace.dsl 改了什麼（diff）</summary>

```diff
@@ -7,2 +7,3 @@
         preorderSystem = softwareSystem "預購抽選系統" "讓買家登記想抽選的玩具，在截止時抽選出結果，並讓抽中的買家選擇取貨門市。" {
+            !adrs adrs
             adminWeb = container "管理後台" "讓營運人員設定預購活動的期間、每人可抽選的總量、可登記的玩具與可取貨的門市。" "React / Web 瀏覽器"
```

</details>

---

## 收尾

```bash
make validate        # 最後檢查
make export          # 輸出到 structurizr/static-site/index.html
make export-saved   # 同上，但改用 structurizr/workspace.json，保留 Step 6 手動排版的位置
```

打開靜態網站，依序點過五張圖。它們彼此一致，因為是**同一個 model** 的五種畫法 —— 這種一致性才是 C4 真正的回報。

<details>
<summary>參考解答：最終完整 <code>workspace.dsl</code>（含 ADR）</summary>

```structurizr
workspace "玩具預購抽選服務" "C4 工作坊" {

    model {
        buyer = person "買家" "想預購熱門玩具的消費者，透過代理商實名制 App 登記預購。"
        operator = person "營運人員" "代理商的營運人員，設定預購活動的期間與每人可抽選的總量。"

        preorderSystem = softwareSystem "預購抽選系統" "讓買家登記想抽選的玩具，在截止時抽選出結果，並讓抽中的買家選擇取貨門市。" {
            !adrs adrs
            adminWeb = container "管理後台" "讓營運人員設定預購活動的期間、每人可抽選的總量、可登記的玩具與可取貨的門市。" "React / Web 瀏覽器"
            preorderApi = container "預購 API" "接收實名制 App 轉交的登記與取貨門市選擇，也提供管理後台讀寫活動設定。" "Node.js / Express REST API" {
                authGuard = component "憑證驗證中介層" "驗證實名制 App 簽發的實名驗證憑證（簽章與有效期限），不通過就拒絕買家請求。" "TypeScript Middleware"
                campaignService = component "活動規則服務" "管理預購活動，並檢查活動期間與每人可抽選的總量。" "TypeScript Service"
                registrationService = component "登記服務" "接收買家登記想抽選的玩具，套用活動規則後寫入登記，並提供結果查詢。" "TypeScript Service"
                pickupService = component "取貨服務" "讓抽中的買家選擇取貨門市，並把抽中名單與取貨門市送給門市取貨系統。" "TypeScript Service"
            }
            lotteryJob = container "抽選排程" "活動截止時讀取所有登記，依規則抽選並寫入結果，再請實名制 App 推播通知。" "Node.js / 排程工作"
            preorderDb = container "預購資料庫" "儲存活動設定、買家登記、抽選結果與取貨門市。" "PostgreSQL"
        }
        realnameApp = softwareSystem "代理商實名制 App" "代理商既有的 App，買家在這裡登入並完成實名驗證；預購登記入口與結果推播都借用它。" "外部系統"
        storeSystem = softwareSystem "門市取貨系統" "代理商既有的門市系統，依抽中名單與取貨門市核對並交付商品。" "外部系統"

        buyer -> realnameApp "在 App 內登記預購、查看結果、選擇取貨門市"
        realnameApp -> authGuard "轉交預購請求（帶實名驗證憑證）" "HTTPS"
        authGuard -> registrationService "憑證通過後轉交登記與結果查詢"
        authGuard -> pickupService "憑證通過後轉交取貨門市選擇"
        registrationService -> campaignService "查詢活動期間與每人可抽選總量"
        pickupService -> campaignService "查詢可取貨的門市"
        operator -> adminWeb "設定預購活動與抽選規則"
        adminWeb -> campaignService "讀寫活動設定" "HTTPS"
        campaignService -> preorderDb "讀寫活動設定" "SQL"
        registrationService -> preorderDb "寫入登記並讀取抽選結果" "SQL"
        pickupService -> preorderDb "寫入取貨門市" "SQL"
        pickupService -> storeSystem "傳送抽中名單與取貨門市" "HTTPS"
        lotteryJob -> preorderDb "讀取登記並寫入抽選結果" "SQL"
        lotteryJob -> realnameApp "請 App 推播抽選結果" "HTTPS"

        production = deploymentEnvironment "正式環境" {
            cloud = deploymentNode "雲端區域" "我們自建的雲端服務。" "AWS ap-northeast-1" {
                tags "Amazon Web Services - Region"
                ecs = deploymentNode "ECS Fargate" "以容器執行預購 API，不用自己管理伺服器。" "AWS Fargate" {
                    tags "Amazon Web Services - Fargate"
                    apiInstance = containerInstance preorderApi
                }
                scheduler = deploymentNode "EventBridge 排程任務" "在活動截止時間觸發抽選工作。" "AWS EventBridge + Fargate 任務" {
                    tags "Amazon Web Services - EventBridge"
                    jobInstance = containerInstance lotteryJob
                }
                rds = deploymentNode "RDS for PostgreSQL" "託管的關聯式資料庫，單一可用區以節省成本。" "PostgreSQL 16" {
                    tags "Amazon Web Services - RDS"
                    dbInstance = containerInstance preorderDb
                }
            }
            office = deploymentNode "代理商辦公室" "營運人員工作的地方。" "辦公室網路" {
                browser = deploymentNode "營運人員電腦" "以瀏覽器開啟管理後台。" "Web 瀏覽器" {
                    adminInstance = containerInstance adminWeb
                }
            }
            agentEnv = deploymentNode "代理商既有系統環境" "代理商自己維運的既有系統，我們只呼叫它們。" "代理商機房" {
                appHost = deploymentNode "實名制 App 服務" "代理商既有的實名制 App 後端。" "既有系統" {
                    realnameInstance = softwareSystemInstance realnameApp
                }
                storeHost = deploymentNode "門市取貨系統主機" "代理商既有的門市系統。" "既有系統" {
                    storeInstance = softwareSystemInstance storeSystem
                }
            }
        }
    }

    configuration {
        scope softwaresystem
    }

    views {
        systemContext preorderSystem "SystemContext" {
            include *
            include buyer
            autoLayout lr
        }
        container preorderSystem "Containers" {
            include *
            include buyer
            autoLayout lr
        }
        component preorderApi "Components" {
            include *
            autoLayout lr
        }
        dynamic preorderSystem "PreorderFlow" "一場預購活動從設定、登記、抽選到取貨門市的完整流程。" {
            operator -> adminWeb "1. 設定活動期間與每人可抽選總量"
            buyer -> realnameApp "2. 活動期間內登記想抽選的玩具"
            realnameApp -> preorderApi "3. 轉交登記（帶實名驗證憑證）" "HTTPS"
            preorderApi -> preorderDb "4. 檢查期間與總量上限，寫入登記" "SQL"
            lotteryJob -> preorderDb "5. 截止時讀取登記、抽選並寫入結果" "SQL"
            lotteryJob -> realnameApp "6. 請 App 推播抽選結果" "HTTPS"
            buyer -> realnameApp "7. 抽中的買家選擇取貨門市"
            realnameApp -> preorderApi "8. 轉交門市選擇（帶實名驗證憑證）" "HTTPS"
            preorderApi -> storeSystem "9. 傳送抽中名單與取貨門市" "HTTPS"
            autoLayout lr
        }
        deployment * "正式環境" "Deployment" "每一項服務在正式環境中的實際位置。" {
            include *
        }
        styles {
            element "外部系統" {
                background #999999
                color #ffffff
            }
        }
        themes https://raw.githubusercontent.com/structurizr/themes/master/default/theme.json https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/amazon-web-services-2025.07/theme.json
    }
}
```

</details>

### 下一步可以試

#### 衍生題目：如果改成「先搶先贏」的即時搶購？

代理商看到抽選的成效，想試試開賣當天即時搶購：**幾萬人同時搶，每人限購兩組，不能超賣**，而且每筆訂單都要有實名驗證通過的紀錄。同一份模型，哪些會變？先想，再畫：

- **System Context：** 人和外部系統有變嗎？（提示：多半沒變，改變的是我們內部。）
- **Containers：** 還需要「抽選排程」嗎？庫存由誰扣？（提示：需要能原子預扣庫存的地方，例如 Redis 計數器；要不要加佇列或限流？）
- **Components：** 「每人可抽選總量」變成「每人限購兩組」，規則該放在哪裡？「先查、再扣庫存」兩步之間會有空隙，怎麼辦？
- **PreorderFlow：** 每個請求都同步呼叫實名制 App 驗證，它撐得住幾萬人同時嗎？哪一張圖看得出這個風險？
- **Deployment：** 單一 Fargate 服務、單一可用區還夠嗎？要不要負載平衡與多副本？
- **ADR：** 如果你寫過「截止時批次抽選」的 ADR，它該標成 Superseded 嗎？新的決策又該怎麼寫？

#### 其他

- 再加一張動態圖，畫「買家登記失敗」（超出活動期間、超過可抽選總量）時發生什麼事。
- 買家沒開 App 怎麼辦？如果加上簡訊通知，會改到哪幾張圖？
- 為其他 ADR 候選各寫一份決策記錄；再加 `!docs` 文件區塊，把品質報告裡的文件類發現清掉。

## 疑難排解

| 你看到的現象 | 原因 | 怎麼解決 |
| --- | --- | --- |
| `Too many tokens, expected: softwareSystem <name> ...` | 巢狀的 `{` 另起了一行 | `{` 要接在元素宣告那一行的結尾 |
| `View keys can only contain the following characters...` | view key 有空格或中文 | 用 `"SystemContext"` 這種英文字串；**標題可以中文，key 不行** |
| `Unexpected tokens (expected: include, exclude, autolayout, ...)` | `autoLayout` 沒有方向 | `autoLayout lr` |
| `The environment "正式環境" does not exist` | `deployment` 圖的第一個字串是 `deploymentEnvironment` 的名稱 | `deployment * "正式環境" "Deployment" "說明"` |
| `A relationship between "ContainerInstance://..." is not permitted` | 把兩個執行中的實例互相連接了 | 改連接包含它們的機器 |
| 方塊渲染出來是空白 | 元素沒有說明（Structurizr 不會警告） | 補一句責任說明 |
| 買家沒有出現在 SystemContext / Containers | 他沒有直接連到我們的系統，`include *` 不會帶進來 | 請 agent 明確加上 `include buyer` |
| `theme ... does not exist`、`is not a file`，或主題沒套用（沒有圖示、顏色不對） | 用了資料夾名稱的簡寫，或網址拼錯；或會場連不到 GitHub | 改成完整的 `raw.githubusercontent.com` 網址（見事前準備的列表），並確認瀏覽器連得到 GitHub |
| `make validate` 印出 `The content from https://static.structurizr.com/...` 且 exit 1 | 用了 `theme default`，而雲端服務已結束 | 改成預設主題的 GitHub 網址 |
| ADR 掛上去卻出現 `Error importing decisions` | ADR 檔名含中文，Java 讀不到 | 檔名改成英文小寫與連字號 |
| 檢視器顯示舊檔案 | 瀏覽器需要重載 | 重新整理 <http://localhost:8080> |
| agent 說驗證過了，卻沒呼叫任何工具 | MCP server 沒接上 | `opencode mcp list`；需要登入就執行 `/mcps` 認證 |

## DSL 速查表（你不用寫，只用來讀）

```structurizr
person               "標題"  "責任說明"
softwareSystem       "標題"  "責任說明"  ["標籤"]
container            "標題"  "責任說明"  "技術"
component            "標題"  "責任說明"  "技術"
deploymentNode       "標題"  "責任說明"  "技術" {
    tags "Amazon Web Services - Fargate"       // 主題提供的圖示標籤
    containerInstance preorderApi
}
!adrs adrs                                    // 把 adrs/ 資料夾裡的決策記錄掛到這個元素

a -> b "動詞片語" "PROTOCOL"      // 協定是最後一個字串，不要寫進動詞片語

systemContext preorderSystem "SystemContext"   // 每張圖一個區塊，全放在同一個 views { }
container     preorderSystem "Containers"
component     preorderApi    "Components"
dynamic       preorderSystem "PreorderFlow"
deployment    *  "正式環境"   "Deployment"
    include *
    autoLayout lr       // 拿掉它，就改由你手動排（Step 6）

theme <預設主題網址>                          // 基本顏色
themes <預設主題網址> <雲端主題網址>         // 再加雲端主題（圖示）
```

## 參考資料

- [C4 Model](https://c4model.com)
- [Structurizr MCP server](https://docs.structurizr.com/ai/mcp)
- [Structurizr DSL 語言參考](https://docs.structurizr.com/dsl/language)
- [Structurizr 主題（Themes）](https://docs.structurizr.com/server/diagrams/themes)、[主題瀏覽器](https://playground.structurizr.com/themes)、[UI 說明：Themes](https://docs.structurizr.com/ui/diagrams/themes)
- [Diagram editor](https://docs.structurizr.com/ui/diagrams/editor)、[Manual layout](https://docs.structurizr.com/ui/diagrams/manual-layout)
- [Implied relationships](https://docs.structurizr.com/dsl/cookbook/implied-relationships/)
- [Structurizr ADR](https://docs.structurizr.com/dsl/adrs)
- [Structurizr CLI](https://docs.structurizr.com/cli)