# mdpreview.nvim

A minimal Markdown preview plugin for Neovim with a Rust backend.  
Provides live browser updates using WebSockets.

## Features

- Live preview in browser with instant updates
- Automatic updates on buffer changes
- Cursor synchronization between Neovim and browser
- GitHub-flavored Markdown support (tables, task lists, etc.)
- Image support with relative path resolution
- Interactive table of contents (click to navigate)
- Fast backend powered by Rust
- Lightweight Neovim integration (Lua)

### Neovim
- lazy.nvim (or any plugin manager)
- curl (for HTTP requests)

## Installation

Using lazy.nvim:

```lua
{
  "DenizIsikli/mdpreview.nvim",
  config = function()
    require("mdpreview").setup()
  end
}

## Usage

1. Open a Markdown file (`.md`) in Neovim

2. Start the preview:

:MarkdownPreview

* This starts the Rust backend
* Opens your browser at http://localhost:3000

3. Edit your Markdown file

* Changes update automatically in the browser
* Cursor position is synced in real time

4. Stop the preview (optional):

:MarkdownPreviewStop

* The server will also stop automatically when leaving Neovim or switching away from Markdown files


## Architecture

- Neovim plugin (Lua) sends buffer content via HTTP
- Rust server converts Markdown to HTML
- WebSocket broadcasts updates to browser

## Dependencies

### Rust
- axum
- tokio
- tokio-tungstenite
- tower-http
- pulldown-cmark
