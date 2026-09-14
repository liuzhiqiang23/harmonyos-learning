import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { router } from '@kit.ArkUI';

// movie-system 的推荐接口：POST /api/recommend
// algo 取值：demographic(热门，不用参数) | content(相似电影，要英文片名)
//            | user_knn/svd/knn_svd(要 userId) | movie_knn/keyword/usr_keywords…
// 注意：推荐要现场拉起 Python 引擎算，比普通接口慢很多，超时要给足。
const API_BASE: string = 'http://127.0.0.1:8000';

// 推荐结果单条（后端 RecommendItemVM）。movieId 也是 TMDB 影片 ID，可直接拼海报地址。
interface RecItem {
  title: string;
  movieId: number;
  score: number;
  voteAverage: number;
}

interface RecResponse {
  code: number;
  message: string;
  response: RecItem[];
}

@Entry
@Component
struct Recommend {
  @State items: RecItem[] = [];
  @State status: string = '选一种推荐方式';
  @State loading: boolean = false;
  @State algo: string = 'demographic';
  @State titleInput: string = '';

  aboutToAppear(): void {
    this.load();
  }

  load(): void {
    this.loading = true;
    this.status = '正在计算推荐（' + this.algo + '），要现场跑 Python 引擎，可能要等几秒...';

    let body = '{"algo":"' + this.algo + '","top":10';
    if (this.algo === 'content') {
      const t = this.titleInput.trim().split('"').join('\\"');
      body += ',"movieTitle":"' + t + '"';
    }
    body += '}';

    const req = http.createHttp();
    req.request(API_BASE + '/api/recommend', {
      method: http.RequestMethod.POST,
      header: { 'Content-Type': 'application/json' },
      extraData: body,
      connectTimeout: 8000,
      readTimeout: 60000,
      expectDataType: http.HttpDataType.STRING
    }, (err: BusinessError, resp: http.HttpResponse) => {
      this.loading = false;

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
        const parsed = JSON.parse(resp.result as string) as RecResponse;
        if (parsed.code !== 1) {
          // content 算法常见错误：片名不在数据集里（要英文原名）
          this.items = [];
          this.status = '后端返回错误：' + parsed.message;
        } else {
          this.items = parsed.response;
          this.status = '拿到 ' + this.items.length + ' 条推荐';
        }
      } catch (e) {
        this.status = '解析 JSON 失败：' + JSON.stringify(e);
      }
      req.destroy();
    });
  }

  @Builder
  recItem(m: RecItem) {
    Row({ space: 12 }) {
      Image(API_BASE + '/posters/' + m.movieId + '.jpg')
        .width(56)
        .height(80)
        .objectFit(ImageFit.Cover)
        .borderRadius(6)
        .alt($r('app.media.icon'))

      Column({ space: 4 }) {
        Text(m.title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text('匹配分 ' + (m.score ? m.score.toFixed(3) : '-'))
          .fontSize(12)
          .fontColor('#999999')

        Text('评分 ' + (m.voteAverage ? m.voteAverage.toFixed(1) : '-'))
          .fontSize(13)
          .fontColor('#E64545')
          .fontWeight(FontWeight.Bold)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(10)
  }

  build() {
    Column({ space: 10 }) {
      Row({ space: 8 }) {
        Button('← 返回')
          .fontSize(14)
          .onClick(() => {
            router.back();
          })

        Text('猜你喜欢').fontSize(20).fontWeight(FontWeight.Bold).layoutWeight(1)
      }
      .width('100%')

      Row({ space: 8 }) {
        Button(this.algo === 'demographic' ? '● 热门推荐' : '热门推荐')
          .layoutWeight(1)
          .backgroundColor(this.algo === 'demographic' ? '#2F7FD1' : '#DDDDDD')
          .fontColor(this.algo === 'demographic' ? '#FFFFFF' : '#333333')
          .enabled(!this.loading)
          .onClick(() => {
            this.algo = 'demographic';
            this.load();
          })

        Button(this.algo === 'content' ? '● 相似电影' : '相似电影')
          .layoutWeight(1)
          .backgroundColor(this.algo === 'content' ? '#2F7FD1' : '#DDDDDD')
          .fontColor(this.algo === 'content' ? '#FFFFFF' : '#333333')
          .enabled(!this.loading)
          .onClick(() => {
            this.algo = 'content';
          })
      }
      .width('100%')

      if (this.algo === 'content') {
        TextInput({ placeholder: '输入英文片名，如 The Dark Knight', text: this.titleInput })
          .width('100%')
          .onChange((value: string) => {
            this.titleInput = value;
          })

        Button('找相似电影')
          .width('100%')
          .enabled(!this.loading && this.titleInput.trim() !== '')
          .onClick(() => {
            this.load();
          })
      } else {
        Button('刷新热门推荐')
          .width('100%')
          .enabled(!this.loading)
          .onClick(() => {
            this.load();
          })
      }

      Text(this.status)
        .fontSize(12)
        .fontColor('#888888')
        .maxLines(5)
        .width('100%')

      List({ space: 8 }) {
        ForEach(this.items, (m: RecItem) => {
          ListItem() {
            this.recItem(m)
          }
          .backgroundColor('#F7F7F7')
          .borderRadius(8)
        }, (m: RecItem) => m.movieId.toString())
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding(16)
  }
}
