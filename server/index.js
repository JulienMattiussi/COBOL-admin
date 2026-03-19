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
  authors: [
    { id: 1, name: "Alice Martin", email: "alice@example.com" },
    { id: 2, name: "Bob Jones", email: "bob@example.com" },
  ],
  tags: [
    { id: 1, name: "javascript" },
    { id: 2, name: "cobol" },
    { id: 3, name: "webdev" },
  ],
  posts: [
    {
      id: 1,
      title: "Hello World",
      body: "First post content.",
      authorId: 1,
      tagIds: [1, 3],
      createdAt: "2025-01-15T10:00:00Z",
    },
    {
      id: 2,
      title: "COBOL Lives",
      body: "COBOL is still relevant.",
      authorId: 2,
      tagIds: [2],
      createdAt: "2025-02-20T14:30:00Z",
    },
  ],
  comments: [
    {
      id: 1,
      postId: 1,
      body: "Great post!",
      authorName: "Charlie",
      createdAt: "2025-01-16T08:00:00Z",
    },
    {
      id: 2,
      postId: 2,
      body: "Absolutely agree.",
      authorName: "Dana",
      createdAt: "2025-02-21T09:15:00Z",
    },
  ],
};

const counters = {
  authors: 2,
  tags: 3,
  posts: 2,
  comments: 2,
};

// --- Generic CRUD helper ---
function crud(resource, timestamped = false) {
  const router = express.Router();

  router.get("/", (req, res) => {
    let items = db[resource];
    if (req.query.postId) {
      items = items.filter((i) => i.postId === Number(req.query.postId));
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
