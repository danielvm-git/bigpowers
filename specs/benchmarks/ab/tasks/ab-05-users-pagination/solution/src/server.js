import http from "http";
import url from "url";

const users = Array.from({ length: 50 }, (_, i) => ({
  id: i + 1,
  name: `User ${i + 1}`,
  email: `user${i + 1}@example.com`,
}));

const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url, true);
  const { pathname } = parsedUrl;

  if (pathname === "/users" && req.method === "GET") {
    const page = Math.max(1, parseInt(parsedUrl.query.page, 10) || 1);
    const limit = Math.max(1, parseInt(parsedUrl.query.limit, 10) || 10);
    const start = (page - 1) * limit;
    res.writeHead(200, {
      "Content-Type": "application/json",
      "X-Total-Count": String(users.length),
    });
    res.end(JSON.stringify(users.slice(start, start + limit)));
    return;
  }

  res.writeHead(404);
  res.end();
});

const PORT = process.env.TEST_PORT || 0;
server.listen(PORT, () => {
  const { port } = server.address();
  console.log(`Server listening on port ${port}`);
  if (process.send) {
    process.send({ port });
  }
});

export default server;
