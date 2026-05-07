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
  authors: require("./fixtures/authors"),
  tags: require("./fixtures/tags"),
  posts: require("./fixtures/posts"),
  comments: require("./fixtures/comments"),
};

const counters = {
  authors: db.authors.length,
  tags: db.tags.length,
  posts: db.posts.length,
  comments: db.comments.length,
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

// Auto-reset: exit after 1h so the host restarts the container with fresh fixtures
const RESET_INTERVAL_MS = 60 * 60 * 1000;
setTimeout(() => {
  console.log("Auto-reset: exiting to reload fixtures");
  process.exit(0);
}, RESET_INTERVAL_MS).unref();
