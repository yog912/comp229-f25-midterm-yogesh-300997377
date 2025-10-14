// server.js
// Student: Yogesh (300997377) — COMP229 Midterm API (Games Library)

const express = require("express");
const cors = require("cors");
const path = require("path");

const app = express();
app.use(cors());
app.use(express.json());

// ---- Starter library (5) + your 2 games (total = 7) ----
const games = [
  {
    title: "The Legend of Zelda: Ocarina of Time",
    genre: "Action-Adventure",
    platform: "Nintendo 64",
    year: 1998,
    developer: "Nintendo EAD",
  },
  {
    title: "Half-Life 2",
    genre: "FPS",
    platform: "PC",
    year: 2004,
    developer: "Valve",
  },
  {
    title: "Portal 2",
    genre: "Puzzle",
    platform: "PC",
    year: 2011,
    developer: "Valve",
  },
  {
    title: "God of War",
    genre: "Action",
    platform: "PS4",
    year: 2018,
    developer: "Santa Monica Studio",
  },
  {
    title: "The Last of Us Part II",
    genre: "Action-Adventure",
    platform: "PS4",
    year: 2020,
    developer: "Naughty Dog",
  },

  // Yogesh's two games (ID ends with 7 → 2020–2024)
  {
    title: "Elden Ring",
    genre: "Action RPG",
    platform: "PC",
    year: 2022,
    developer: "FromSoftware",
  },
  {
    title: "Baldur's Gate 3",
    genre: "RPG",
    platform: "PC",
    year: 2023,
    developer: "Larian Studios",
  },
];

// ---- Helpers ----
function validateGamePayload(body) {
  const errors = [];
  const required = ["title", "genre", "platform", "year", "developer"];
  for (const f of required) {
    if (body[f] === undefined || body[f] === null || body[f] === "") {
      errors.push(`Field "${f}" is required.`);
    }
  }
  if (body.year !== undefined && !Number.isInteger(body.year)) {
    errors.push(`Field "year" must be an integer.`);
  }
  return errors;
}

function ensureIndex(req) {
  const i = Number(req.params.id);
  if (!Number.isInteger(i)) {
    return { error: "Index must be an integer." };
  }
  if (i < 0 || i >= games.length) {
    return { error: `Index out of range. Must be between 0 and ${games.length - 1}.` };
  }
  return { i };
}

// ---- Routes ----

// GET /api/games – all
app.get("/api/games", (req, res) => {
  res.status(200).json(games);
});

// GET /api/games/filter?genre=...
app.get("/api/games/filter", (req, res) => {
  const { genre } = req.query;
  if (!genre || genre.trim() === "") {
    return res.status(400).json({ error: 'Query "genre" is required.' });
  }
  const g = genre.toLowerCase();
  const filtered = games.filter((x) => (x.genre || "").toLowerCase().includes(g));
  res.status(200).json(filtered);
});

// GET /api/games/:id – by index
app.get("/api/games/:id", (req, res) => {
  const { i, error } = ensureIndex(req);
  if (error) return res.status(400).json({ error });
  res.status(200).json(games[i]);
});

// POST /api/games – add new
app.post("/api/games", (req, res) => {
  const errors = validateGamePayload(req.body || {});
  if (errors.length) return res.status(400).json({ errors });

  const toAdd = {
    title: req.body.title,
    genre: req.body.genre,
    platform: req.body.platform,
    year: req.body.year,
    developer: req.body.developer,
  };
  games.push(toAdd);
  res.status(201).json({ message: "Game added", index: games.length - 1, game: toAdd });
});

// PUT /api/games/:id – replace at index
app.put("/api/games/:id", (req, res) => {
  const { i, error } = ensureIndex(req);
  if (error) return res.status(400).json({ error });

  const errors = validateGamePayload(req.body || {});
  if (errors.length) return res.status(400).json({ errors });

  const updated = {
    title: req.body.title,
    genre: req.body.genre,
    platform: req.body.platform,
    year: req.body.year,
    developer: req.body.developer,
  };
  games[i] = updated;
  res.status(200).json({ message: "Game updated", index: i, game: updated });
});

// DELETE /api/games/:id – remove by index
app.delete("/api/games/:id", (req, res) => {
  const { i, error } = ensureIndex(req);
  if (error) return res.status(400).json({ error });
  const removed = games.splice(i, 1)[0];
  res.status(200).json({ message: "Game deleted", removed });
});

// Optional root = serve docs page
app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "index.html"));
});

// ---- Start ----
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`OK → http://localhost:${PORT}`));
