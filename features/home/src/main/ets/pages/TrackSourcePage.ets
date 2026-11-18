import { webview } from '@kit.ArkWeb';
import { Song } from '@cloudmusic/commons';
import { HomeTheme } from '../view/HomeTheme';

@ComponentV2
export struct TrackSourcePage {
  @Require @Param song: Song;
  @Local loadFailed: boolean = false;
  @Local showingLyrics: boolean = false;
  private readonly controller: webview.WebviewController = new webview.WebviewController();

  private show(lyrics: boolean): void {
    const url = lyrics ? this.song.lyricsPageUrl : this.song.sourcePageUrl;
    if (url && this.showingLyrics !== lyrics) {
      this.loadFailed = false;
      this.showingLyrics = lyrics;
      this.controller.loadUrl(url);
    }
  }

  build() {
    NavDestination() {
      Column({ space: HomeTheme.sm }) {
        Text(this.song.artist)
          .fontSize(HomeTheme.body)
          .fontColor(HomeTheme.textPrimary)
        Text('在线试听由 Apple Music 提供')
          .fontSize(HomeTheme.caption)
          .fontColor(HomeTheme.textSecondary)
        if (this.song.lyricsPageUrl) {
          Row({ space: HomeTheme.sm }) {
            Button('试听')
              .fontColor(HomeTheme.accent)
              .backgroundColor(HomeTheme.accentSurface)
              .enabled(this.showingLyrics)
              .onClick(() => { this.show(false); })
            Button('歌词')
              .fontColor(HomeTheme.accent)
              .backgroundColor(HomeTheme.accentSurface)
              .enabled(!this.showingLyrics)
              .onClick(() => { this.show(true); })
          }
        }
        if (this.loadFailed) {
          Text('音乐平台加载失败，请检查网络后重试。')
            .fontColor(HomeTheme.error)
          Button('重试').onClick(() => {
            this.loadFailed = false;
            this.controller.refresh();
          })
        }
        Web({ src: this.song.sourcePageUrl ?? '', controller: this.controller })
          .layoutWeight(1)
          .width('100%')
          .javaScriptAccess(true)
          .domStorageAccess(true)
          .onErrorReceive((event) => {
            if (event?.request.isMainFrame()) {
              this.loadFailed = true;
            }
          })
      }
      .padding({ left: HomeTheme.lg, right: HomeTheme.lg, bottom: HomeTheme.sm })
      .width('100%')
      .height('100%')
      .backgroundColor(HomeTheme.background)
    }
    .title(this.song.title)
  }
}
