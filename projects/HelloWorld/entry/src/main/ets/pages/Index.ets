import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';

// movie-system 后端（Spring Boot，跑在 8000 端口）。
// 真机调试时把 127.0.0.1 换成电脑的局域网地址。
const API_BASE: string = 'http://127.0.0.1:8000';
const PAGE_SIZE: number = 20;

// 列表接口返回的单条数据（对应后端 VideoResponseVM）
interface Movie {
  videoId: number;
  videoName: string;
  videoCategory: number;
  popularity: number;
  voteAverage: number;
}

// 分页信息（后端用的是 PageHelper，字段名是它自带的）
interface MoviePage {
  total: number;
  list: Movie[];
  pageNum: number;
  pages: number;
  hasPreviousPage: boolean;
  hasNextPage: boolean;
}

// 后端统一返回结构。注意：code === 1 才是成功，不是 0。
interface RestResponse {
  code: number;
  message: string;
  response: MoviePage;
}

@Entry
@Component
struct Index {
  @State movies: Movie[] = [];
  @State status: string = '还没开始加载';
  @State loading: boolean = false;
  @State pageIndex: number = 1;
  @State totalPages: number = 0;
  @State total: number = 0;

  aboutToAppear(): void {
    this.loadPage(1);
  }

  loadPage(page: number): void {
    this.loading = true;
    this.status = '正在请求第 ' + page + ' 页 ...';

    const req = http.createHttp();
    req.request(API_BASE + '/api/admin/video/page/list', {
      method: http.RequestMethod.POST,
      header: { 'Content-Type': 'application/json' },
      extraData: JSON.stringify({ pageIndex: page, pageSize: PAGE_SIZE }),
      connectTimeout: 8000,
      readTimeout: 10000,
      expectDataType: http.HttpDataType.STRING
    }, (err: BusinessError, resp: http.HttpResponse) => {
      this.loading = false;

      if (err) {
        // 把失败原因直接显示出来，方便排查（后端没启动、端口错、明文HTTP被拦等）
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
        const parsed = JSON.parse(resp.result as string) as RestResponse;
        if (parsed.code !== 1) {
          // 后端的业务错误也带着 HTTP 200 返回，必须看 code
          this.status = '后端返回错误：code=' + parsed.code + ' ' + parsed.message;
          req.destroy();
          return;
        }
        this.movies = parsed.response.list;
        this.pageIndex = parsed.response.pageNum;
        this.totalPages = parsed.response.pages;
        this.total = parsed.response.total;
        this.status = '第 ' + this.pageIndex + ' / ' + this.totalPages + ' 页，共 '
          + this.total + ' 部（本页 ' + this.movies.length + ' 条）';
      } catch (e) {
        this.status = '解析 JSON 失败：' + JSON.stringify(e);
      }
      req.destroy();
    });
  }

  @Builder
  movieItem(m: Movie) {
    Row({ space: 12 }) {
      // 海报：文件名就是 videoId（TMDB 影片 ID）。
      // 注意不是每部都有海报，缺图时接口返回的是 JSON 错误，所以要用 alt 兜底占位图。
      Image(API_BASE + '/posters/' + m.videoId + '.jpg')
        .width(64)
        .height(90)
        .objectFit(ImageFit.Cover)
        .borderRadius(6)
        .alt($r('app.media.icon'))

      Column({ space: 6 }) {
        Text(m.videoName)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text('热度 ' + m.popularity.toFixed(1))
          .fontSize(12)
          .fontColor('#999999')

        Text('评分 ' + m.voteAverage.toFixed(1))
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
      Text('电影列表').fontSize(22).fontWeight(FontWeight.Bold)

      Text(this.status)
        .fontSize(12)
        .fontColor('#888888')
        .maxLines(4)
        .width('100%')

      List({ space: 8 }) {
        ForEach(this.movies, (m: Movie) => {
          ListItem() {
            this.movieItem(m)
          }
          .backgroundColor('#F7F7F7')
          .borderRadius(8)
        }, (m: Movie) => m.videoId.toString())
      }
      .layoutWeight(1)
      .width('100%')

      Row({ space: 10 }) {
        Button('上一页')
          .layoutWeight(1)
          .enabled(!this.loading && this.pageIndex > 1)
          .onClick(() => {
            this.loadPage(this.pageIndex - 1);
          })

        Button('下一页')
          .layoutWeight(1)
          .enabled(!this.loading && this.pageIndex < this.totalPages)
          .onClick(() => {
            this.loadPage(this.pageIndex + 1);
          })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding(16)
  }
}
