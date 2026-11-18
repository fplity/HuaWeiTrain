import { AnimatorResult } from '@ohos.animator';
import { image } from '@kit.ImageKit';
import { http } from '@kit.NetworkKit';
import { MusicTheme } from '@cloudmusic/commons';

const MAX_COVER_BYTES: number = 8 * 1024 * 1024;
const MAX_DECODE_EDGE: number = 900;
const FULL_CIRCLE: number = 2 * Math.PI;

@ComponentV2
export struct DiscCanvas {
  @Param coverUrl: string = '';
  @Param artworkId: number = 0;
  @Param spinning: boolean = false;
  @Local angle: number = 0;
  private animator: AnimatorResult | undefined;

  @Monitor('spinning')
  syncRotation(): void {
    if (!this.spinning) {
      this.animator?.pause();
      return;
    }
    if (!this.animator) {
      this.animator = this.getUIContext().createAnimator({
        duration: 7500, easing: 'linear', delay: 0, fill: 'forwards',
        direction: 'normal', iterations: -1, begin: 0, end: 360
      });
      this.animator.onFrame = (angle: number) => { this.angle = angle; };
    }
    this.animator.play();
  }
  private readonly canvas: CanvasRenderingContext2D =
    new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private ready: boolean = false;
  private cover: image.PixelMap | undefined;
  private coverSize: image.Size | undefined;
  private download: http.HttpRequest | undefined;
  private revision: number = 0;

  @Monitor('coverUrl', 'artworkId')
  onArtworkChange(): void {
    this.refresh();
  }

  aboutToDisappear(): void {
    this.ready = false;
    this.animator?.cancel();
    this.animator = undefined;
    this.refresh();
  }

  private refresh(): void {
    const revision = ++this.revision;
    this.download?.destroy();
    this.download = undefined;
    const previous = this.cover;
    this.cover = undefined;
    this.coverSize = undefined;
    this.paint();
    previous?.release().catch(() => {});
    if (this.ready && this.coverUrl) {
      this.loadCover(revision, this.coverUrl);
    }
  }

  private async readArtwork(address: string): Promise<ArrayBuffer | undefined> {
    if (address.startsWith('rawfile:')) {
      const file = address.substring('rawfile:'.length);
      if (!/^(offline-cover-[a-z]+\.png|album-\d+\.jpg)$/.test(file)) {
        return undefined;
      }
      const resource = this.getUIContext().getHostContext()?.resourceManager;
      if (!resource) {
        return undefined;
      }
      const bytes = await resource.getRawFileContent(file);
      return bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength) as ArrayBuffer;
    }
    if (!address.startsWith('https://')) {
      return undefined;
    }
    const request = http.createHttp();
    this.download = request;
    try {
      const response = await request.request(address, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.ARRAY_BUFFER,
        connectTimeout: 5000,
        readTimeout: 8000,
        maxLimit: MAX_COVER_BYTES
      });
      if (response.responseCode >= 200 && response.responseCode < 300 && response.result instanceof ArrayBuffer &&
        response.result.byteLength <= MAX_COVER_BYTES) {
        return response.result;
      }
      return undefined;
    } finally {
      if (this.download === request) {
        this.download = undefined;
        request.destroy();
      }
    }
  }

  private async loadCover(revision: number, address: string): Promise<void> {
    let source: image.ImageSource | undefined;
    let bitmap: image.PixelMap | undefined;
    try {
      const bytes = await this.readArtwork(address);
      if (!bytes || !this.ready || revision !== this.revision) {
        return;
      }
      source = image.createImageSource(bytes);
      const info = await source.getImageInfo();
      const scale = Math.min(1, MAX_DECODE_EDGE / Math.max(info.size.width, info.size.height));
      bitmap = await source.createPixelMap({
        desiredSize: {
          width: Math.max(1, Math.round(info.size.width * scale)),
          height: Math.max(1, Math.round(info.size.height * scale))
        }
      });
      const decoded = await bitmap.getImageInfo();
      if (this.ready && revision === this.revision) {
        this.cover = bitmap;
        this.coverSize = decoded.size;
        bitmap = undefined;
        this.paint();
      }
    } catch (_) {
      // Keep the vinyl visible when the cover is unavailable.
    } finally {
      bitmap?.release().catch(() => {});
      source?.release().catch(() => {});
    }
  }

  private circle(x: number, y: number, radius: number): void {
    this.canvas.beginPath();
    this.canvas.arc(x, y, radius, 0, FULL_CIRCLE);
  }

  private paint(): void {
    if (!this.ready) {
      return;
    }
    const canvas = this.canvas;
    const x = canvas.width / 2;
    const y = canvas.height / 2;
    const radius = Math.min(x, y) * 0.9;
    if (radius <= 1) {
      return;
    }
    canvas.clearRect(0, 0, canvas.width, canvas.height);
    const vinyl = canvas.createLinearGradient(x - radius, y - radius, x + radius, y + radius);
    vinyl.addColorStop(0, '#564656');
    vinyl.addColorStop(0.46, '#201820');
    vinyl.addColorStop(1, '#100D13');
    this.circle(x, y, radius);
    canvas.fillStyle = vinyl;
    canvas.fill();
    canvas.strokeStyle = '#171017';
    canvas.lineWidth = 2;
    canvas.stroke();

    canvas.lineWidth = 1;
    canvas.strokeStyle = 'rgba(231, 204, 218, 0.14)';
    for (let groove = 0; groove < 9; groove++) {
      this.circle(x, y, radius * (0.74 + groove * 0.027));
      canvas.stroke();
    }

    const labelRadius = radius * 0.69;
    canvas.save();
    this.circle(x, y, labelRadius);
    canvas.clip();
    canvas.fillStyle = MusicTheme.artworkBackground(this.artworkId);
    canvas.fillRect(x - labelRadius, y - labelRadius, labelRadius * 2, labelRadius * 2);
    if (this.cover && this.coverSize) {
      const size = this.coverSize;
      const crop = Math.min(size.width, size.height);
      canvas.drawImage(this.cover, (size.width - crop) / 2, (size.height - crop) / 2, crop, crop,
        x - labelRadius, y - labelRadius, labelRadius * 2, labelRadius * 2);
    } else {
      this.circle(x, y, labelRadius * 0.58);
      canvas.fillStyle = MusicTheme.artworkAccent(this.artworkId);
      canvas.fill();
    }
    const gloss = canvas.createLinearGradient(x - labelRadius, y - labelRadius, x + labelRadius, y + labelRadius);
    gloss.addColorStop(0, 'rgba(255,255,255,0.22)');
    gloss.addColorStop(0.55, 'rgba(255,255,255,0)');
    canvas.fillStyle = gloss;
    canvas.fillRect(x - labelRadius, y - labelRadius, labelRadius * 2, labelRadius * 2);
    canvas.restore();

    this.circle(x, y, labelRadius);
    canvas.strokeStyle = '#2D202B';
    canvas.lineWidth = 2;
    canvas.stroke();
  }

  build() {
    Canvas(this.canvas)
      .width('100%')
      .height('100%')
      .accessibilityLevel('no')
      .rotate({ angle: this.angle })
      .onReady(() => {
        this.ready = true;
        this.refresh();
        this.syncRotation();
      })
      .onSizeChange(() => { this.paint(); })
  }
}
