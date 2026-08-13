import http from 'node:http';
import { config as loadEnv } from 'dotenv';
import express from 'express';
import cors from 'cors';
import { Server } from 'socket.io';
import { connectDB } from './config/database.js';
import { registerSocketHandlers } from './sockets/index.js';
import { roomRoutes } from './routes/roomRoutes.js';
import { seedCatalogTaskStates } from './models/CatalogTaskState.js';

loadEnv();

const app = express();
const httpServer = http.createServer(app);

const io = new Server(httpServer, {
  cors: { origin: process.env.CORS_ORIGIN ?? '*' },
});

app.use(cors());
app.use(express.json());

app.use('/api/rooms', roomRoutes);

app.get('/health', (_req, res) => {
  res.json({ status: 'ok' });
});

async function start(): Promise<void> {
  try {
    await connectDB();
    await seedCatalogTaskStates();
    registerSocketHandlers(io);
    const port = Number(process.env.PORT ?? 4000);
    httpServer.listen(port, () => {
      console.log(`[server] StudyHub escuchando en http://localhost:${port}`);
    });
  } catch (error) {
    console.error('[server] Error al iniciar:', error);
    process.exit(1);
  }
}

start();
