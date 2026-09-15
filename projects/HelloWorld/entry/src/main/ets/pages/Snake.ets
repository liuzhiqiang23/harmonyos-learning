import { router } from '@kit.ArkUI';

// 贪吃蛇：纯 ArkUI Canvas 手写，没有用任何游戏引擎。
// 棋盘 20x20 格，每 200ms 走一格（setInterval），所以模拟器再卡也不会崩——
// 比打砖块那种每帧算物理的游戏适合在模拟器上跑得多。
// 方向用屏幕上的方向键按钮，比滑动手势好按，也方便自动化测试点击。

const COLS: number = 20;
const ROWS: number = 20;
const TICK_MS: number = 200;

interface Point {
  x: number;
  y: number;
}

@Entry
@Component
struct Snake {
  @State score: number = 0;
  @State best: number = 0;
  @State running: boolean = false;
  @State paused: boolean = false;
  @State gameOver: boolean = false;
  @State status: string = '按「开始」出发';

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private snake: Point[] = [];
  private food: Point = { x: 0, y: 0 };
  // dir 是上一帧实际走的方向，pending 是玩家按下的下一个方向。
  // 分成两个变量是为了防止两次快速按键把蛇原地掉头（会直接咬到自己）。
  private dirX: number = 1;
  private dirY: number = 0;
  private pendingX: number = 1;
  private pendingY: number = 0;
  private timerId: number = -1;
  private ready: boolean = false;

  // 离开页面要把定时器停掉，否则返回列表后它还在后台跑
  aboutToDisappear(): void {
    this.stopLoop();
  }

  reset(): void {
    const cx = Math.floor(COLS / 2);
    const cy = Math.floor(ROWS / 2);
    const a: Point = { x: cx, y: cy };
    const b: Point = { x: cx - 1, y: cy };
    const c: Point = { x: cx - 2, y: cy };
    this.snake = [a, b, c];
    this.dirX = 1;
    this.dirY = 0;
    this.pendingX = 1;
    this.pendingY = 0;
    this.score = 0;
    this.gameOver = false;
    this.paused = false;
    this.placeFood();
    this.draw();
  }

  isOnSnake(x: number, y: number): boolean {
    for (let i = 0; i < this.snake.length; i++) {
      if (this.snake[i].x === x && this.snake[i].y === y) {
        return true;
      }
    }
    return false;
  }

  placeFood(): void {
    for (let tries = 0; tries < 500; tries++) {
      const fx = Math.floor(Math.random() * COLS);
      const fy = Math.floor(Math.random() * ROWS);
      if (!this.isOnSnake(fx, fy)) {
        const f: Point = { x: fx, y: fy };
        this.food = f;
        return;
      }
    }
  }

  startLoop(): void {
    this.stopLoop();
    this.timerId = setInterval(() => {
      this.tick();
    }, TICK_MS);
  }

