# config_intervalos.R · cena "intervalos": 20 intervalos de confiança de 95% para a média.
# Dados SIMULADOS: 20 amostras de tamanho 25 de uma Normal com média 50 e desvio-padrão 10
# (semente 4404). Intervalo t de Student, calculado no R e conferido por t.test().

semente_ic <- 4404L
m_ic <- 20L; n_ic <- 25L; mu_ic <- 50; sigma_ic <- 10; conf_ic <- 0.95

fmt_br <- function(x, d = 2) formatC(x, format = "f", digits = d, decimal.mark = ",")

dados_intervalos <- function() {
  set.seed(semente_ic)
  am <- matrix(rnorm(m_ic * n_ic, mean = mu_ic, sd = sigma_ic), nrow = m_ic)
  xb <- rowMeans(am); s <- apply(am, 1, sd)
  meia <- qt(1 - (1 - conf_ic) / 2, df = n_ic - 1) * s / sqrt(n_ic)
  li <- xb - meia; ls <- xb + meia
  # Conferência por outro caminho: t.test() em cada amostra.
  tt <- t(apply(am, 1, function(v) t.test(v, conf.level = conf_ic)$conf.int))
  stopifnot(isTRUE(all.equal(unname(tt), unname(cbind(li, ls)))))
  contem <- li <= mu_ic & mu_ic <= ls
  list(xb = xb, li = li, ls = ls, contem = contem, k = sum(contem))
}

narracao_intervalos <- function() {
  d <- dados_intervalos()
  extenso <- c("15" = "quinze", "16" = "dezesseis", "17" = "dezessete", "18" = "dezoito",
               "19" = "dezenove", "20" = "todos os vinte")
  stopifnot(m_ic == 20, n_ic == 25, mu_ic == 50, conf_ic == 0.95, as.character(d[["k"]]) %in% names(extenso))
  conta <- if (d[["k"]] == m_ic) "Aqui, todos os vinte intervalos contêm a média."
           else sprintf("Aqui, %s dos vinte intervalos contêm a média.", extenso[[as.character(d[["k"]])]])
  fr <- list(
    c("c1f1", 1, "Vinte amostras de tamanho vinte e cinco foram simuladas de uma população Normal de média cinquenta."),
    c("c1f2", 1, "Para cada amostra, o R calcula um intervalo de confiança de noventa e cinco por cento para a média."),
    c("c1f3", 1, "Os segmentos azuis cruzam a linha da média verdadeira; os laranja não a alcançam."),
    c("c1f4", 1, conta),
    c("c1f5", 1, "A confiança se refere ao procedimento, e não a um intervalo já calculado.")
  )
  n <- data.frame(id = vapply(fr, `[`, "", 1), cena = as.integer(vapply(fr, `[`, "", 2)),
                  texto = vapply(fr, `[`, "", 3), pausa = 0)
  n[["pausa"]][n[["id"]] == "c1f2"] <- 6   # os intervalos aparecem sem fala
  n
}

config_intervalos <- function(duracoes = NULL) {
  d <- dados_intervalos()
  nar <- animacao_tempos(narracao_intervalos(), duracoes)
  m <- setNames(as.list(nar[["ini"]]), nar[["id"]])
  marcas <- list(aparece_ini = m[["c1f2"]], aparece_fim = m[["c1f3"]] - 0.5,
                 cores = m[["c1f3"]], contagem = m[["c1f4"]])
  stopifnot(marcas[["aparece_fim"]] > marcas[["aparece_ini"]])
  ticks <- seq(35, 65, by = 5)
  list(
    cena = "intervalos",
    duracao = max(nar[["fim"]]) + 3,
    legendas = nar[, c("ini", "fim", "texto", "cena")],
    marcas = marcas,
    dados = list(m = m_ic, mu = mu_ic, xmin = 35, xmax = 65,
                 xb = round(d[["xb"]], 4), li = round(d[["li"]], 4), ls = round(d[["ls"]], 4),
                 contem = d[["contem"]], k = d[["k"]],
                 ticks = ticks, rotulos = as.character(ticks)),
    textos = list(
      titulo = sprintf("%d intervalos de confiança de %s%% para a média (n = %d)",
                       m_ic, fmt_br(100 * conf_ic, 0), n_ic),
      simulados = sprintf("dados simulados: Normal com média %d e desvio-padrão %d", mu_ic, sigma_ic),
      media = "média verdadeira (50)", eixo = "valor da variável",
      contem = sprintf("contêm a média: %d de %d", d[["k"]], m_ic),
      amostra = "amostra"
    ),
    rotulos = list(
      dica = "Antes de iniciar: quantos dos 20 intervalos você espera que contenham a média verdadeira?",
      descricao = sprintf(paste("Animação com dados simulados: %d intervalos de confiança de %s%% para a média,",
                                "um por amostra de tamanho %d de uma Normal com média %d, aparecem um a um",
                                "ao lado de uma linha vertical na média verdadeira; %d deles contêm a média."),
                          m_ic, fmt_br(100 * conf_ic, 0), n_ic, mu_ic, d[["k"]])
    )
  )
}
