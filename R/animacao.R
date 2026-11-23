# animacao.R · funções do R para as animações narradas em slides Reveal.js.
# Versão da apostila "Quarto com R para docentes de Estatística", adaptada do
# tocador das disciplinas do autor. Licença MIT.
#
# Peças da pasta-modelo:
#   libs/animacao/animacao.js   tocador genérico (canvas, botões, legenda, áudio)
#   libs/animacao/animacao.css  aparência do tocador
#   animacao/cena_*.js          desenho da cena, função pura do tempo
#   animacao/config_*.R         dados, narração e marcas de tempo, gerados no R
#
# O HTML sai com o JavaScript e o CSS embutidos no próprio slide, para funcionar
# igual com e sem embed-resources e sem fetch. Todo texto que aparece na tela
# (legendas, rótulos, números) vem do R, pela configuração em JSON; os arquivos
# .js e .css ficam só com ASCII.

# Narração: a parte decimal se lê como inteiro, "zero vírgula noventa e dois",
# nunca algarismo por algarismo ("zero vírgula nove dois"). Só o zero à esquerda
# da parte decimal é lido à parte ("zero vírgula zero cinco").
animacao_conferir_decimais <- function(texto) {
  d1 <- c("um", "dois", "três", "quatro", "cinco", "seis", "sete", "oito", "nove")
  d0 <- c("zero", d1)
  padrao <- paste0("vírgula (", paste(d1, collapse = "|"), ") (",
                   paste(d0, collapse = "|"), ")([^[:alpha:]]|$)")
  ruim <- grepl(padrao, texto, ignore.case = TRUE)
  if (any(ruim)) stop("Decimal lido algarismo por algarismo na narração: ",
                      paste(texto[ruim], collapse = " | "))
  invisible(TRUE)
}

# Tempos de cada frase da narração.
# narracao: data.frame com as colunas id (ex.: "c1f2"), cena, texto e pausa
#   (segundos de silêncio depois da frase).
# duracoes: duração real de cada frase no áudio, em segundos; sem ela, estima
#   pela taxa de fala (palavras por minuto).
# Devolve a narração com as colunas palavras, ini e fim (segundos).
animacao_tempos <- function(narracao, duracoes = NULL, ppm = 140,
                            inicio = 2, intervalo = 0.5) {
  animacao_conferir_decimais(narracao[["texto"]])
  palavras <- lengths(strsplit(trimws(narracao[["texto"]]), "[[:space:]]+"))
  if (is.null(duracoes)) duracoes <- palavras / ppm * 60
  stopifnot(length(duracoes) == nrow(narracao), all(duracoes > 0))
  ini <- numeric(nrow(narracao)); fim <- ini
  t <- inicio
  for (i in seq_len(nrow(narracao))) {
    ini[i] <- t
    fim[i] <- t + duracoes[i]
    t <- fim[i] + intervalo + narracao[["pausa"]][i]
  }
  narracao[["palavras"]] <- palavras
  narracao[["ini"]] <- ini
  narracao[["fim"]] <- fim
  narracao
}

# Duração de um arquivo WAV PCM, lida do cabeçalho (sem pacotes extras).
animacao_duracao_wav <- function(arquivo) {
  con <- file(arquivo, "rb"); on.exit(close(con))
  stopifnot(identical(readChar(con, 4, useBytes = TRUE), "RIFF"))
  readBin(con, "integer", size = 4, endian = "little")
  stopifnot(identical(readChar(con, 4, useBytes = TRUE), "WAVE"))
  taxa_bytes <- NA
  repeat {
    id <- readChar(con, 4, useBytes = TRUE)
    if (length(id) == 0 || nchar(id) < 4) stop("WAV sem bloco de dados: ", arquivo)
    tam <- readBin(con, "integer", size = 4, endian = "little")
    if (id == "fmt ") {
      fmt <- readBin(con, "raw", tam)
      taxa_bytes <- sum(as.integer(fmt[9:12]) * 256^(0:3))
    } else if (id == "data") {
      stopifnot(!is.na(taxa_bytes))
      return(tam / taxa_bytes)
    } else {
      readBin(con, "raw", tam + tam %% 2)
    }
  }
}

