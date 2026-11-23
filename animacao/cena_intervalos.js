/* cena_intervalos.js - intervalos de confianca aparecem um a um ao lado da
   media verdadeira (dados simulados no R, animacao/config_intervalos.R).
   Funcao pura do tempo t. Arquivo so com ASCII; todo texto vem de tx. */
AnimacaoAula.registrar("intervalos", function (ctx, t, d, m, tx, W, H, estado) {
  "use strict";
  var AZUL = "#1d3b53", LARANJA = "#c8553d", CINZA = "#6b6b6b", ESCURO = "#2b2f36",
      FONTE = "Source Sans Pro, Helvetica, Arial, sans-serif";
  var x0 = 120, x1 = 900, yt = 100, yb = 440;

  function lim(u) { return Math.max(0, Math.min(1, u)); }
  function fase(ini, dur) {
    if (estado.reduzido) return t >= ini ? 1 : 0;
    var u = lim((t - ini) / dur);
    return u * u * (3 - 2 * u);
  }
  function texto(s, x, y, tam, cor, alin, negrito) {
    ctx.font = (negrito ? "bold " : "") + tam + "px " + FONTE;
    ctx.fillStyle = cor; ctx.textAlign = alin || "left"; ctx.textBaseline = "middle";
    ctx.fillText(s, x, y);
  }
  function px(v) { return x0 + (v - d.xmin) / (d.xmax - d.xmin) * (x1 - x0); }
  function py(i) { return yt + (i + 0.5) / d.m * (yb - yt); }

  texto(tx.titulo, W / 2, 34, 24, ESCURO, "center", true);
  texto(tx.simulados, W / 2, 64, 16, LARANJA, "center");

  // Eixo horizontal
  ctx.strokeStyle = CINZA; ctx.lineWidth = 2;
  ctx.beginPath(); ctx.moveTo(x0, yb); ctx.lineTo(x1, yb); ctx.stroke();
  var i;
  for (i = 0; i < d.ticks.length; i++) {
    var x = px(d.ticks[i]);
    ctx.beginPath(); ctx.moveTo(x, yb); ctx.lineTo(x, yb + 6); ctx.stroke();
    texto(d.rotulos[i], x, yb + 20, 16, CINZA, "center");
  }
  texto(tx.eixo, (x0 + x1) / 2, yb + 48, 18, ESCURO, "center");

  // Media verdadeira
  ctx.setLineDash([8, 6]); ctx.strokeStyle = ESCURO; ctx.lineWidth = 2;
  ctx.beginPath(); ctx.moveTo(px(d.mu), yt - 8); ctx.lineTo(px(d.mu), yb); ctx.stroke();
  ctx.setLineDash([]);
  texto(tx.media, px(d.mu) + 8, yt - 14, 16, ESCURO, "left");

  // Intervalos: um a um entre aparece_ini e aparece_fim; as cores entram em m.cores
  var quantos = Math.floor(lim((t - m.aparece_ini) / (m.aparece_fim - m.aparece_ini)) * d.m + 1e-9);
  if (t >= m.aparece_fim) quantos = d.m;
  var aCor = fase(m.cores, 1.0);
  for (i = 0; i < quantos; i++) {
    var y = py(i);
    // Antes de m.cores, todos azuis; depois, laranja (e mais grossos) os que nao contem a media.
    ctx.strokeStyle = (aCor > 0 && !d.contem[i]) ? LARANJA : AZUL;
    ctx.lineWidth = d.contem[i] ? 4 : 4 + 2 * aCor;
    ctx.beginPath(); ctx.moveTo(px(d.li[i]), y); ctx.lineTo(px(d.ls[i]), y); ctx.stroke();
    ctx.fillStyle = ctx.strokeStyle;
    ctx.beginPath(); ctx.arc(px(d.xb[i]), y, 4, 0, 2 * Math.PI); ctx.fill();
  }
  texto(tx.amostra + " 1", x0 - 10, py(0), 14, CINZA, "right");
  texto(tx.amostra + " " + d.m, x0 - 10, py(d.m - 1), 14, CINZA, "right");

  // Contagem (numero calculado no R)
  var aCont = fase(m.contagem, 0.8);
  if (aCont > 0) {
    ctx.globalAlpha = aCont;
    texto(tx.contem, x1, yt - 14, 18, AZUL, "right", true);
    ctx.globalAlpha = 1;
  }
});
