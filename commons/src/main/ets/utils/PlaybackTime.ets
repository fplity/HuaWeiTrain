export function formatPlaybackTime(ms: number): string {
  const seconds = Number.isFinite(ms) ? Math.max(0, Math.floor(ms / 1000)) : 0;
  return Math.floor(seconds / 60).toString() + ':' + (seconds % 60).toString().padStart(2, '0');
}
