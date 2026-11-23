/* cena_proporcao.js - cena minima: proporcao de caras ao longo dos lancamentos
   de uma moeda (dados simulados no R, animacao/config_proporcao.R).
   Funcao pura do tempo t. Arquivo so com ASCII; todo texto vem de tx. */
AnimacaoAula.registrar("proporcao", function (ctx, t, d, m, tx, W, H, estado) {
  "use strict";
  var AZUL = "#1d3b53", LARANJA = "#c8553d", CINZA = "#6b6b6b", ESCURO = "#2b2f36",
      FONTE = "Source Sans Pro, Helvetica, Arial, sans-serif";
  var x0 = 110, x1 = 940, yt = 90, yb = 430;

  function lim(u) { return Math.max(0, Math.min(1, u)); }
  // Transicao suave; com movimento reduzido, troca direta.
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
  function px(k) { return x0 + k / d.n * (x1 - x0); }
  function py(p) { return yb - p * (yb - yt); }

  // Titulo e aviso de dados simulados
  texto(tx.titulo, W / 2, 36, 24, ESCURO, "center", true);
  texto(tx.simulados, x1, 64, 16, LARANJA, "right");

  // Eixos, com os rotulos vindos do R
  ctx.strokeStyle = CINZA; ctx.lineWidth = 2;
  ctx.beginPath(); ctx.moveTo(x0, yt); ctx.lineTo(x0, yb); ctx.lineTo(x1, yb); ctx.stroke();
  var i;
  for (i = 0; i < d.ticks_y.length; i++) {
    var y = py(d.ticks_y[i]);
    ctx.beginPath(); ctx.moveTo(x0 - 6, y); ctx.lineTo(x0, y); ctx.stroke();
    texto(d.rotulos_y[i], x0 - 12, y, 16, CINZA, "right");
  }
  for (i = 0; i < d.ticks_x.length; i++) {
    var x = px(d.ticks_x[i]);
    ctx.beginPath(); ctx.moveTo(x, yb); ctx.lineTo(x, yb + 6); ctx.stroke();
    texto(d.rotulos_x[i], x, yb + 20, 16, CINZA, "center");
  }
  texto(tx.eixo_x, (x0 + x1) / 2, yb + 50, 18, ESCURO, "center");
  ctx.save();
  ctx.translate(36, (yt + yb) / 2); ctx.rotate(-Math.PI / 2);
  texto(tx.eixo_y, 0, 0, 18, ESCURO, "center");
  ctx.restore();

  // Linha de referencia (probabilidade de cara), aparece na ultima frase
  var aRef = fase(m.referencia, 1.0);
  if (aRef > 0) {
    ctx.globalAlpha = aRef;
    ctx.setLineDash([8, 6]); ctx.strokeStyle = LARANJA; ctx.lineWidth = 2;
    ctx.beginPath(); ctx.moveTo(x0, py(d.p)); ctx.lineTo(x1, py(d.p)); ctx.stroke();
    ctx.setLineDash([]);
    texto(tx.referencia, x1 - 4, py(d.p) - 16, 16, LARANJA, "right");
    ctx.globalAlpha = 1;
  }

  // Curva: cresce de m.curva_ini a m.curva_fim (crescimento linear, e o conteudo da cena)
  var k = Math.round(lim((t - m.curva_ini) / (m.curva_fim - m.curva_ini)) * d.n);
  if (k > 0) {
    ctx.strokeStyle = AZUL; ctx.lineWidth = 3; ctx.lineJoin = "round";
    ctx.beginPath();
    for (i = 0; i < k; i++) {
      if (i === 0) ctx.moveTo(px(1), py(d.prop[0])); else ctx.lineTo(px(i + 1), py(d.prop[i]));
    }
    ctx.stroke();
    ctx.fillStyle = AZUL;
    ctx.beginPath(); ctx.arc(px(k), py(d.prop[k - 1]), 6, 0, 2 * Math.PI); ctx.fill();
    texto(tx.contagem + k + "   " + tx.proporcao + d.prop_txt[k - 1], x0, 64, 18, AZUL, "left");
  }
});
