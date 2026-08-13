import { Router } from 'express';
import { createRoom, getRoomByCode } from '../controllers/roomController.js';

export const roomRoutes = Router();

roomRoutes.post('/', createRoom);
roomRoutes.get('/:roomId', getRoomByCode);