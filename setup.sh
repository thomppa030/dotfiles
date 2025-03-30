#!/bin/bash

# Author: Kay Priesnitz
# Date: March 10, 2025

set -e # Exit on any error

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Required packages to install via Paru
PACKAGES=("foot" "wofi" "hyprland" "swww" "neovim" "waybar" "dunst")

EXTRA_PACKAGES=("deno" "neofetch" "ripgrep" "swww" "btop" "wlogout" "starship" "thunar" "thunar-archive-plugin" "eza" "zsh" "cmake" "pavucontrol")

FONT_PACKAGES=("ttf-jetbrains-mono-nerd" "noto-fonts-emoji" "inter-font")

BUILD_DIR="$HOME/builds"
CONFIG_DIR="$HOME/.config"
REPO_DIR="$(pwd)" 

# Check if required tools are installed
check_requirements() {
    echo -e "${BLUE}Checking required tools...${NC}"
    
    # Check for git
    if ! command -v git &> /dev/null; then
        echo -e "${RED}Error: git is not installed. Please install it with 'sudo pacman -S git'${NC}"
        exit 1
    fi
    
    # Check for base-devel (needed for building packages)
    if ! pacman -Q base-devel &> /dev/null; then
        echo -e "${RED}Error: base-devel is not installed. Please install it with 'sudo pacman -S base-devel'${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}All required tools are installed.${NC}"
}

# Install Paru if not already installed
install_paru() {
    echo -e "${BLUE}Checking for Paru...${NC}"
    
    if command -v paru &> /dev/null; then
        echo -e "${GREEN}Paru is already installed.${NC}"
        return
    fi
    
    echo -e "${YELLOW}Paru not found. Installing Paru...${NC}"
    
    # Create build directory
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    
    # Clone the Paru repository
    git clone "https://aur.archlinux.org/paru.git"
     
    cd paru
    
    # Build and install Paru
    makepkg -si --noconfirm
    
    # Return to original directory
    cd "$REPO_DIR"
    
    # Verify installation
    if command -v paru &> /dev/null; then
        echo -e "${GREEN}Paru installed successfully.${NC}"
    else
        echo -e "${RED}Failed to install Paru. Exiting.${NC}"
        exit 1
    fi
}

# Install packages using Paru
install_packages() {
    echo -e "${BLUE}Installing required packages using Paru...${NC}"
    
    # Install all packages in one command
    paru -S --needed --noconfirm "${PACKAGES[@]}"

    paru -S --needed --noconfirm "${EXTRA_PACKAGES[@]}"

    paru -S --needed --noconfirm "${FONT_PACKAGES[@]}"
    
    echo -e "${GREEN}All packages installed.${NC}"
}

link_config() {
    local package=$1
    
    echo -e "${BLUE}Linking configuration for $package...${NC}"
    
    # Define special cases for package names
    local config_name="$package"
    case "$package" in
        "hyprland")
            config_name="hypr"
            ;;
        "neovim")
            config_name="nvim"
            ;;
    esac
    
    local source_dir="$REPO_DIR/$config_name"
    
    local dest_dir="$CONFIG_DIR/$config_name"
    
    echo -e "${YELLOW}Checking for configuration at: $source_dir${NC}"
    
    if [ -L "$source_dir" ]; then
        local link_target=$(readlink -f "$source_dir")
        echo -e "${YELLOW}Warning: Source directory is already a symlink pointing to: $link_target${NC}"
        
        if [[ "$link_target" == "$CONFIG_DIR"* ]]; then
            echo -e "${RED}Error: Source is already linked from config directory. Reverse linking detected.${NC}"
            echo -e "${YELLOW}Skipping $package to avoid circular links.${NC}"
            return
        fi
    fi
    
    # Check if destination is already a link
    if [ -L "$dest_dir" ]; then
        local dest_target=$(readlink -f "$dest_dir")
        
        # If it already links to our repo, nothing to do
        if [ "$dest_target" == "$source_dir" ]; then
            echo -e "${GREEN}Configuration already properly linked.${NC}"
            return
        else
            echo -e "${YELLOW}Destination is already a symlink pointing elsewhere. Removing: $dest_dir -> $dest_target${NC}"
            rm "$dest_dir"
        fi
    # If it's a regular directory, back it up
    elif [ -d "$dest_dir" ]; then
        local backup_dir="$dest_dir.backup.$(date +%Y%m%d%H%M%S)"
        echo -e "${YELLOW}Backing up existing configuration to $backup_dir${NC}"
        mv "$dest_dir" "$backup_dir"
    fi
    
    # Backup existing configuration if it exists
    if [ -d "$dest_dir" ] && [ ! -L "$dest_dir" ]; then
        local backup_dir="$dest_dir.backup.$(date +%Y%m%d%H%M%S)"
        echo -e "${YELLOW}Backing up existing configuration to $backup_dir${NC}"
        mv "$dest_dir" "$backup_dir"
    elif [ -L "$dest_dir" ]; then
        echo -e "${YELLOW}Removing existing symbolic link at $dest_dir${NC}"
        rm "$dest_dir"
    fi
    
    echo -e "${GREEN}Creating symbolic link from $source_dir to $dest_dir${NC}"
    ln -sf "$source_dir" "$dest_dir"
    
    if [ -L "$dest_dir" ]; then
        local link_target=$(readlink -f "$dest_dir")
        if [ "$link_target" == "$source_dir" ]; then
            echo -e "${GREEN}Configuration for $package linked successfully.${NC}"
        else
            echo -e "${RED}Link created, but points to unexpected location: $link_target${NC}"
        fi
    else
        echo -e "${RED}Failed to create link.${NC}"
    fi

    echo -e "${YELLOW}Note: changing default shell to zsh.${NC}"
    chsh -s /usr/bin/zsh

    touch ~/.zshrc
    touch ~/.config/starship.toml

    echo -e "${GREEN}Creating symbolic link from .zshrc to HOME{NC}"
    ln -sf "${REPO_DIR}/.zshrc" "~/.zshrc"

    echo -e "${GREEN}Creating symbolic link from starship.toml to .config/{NC}"
    ln -sf "${REPO_DIR}/starship.toml" "~/.config/starship.toml"
}

main() {
    echo -e "${BLUE}Starting setup process...${NC}"
    
    check_requirements
    
    install_paru
    
    install_packages
    
    echo -e "${BLUE}Linking configurations...${NC}"
    for package in "${PACKAGES[@]}"; do
        link_config "$package"
    done
    
    echo -e "${GREEN}All packages installed and configurations linked.${NC}"


    echo -e "${YELLOW}Note: Running hyprctl reload, to check immediate hyprland effects.${NC}"
    hyprctl reload

    neofetch

    echo -e "${YELLOW}Note: You may need to restart your window manager or reload configurations for changes to take effect.${NC}"
}

main
