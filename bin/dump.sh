#!/bin/zsh

# Dump Homebrew
brew bundle dump -fg --formula --cask --tap --no-describe

brew bundle dump -f --file ~/.homebrew/Brewfile_npm --npm
brew bundle dump -f --file ~/.homebrew/Brewfile_go --go
