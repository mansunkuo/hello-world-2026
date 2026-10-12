# OpenCode V2 Setup Guide (Windows WSL / Linux / macOS)
 
This guide gets your **OpenCode V2 + Structurizr + VS Code** environment ready before the workshop. Use it together with the *C4 Architecture Workshop* tutorial. It covers three environments only: **Windows (WSL2)**, **Linux** and **macOS**. Native Windows is out of scope: the OpenCode V2 docs state that Windows package managers are not supported, so on Windows please work inside WSL2.
 
> **Recommended way of working:** use **VS Code** as your main screen, with the **OpenChamber** extension (chat with OpenCode right next to your code) and the **Structurizr** extension (syntax highlighting for `.dsl` files).
 
---
 
## Contents
 
- [What You Need](#what-you-need)
- [Part 1: Prepare the Base Environment for Your Platform](#part-1-prepare-the-base-environment-for-your-platform)
- [Part 2: Install OpenCode V2 and the Tools (Same on All Platforms)](#part-2-install-opencode-v2-and-the-tools-same-on-all-platforms)
- [Final Check](#final-check)
- [Troubleshooting](#troubleshooting)
- [Fallback: If You Can't Finish the Setup in Time](#fallback-if-you-cant-finish-the-setup-in-time)
- [References](#references)
---
 
## What You Need
 
| Item | Purpose | How to check |
| --- | --- | --- |
| Git | Get the tutorial repo, commit after each step | `git --version` |
| make | The tutorial's `make up`, `make validate`, `make export` | `make --version` |
| curl, tar | Needed by the OpenCode install script | `curl --version`, `tar --version` |
| Docker or Podman | Runs the Structurizr viewer and the MCP server | `docker version` (or `podman version`) |
| OpenCode V2 | The AI coding assistant | `opencode --version` (should be `2.x`) |
| Model access | An OpenCode Go account (includes free models), or your own API key | Run `/models` inside OpenCode |
| VS Code 1.85 or later | Editor; OpenChamber's minimum requirement | `code --version` |
| Node.js | **Optional**: only if you install OpenCode with npm | `node --version` |
 
> The workshop's registration page lists Node.js / npm as a requirement. This guide uses the official install script (`curl`), which **does not need Node.js**; npm is just an alternative (see step 1).
 
**Network requirements.** If your company or the venue restricts the network, check that you can reach:
 
| Address | Used for |
| --- | --- |
| `opencode.ai`, `registry.npmjs.org` | The OpenCode install script (it downloads the binary from the npm registry), the OpenCode Console and the OpenCode Go API |
| Your model provider's API (only if you use your own key) | Chat |
| `github.com` | Cloning the tutorial repo (SSH needs port 22; use HTTPS if it is blocked) |
| `mcp.structurizr.com` | Hosted Structurizr MCP (not needed if you run it locally) |
| Docker Hub (`docker.io`) | Pulling the `structurizr/structurizr` and `structurizr/mcp` images |
| `raw.githubusercontent.com` | The tutorial's Structurizr themes (referenced by URL) |
| `marketplace.visualstudio.com` | Installing VS Code extensions |
 
---
 
## Part 1: Prepare the Base Environment for Your Platform
 
### Windows (WSL2)
 
**1. Enable WSL2.** Open PowerShell as administrator:
 
```powershell
wsl --install
```
 
Reboot when asked and create your Linux user (Ubuntu is installed by default). Then check that the version is 2:
 
```powershell
wsl --update
wsl -l -v
```
 
The `VERSION` column must say `2`; if it says `1`, run `wsl --set-version <distro name> 2`.
 
**2. Install a container runtime (pick one).**
 
- **Docker Desktop** (simplest): after installing, go to *Settings → Resources → WSL integration* and **turn on your Linux distro**.
- Or install Docker Engine inside WSL, as in the Linux section below.
Confirm in a **WSL terminal**:
 
```bash
docker version
docker run --rm hello-world
```
 
**3. Install VS Code (on Windows) and the WSL extension.** Install [VS Code](https://code.visualstudio.com/) and the *WSL* extension (`ms-vscode-remote.remote-wsl`). Then open projects from a WSL terminal with `code .`; the bottom-left corner will show `WSL: Ubuntu`.
 
**4. Always work inside WSL's Linux file system.** Keep the repo under `~/work/`, **not** under `/mnt/c/...` (crossing file systems is slow, and file watching and line endings can break).
 
```bash
mkdir -p ~/work && cd ~/work
sudo apt update && sudo apt install -y git make curl tar
```
 
**5. Run every command below in the WSL terminal.** After `make up`, open <http://localhost:8080> in your Windows browser.
 
### Linux
 
**1. Install the basic tools.**
 
```bash
# Debian / Ubuntu
sudo apt update && sudo apt install -y git make curl tar
 
# Fedora
sudo dnf install -y git make curl tar
```
 
**2. Install a container runtime (pick one).**
 
- **Docker Engine:** install it following the [official docs](https://docs.docker.com/engine/install/), then let your user run docker directly, and **log out and back in** so the group takes effect:
```bash
  sudo usermod -aG docker $USER
  docker run --rm hello-world
```
 
- **Podman:** `sudo apt install -y podman` (or `sudo dnf install -y podman`). The repo's Makefile supports Podman: just run `DOCKER=podman make up`; `podman-docker` is not needed.
**3. Install VS Code.** Download the `.deb` or `.rpm` from [code.visualstudio.com](https://code.visualstudio.com/), install it, and check `code --version`.
 
### macOS
 
**1. Install the command line tools** (they include git and make):
 
```bash
xcode-select --install
```
 
**2. Install a container runtime (pick one).**
 
- **Docker Desktop:** download it from [docker.com](https://www.docker.com/products/docker-desktop/), install it and start it once.
- Or with Homebrew: `brew install colima docker && colima start`
- Or Podman: `brew install podman && podman machine init && podman machine start` (then use `DOCKER=podman make up`)
```bash
docker run --rm hello-world
```
 
**3. Install VS Code.** `brew install --cask visual-studio-code`, or download it from the website. Open VS Code, press `⇧⌘P`, and run **Shell Command: Install 'code' command in PATH** so that the terminal gets a `code` command.
 
---
 
## Part 2: Install OpenCode V2 and the Tools (Same on All Platforms)
 
> On Windows, run these in the **WSL terminal**; every command below is a Linux / macOS shell command.
 
### 1. Install OpenCode V2
 
```bash
curl -fsSL https://opencode.ai/v2/install | bash
```
 
The script puts the binary in `~/.opencode/bin/` and adds that directory to your shell config (`~/.bashrc`, `~/.zshrc`, and so on). **Open a new terminal** (or `source ~/.bashrc` / `source ~/.zshrc`), then check:
 
```bash
opencode --version      # should be 2.x
which opencode          # should be ~/.opencode/bin/opencode
```
 
- The script detects your OS and CPU architecture (x64 / arm64) by itself, and also handles older CPUs without AVX2 and musl (Alpine); you don't have to pick.
- To pin a version: `curl -fsSL https://opencode.ai/v2/install | bash -s -- --version <version>`; to leave your shell config alone, add `--no-modify-path`.
- The script also installs an `opencode2` alias, which is the same program as `opencode`.
- **npm install (optional):** `npm install -g @opencode/cli` (needs Node.js; a postinstall step selects the binary for your platform). **Do not install `opencode-ai`; that is the old V1 (1.x).**
- **If `opencode --version` shows 1.x,** your PATH found an old copy. Use `type -a opencode` to see how many there are, then remove the old one or run the install script again.
- To uninstall, preview with `opencode uninstall --dry-run`, then run `opencode uninstall`.

### 2. Connect a Model

OpenCode needs to connect to a model provider to work. You can use **OpenCode Console** or **OpenCode Go** (which includes free models), or connect with your preferred LLM provider's API key.

**OpenCode Console:**

1. **Enter the connect command:** In the CLI terminal, type `/connect` and press Enter to start the integration setup.

   ![Enter the /connect command](./assets/how-to-connect-step-1.png)

2. **Select the integration type:** From the "Connect an integration" menu, find and select "OpenCode Console".

   ![Select integration type](./assets/how-to-connect-step-2.png)

3. **Add a new account:** In the OpenCode Console menu, select "Add account" to link a new account.

   ![Select Add account](./assets/how-to-connect-step-3.png)

4. **Choose authentication method:** In the "Connect OpenCode Console" menu, select "OpenCode Console account".

   ![Select OpenCode Console account](./assets/how-to-connect-step-4.png)

5. **Open the verification link:** The system will generate a device verification URL and device code. Press `o` (or click "open") to open your browser for authorization.

   ![Open the device verification link](./assets/how-to-connect-step-5.png)

6. **Complete browser authorization:** The browser will open an authorization page. Verify the account and device code are correct, then click the "Authorize" button (highlighted in red) to grant access.

   ![Click Authorize to grant access](./assets/how-to-connect-step-6.png)

7. **Select a model:** After authorization succeeds, return to the terminal and select your desired default model from the list (e.g., "Big Pickle Default" / "OpenCode") to complete the connection.

   ![Select a default model](./assets/how-to-connect-step-7.png)

**Using your own provider:** Run `/connect`, select your provider (Anthropic, OpenAI, GitHub Copilot, etc.), paste your API key, or complete the login flow. If you provide an API key via environment variables, set it on the **server that executes model requests**—for example, with a one-time private server:

```bash
ANTHROPIC_API_KEY=sk-ant-... opencode --standalone
```

**Verify the model is working** (non-interactive):

```bash
opencode run "Answer with just one word: ready"
```

### 3. Get the Tutorial Repo
 
```bash
cd ~/work        # on Windows, inside WSL's Linux file system
git clone --branch init git@github.com:mansunkuo/hello-world-2026.git
cd hello-world-2026
git checkout -b main
git branch -M main
```
 
- **No GitHub SSH key set up?** The repo is public, so use HTTPS for the clone line and keep the rest: `git clone --branch init https://github.com/mansunkuo/hello-world-2026.git`
- These commands start from the `init` branch and create a local branch called `main`. **The remote `main` is the finished version** (it contains the reference answers for each step and the docs). Don't `git pull origin main` or switch to it, or you will see the answers right away.
- The repo **already contains** the following, so you don't need to create anything:
  - `AGENTS.md`: the rules file (OpenCode V2 reads it automatically at startup, and recognizes only this file name)
  - `opencode.jsonc`: already configured with the hosted Structurizr MCP
  - `Makefile`: `make up`, `make validate`, `make export`, `make down`…
  - `structurizr/workspace.dsl`: the starter sample
### 4. Check the Structurizr MCP Server
 
The repo's `opencode.jsonc` already registers the hosted server, so you **don't need to run `opencode mcp add`**. Just confirm that it connects, from the repo folder:
 
```bash
opencode mcp list
```
 
The list should show `✓ structurizr  connected`.
 
- If it shows `needs authentication` and you know the server needs no login: OpenCode uses OAuth for remote servers by default. Add `"oauth": false` to the server entry in `opencode.jsonc` (a local change just to make it work on the day; don't commit it):
```jsonc
  {
    "mcp": {
      "servers": {
        "structurizr": {
          "type": "remote",
          "url": "https://mcp.structurizr.com/mcp",
          "oauth": false
        }
      }
    }
  }
```
 
- If the server really needs a login, run `/mcps` inside OpenCode, select the server and sign in as prompted.
- **To use the local version** (bound to localhost only, works offline; prefer this for real client projects), start it and change the `url` above to `http://localhost:3000/mcp`:
```bash
  docker run -d --rm -p 127.0.0.1:3000:3000 -e PORT=3000 structurizr/mcp -dsl -mermaid
```
 
### 5. Pre-pull the Images
 
Venue networks are often congested, so pull the images beforehand (with Podman, replace `docker` with `podman`):
 
```bash
docker pull structurizr/structurizr:latest    # the image named in the repo's Makefile; make up / validate / export all use it
docker pull structurizr/mcp                   # only needed if you run the local MCP
```
 
### 6. Install the VS Code Extensions
 
| Extension | ID | Purpose |
| --- | --- | --- |
| [OpenChamber](https://marketplace.visualstudio.com/items?itemName=FedaykinDev.openchamber) | `FedaykinDev.openchamber` | Chat with OpenCode beside your code; right-click a selection to ask about it, and run one prompt on several models to compare |
| [Structurizr](https://marketplace.visualstudio.com/items?itemName=ciarant.vscode-structurizr) | `ciarant.vscode-structurizr` | Syntax highlighting for Structurizr DSL (highlighting only; no preview or validation) |
 
Install in either way: press `Ctrl+P` in VS Code (`⌘P` on macOS), paste `ext install FedaykinDev.openchamber` and press Enter, then repeat for the second one; or run in a terminal:
 
```bash
code --install-extension FedaykinDev.openchamber
code --install-extension ciarant.vscode-structurizr
```
 
- **Windows:** install them from the **WSL window** (the bottom-left corner shows `WSL: Ubuntu`) so that they land on the WSL side; running the `code --install-extension` commands above in a WSL terminal puts them in the right place.
- **OpenChamber needs `opencode` on your PATH.** It starts a local OpenCode automatically. If it can't find it, set `openchamber.opencodeBinary` in the VS Code settings to the absolute path of `opencode` (for example `/home/<you>/.opencode/bin/opencode`) and reload the window.
- Useful commands (`Ctrl+Shift+P` / `⇧⌘P`): `OpenChamber: Focus Chat`, `OpenChamber: New Session`, `OpenChamber: Show OpenCode Status` (for debugging), `OpenChamber: Restart API Connection`.
### 7. A Suggested Working Layout
 
- Left: `structurizr/workspace.dsl` (with syntax highlighting).
- Beside it: the OpenChamber chat panel, where you paste the tutorial's prompts.
- Browser: <http://localhost:8080> (`make up`); reload every time the agent changes the DSL.
- Terminal: `make validate`, `git diff`, `git commit`.
---
 
## Final Check
 
Before the workshop, confirm every item passes (on Windows, run these in the WSL terminal):
 
- [ ] `git --version` and `make --version` both print a version
- [ ] `docker run --rm hello-world` succeeds (or the Podman equivalent)
- [ ] `docker pull structurizr/structurizr:latest` has finished
- [ ] `opencode --version` shows **2.x**, and `which opencode` points to `~/.opencode/bin/opencode`
- [ ] A model is selected in `/models` (for example `opencode-go/...`), and `opencode run "Answer with a single word: ready"` replies
- [ ] The repo is cloned, and `AGENTS.md` and `opencode.jsonc` are there
- [ ] `opencode mcp list` shows `structurizr` as `connected`
- [ ] In the repo, `make up` works and <http://localhost:8080> shows the viewer
- [ ] In VS Code, the OpenChamber panel opens and `.dsl` files are syntax-highlighted
## Troubleshooting
 
| What you see | Cause | Fix |
| --- | --- | --- |
| `opencode: command not found` | The new PATH is not loaded yet | Open a new terminal, or `source ~/.bashrc` / `source ~/.zshrc`; or `export PATH=$HOME/.opencode/bin:$PATH` by hand |
| `opencode --version` is `1.x` | The old V1 was installed (for example via `npm i -g opencode-ai`), or PATH finds it first | `type -a opencode` to see which exist; use the install script above or `@opencode/cli` |
| OpenCode hangs or cannot reach its server | The background service is unhealthy | `opencode service status`, `opencode service restart`; read the log with `tail -f ~/.local/share/opencode/log/opencode.log` |
| `opencode mcp list` shows `needs authentication` | Remote MCP servers use OAuth by default | Sign in with `/mcps` inside OpenCode; if the server needs no login, set `"oauth": false` (see step 4) |
| The hosted MCP never connects | The network blocks `mcp.structurizr.com` | Use the local MCP (see step 4) |
| `permission denied` reaching Docker (Linux) | Your user is not in the `docker` group | `sudo usermod -aG docker $USER`, then log out and back in |
| `docker: command not found` in WSL | Docker Desktop's integration is off for this distro | Docker Desktop → Settings → Resources → WSL integration, turn on your distro |
| File operations are slow or `make` misbehaves in WSL | The repo is under `/mnt/c/...` | Move the repo under `~/work/` |
| Port `8080` is in use | Another program is using it (the Makefile fixes the port at 8080) | Find it with `lsof -i :8080` and stop it; or run `make down` to stop an old Structurizr container |
| OpenCode Go models are missing from `/models` | Go is not connected yet, or the API key is wrong | `/connect` again and choose OpenCode Go; make sure the key was copied from the OpenCode Console |
| A free model you picked suddenly disappears | A limited-time preview model was withdrawn or replaced | `curl https://opencode.ai/zen/go/v1/models` to see what exists now, then pick another free model |
| A usage-limit message appears during a chat | You hit Go's 5-hour, weekly or monthly limit | Switch to a free model, or to a cheaper model with a bigger allowance (see the table in step 2) |
| OpenChamber cannot find OpenCode | VS Code did not inherit your PATH | Set `openchamber.opencodeBinary` to the absolute path and reload the window (see step 6) |
| The install script fails to download | The network blocks `opencode.ai` or `registry.npmjs.org` | Use an allowed network or proxy, or ask IT to allow them; see the fallback below |
| A platform warning when pulling images on Apple silicon | The image and CPU architecture differ | Usually just a warning; if the container won't start, retry with `--platform linux/amd64` on `docker run` |
 
## Fallback: If You Can't Finish the Setup in Time
 
- Use the [Structurizr Playground](https://playground.structurizr.com/) with the free tier of Claude, ChatGPT or Gemini for a light-weight experience of the tutorial (paste the prompts into the web AI, then paste the DSL it produces into the Playground to see the diagram).
- Or pair up with a neighbour and share a screen.
## References
 
- [OpenCode V2 docs: installation (Intro)](https://opencode.ai/v2/docs/#cli)
- [OpenCode V2: OpenCode Go](https://opencode.ai/v2/docs/console/go/), [Providers](https://opencode.ai/v2/docs/providers/)
- [Tutorial repo (hello-world-2026)](https://github.com/mansunkuo/hello-world-2026)
- [OpenCode V2: MCP servers](https://opencode.ai/v2/docs/mcp-servers/), [Instructions (AGENTS.md)](https://opencode.ai/v2/docs/instructions/), [Providers](https://opencode.ai/v2/docs/cli/providers/), [Troubleshooting](https://opencode.ai/v2/docs/troubleshooting/)
- [Workshop page: AI-driven architecture in practice: Structurizr × OpenCode](https://hwdc.ithome.com.tw/2026/lab/5031)
- [OpenChamber (VS Code)](https://marketplace.visualstudio.com/items?itemName=FedaykinDev.openchamber), [Structurizr syntax highlighting (VS Code)](https://marketplace.visualstudio.com/items?itemName=ciarant.vscode-structurizr)
- [Installing WSL](https://learn.microsoft.com/windows/wsl/install), [Installing Docker Engine](https://docs.docker.com/engine/install/)
 