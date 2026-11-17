# Mac App Store — mas

## 1. Gerar o arquivo

No Mac que já possui os aplicativos instalados, execute:

```bash
mas list | awk '{print $1}' > ~/dotfiles/apps/mas/mas-apps.txt
```

## 2. Validar o arquivo

Para visualizar os aplicativos registrados no arquivo, execute:

```bash
while read -r app; do
  echo "\n"
  mas info "$app"
done < ~/dotfiles/apps/mas/mas-apps.txt
```

## 3. Instalar os aplicativos

Para instalar os aplicativos no novo Mac, execute:

```bash
while read -r app; do
  echo "\n"
  mas install "$app"
done < ~/dotfiles/apps/mas/mas-apps.txt
```
