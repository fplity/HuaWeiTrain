import { MusicIcon } from '@cloudmusic/commons';
import { BannerItem } from '../model/HomeData';
import { FeedArtwork } from './FeedArtwork';

@ComponentV2
export struct BannerSwiper {
  @Param banners: BannerItem[] = [];
  @Require @Param onPlaylist: (id: number) => void;

  build() {
    Swiper() {
      ForEach(this.banners, (item: BannerItem) => {
        Stack({ alignContent: Alignment.BottomStart }) {
          FeedArtwork({ src: item.imageUrl, artworkId: item.id, wide: true })
          Row()
            .width('100%')
            .height('100%')
            .linearGradient({
              direction: GradientDirection.Right,
              colors: [['#DD130F17', 0], ['#80130F17', 0.43], ['#10130F17', 1]]
            })
          Row()
            .width('100%')
            .height('100%')
            .linearGradient({
              direction: GradientDirection.Bottom,
              colors: [['#00130F17', 0.23], ['#8A130F17', 1]]
            })

          Column({ space: 14 }) {
            Text(item.title || '推荐专题')
              .fontSize(29)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFF7F1')
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            if (Number.isSafeInteger(item.targetId) && item.targetId > 0) {
              Row({ space: 7 }) {
                MusicIcon({ name: 'arrow', iconSize: 14, tint: '#2C2029' })
                Text('打开歌单').fontSize(12).fontWeight(FontWeight.Bold).fontColor('#2C2029')
              }
              .padding({ left: 11, right: 14, top: 8, bottom: 8 })
              .backgroundColor('#FFF7F0')
              .borderRadius(20)
            }
          }
          .width('74%')
          .alignItems(HorizontalAlign.Start)
          .padding({ left: 18, bottom: 28 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#2C2029')
        .id('discover-banner-' + item.id.toString())
        .accessibilityText(item.title || '推荐专题')
        .focusable(Number.isSafeInteger(item.targetId) && item.targetId > 0)
        .onClick(() => {
          if (Number.isSafeInteger(item.targetId) && item.targetId > 0) {
            this.onPlaylist(item.targetId);
          }
        })
      }, (item: BannerItem) => item.id.toString() + '|' + item.imageUrl + '|' + (item.title ?? ''))
    }
    .height(195)
    .width('100%')
    .indicator(this.banners.length > 1 ?
      new DotIndicator().itemWidth(5).itemHeight(5).selectedItemWidth(14).selectedItemHeight(5)
        .color('#80FFF7F0').selectedColor('#FFF7F0').bottom(12).right(14) : false)
    .autoPlay(this.banners.length > 1)
    .loop(this.banners.length > 1)
    .interval(6000)
    .borderRadius(20)
    .clip(true)
  }
}
