import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 本机后端地址。预览器跑在电脑上，所以 127.0.0.1 就是这台电脑。
// 真机调试时换成后端启动时打印的局域网地址，例如 http://192.168.1.5:8787
const API_BASE: string = 'http://127.0.0.1:8787';

// ArkTS 是强类型的：接口返回的数据要先定义成 interface，不能像 JS 那样随便用
interface Movie {
  id: number;
  title: string;
  year: number;
  rating: number;
  genre: string;
}

interface ApiResult {
  code: number;
  message: string;
  data: Movie[];
  total: number;
}

@Entry
@Component
struct Index {
  @State movies: Movie[] = [];
  @State status: string = '还没开始加载';
  @State loading: boolean = false;

  aboutToAppear(): void {
    // 页面创建时自动加载一次
    this.loadMovies();
  }

  loadMovies(): void {
    this.loading = true;
    this.status = '正在请求 ' + API_BASE + '/api/movies ...';

    const req = http.createHttp();
    req.request(API_BASE + '/api/movies', {
      method: http.RequestMethod.GET,
      connectTimeout: 8000,
      readTimeout: 8000,
      expectDataType: http.HttpDataType.STRING
    }, (err: BusinessError, resp: http.HttpResponse) => {
      this.loading = false;

      if (err) {
        // 失败原因直接显示在界面上，方便排查（比如忘了开后端、权限没加）
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
        const parsed = JSON.parse(resp.result as string) as ApiResult;
        this.movies = parsed.data;
        this.status = '成功：从服务器拿到 ' + this.movies.length + ' 条数据';
      } catch (e) {
        this.status = '解析 JSON 失败：' + JSON.stringify(e);
      }
      req.destroy();
    });
  }

  build() {
    Column({ space: 12 }) {
      Text('电影列表').fontSize(22).fontWeight(FontWeight.Bold)

      Text(this.status)
        .fontSize(12)
        .fontColor('#888888')
        .maxLines(4)
        .width('100%')

      Button(this.loading ? '加载中...' : '重新加载')
        .width('100%')
        .enabled(!this.loading)
        .onClick(() => {
          this.loadMovies();
        })

      List({ space: 10 }) {
        ForEach(this.movies, (m: Movie) => {
          ListItem() {
            Row() {
              Column({ space: 4 }) {
                Text(m.title).fontSize(16).fontWeight(FontWeight.Medium)
                Text(m.genre + ' · ' + m.year).fontSize(12).fontColor('#999999')
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Text(m.rating.toFixed(1))
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#E64545')
            }
            .width('100%')
            .padding(12)
          }
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
        }, (m: Movie) => m.id.toString())
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding(16)
  }
}