# Lê um arquivo de texto como uma única cadeia (UTF-8).
animacao_ler <- function(arquivo) {
  paste(readLines(arquivo, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}

# Rótulos padrão dos controles; a configuração da cena pode trocar qualquer um.
animacao_rotulos <- function() {
  list(
    iniciar = "Iniciar", pausar = "Pausar", continuar = "Continuar",
    recomecar = "Recomeçar", narracao = "Narração", legenda = "Legenda",
    posicao = "Posição na animação", tempo_de = "de",
    controles = "Controles da animação",
    transcricao = "Transcrição da narração",
    sem_js = "Esta animação precisa de JavaScript. A transcrição da narração está abaixo.",
    dica = "Clique em Iniciar. A legenda acompanha a narração.",
    descricao = "Animação."
  )
}

animacao_escapar <- function(x) htmltools::htmlEscape(x, attribute = TRUE)

# Parágrafos da transcrição: um por cena (se houver a coluna cena), ou um só.
animacao_paragrafos <- function(legendas) {
  txt <- legendas[["texto"]]
  if (is.null(legendas[["cena"]])) return(paste(txt, collapse = " "))
  cenas <- unique(legendas[["cena"]])
  vapply(cenas, function(k) paste(txt[legendas[["cena"]] == k], collapse = " "), character(1))
}

# Transcrição recolhível (HTML), usada por animacao_slide().
animacao_transcricao_html <- function(legendas, titulo) {
  p <- paste0("<p>", htmltools::htmlEscape(animacao_paragrafos(legendas)), "</p>")
  c("<details class=\"anim-transcricao\">",
    sprintf("<summary>%s</summary>", htmltools::htmlEscape(titulo)),
    p, "</details>")
}

# Estado por documento: o JS e o CSS-base entram uma vez só em cada documento.
animacao_estado <- new.env()

# HTML do slide da animação.
# id: identificador único no documento (ex.: "abertura01");
# config: lista com cena (nome registrado no .js da cena), duracao, legendas
#   (data.frame ini, fim, texto e, opcional, cena), marcas (lista nome = segundos),
#   dados, textos e rotulos (só os que mudam; os demais vêm de animacao_rotulos());
# cena_js: caminho do .js da cena; audio: caminho do áudio relativo ao HTML, ou NULL;
# libs: pasta com animacao.js e animacao.css; transcricao: inclui a transcrição recolhível.
animacao_slide <- function(id, config, cena_js, audio = NULL,
                           largura = 1000, altura = 520,
                           libs = "libs/animacao", transcricao = TRUE) {
  if (!knitr::is_html_output()) return(invisible(NULL))
  stopifnot(grepl("^[A-Za-z][A-Za-z0-9_-]*$", id), file.exists(cena_js),
            is.numeric(config[["duracao"]]), config[["duracao"]] > 0)
  rot <- utils::modifyList(animacao_rotulos(), as.list(config[["rotulos"]]))
  config[["rotulos"]] <- rot
  config[["largura"]] <- largura
  config[["altura"]] <- altura
  json <- jsonlite::toJSON(config, auto_unbox = TRUE, digits = NA,
                           dataframe = "rows", null = "null")
  # Segurança do bloco <script>: "</" e "<!--" dentro de uma cadeia fechariam o bloco.
  json <- gsub("</", "<\\/", json, fixed = TRUE)
  json <- gsub("<!--", "\\u003c!--", json, fixed = TRUE)
  doc <- knitr::current_input()
  base <- !identical(animacao_estado[["doc"]], doc)
  animacao_estado[["doc"]] <- doc
  e <- animacao_escapar
  partes <- c(
    if (base) c("<style>", animacao_ler(file.path(libs, "animacao.css")), "</style>",
                "<script>", animacao_ler(file.path(libs, "animacao.js")), "</script>"),
    "<script>", animacao_ler(cena_js), "</script>",
    sprintf("<div class=\"anim-aula\" id=\"%s\">", id),
    sprintf("<noscript><p>%s</p></noscript>", e(rot[["sem_js"]])),
    sprintf("<canvas width=\"%d\" height=\"%d\" role=\"img\" aria-label=\"%s\"></canvas>",
            2 * largura, 2 * altura, e(rot[["descricao"]])),
    sprintf("<div class=\"anim-legenda\" id=\"%s-legenda\" aria-live=\"polite\"></div>", id),
    sprintf("<div class=\"anim-controles\" role=\"group\" aria-label=\"%s\">", e(rot[["controles"]])),
    sprintf("<button type=\"button\" class=\"anim-iniciar\">%s</button>", e(rot[["iniciar"]])),
    sprintf("<button type=\"button\" class=\"anim-recomecar\">%s</button>", e(rot[["recomecar"]])),
    if (!is.null(audio))
      sprintf("<button type=\"button\" class=\"anim-narracao\" aria-pressed=\"true\">%s</button>",
              e(rot[["narracao"]])),
    sprintf("<button type=\"button\" class=\"anim-legenda-btn\" aria-pressed=\"true\" aria-controls=\"%s-legenda\">%s</button>",
            id, e(rot[["legenda"]])),
    sprintf("<input type=\"range\" class=\"anim-posicao\" min=\"0\" max=\"%s\" step=\"any\" value=\"0\" aria-label=\"%s\">",
            format(config[["duracao"]], scientific = FALSE), e(rot[["posicao"]])),
    "<span class=\"anim-relogio\" aria-hidden=\"true\"></span>",
    "</div>",
    if (!is.null(audio)) sprintf("<audio preload=\"auto\" src=\"%s\"></audio>", e(audio)),
    if (transcricao) animacao_transcricao_html(config[["legendas"]], rot[["transcricao"]]),
    "</div>",
    sprintf("<script>AnimacaoAula.criar(document.getElementById(\"%s\"), %s);</script>",
            id, json)
  )
  knitr::asis_output(paste(partes, collapse = "\n"))
}

# Transcrição da narração para o PDF: um parágrafo por cena. No HTML, o slide
# já traz a transcrição recolhível, e esta função não escreve nada.
# narracao: data.frame com as colunas texto e, opcional, cena.
animacao_transcricao <- function(narracao, titulo = "Transcrição da narração.") {
  if (knitr::is_html_output()) return(invisible(NULL))
  txt <- paste(animacao_paragrafos(narracao), collapse = "\n\n")
  # Letras gregas e x com barra fora do modo matemático saem como glifo ausente no PDF.
  bs <- intToUtf8(92)
  txt <- gsub("μ", paste0("$", bs, "mu$"), txt, fixed = TRUE)
  txt <- gsub("x̄", paste0("$", bs, "bar{x}$"), txt, fixed = TRUE)
  txt <- gsub("X̄", paste0("$", bs, "bar{X}$"), txt, fixed = TRUE)
  knitr::asis_output(paste0("**", titulo, "** ", txt, "\n"))
}
