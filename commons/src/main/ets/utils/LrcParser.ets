export interface LyricLine {
  timeMs: number;
  text: string;
}

export function parseLrc(source: string): LyricLine[] {
  const lines: LyricLine[] = [];
  const offset = Number(source.match(/\[offset:([+-]?\d+)\]/i)?.[1] ?? 0);
  for (const row of source.split(/\r?\n/)) {
    const timestamp = /\[(\d{1,3}):([0-5]\d)(?:[.:](\d{1,3}))?\]/g;
    const text = row.replace(timestamp, '').trim();
    if (!text) {
      continue;
    }
    let match = timestamp.exec(row);
    while (match) {
      const minutes = Number(match[1]);
      const seconds = Number(match[2]);
      const millis = Number((match[3] ?? '').padEnd(3, '0'));
      lines.push({ timeMs: Math.max(0, (minutes * 60 + seconds) * 1000 + millis - offset), text: text });
      match = timestamp.exec(row);
    }
  }
  return lines.sort((first: LyricLine, second: LyricLine) => first.timeMs - second.timeMs);
}

export function lyricIndexAt(lines: LyricLine[], positionMs: number): number {
  let low = 0;
  let high = lines.length;
  while (low < high) {
    const middle = Math.floor((low + high) / 2);
    if (lines[middle].timeMs <= positionMs) {
      low = middle + 1;
    } else {
      high = middle;
    }
  }
  return low - 1;
}
