import { PrismaClient } from '@prisma/client';
import { PrismaBetterSqlite3 } from '@prisma/adapter-better-sqlite3';
import path from 'path';

// Compute absolute path to dev.db SQLite file
const dbPath = path.resolve(__dirname, '../../dev.db');

// Instantiate PrismaBetterSqlite3 by passing the configuration object directly
const adapter = new PrismaBetterSqlite3({
  url: `file:${dbPath}`,
});

const prisma = new PrismaClient({ adapter });

export default prisma;
export const pool = null;
