#!/usr/bin/env bash
# Installs and sets up discord

if [ -n ${SKIP_FLATPAK} ] || [ -n ${SKIP_DISCORD} ]; then
    echo "SKIP_DISCORD is set. Skipping 31-discord.sh"
    exit 0
fi

echo "Install discord flatpak"
flatpak install flathub com.discordpp.Discord
