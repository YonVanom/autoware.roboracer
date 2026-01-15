# Build Tools

This role installs build tools for building Autoware.

## Tools

- ccache

## Inputs

## Manual Installation

This is slightly different from the ansible version.
We'll update the ansible version to match these steps below.

```bash
sudo apt-get update
sudo apt-get install -y ccache

# Make sure the ccache directory exists
mkdir -p "$HOME/.cache/ccache"

# Add the following lines to ~/.bashrc file
export CMAKE_C_COMPILER_LAUNCHER=ccache
export CMAKE_CXX_COMPILER_LAUNCHER=ccache
export CCACHE_DIR="$HOME/.cache/ccache/"
export CCACHE_LOGFILE=/tmp/ccache.log
```

Configure ccache maximum size:
`gedit $HOME/.cache/ccache/ccache.conf`

Add the following lines and save the file:

```bash
# Set maximum cache size
max_size = 15G
```
