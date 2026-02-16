# Chrome Integration Reference

## Requirements

- **Google Chrome** or **Microsoft Edge** browser (Brave, Arc, and other Chromium browsers are not supported)
- **Claude in Chrome extension** v1.0.36+ from the Chrome Web Store (works for both browsers)
- **Claude Code** v2.0.73+
- A direct Anthropic plan (Pro, Max, Teams, or Enterprise) — third-party providers (Bedrock, Vertex, Foundry) do not support Chrome integration

## Connecting

### Option 1: Launch with Chrome flag
```bash
claude --chrome
```

### Option 2: Enable from an existing session
```
/chrome
```

### Option 3: Enable by default
Run `/chrome` and select "Enabled by default". Note: this increases context usage since browser tools are always loaded.

## Available MCP Tools

All tools are prefixed `mcp__claude-in-chrome__`. Run `/mcp` and select `claude-in-chrome` to see full schemas.

| Tool | Purpose |
|------|---------|
| `navigate` | Open URLs, go back/forward |
| `computer` | Click, type, scroll, screenshot, keyboard interactions |
| `form_input` | Fill inputs, select dropdowns |
| `find` | Search elements by text |
| `read_page` | Get DOM with element references |
| `get_page_text` | Extract visible text content |
| `tabs_context` | List open tabs |
| `tabs_create` | Create a new tab |
| `resize_window` | Resize the browser window |
| `read_console_messages` | Read browser console output |
| `read_network_requests` | Read network requests |
| `upload_image` | Upload files via drag-and-drop |
| `gif_creator` | Record interactions as GIF |
| `javascript_tool` | Execute JavaScript in the page |

## Capabilities

- **Navigate**: Open URLs, click links, follow redirects
- **Interact**: Click buttons, fill forms, select dropdowns, scroll
- **Read**: Extract text content, check element visibility, read console output
- **Verify**: Compare page state against expected outcomes
- **Record**: Capture interactions as GIF recordings
- **Multi-tab**: Work across multiple browser tabs
- **Authenticated**: Access any site the user is already logged into (shares browser session)

## Limitations

- **No credential entry**: Claude pauses and asks the user to handle login pages and CAPTCHAs manually
- **No invisible actions**: All browser actions run in a visible Chrome window in real time
- **Connection drops**: The Chrome extension service worker can go idle during long sessions. Run `/chrome` and select "Reconnect extension" to restore
- **Modal blocking**: JavaScript dialogs (alert, confirm, prompt) block browser events. The user must dismiss them manually
- **No WSL support**: Chrome integration does not work in Windows Subsystem for Linux
- **Site permissions**: Inherited from Chrome extension settings — manage in extension settings to control which sites Claude can access

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Extension not detected | Check extension is installed in `chrome://extensions`, restart Chrome to pick up native messaging host config |
| Browser not responding | Check for blocking modal dialogs, ask Claude to create a new tab |
| Connection drops mid-session | Run `/chrome` and select "Reconnect extension" |
| Native messaging host error | Restart Claude Code to regenerate the host configuration |
| Named pipe conflicts (Windows) | Close other Claude Code sessions using Chrome, restart |

### Native messaging host config locations

**Chrome:**
- macOS: `~/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.anthropic.claude_code_browser_extension.json`
- Linux: `~/.config/google-chrome/NativeMessagingHosts/com.anthropic.claude_code_browser_extension.json`

**Edge:**
- macOS: `~/Library/Application Support/Microsoft Edge/NativeMessagingHosts/com.anthropic.claude_code_browser_extension.json`
- Linux: `~/.config/microsoft-edge/NativeMessagingHosts/com.anthropic.claude_code_browser_extension.json`
