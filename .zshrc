# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Load Powerlevel10k theme engine (NixOS system path)
for p10k in \
  /run/current-system/sw/share/zsh/themes/powerlevel10k/powerlevel10k.zsh-theme \
  /run/current-system/sw/share/zsh-powerlevel10k/powerlevel10k.zsh-theme \
  ~/.local/share/zsh/themes/powerlevel10k/powerlevel10k.zsh-theme
do
  if [[ -r "$p10k" ]]; then
    source "$p10k"
    break
  fi
done

# Load Powerlevel10k configuration
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Load Zsh Plugins (Autosuggestions & Syntax Highlighting)
for plugin in \
  /run/current-system/sw/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /run/current-system/sw/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /run/current-system/sw/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /run/current-system/sw/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
do
  [[ -r "$plugin" ]] && source "$plugin"
done

# System wrappers & local user binary PATH
export PATH="$HOME/.local/bin:/run/wrappers/bin:$PATH"
