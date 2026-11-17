# Snap — Snapcraft

## 1. Gerar o arquivo

Na máquina que já possui os pacotes instalados, execute:

```bash
snap list | awk 'NR > 1 {print $1}' > ~/dotfiles/apps/snap/snaps.txt
```

## 2. Validar o arquivo

Para visualizar os pacotes registrados no arquivo, execute:

```bash
while read -r app; do
  snap info "$app"
done < ~/dotfiles/apps/snap/snaps.txt
```

## 3. Instalar os pacotes

Para instalar os pacotes na nova máquina, execute:

**Observação:** certifique-se de que o Snap esteja instalado e configurado na nova máquina antes de executar a instalação.

```bash
sudo dnf install snapd
sudo ln -s /var/lib/snapd/snap /snap

while read -r app; do
  sudo snap install "$app"
done < ~/dotfiles/apps/snap/snaps.txt
```
