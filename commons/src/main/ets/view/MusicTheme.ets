export class MusicTheme {
  static readonly background = $r('app.color.music_background');
  static readonly surface = $r('app.color.music_surface');
  static readonly textPrimary = $r('app.color.music_text_primary');
  static readonly textSecondary = $r('app.color.music_text_secondary');
  static readonly border = $r('app.color.music_border');
  static readonly accent = $r('app.color.music_accent');
  static readonly accentSurface = $r('app.color.music_accent_surface');
  static readonly onAccent = $r('app.color.music_on_accent');
  static readonly surfaceAlt = $r('app.color.music_surface_alt');
  static readonly wine: string = '#A52646';
  static readonly ink: string = '#181218';
  static readonly playerText: string = '#FFF6F8';
  static readonly playerMuted: string = '#D6BCC8';
  static readonly playerAccent: string = '#F7A0B5';
  static readonly playerTrack: string = '#38FFFFFF';
  static readonly error = $r('app.color.music_error');
  static readonly errorSurface = $r('app.color.music_error_surface');

  static readonly xs: number = 4;
  static readonly sm: number = 8;
  static readonly md: number = 12;
  static readonly lg: number = 16;
  static readonly xl: number = 24;
  static readonly radiusSm: number = 8;
  static readonly radiusMd: number = 12;
  static readonly radiusLg: number = 20;
  static readonly title: number = 32;
  static readonly section: number = 20;
  static readonly body: number = 16;
  static readonly caption: number = 13;

  private static readonly coverBackgrounds: string[] = ['#62424D', '#42435A', '#824A57', '#615548', '#4C454D'];
  private static readonly coverAccents: string[] = ['#DDAEBC', '#B9B9D5', '#F2B6C4', '#D8BD9B', '#C9B4C4'];

  static artworkBackground(id: number): string {
    return MusicTheme.coverBackgrounds[id % MusicTheme.coverBackgrounds.length];
  }

  static artworkAccent(id: number): string {
    return MusicTheme.coverAccents[id % MusicTheme.coverAccents.length];
  }
}