  stopLoop(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  tick(): void {
    this.dirX = this.pendingX;
    this.dirY = this.pendingY;

    const head = this.snake[0];
    const nx = head.x + this.dirX;
    const ny = head.y + this.dirY;

    if (nx < 0 || ny < 0 || nx >= COLS || ny >= ROWS) {
      this.end('撞墙了');
      return;
    }
    // 注意排除最后一节：尾巴这一帧会移走，走进它原来的格子是合法的
    for (let i = 0; i < this.snake.length - 1; i++) {
      if (this.snake[i].x === nx && this.snake[i].y === ny) {
        this.end('咬到自己了');
        return;
      }
    }

    const nh: Point = { x: nx, y: ny };
    this.snake.unshift(nh);
    if (nx === this.food.x && ny === this.food.y) {
      this.score += 1;
      if (this.score > this.best) {
        this.best = this.score;
      }
      this.placeFood();
      this.status = '吃到啦，得分 ' + this.score;
    } else {
      this.snake.pop();
    }
    this.draw();
  }

  end(reason: string): void {
    this.stopLoop();
    this.running = false;
    this.gameOver = true;
    this.status = '游戏结束：' + reason + '，得分 ' + this.score;
    this.draw();
  }

  start(): void {
    if (this.gameOver) {
      this.reset();
    }
    this.running = true;
    this.paused = false;
    this.status = '进行中';
    this.startLoop();
    this.draw();
  }

  pause(): void {
    this.stopLoop();
    this.running = false;
    this.paused = true;
    this.status = '已暂停，按「继续」接着走';
  }

  setDir(x: number, y: number): void {
    if (!this.running) {
      return;
    }
    // 不能原地掉头：新方向和当前实际方向相反就忽略
    if (this.dirX + x === 0 && this.dirY + y === 0) {
      return;
    }
    this.pendingX = x;
    this.pendingY = y;
  }

  draw(): void {
    if (!this.ready) {
      return;
    }
    const w = this.ctx.width;
    const h = this.ctx.height;
    const cell = w / COLS;

    this.ctx.fillStyle = '#121A22';
    this.ctx.fillRect(0, 0, w, h);

    // 网格
    this.ctx.strokeStyle = '#1D2A36';
    this.ctx.lineWidth = 1;
    for (let i = 1; i < COLS; i++) {
      this.ctx.beginPath();
      this.ctx.moveTo(i * cell, 0);
      this.ctx.lineTo(i * cell, h);
      this.ctx.stroke();
      this.ctx.beginPath();
      this.ctx.moveTo(0, i * cell);
      this.ctx.lineTo(w, i * cell);
      this.ctx.stroke();
    }

    // 食物（红球）
    this.ctx.fillStyle = '#E64545';
    this.ctx.beginPath();
    this.ctx.arc((this.food.x + 0.5) * cell, (this.food.y + 0.5) * cell, cell * 0.33, 0, Math.PI * 2);
    this.ctx.fill();

    // 蛇身（头亮一点）
    for (let i = 0; i < this.snake.length; i++) {
      const p = this.snake[i];
      this.ctx.fillStyle = i === 0 ? '#8BE06A' : '#3FA34D';
      this.ctx.fillRect(p.x * cell + 1, p.y * cell + 1, cell - 2, cell - 2);
    }
  }

  build() {
    Column({ space: 10 }) {
      Row({ space: 8 }) {
        Button('← 返回')
          .fontSize(14)
          .onClick(() => {
            router.back();
          })

        Text('贪吃蛇').fontSize(20).fontWeight(FontWeight.Bold).layoutWeight(1)

        Text('得分 ' + this.score)
          .fontSize(15)
          .fontColor('#E64545')
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')

      Text(this.status)
        .fontSize(12)
        .fontColor('#888888')
        .width('100%')

      // 棋盘 + 未在游戏时的遮罩
      Stack({ alignContent: Alignment.Center }) {
        Canvas(this.ctx)
          .width('100%')
          .height('100%')
          .onReady(() => {
            this.ready = true;
            this.reset();
          })

        if (!this.running) {
          Column({ space: 12 }) {
            Text(this.gameOver ? '游戏结束' : (this.paused ? '已暂停' : '准备好了吗'))
              .fontSize(22)
              .fontColor('#FFFFFF')
              .fontWeight(FontWeight.Bold)

            Text(this.gameOver
              ? '得分 ' + this.score + '　最高 ' + this.best
              : (this.paused ? '当前得分 ' + this.score : '方向键控制，吃红点加分'))
              .fontSize(13)
              .fontColor('#DDDDDD')

            Button(this.gameOver ? '再来一局' : (this.paused ? '继续' : '开始'))
              .fontSize(16)
              .onClick(() => {
                this.start();
              })
          }
          .width('100%')
          .height('100%')
          .backgroundColor('#99000000')
          .justifyContent(FlexAlign.Center)
        }
      }
      .width('100%')
      .aspectRatio(1)
      .borderRadius(10)
      .clip(true)

      Row({ space: 10 }) {
        Button(this.running ? '暂停' : '继续')
          .fontSize(14)
          .layoutWeight(1)
          .enabled(this.running || this.paused)
          .onClick(() => {
            if (this.running) {
              this.pause();
            } else {
              this.start();
            }
          })

        Button('重开')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => {
            this.stopLoop();
            this.running = false;
            this.status = '已重开，按「开始」出发';
            this.reset();
          })
      }
      .width('100%')

      // 方向键
      Column({ space: 8 }) {
        Button('▲')
          .fontSize(18)
          .width(72)
          .height(44)
          .onClick(() => {
            this.setDir(0, -1);
          })

        Row({ space: 8 }) {
          Button('◀')
            .fontSize(18)
            .width(72)
            .height(44)
            .onClick(() => {
              this.setDir(-1, 0);
            })

          Button('▼')
            .fontSize(18)
            .width(72)
            .height(44)
            .onClick(() => {
              this.setDir(0, 1);
            })

          Button('▶')
            .fontSize(18)
            .width(72)
            .height(44)
            .onClick(() => {
              this.setDir(1, 0);
            })
        }
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding(16)
  }
}
