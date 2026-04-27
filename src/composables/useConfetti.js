import { shallowRef } from 'vue';

/**
 * Canvas-based confetti particle burst — extracted from dashboard.js.
 * Usage:
 *   const { canvasRef, fireConfetti } = useConfetti();
 *   // Bind canvasRef to a <canvas> element in the template via ref.
 */
export function useConfetti() {
  const canvasRef = shallowRef(null);
  let _confAF = null;

  function getCtx() {
    return canvasRef.value ? canvasRef.value.getContext('2d') : null;
  }

  /**
   * Fire a confetti burst originating from (ox, oy).
   * Falls back to centre of screen when coordinates are omitted.
   */
  function fireConfetti(ox, oy) {
    const CC = canvasRef.value;
    const ctx = getCtx();
    if (!CC || !ctx) return;

    // Ensure canvas matches viewport
    CC.width  = window.innerWidth;
    CC.height = window.innerHeight;

    const cx = ox != null ? ox : CC.width / 2;
    const cy = oy != null ? oy : CC.height * 0.45;
    const PALETTE = ['#c9a84c','#e8c97a','#4caf50','#f5f0e8','#e07070','#7ab0e0','#b07ae0'];

    const particles = Array.from({ length: 110 }, () => ({
      x:    cx + (Math.random() - 0.5) * 50,
      y:    cy + (Math.random() - 0.5) * 20,
      vx:   (Math.random() - 0.5) * 10,
      vy:   -(Math.random() * 9 + 2),
      r:    Math.random() * 5 + 2,
      rot:  Math.random() * 360,
      rotV: (Math.random() - 0.5) * 8,
      color: PALETTE[Math.floor(Math.random() * PALETTE.length)],
      life: 1
    }));

    cancelAnimationFrame(_confAF);

    (function draw() {
      ctx.clearRect(0, 0, CC.width, CC.height);
      let alive = false;

      particles.forEach((p) => {
        p.x   += p.vx;
        p.y   += p.vy;
        p.vy  += 0.2;
        p.vx  *= 0.98;
        p.rot += p.rotV;
        p.life -= 0.013;
        if (p.life <= 0) return;
        alive = true;

        ctx.save();
        ctx.globalAlpha = p.life;
        ctx.translate(p.x, p.y);
        ctx.rotate(p.rot * Math.PI / 180);
        ctx.fillStyle = p.color;
        ctx.fillRect(-p.r / 2, -p.r / 2, p.r, p.r * 0.55);
        ctx.restore();
      });

      if (alive) _confAF = requestAnimationFrame(draw);
      else ctx.clearRect(0, 0, CC.width, CC.height);
    })();
  }

  return { canvasRef, fireConfetti };
}
