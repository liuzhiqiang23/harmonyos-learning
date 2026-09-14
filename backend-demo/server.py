"""最小后端练习服务：只用 Python 标准库，不需要 pip 装任何东西。

启动：  python server.py
然后浏览器打开 http://127.0.0.1:8787/ 能看到数据。

给客户端用的接口：
    GET /api/movies    -> {"code":0,"message":"ok","data":[{...}]}
    GET /api/movies/3  -> 只返回 id=3 的那一条

鸿蒙端用 @kit.NetworkKit 的 http 调这个接口；以后微信小程序端用 wx.request
调的是同一个地址，所以这个后端是两端共用的。

注意：局域网里的真机要访问时，把地址换成下面打印的 LAN 地址；
并且手机和电脑要在同一个 WiFi 下。
"""

import json
import socket
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = 8787

MOVIES = [
    {"id": 1, "title": "肖申克的救赎", "year": 1994, "rating": 9.7, "genre": "剧情"},
    {"id": 2, "title": "霸王别姬", "year": 1993, "rating": 9.6, "genre": "剧情"},
    {"id": 3, "title": "阿甘正传", "year": 1994, "rating": 9.5, "genre": "剧情"},
    {"id": 4, "title": "千与千寻", "year": 2001, "rating": 9.4, "genre": "动画"},
    {"id": 5, "title": "星际穿越", "year": 2014, "rating": 9.4, "genre": "科幻"},
    {"id": 6, "title": "盗梦空间", "year": 2010, "rating": 9.4, "genre": "科幻"},
    {"id": 7, "title": "让子弹飞", "year": 2010, "rating": 9.0, "genre": "喜剧"},
    {"id": 8, "title": "流浪地球2", "year": 2023, "rating": 8.3, "genre": "科幻"},
]


class Handler(BaseHTTPRequestHandler):
    server_version = "HarmonyDemo/1.0"

    def _send_json(self, obj, status=200):
        body = json.dumps(obj, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        # 跨域放开，方便以后小程序/H5 端直接调
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        path = self.path.split("?")[0]
        print("[{}] {} {}".format(self.log_date_time_string(), "GET", path))

        if path == "/api/movies":
            self._send_json({"code": 0, "message": "ok", "data": MOVIES, "total": len(MOVIES)})
            return

        if path.startswith("/api/movies/"):
            raw = path[len("/api/movies/"):]
            if raw.isdigit():
                mid = int(raw)
                hit = [m for m in MOVIES if m["id"] == mid]
                if hit:
                    self._send_json({"code": 0, "message": "ok", "data": hit[0]})
                else:
                    self._send_json({"code": 404, "message": "movie not found", "data": None}, 404)
                return
            self._send_json({"code": 400, "message": "bad id", "data": None}, 400)
            return

        if path in ("/", "/index.html"):
            rows = "".join(
                "<tr><td>{}</td><td>{}</td><td>{}</td><td>{}</td><td>{}</td></tr>".format(
                    m["id"], m["title"], m["year"], m["rating"], m["genre"]
                )
                for m in MOVIES
            )
            html = (
                "<!doctype html><meta charset='utf-8'>"
                "<title>后端练习服务</title>"
                "<h2>后端跑起来了</h2>"
                "<p>接口地址：<a href='/api/movies'>/api/movies</a></p>"
                "<table border='1' cellpadding='6' style='border-collapse:collapse'>"
                "<tr><th>id</th><th>片名</th><th>年份</th><th>评分</th><th>类型</th></tr>"
                + rows
                + "</table>"
            ).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(html)))
            self.end_headers()
            self.wfile.write(html)
            return

        self._send_json({"code": 404, "message": "no such path", "data": None}, 404)

    def log_message(self, fmt, *args):
        # 默认日志会往 stderr 写一行，这里保留但统一走 print，方便重定向到文件
        pass


def lan_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("223.5.5.5", 80))
        return s.getsockname()[0]
    except Exception:
        return "127.0.0.1"
    finally:
        s.close()


if __name__ == "__main__":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

    srv = ThreadingHTTPServer(("0.0.0.0", PORT), Handler)
    print("=" * 58)
    print("后端已启动，共 {} 条数据".format(len(MOVIES)))
    print("  本机访问(预览器用这个):  http://127.0.0.1:{}/api/movies".format(PORT))
    print("  局域网访问(真机/手机用): http://{}:{}/api/movies".format(lan_ip(), PORT))
    print("  浏览器直接看效果:        http://127.0.0.1:{}/".format(PORT))
    print("  停止服务: Ctrl+C")
    print("=" * 58)
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        print("\n已停止")
