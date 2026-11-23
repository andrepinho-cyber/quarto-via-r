/* animacao.js - tocador de animacoes narradas para slides Reveal.js.
   Versao da apostila "Quarto com R para docentes de Estatistica", adaptada do
   tocador das disciplinas do autor. Licenca MIT.

   Sem bibliotecas externas. Arquivo so com ASCII: todo texto exibido vem da
   configuracao (JSON gerado pelo R, R/animacao.R).

   Uso:
     AnimacaoAula.registrar("nome", function (ctx, t, dados, marcas, textos, W, H, estado) {...});
     AnimacaoAula.criar(elementoRaiz, config);

   A cena e uma funcao pura do tempo t (segundos): o quadro inteiro e
   redesenhado a cada passo, o que permite pausar, recomecar e saltar.
   estado.reduzido e true quando o sistema pede menos movimento
   (prefers-reduced-motion); a cena decide o que simplificar.
   O relogio e o do navegador; o audio, quando existe, acompanha o relogio
   (e reposicionado se a diferenca passar de 0,25 s). */
(function () {
  "use strict";
  if (window.AnimacaoAula) return;

  var cenas = {};
  var tocadores = [];
  var CHAVE_LEGENDA = "animacao.legenda";

  function registrar(nome, fn) { cenas[nome] = fn; }

  function fmtTempo(s) {
    s = Math.max(0, Math.floor(s));
    var m = Math.floor(s / 60), r = s % 60;
    return m + ":" + (r < 10 ? "0" : "") + r;
  }

  // localStorage pode faltar ou lancar erro (arquivo aberto em moldura isolada,
  // navegacao privada, politica da instituicao): nesse caso vale o padrao.
  function lerPreferencia(chave, padrao) {
    try {
      var v = window.localStorage.getItem(chave);
      return v === null ? padrao : v === "1";
    } catch (e) { return padrao; }
  }
  function gravarPreferencia(chave, valor) {
    try { window.localStorage.setItem(chave, valor ? "1" : "0"); } catch (e) { /* sem memoria */ }
  }

  var consultaMovimento = window.matchMedia ? window.matchMedia("(prefers-reduced-motion: reduce)") : null;

  function criar(raiz, cfg) {
    var W = cfg.largura, H = cfg.altura;
    var canvas = raiz.querySelector("canvas");
    var ctx = canvas.getContext("2d");
    var caixaLegenda = raiz.querySelector(".anim-legenda");
    var bIniciar = raiz.querySelector(".anim-iniciar");
    var bRecomecar = raiz.querySelector(".anim-recomecar");
    var bNarracao = raiz.querySelector(".anim-narracao");     // so existe com audio
    var bLegenda = raiz.querySelector(".anim-legenda-btn");
    var posicao = raiz.querySelector(".anim-posicao");        // <input type="range">
    var relogio = raiz.querySelector(".anim-relogio");
    var controles = raiz.querySelector(".anim-controles");
    var audio = raiz.querySelector("audio");
    var rot = cfg.rotulos;
    var desenhar = cenas[cfg.cena];
    var dur = cfg.duracao;
    var leg = cfg.legendas;

    var t = 0, tocando = false, narracao = true, audioOk = !!audio;
    var tRef = 0, relRef = 0, pedido = null, legendaAtual = -2, segundoAtual = -1;
    var legendaVisivel = lerPreferencia(CHAVE_LEGENDA, true);
    var estado = { reduzido: !!(consultaMovimento && consultaMovimento.matches) };

    function agora() { return performance.now() / 1000; }

    // Legenda como regiao viva: "polite" quando ela e o unico canal (sem audio
    // ou com a narracao desligada); "off" com a narracao audivel, para o leitor
    // de tela nao falar por cima da voz. A transcricao completa fica abaixo.
    function ajustarRegiaoViva() {
      caixaLegenda.setAttribute("aria-live", (audioOk && narracao) ? "off" : "polite");
    }

    function semAudio() {
      audioOk = false;
      if (bNarracao) bNarracao.hidden = true;
      ajustarRegiaoViva();
    }
    if (audio) audio.addEventListener("error", semAudio);
    if (!audio && bNarracao) bNarracao.hidden = true;

    function mostrarLegenda() {
      caixaLegenda.style.visibility = legendaVisivel ? "visible" : "hidden";  // mantem a altura
      bLegenda.setAttribute("aria-pressed", legendaVisivel ? "true" : "false");
    }

    function legendaEm(tt) {
      for (var i = 0; i < leg.length; i++) {
        var ate = leg[i].fim + 1.5;           // a frase fica ate a seguinte, ou 1,5 s
        if (i + 1 < leg.length) ate = Math.min(ate, leg[i + 1].ini);
        if (tt >= leg[i].ini && tt < ate) return i;
      }
      return -1;
    }

    function quadro() {
      ctx.setTransform(canvas.width / W, 0, 0, canvas.height / H, 0, 0);
      ctx.clearRect(0, 0, W, H);
      ctx.fillStyle = "#ffffff";
      ctx.fillRect(0, 0, W, H);
      ctx.globalAlpha = 1;
      if (desenhar) {
        ctx.save();
        desenhar(ctx, t, cfg.dados, cfg.marcas, cfg.textos, W, H, estado);
        ctx.restore();
      }
      var i = legendaEm(t);
      if (i !== legendaAtual) {
        legendaAtual = i;
        caixaLegenda.textContent = i >= 0 ? leg[i].texto : (t === 0 ? rot.dica : "");
      }
      posicao.value = String(t);
      var s = Math.floor(t);
      if (s !== segundoAtual) {
        segundoAtual = s;
        var txt = fmtTempo(t) + " / " + fmtTempo(dur);
        relogio.textContent = txt;
        posicao.setAttribute("aria-valuetext", fmtTempo(t) + " " + rot.tempo_de + " " + fmtTempo(dur));
      }
    }

    function sincronizarAudio() {
      if (!audioOk) return;
      if (!tocando || t >= audio.duration) {
        if (!audio.paused) audio.pause();
        return;
      }
      if (Math.abs(audio.currentTime - t) > 0.25) {
        try { audio.currentTime = t; } catch (e) { /* ainda sem metadados */ }
      }
      if (audio.paused) {
        var p = audio.play();
        if (p && p.catch) p.catch(function () { semAudio(); });
      }
    }

    function passo() {
      if (!tocando) return;
      t = tRef + (agora() - relRef);
      if (t >= dur) { t = dur; parar(true); }
      sincronizarAudio();
      quadro();
      if (tocando) pedido = requestAnimationFrame(passo);
    }

    function tocar() {
      if (t >= dur) t = 0;
      tocando = true;
      tRef = t; relRef = agora();
      bIniciar.textContent = rot.pausar;
      sincronizarAudio();
      pedido = requestAnimationFrame(passo);
    }

    function parar(fim) {
      tocando = false;
      if (pedido) cancelAnimationFrame(pedido);
      pedido = null;
      if (audioOk && !audio.paused) audio.pause();
      bIniciar.textContent = fim ? rot.iniciar : rot.continuar;
    }

    function irPara(novo) {
      t = Math.max(0, Math.min(dur, novo));
      tRef = t; relRef = agora();
      if (audioOk) { try { audio.currentTime = t; } catch (e) { /* idem */ } }
      quadro();
    }

    // Clique com o mouse devolve o foco ao slide (as setas voltam a mudar de
    // slide); acionado pelo teclado (detail = 0), o foco fica no botao.
    function soltar(b, ev) { if (ev && ev.detail > 0) b.blur(); }

    bIniciar.addEventListener("click", function (ev) {
      if (tocando) parar(false); else tocar();
      soltar(bIniciar, ev);
    });
    bRecomecar.addEventListener("click", function (ev) {
      var estava = tocando;
      if (estava) parar(false);
      irPara(0);
      bIniciar.textContent = rot.iniciar;
      if (estava) tocar();
      soltar(bRecomecar, ev);
    });
    if (bNarracao) {
      bNarracao.addEventListener("click", function (ev) {
        narracao = !narracao;
        if (audio) audio.muted = !narracao;
        bNarracao.setAttribute("aria-pressed", narracao ? "true" : "false");
        ajustarRegiaoViva();
        soltar(bNarracao, ev);
      });
    }
    bLegenda.addEventListener("click", function (ev) {
      legendaVisivel = !legendaVisivel;
      gravarPreferencia(CHAVE_LEGENDA, legendaVisivel);
      mostrarLegenda();
      soltar(bLegenda, ev);
    });

    // Controle deslizante nativo: o mouse arrasta; o teclado salta 5 s
    // (setas), 15 s (PageUp e PageDown), inicio e fim (Home e End).
    posicao.min = "0";
    posicao.max = String(dur);
    posicao.step = "any";
    posicao.addEventListener("input", function () {
      irPara(parseFloat(posicao.value));
    });
    posicao.addEventListener("keydown", function (ev) {
      var salto = { ArrowLeft: -5, ArrowDown: -5, ArrowRight: 5, ArrowUp: 5, PageDown: -15, PageUp: 15 };
      if (ev.key in salto) irPara(t + salto[ev.key]);
      else if (ev.key === "Home") irPara(0);
      else if (ev.key === "End") irPara(dur);
      else return;
      ev.preventDefault();
    });
    posicao.addEventListener("change", function (ev) { soltar(posicao, ev); });

    // Teclas dentro dos controles nao chegam ao Reveal.js (nao mudam o slide).
    controles.addEventListener("keydown", function (ev) { ev.stopPropagation(); });

    if (consultaMovimento) {
      var aoMudar = function () { estado.reduzido = consultaMovimento.matches; quadro(); };
      if (consultaMovimento.addEventListener) consultaMovimento.addEventListener("change", aoMudar);
      else if (consultaMovimento.addListener) consultaMovimento.addListener(aoMudar);
    }

    var tocador = { raiz: raiz, parar: function () { if (tocando) parar(false); },
                    irPara: irPara, tempo: function () { return t; },
                    tocando: function () { return tocando; }, quadro: quadro,
                    movimentoReduzido: function () { return estado.reduzido; } };
    tocadores.push(tocador);
    raiz.animacao = tocador;
    mostrarLegenda();
    ajustarRegiaoViva();
    quadro();
    return tocador;
  }

  // Ao sair do slide, a animacao para (e o audio junto).
  function ligarReveal() {
    if (!window.Reveal || !window.Reveal.on) return false;
    window.Reveal.on("slidechanged", function (ev) {
      tocadores.forEach(function (p) {
        if (!ev.currentSlide || !ev.currentSlide.contains(p.raiz)) p.parar();
      });
    });
    return true;
  }
  if (!ligarReveal()) {
    window.addEventListener("load", function () { ligarReveal(); });
  }

  window.AnimacaoAula = { registrar: registrar, criar: criar, fmtTempo: fmtTempo };
})();
