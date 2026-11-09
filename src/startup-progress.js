export function startLoadingBar(output) {
  if (!output.isTTY) return () => {};

  const width = 18;
  const marker = '===';
  const started = performance.now();
  let position = 0;
  const draw = () => {
    const elapsed = Math.floor((performance.now() - started) / 1000);
    output.cursorTo(0);
    output.write(`[${'-'.repeat(position)}${marker}${'-'.repeat(width - marker.length - position)}] Loading model (${elapsed}s)`);
    position = (position + 1) % (width - marker.length + 1);
  };
  draw();
  const timer = setInterval(draw, 150);
  return () => {
    clearInterval(timer);
    output.clearLine(0);
    output.cursorTo(0);
  };
}
