const MEDIUM_WIDTH = 600;
const EXPANDED_WIDTH = 840;

export const MUSIC_GRID_BREAKPOINTS: string[] = [`${MEDIUM_WIDTH}vp`, `${EXPANDED_WIDTH}vp`];
export const EXPANDED_CONTENT_WIDTH = 1200;

export type WindowBreakpoint = 'compact' | 'medium' | 'expanded';

export function windowBreakpoint(width: number): WindowBreakpoint {
  if (width >= EXPANDED_WIDTH) {
    return 'expanded';
  }
  return width >= MEDIUM_WIDTH ? 'medium' : 'compact';
}
