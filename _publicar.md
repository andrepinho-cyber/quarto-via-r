# Publicar o site companheiro

O site desta pasta (projeto Quarto do tipo `website`) foi construído e testado
só no computador local (`quarto render` em `site/`, saída em `site/_site`, cerca
de 10 MB). **Nada foi publicado.** A escolha da hospedagem e a publicação são do
autor; este arquivo só reúne os passos. Os comandos do Quarto abaixo foram
conferidos em `quarto publish --help` (Quarto 1.11.9, 23/11/2026), mas nenhuma
publicação foi executada. Limites e termos dos serviços foram lidos nas páginas
oficiais em 22 e 23/11/2026 e podem ter mudado: confira de novo antes de publicar.

## Antes de publicar

1. Renderize o site: no terminal, em `site/`, `quarto render`. Abra
   `_site/index.html` por um servidor local (`servr::httd("_site")` no console do
   R), porque a demo com `ojs` não funciona por `file://`.
2. Confirme o aviso de voz sintética nas demos e os termos de uso da voz do
   Windows para material publicado (`PENDENCIAS.md`).
3. As demos de vídeo e de narração incluem arquivos de áudio e vídeo em `resources:`
   do `_quarto.yml`; confira que estão em `_site/` depois de renderizar.

## Opção 1: GitHub Pages

Limites conferidos: site publicado de até 1 GB e cerca de 100 GB de tráfego por
mês (limite flexível). Requer conta no GitHub e o programa `git` instalado.

1. No GitHub, crie um repositório vazio (por exemplo `quarto-via-r`).
2. No terminal, em `site/`:

   ```powershell
   git init
   git add .
   git commit -m "Site companheiro"
   git branch -M main
   git remote add origin https://github.com/SEU-USUARIO/quarto-via-r.git
   git push -u origin main
   quarto publish gh-pages
   ```

3. O Quarto cria o ramo `gh-pages`, publica `_site/` e abre o endereço, do tipo
   `https://SEU-USUARIO.github.io/quarto-via-r/`. Na primeira vez, o GitHub pode
   pedir que você ative o Pages para o ramo `gh-pages` em Settings, Pages.

## Opção 2: Quarto Pub

Limites conferidos: 100 MB por site e cerca de 10 GB de tráfego por mês. A
documentação do Quarto indica que o serviço está sendo substituído pelo Posit
Connect Cloud, cujos termos não foram lidos. No terminal, em `site/`:

```powershell
quarto publish quarto-pub
```

O comando pede o login (aberto no navegador) e o nome do site. O endereço é do
tipo `https://SEU-USUARIO.quarto.pub/nome-do-site/`.

## Outras opções que o Quarto 1.11.9 lista

`quarto publish posit-connect-cloud`, `connect` (servidor próprio do Posit),
`netlify`. Não foram avaliadas nem testadas aqui.

## Depois de publicar

1. Escreva o endereço definitivo em `site/endereco.txt` (hoje há um endereço
   provisório, `https://usuario.github.io/quarto-via-r/`).
2. Regenere o livro (`quarto render --to pdf`, na raiz de `apostila-quarto/`),
   porque o QR code da seção de hospedagem do Capítulo 4 é gerado desse endereço.
3. Abra o site publicado e confira as cinco demos, incluindo o vídeo com legenda e
   o áudio da narração.
4. O envio de arquivos gerados com a sua voz, em vez da voz sintética de teste,
   segue o roteiro do Capítulo 4.
