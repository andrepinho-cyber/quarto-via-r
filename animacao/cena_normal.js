/* cena_normal.js - area sob a densidade da Normal padrao a esquerda de z
   (densidades e probabilidades do R, animacao/config_normal.R).
   Funcao pura do tempo t. Arquivo so com ASCII; todo texto vem de tx. */
AnimacaoAula.registrar("normal", function (ctx, t, d, m, tx, W, H, estado) {
  "use strict";
  var AZUL = "#1d3b53", LARANJA = "#c8553d", CINZA = "#6b6b6b", ESCURO = "#2b2f36",
      FONTE = "Source Sans Pro, Helvetica, Arial, sans-serif";
  var x0 = 80, x1 = 920, yt = 110, yb = 430;
  var zmin = d.z[0], zmax = d.z[d.z.length - 1], dmax = 0.42;

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
  function px(z) { return x0 + (z - zmin) / (zmax - zmin) * (x1 - x0); }
  function py(v) { return yb - v / dmax * (yb - yt); }

  texto(tx.titulo, W / 2, 34, 24, ESCURO, "center", true);
  texto(tx.modelo, W / 2, 66, 17, ESCURO, "center");

  // Posicao de z: parado em z_ini ate anda_ini; anda ate z_fim em anda_fim (linear: e o conteudo).
  var u = lim((t - m.anda_ini) / (m.anda_fim - m.anda_ini));
  var zAgora = d.z_ini + (d.z_fim - d.z_ini) * u;
  var j = Math.round((zAgora - zmin) / (zmax - zmin) * (d.z.length - 1));

  // Area sombreada (aparece em m.area)
  var aArea = fase(m.area, 1.0);
  var i;
  if (aArea > 0) {
    ctx.globalAlpha = 0.35 * aArea; ctx.fillStyle = LARANJA;
    ctx.beginPath(); ctx.moveTo(px(d.z[0]), yb);
    for (i = 0; i <= j; i++) ctx.lineTo(px(d.z[i]), py(d.dens[i]));
    ctx.lineTo(px(d.z[j]), yb); ctx.closePath(); ctx.fill();
    ctx.globalAlpha = 1;
  }

  // Curva e eixo
  ctx.strokeStyle = AZUL; ctx.lineWidth = 3;
  ctx.beginPath();
  for (i = 0; i < d.z.length; i++) {
    if (i === 0) ctx.moveTo(px(d.z[i]), py(d.dens[i])); else ctx.lineTo(px(d.z[i]), py(d.dens[i]));
  }
  ctx.stroke();
  ctx.strokeStyle = CINZA; ctx.lineWidth = 2;
  ctx.beginPath(); ctx.moveTo(x0, yb); ctx.lineTo(x1, yb); ctx.stroke();
  for (i = 0; i < d.ticks.length; i++) {
    ctx.beginPath(); ctx.moveTo(px(d.ticks[i]), yb); ctx.lineTo(px(d.ticks[i]), yb + 6); ctx.stroke();
    texto(d.rotulos[i], px(d.ticks[i]), yb + 20, 16, CINZA, "center");
  }
  texto(tx.eixo, x1, yb + 46, 18, ESCURO, "right");

  // Ponto z e probabilidade (texto e numeros do R)
  if (aArea > 0) {
    ctx.globalAlpha = aArea;
    ctx.strokeStyle = LARANJA; ctx.lineWidth = 2;
    ctx.beginPath(); ctx.moveTo(px(d.z[j]), yb); ctx.lineTo(px(d.z[j]), py(d.dens[j])); ctx.stroke();
    texto(tx.eixo + " = " + d.z_txt[j], px(d.z[j]), yb + 46, 18, LARANJA, "center", true);
    texto(tx.prob + d.z_txt[j] + tx.igual + d.p_txt[j], x0 + 10, yt, 22, LARANJA, "left", true);
    ctx.globalAlpha = 1;
  }
});
