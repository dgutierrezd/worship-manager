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

// Health check (available at both /health and /api/health)
app.get("/health", (_req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

// API routes — mounted under /api so the web app and backend can share one domain.
// iOS and web both call worship-manager-psi.vercel.app/api/...
const apiRouter = express.Router();
apiRouter.use("/auth", authRouter);
apiRouter.use("/bands", bandsRouter);
apiRouter.use("/bands", membersRouter);        // /api/bands/:id/members
apiRouter.use("/bands", bandSongsRouter);      // /api/bands/:id/songs
apiRouter.use("/bands", bandSetlistsRouter);   // /api/bands/:id/setlists
apiRouter.use("/bands", bandRehearsalsRouter); // /api/bands/:id/rehearsals
apiRouter.use("/songs", songsRouter);          // /api/songs/:id/chords
apiRouter.use("/chords", chordsRouter);        // /api/chords/:id
apiRouter.use("/setlists", setlistsRouter);    // /api/setlists/:id
apiRouter.use("/rehearsals", rehearsalsRouter);// /api/rehearsals/:id
apiRouter.use("/notifications", notificationsRouter);
apiRouter.get("/health", (_req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

app.use("/api", apiRouter);

app.listen(PORT, () => {
  console.log(`WorshipFlow API running on port ${PORT}`);
});

export default app;
