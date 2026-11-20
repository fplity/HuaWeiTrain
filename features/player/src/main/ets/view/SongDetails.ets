import { MusicIcon, MusicTheme, Song } from '@cloudmusic/commons';
import { TrackNote, TrackNotes } from '../service/TrackNotes';

@ComponentV2
export struct SongDetails {
  @Require @Param song: Song;
  @Require @Param playing: boolean;
  @Require @Param onToggle: () => void;
  @Require @Param onReturn: () => void;

  private get note(): TrackNote | undefined {
    return TrackNotes.find(this.song.id);
  }

  private metricValue(label: string): string {
    if (label === '曲风') {
      return this.note?.genre ?? '暂未收录';
    }
    const tempo = this.note?.tempo;
    return tempo ? '约 ' + tempo.toString() + ' BPM' : '暂未测定';
  }

  @Builder
  metric(label: string) {
    Column({ space: 8 }) {
      Text(label)
        .fontSize(12)
        .fontColor(MusicTheme.playerMuted)
      Text(this.metricValue(label))
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(MusicTheme.playerText)
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
    .padding({ left: 14, right: 12, top: 13, bottom: 13 })
    .backgroundColor('#29FFFFFF')
    .borderRadius(14)
  }

  build() {
    Column({ space: 18 }) {
      Row({ space: 7 }) {
        MusicIcon({ name: 'music', iconSize: 16, tint: MusicTheme.playerAccent })
        Text('歌曲资料')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(MusicTheme.playerAccent)
      }

      Row({ space: 14 }) {
        if (this.song.coverUrl.startsWith('rawfile:')) {
          Image($rawfile(this.song.coverUrl.substring(8)))
            .width(76)
            .height(76)
            .sourceSize({ width: 160, height: 160 })
            .objectFit(ImageFit.Cover)
            .borderRadius(13)
            .draggable(false)
            .accessibilityLevel('no')
        }
        Column({ space: 5 }) {
          Text(this.song.title)
            .id('track-details-title')
            .fontSize(29)
            .fontWeight(FontWeight.Bold)
            .fontColor(MusicTheme.playerText)
          Text(this.song.artist)
            .fontSize(14)
            .fontColor(MusicTheme.playerMuted)
          if (this.song.album && this.song.album !== this.song.title) {
            Text('《' + this.song.album + '》')
              .fontSize(12)
              .fontColor(MusicTheme.playerMuted)
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      if (this.note) {
        Row({ space: 10 }) {
          this.metric('曲风')
          this.metric('参考速度')
        }
        .width('100%')

        Column({ space: 13 }) {
          Text('背景介绍')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(MusicTheme.playerText)
          Text(this.note.introduction)
            .fontSize(15)
            .lineHeight(24)
            .fontColor(MusicTheme.playerText)
          Divider().color('#34FFFFFF')
          Text('节奏听感')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor(MusicTheme.playerAccent)
          Text(this.note.rhythm)
            .fontSize(14)
            .lineHeight(21)
            .fontColor(MusicTheme.playerMuted)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding(17)
        .borderRadius(17)
        .backgroundColor('#2819121C')
        .border({ width: 1, color: '#36FFFFFF' })
      } else {
        Text('曲风、速度和背景介绍暂未收录')
          .fontSize(14)
          .fontColor(MusicTheme.playerMuted)
      }

      Row({ space: 10 }) {
        Button('返回播放页')
          .id('track-details-return')
          .height(44)
          .fontSize(14)
          .fontColor(MusicTheme.playerText)
          .backgroundColor('#2BFFFFFF')
          .onClick(this.onReturn)
        Button(this.playing ? '暂停' : '播放')
          .id('track-details-toggle')
          .height(44)
          .fontSize(14)
          .fontColor(MusicTheme.ink)
          .backgroundColor(MusicTheme.playerAccent)
          .onClick(this.onToggle)
      }
      .width('100%')
    }
    .width('100%')
    .constraintSize({ maxWidth: 640 })
    .alignItems(HorizontalAlign.Start)
    .padding({ left: 24, right: 24, top: 22, bottom: 26 })
  }
}
