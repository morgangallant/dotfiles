# Zig setup
export PATH="$PATH:$HOME/zig"

# Ruby
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
export PATH="/opt/homebrew/lib/ruby/gems/3.3.0/bin:$PATH"

# Go
export PATH="$PATH:$HOME/go/bin"

# Google Cloud SDK
source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"
source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"

# Fix FZF
export FZF_DEFAULT_COMMAND="find . | sed 's/^..//'"
