@ComponentV2
export struct MusicIcon {
  @Param name: string = 'disc';
  @Param iconSize: number = 24;
  @Param tint: ResourceColor = Color.White;

  build() {
    Image($r('app.media.echo_' + this.name))
      .width(this.iconSize)
      .height(this.iconSize)
      .objectFit(ImageFit.Contain)
      .fillColor(this.tint)
      .draggable(false)
      .accessibilityLevel('no')
  }
}
