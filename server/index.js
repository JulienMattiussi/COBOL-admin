const express = require("express");
const cors = require("cors");
const swaggerUi = require("swagger-ui-express");
const yaml = require("js-yaml");
const fs = require("fs");
const path = require("path");

const app = express();
app.use(cors());
app.use(express.json());

// --- In-memory data with seed ---
const db = {
  authors: Array.from({ length: 100 }, (_, i) => ({
    id: i + 1,
    name: `Author ${i + 1}`,
    email: `author${i + 1}@example.com`,
  })),
  tags: Array.from({ length: 100 }, (_, i) => ({
    id: i + 1,
    name: `tag-${i + 1}`,
  })),
  posts: Array.from({ length: 150 }, (_, i) => ({
    id: i + 1,
    title: `Post ${i + 1}`,
    body: `Content of post ${i + 1}.`,
    authorId: (i % 100) + 1,
    tagIds: [(i % 100) + 1],
    createdAt: new Date(2025, 0, (i % 28) + 1).toISOString(),
  })),
  comments: Array.from({ length: 200 }, (_, i) => ({
    id: i + 1,
    postId: (i % 150) + 1,
    body: `Comment ${i + 1}`,
    authorName: `Commenter ${(i % 100) + 1}`,
    createdAt: new Date(2025, 1, (i % 28) + 1).toISOString(),
  })),
};

const counters = {
  authors: 100,
  tags: 100,
  posts: 150,
  comments: 200,
};

// --- Generic CRUD helper ---
function crud(resource, timestamped = false) {
  const router = express.Router();

  router.get("/", (req, res) => {
    let items = db[resource];
    if (req.query.postId) {
      items = items.filter((i) => i.postId === Number(req.query.postId));
    }
    const total = items.length;
    if (req.query.perPage) {
      const perPage = Math.max(1, Number(req.query.perPage) || 10);
      const page = Math.max(1, Number(req.query.page) || 1);
      const start = (page - 1) * perPage;
      items = items.slice(start, start + perPage);
      res.set("X-Total-Count", String(total));
    }
    res.json(items);
  });

  router.get("/:id", (req, res) => {
    const item = db[resource].find((i) => i.id === Number(req.params.id));
    item ? res.json(item) : res.status(404).json({ error: "Not found" });
  });

  router.post("/", (req, res) => {
    const item = { id: ++counters[resource], ...req.body };
    if (timestamped) item.createdAt = new Date().toISOString();
    db[resource].push(item);
    res.status(201).json(item);
  });

  router.put("/:id", (req, res) => {
    const idx = db[resource].findIndex((i) => i.id === Number(req.params.id));
    if (idx === -1) return res.status(404).json({ error: "Not found" });
    db[resource][idx] = {
      ...db[resource][idx],
      ...req.body,
      id: db[resource][idx].id,
    };
    res.json(db[resource][idx]);
  });

  router.delete("/:id", (req, res) => {
    const idx = db[resource].findIndex((i) => i.id === Number(req.params.id));
    if (idx === -1) return res.status(404).json({ error: "Not found" });
    db[resource].splice(idx, 1);
    res.status(204).end();
  });

  return router;
}

// --- Routes ---
app.use("/authors", crud("authors"));
app.use("/tags", crud("tags"));
app.use("/posts", crud("posts", true));
app.use("/comments", crud("comments", true));

// --- OpenAPI spec & Swagger UI ---
const specPath = path.join(__dirname, "openapi.json");
const spec = yaml.load(fs.readFileSync(specPath, "utf8"));
app.use("/docs", swaggerUi.serve, swaggerUi.setup(spec));
app.get("/openapi.json", (_req, res) => {
  res.json(spec);
});

// --- Start ---
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`API running at http://localhost:${PORT}`);
  console.log(`Swagger UI at http://localhost:${PORT}/docs`);
});
