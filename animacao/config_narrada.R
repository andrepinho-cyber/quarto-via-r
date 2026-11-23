# config_narrada.R · a cena mínima com narração em áudio, na voz do autor.
# Dados SIMULADOS (os de config_proporcao.R). Sem frase de aviso: a voz não é sintética.
source("animacao/config_proporcao.R", encoding = "UTF-8")

narracao_narrada <- function() narracao_proporcao()

config_narrada <- function(duracoes = NULL) {
  cfg <- config_proporcao()
  nar <- animacao_tempos(narracao_narrada(), duracoes)
  m <- setNames(as.list(nar[["ini"]]), nar[["id"]])
  cfg[["marcas"]] <- list(curva_ini = m[["c1f2"]], curva_fim = m[["c1f4"]], referencia = m[["c1f4"]])
  stopifnot(cfg[["marcas"]][["curva_fim"]] > cfg[["marcas"]][["curva_ini"]])
  cfg[["duracao"]] <- max(nar[["fim"]]) + 3
  cfg[["legendas"]] <- nar[, c("ini", "fim", "texto", "cena")]
  cfg[["textos"]][["simulados"]] <- "dados simulados · voz do autor"
  cfg
}
