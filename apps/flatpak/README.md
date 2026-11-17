
# Flatpak

## 1. Gerar o arquivo

No Fedora que já possui os aplicativos instalados, execute:

```bash
flatpak list --app --columns=application > ~/dotfiles/apps/flatpak/flatpaks.txt
```

## 2. Validar o arquivo

Para visualizar os aplicativos registrados no arquivo, execute:

```bash
while read -r app; do
  echo "\n"
  flatpak info "$app"
done < ~/dotfiles/apps/flatpak/flatpaks.txt
```

## 3. Instalar os aplicativos

Para instalar os aplicativos no novo computador, execute:

**Observação:** antes de instalar, certifique-se de que o Flathub esteja configurado:

```bash
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

while read -r app; do
  echo "\n"
  flatpak install -y flathub "$app"
done < ~/dotfiles/apps/flatpak/flatpaks.txt
```
