# config_proporcao.R · configuração da cena mínima (proporção de caras).
# Dados SIMULADOS: 200 lançamentos de uma moeda equilibrada (semente 2026).
# Usado pelo setup de aula.qmd, depois de source("R/animacao.R").

semente_prop <- 2026L
n_prop <- 200L
p_prop <- 0.5

# Formato brasileiro sem mexer no OutDec.
fmt_br <- function(x, d = 2) formatC(x, format = "f", digits = d, decimal.mark = ",")

dados_proporcao <- function() {
  set.seed(semente_prop)
  x <- rbinom(n_prop, size = 1, prob = p_prop)
  prop <- cumsum(x) / seq_len(n_prop)
  # Conferência por outro caminho: média dos k primeiros lançamentos.
  stopifnot(isTRUE(all.equal(prop, vapply(seq_len(n_prop), function(k) mean(x[1:k]), 0))))
  list(x = x, prop = prop, final = prop[n_prop])
}

narracao_proporcao <- function() {
  extenso <- c("200" = "duzentas")
  stopifnot(as.character(n_prop) %in% names(extenso))
  d <- dados_proporcao()
  # A frase "perto da metade" só vale se a proporção final estiver perto de 0,5.
  stopifnot(abs(d[["final"]] - p_prop) < 0.1, d[["final"]] != p_prop)
  fr <- list(
    c("c1f1", 1, sprintf("Uma moeda equilibrada é lançada %s vezes, em dados simulados.", extenso[[as.character(n_prop)]])),
    c("c1f2", 1, "A curva mostra a proporção de caras depois de cada lançamento."),
    c("c1f3", 1, "No começo, a proporção oscila muito, porque cada lançamento pesa bastante."),
    c("c1f4", 1, "Com mais lançamentos, ela fica perto da metade, sem ser igual a ela.")
  )
  n <- data.frame(id = vapply(fr, `[`, "", 1), cena = as.integer(vapply(fr, `[`, "", 2)),
                  texto = vapply(fr, `[`, "", 3), pausa = 0)
  n[["pausa"]][n[["id"]] == "c1f2"] <- 4   # a curva cresce sem fala
  n
}

# duracoes: durações reais das frases (segundos), quando houver áudio; sem elas,
# os tempos são estimados a 140 palavras por minuto.
config_proporcao <- function(duracoes = NULL) {
  d <- dados_proporcao()
  nar <- animacao_tempos(narracao_proporcao(), duracoes)
  m <- setNames(as.list(nar[["ini"]]), nar[["id"]])
  marcas <- list(curva_ini = m[["c1f2"]], curva_fim = m[["c1f4"]], referencia = m[["c1f4"]])
  stopifnot(marcas[["curva_fim"]] > marcas[["curva_ini"]])
  ticks_y <- seq(0, 1, by = 0.25)
  ticks_x <- seq(0, n_prop, by = 50)
  list(
    cena = "proporcao",
    duracao = max(nar[["fim"]]) + 3,
    legendas = nar[, c("ini", "fim", "texto", "cena")],
    marcas = marcas,
    dados = list(
      n = n_prop, p = p_prop, prop = round(d[["prop"]], 4), prop_txt = fmt_br(d[["prop"]]),
      ticks_y = ticks_y, rotulos_y = formatC(ticks_y, format = "g", decimal.mark = ","),
      ticks_x = ticks_x, rotulos_x = as.character(ticks_x)
    ),
    textos = list(
      titulo = sprintf("Proporção de caras em %d lançamentos de uma moeda equilibrada", n_prop),
      simulados = "dados simulados",
      eixo_x = "número de lançamentos", eixo_y = "proporção de caras",
      referencia = "metade (probabilidade de cara)",
      contagem = "lançamentos: ", proporcao = "proporção de caras: "
    ),
    rotulos = list(
      dica = "Antes de iniciar: o que acontece com a proporção de caras quando o número de lançamentos cresce?",
      descricao = sprintf(paste("Animação com dados simulados: proporção de caras ao longo de %d lançamentos",
                                "de uma moeda equilibrada. A curva oscila muito no começo e termina em %s,",
                                "perto da metade, sem ser igual a ela."), n_prop, fmt_br(d[["final"]]))
    )
  )
}
