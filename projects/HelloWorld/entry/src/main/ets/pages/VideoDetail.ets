import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { router } from '@kit.ArkUI';

// movie-system 的详情接口：POST /api/admin/video/getVideoDetailByVideoId/{videoId}
// videoId 就是 TMDB 影片 ID，跟列表、海报文件名用的是同一个号。
// 这个接口不需要登录（同页的 select/{id} 才要，会 500，别用）。
const API_BASE: string = 'http://192.168.82.214:8000';  // 电脑局域网 IP，换网段要改

class MovieDetail {
  videoId: number = 0;
  videoName: string = '';
  originalTitle: string = '';
  overview: string = '';
  tagline: string = '';
  voteAverage: number = 0;
  popularity: number = 0;
  releaseDate: string = '';
  videoPlayList: VideoPlay[] = [];
}

// 播放记录（后端 VideoPlay）。这批电影没有实际视频文件，videoUrl 是空的，
// 这里只取 playTimes 显示"被点开过多少次"。
interface VideoPlay {
  playTimes: number;
  lastPlayTime: string;
}

interface DetailResponse {
  code: number;
  message: string;
  response: MovieDetail;
}

// router 传参：{ videoId: 157336 }
interface DetailParams {
  videoId: number;
}

@Entry
@Component
struct VideoDetail {
  @State detail: MovieDetail = new MovieDetail();
  @State status: string = '正在加载详情...';
  @State loaded: boolean = false;
  @State playTimes: number = -1;        // -1 = 后端没有播放记录
  @State posterFailed: boolean = false; // 海报文件不存在时兜底成占位块
  @State showPoster: boolean = false;   // 全屏看大图
  private videoId: number = 0;

  aboutToAppear(): void {
    const p = router.getParams() as DetailParams;
    if (p === undefined || p === null) {
      this.status = '没有收到 videoId，请从列表页点进来';
      return;
    }
    this.videoId = p.videoId;
    if (!this.videoId) {
      this.status = '没有收到 videoId，请从列表页点进来';
      return;
    }
    this.load();
  }

  load(): void {
    // 这个接口是 POST + 路径参数，后端没有 @RequestBody，请求体会被忽略。
    // 但 extraData 不能留空字符串：实测传 '' 时 http 直接抛 401 Parameter error，
    // 给个空 JSON 对象就行。
    const req = http.createHttp();
    req.request(API_BASE + '/api/admin/video/getVideoDetailByVideoId/' + this.videoId, {
      method: http.RequestMethod.POST,
      header: { 'Content-Type': 'application/json' },
      extraData: '{}',
      connectTimeout: 8000,
      readTimeout: 10000,
      expectDataType: http.HttpDataType.STRING
    }, (err: BusinessError, resp: http.HttpResponse) => {
      if (err) {
        this.status = '请求失败：' + JSON.stringify(err);
        req.destroy();
        return;
      }
      if (resp.responseCode !== 200) {
        this.status = 'HTTP 状态码 ' + resp.responseCode;
        req.destroy();
        return;
      }
      try {
        const parsed = JSON.parse(resp.result as string) as DetailResponse;
        // 影片不存在时后端给的是 code=404，不是 HTTP 404，所以两层都要判
        if (parsed.code !== 1) {
          this.status = '后端返回：code=' + parsed.code + ' ' + parsed.message;
          req.destroy();
          return;
        }
        this.detail = parsed.response;
        const plays = parsed.response.videoPlayList;
        this.playTimes = (plays && plays.length > 0) ? plays[0].playTimes : -1;
        this.loaded = true;
        this.status = '';
      } catch (e) {
        this.status = '解析 JSON 失败：' + JSON.stringify(e);
      }
      req.destroy();
    });
  }

  posterUrl(): string {
    return API_BASE + '/posters/' + this.videoId + '.jpg';
  }

  @Builder
  field(label: string, value: string) {
    Row({ space: 8 }) {
      Text(label).fontSize(13).fontColor('#888888').width(64)
      Text(value).fontSize(13).layoutWeight(1)
    }
    .width('100%')
  }

