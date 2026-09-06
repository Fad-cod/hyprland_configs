#!/bin/bash
# Installe OpenSSH si ce n'est pas fait (via pacman) et démarre le service
sudo pacman -S --needed --noconfirm openssh
sudo systemctl enable --now sshd

# Affiche ton IP locale pour la suite
IP_ADDR=$(ip -o -4 route get 1 | awk '{print $7}')
USER_NAME=$(whoami)

echo "Serveur SSH prêt ! Ton utilisateur est '$USER_NAME' et ton IP est '$IP_ADDR'."
