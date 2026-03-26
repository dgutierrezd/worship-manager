import "dotenv/config";
import express from "express";
import cors from "cors";
import rateLimit from "express-rate-limit";
import authRouter from "./routes/auth";
import bandsRouter from "./routes/bands";
import membersRouter from "./routes/members";
import { bandSongsRouter, songsRouter, chordsRouter } from "./routes/songs";
import { bandSetlistsRouter, setlistsRouter } from "./routes/setlists";
import { bandRehearsalsRouter, rehearsalsRouter } from "./routes/rehearsals";
import notificationsRouter from "./routes/notifications";
import aiRouter from "./routes/ai";

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(
  cors({
    origin: "*",
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE"],
  })
);
app.use(
  rateLimit({
    windowMs: 60 * 1000,
    max: 100,
    standardHeaders: true,
    legacyHeaders: false,
  })
);

// Health check
app.get("/health", (_req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

// Routes
app.use("/auth", authRouter);
app.use("/bands", bandsRouter);
app.use("/bands", membersRouter);       // /bands/:id/members
app.use("/bands", bandSongsRouter);     // /bands/:id/songs
app.use("/bands", bandSetlistsRouter);  // /bands/:id/setlists
app.use("/bands", bandRehearsalsRouter);// /bands/:id/rehearsals
app.use("/songs", songsRouter);         // /songs/:id/chords
app.use("/chords", chordsRouter);       // /chords/:id
app.use("/setlists", setlistsRouter);   // /setlists/:id, /setlists/:id/songs
app.use("/rehearsals", rehearsalsRouter);// /rehearsals/:id, /rehearsals/:id/rsvp
app.use("/notifications", notificationsRouter);
app.use("/ai", aiRouter);                    // /ai/song-lookup

app.listen(PORT, () => {
  console.log(`WorshipFlow API running on port ${PORT}`);
});

export default app;