  // 列表里那一小块海报：点了就全屏看大图。
  // 本地海报只有 4891 张、影片有 4908 部，缺图的那些后端会返回 200 + 一段 JSON 错误
  // （不是 404），图片解码会失败，所以用 onError 换成占位块，别让桌面图标被拉成海报。
  @Builder
  posterThumb() {
    if (this.posterFailed) {
      Column() {
        Text('暂无海报').fontSize(12).fontColor('#999999')
      }
      .width(110)
      .height(160)
      .backgroundColor('#EDEDED')
      .borderRadius(8)
      .justifyContent(FlexAlign.Center)
    } else {
      Stack({ alignContent: Alignment.TopStart }) {
        Image(this.posterUrl())
          .width(110)
          .height(160)
          .objectFit(ImageFit.Cover)
          .borderRadius(8)
          .onError(() => {
            this.posterFailed = true;
          })

        Text('点击看大图')
          .fontSize(10)
          .fontColor('#FFFFFF')
          .backgroundColor('#66000000')
          .padding({ left: 6, right: 6, top: 3, bottom: 3 })
          .borderRadius(4)
          .margin({ left: 6, top: 6 })
      }
      .width(110)
      .height(160)
      .onClick(() => {
        this.showPoster = true;
      })
    }
  }

  build() {
    Stack() {
      Column({ space: 10 }) {
        Row({ space: 8 }) {
          Button('← 返回')
            .fontSize(14)
            .onClick(() => {
              router.back();
            })

          Text('影片详情').fontSize(20).fontWeight(FontWeight.Bold).layoutWeight(1)
        }
        .width('100%')

        if (this.status !== '') {
          Text(this.status)
            .fontSize(13)
            .fontColor('#888888')
            .width('100%')
        }

        if (this.loaded) {
          Scroll() {
            Column({ space: 12 }) {
              Row({ space: 12 }) {
                this.posterThumb()

                Column({ space: 8 }) {
                  Text(this.detail.videoName)
                    .fontSize(19)
                    .fontWeight(FontWeight.Bold)
                    .maxLines(3)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  if (this.detail.originalTitle) {
                    Text(this.detail.originalTitle)
                      .fontSize(13)
                      .fontColor('#777777')
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }

                  Text('评分 ' + this.detail.voteAverage.toFixed(1))
                    .fontSize(15)
                    .fontColor('#E64545')
                    .fontWeight(FontWeight.Bold)

                  Text('热度 ' + this.detail.popularity.toFixed(1))
                    .fontSize(13)
                    .fontColor('#999999')
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
              }
              .width('100%')

              if (this.detail.tagline) {
                Text(this.detail.tagline)
                  .fontSize(13)
                  .fontColor('#666666')
                  .fontStyle(FontStyle.Italic)
                  .width('100%')
              }

              Divider()

              this.field('上映日期', this.detail.releaseDate ? this.detail.releaseDate : '后端未提供')
              this.field('影片 ID', this.detail.videoId.toString())
              this.field('播放次数', this.playTimes < 0 ? '暂无播放记录' : this.playTimes + ' 次')

              Divider()

              Text('剧情简介').fontSize(15).fontWeight(FontWeight.Bold).width('100%')
              Text(this.detail.overview ? this.detail.overview : '后端没有这部片的中文简介。')
                .fontSize(14)
                .lineHeight(22)
                .width('100%')

              Text('说明：这批影片只存了元数据，没有实际视频文件，所以详情页不做播放。')
                .fontSize(12)
                .fontColor('#AAAAAA')
                .width('100%')
            }
            .width('100%')
            .padding({ bottom: 20 })
          }
          .layoutWeight(1)
          .width('100%')
        } else {
          Blank().layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')
      .padding(16)

      // 全屏看大图：黑底 + 按比例完整显示（Contain 才不会被裁掉），点任意处关闭
      if (this.showPoster) {
        Column({ space: 16 }) {
          Image(this.posterUrl())
            .width('92%')
            .objectFit(ImageFit.Contain)

          Text('点击任意位置关闭')
            .fontSize(13)
            .fontColor('#BBBBBB')
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#000000')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.showPoster = false;
        })
      }
    }
    .width('100%')
    .height('100%')
  }
}
