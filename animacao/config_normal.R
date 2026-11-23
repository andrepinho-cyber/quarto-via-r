# config_normal.R · cena "normal": área sob a densidade da Normal padrão à esquerda de z.
# Sem dados: as densidades e as probabilidades vêm de dnorm() e pnorm(), conferidas
# por integrate().

z_fim_normal <- 1.96
passo_normal <- 0.01

fmt_br <- function(x, d = 2) formatC(x, format = "f", digits = d, decimal.mark = ",")

dados_normal <- function() {
  z <- round(seq(-3.5, 3.5, by = passo_normal), 2)
  p <- pnorm(z)
  # Conferência por outro caminho: integração numérica da densidade em alguns pontos.
  for (zz in c(-1, 0, z_fim_normal))
    stopifnot(abs(integrate(dnorm, -Inf, zz)$value - pnorm(zz)) < 1e-6)
  list(z = z, dens = round(dnorm(z), 5), p = p)
}

narracao_normal <- function() {
  # 1,96 e P(Z <= 1,96) = 0,975 lidos por extenso; a parte decimal se lê como inteiro.
  stopifnot(z_fim_normal == 1.96, round(pnorm(z_fim_normal), 3) == 0.975)
  fr <- list(
    c("c1f1", 1, "A curva é a densidade da Normal padrão, de média zero e variância um."),
    c("c1f2", 1, "A área sombreada, à esquerda do ponto z, é a probabilidade de Z ser menor ou igual a z."),
    c("c1f3", 1, "Quando z anda para a direita, a área cresce e se aproxima de um."),
    c("c1f4", 1, "Em z igual a um vírgula noventa e seis, a área é zero vírgula novecentos e setenta e cinco.")
  )
  n <- data.frame(id = vapply(fr, `[`, "", 1), cena = as.integer(vapply(fr, `[`, "", 2)),
                  texto = vapply(fr, `[`, "", 3), pausa = 0)
  n[["pausa"]][n[["id"]] == "c1f3"] <- 3
  n
}

config_normal <- function(duracoes = NULL) {
  d <- dados_normal()
  nar <- animacao_tempos(narracao_normal(), duracoes)
  m <- setNames(as.list(nar[["ini"]]), nar[["id"]])
  marcas <- list(area = m[["c1f2"]], anda_ini = m[["c1f3"]], anda_fim = m[["c1f4"]])
  ticks <- -3:3
  list(
    cena = "normal",
    duracao = max(nar[["fim"]]) + 3,
    legendas = nar[, c("ini", "fim", "texto", "cena")],
    marcas = marcas,
    dados = list(z = d[["z"]], dens = d[["dens"]], p_txt = fmt_br(d[["p"]], 4),
                 z_txt = sub("-", "−", fmt_br(d[["z"]], 2), fixed = TRUE), z_ini = -1, z_fim = z_fim_normal,
                 ticks = ticks, rotulos = sub("-", "−", as.character(ticks), fixed = TRUE)),
    textos = list(
      titulo = "Probabilidade como área sob a densidade da Normal padrão",
      modelo = "Z ~ Normal(0; 1): média 0, variância 1, suporte (−∞; ∞)",
      eixo = "z", prob = "P(Z ≤ ", igual = ") = "
    ),
    rotulos = list(
      dica = "Antes de iniciar: qual é a área total sob a curva?",
      descricao = sprintf(paste("Animação: densidade da Normal padrão com a área à esquerda de um ponto z",
                                "sombreada; o ponto anda para a direita e a área cresce; em z = %s,",
                                "a área é %s."), fmt_br(z_fim_normal), fmt_br(pnorm(z_fim_normal), 4))
    )
  )
}
