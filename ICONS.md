# 🎨 Customização de Ícones - ACAL

Este guia explica como atualizar os ícones da aplicação Flutter.

## 📁 Locais dos Ícones

### Web Icons (Navegador/PWA)
```
app/web/
├── favicon.png                 # Ícone na aba do navegador (192x192px)
└── icons/
    ├── Icon-192.png           # Ícone pequeno (192x192px)
    ├── Icon-512.png           # Ícone grande (512x512px)
    ├── Icon-maskable-192.png  # Versão adaptada para home screen (192x192px)
    └── Icon-maskable-512.png  # Versão adaptada para home screen (512x512px)
```

### Windows Icons (Desktop)
```
app/windows/runner/resources/
└── app_icon.ico  # Ícone do executável Windows (256x256px)
```

## 🚀 Como Integrar Novos Ícones

### 1. Preparar os Arquivos

Você precisa de:
- **favicon.png** - 192x192px (PNG)
- **Icon-192.png** - 192x192px (PNG)
- **Icon-512.png** - 512x512px (PNG)
- **Icon-maskable-192.png** - 192x192px (PNG, versão adaptada)
- **Icon-maskable-512.png** - 512x512px (PNG, versão adaptada)
- **app_icon.ico** - 256x256px (ICO)

### 2. Substituir os Arquivos

```bash
# Web icons
cp seu-favicon.png app/web/favicon.png
cp seu-icon-192.png app/web/icons/Icon-192.png
cp seu-icon-512.png app/web/icons/Icon-512.png
cp seu-maskable-192.png app/web/icons/Icon-maskable-192.png
cp seu-maskable-512.png app/web/icons/Icon-maskable-512.png

# Windows icon
cp seu-app-icon.ico app/windows/runner/resources/app_icon.ico
```

### 3. Fazer Commit

```bash
git add app/web/ app/windows/runner/resources/
git commit -m "style: update application icons"
```

## 📐 Especificações Técnicas

| Arquivo | Tamanho | Formato | Descrição |
|---------|---------|---------|-----------|
| favicon.png | 192x192 | PNG | Ícone do navegador |
| Icon-192.png | 192x192 | PNG | Ícone PWA pequeno |
| Icon-512.png | 512x512 | PNG | Ícone PWA grande |
| Icon-maskable-192.png | 192x192 | PNG | Ícone home screen pequeno |
| Icon-maskable-512.png | 512x512 | PNG | Ícone home screen grande |
| app_icon.ico | 256x256 | ICO | Ícone Windows |

### Dicas para Maskable Icons

Maskable icons são usados em telas de home no Android/iOS. O design deve deixar uma área segura de pelo menos 80px de cada lado para caber em diferentes tamanhos de máscara.

**Boas práticas:**
- Use design simples e limpo
- Evite detalhes nas bordas (serão cortados)
- Certifique-se de que funciona em diferentes formas (círculo, square, teardrop)

## 🔗 Referências

- [Flutter Icon Documentation](https://docs.flutter.dev/development/ui/assets-and-images#app-icons)
- [Web App Icon Guidelines](https://web.dev/add-a-web-app-manifest/#add-icons)
- [Maskable Icons Spec](https://w3c.github.io/manifest/#icon-masks)

## 💡 Ferramentas Recomendadas

- **Figma** - Design e export
- **AppIcon.co** - Converter e gerar múltiplos tamanhos
- **ImageOptim** - Otimizar PNGs
- **ICO Convert** - Converter PNG para ICO

## ❓ Próximas Etapas

1. **Design dos ícones** (Figma)
2. **Export em múltiplos tamanhos** (App Icon Generator)
3. **Substituir os arquivos** (cp commands acima)
4. **Testar localmente**:
   ```bash
   cd app
   flutter run -d web
   # Verificar favicon na aba do navegador
   
   flutter run -d windows
   # Verificar ícone no executável
   ```
5. **Fazer commit e push**
6. **CI/CD fará build** com os novos ícones

---

**Criado em:** 2026-08-12  
**Última atualização:** 2026-08-12
