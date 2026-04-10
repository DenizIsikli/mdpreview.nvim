# mdpreview.nvim

A minimal Markdown preview plugin for Neovim with a Rust backend.  
Provides live browser updates using WebSockets.

## Features

- Live preview in browser
- Automatic updates on buffer changes
- Lightweight Neovim integration (Lua)
- Fast backend written in Rust

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

### Neovim
- lazy.nvim (or any plugin manager)
- curl (for HTTP requests)

## Installation

Using lazy.nvim:

```lua
{
  "yourname/mdpreview.nvim",
  config = function()
    require("mdpreview").setup()
  end
}
