const express = require('express');
const cors = require('cors');
const path = require('path');
const { Pool } = require('pg');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 8080;

app.use(cors());
app.use(express.json());

// ── Database Connection ────────────────────────────────────────────────────────
const databaseUrl = process.env.DATABASE_URL;
let pool = null;

if (databaseUrl) {
  pool = new Pool({
    connectionString: databaseUrl,
    ssl: databaseUrl.includes('railway') || databaseUrl.includes('localhost')
      ? false
      : { rejectUnauthorized: false }
  });

  // Test connection on startup
  pool.connect()
    .then(client => {
      console.log('✅ Connected to PostgreSQL database successfully!');
      client.release();
      initTables();
    })
    .catch(err => {
      console.error('❌ Failed to connect to PostgreSQL:', err.message);
    });
} else {
  console.warn('⚠️ No DATABASE_URL provided. Server running in in-memory fallback mode.');
}

// In-memory fallback if no DB connected
let inMemoryListings = [];
let inMemoryUsers = {};

async function initTables() {
  if (!pool) return;
  const sql = `
    CREATE TABLE IF NOT EXISTS listings (
      id VARCHAR(64) PRIMARY KEY,
      title VARCHAR(255) NOT NULL,
      author VARCHAR(255) NOT NULL,
      isbn VARCHAR(32),
      cover_url TEXT,
      category VARCHAR(100),
      condition VARCHAR(50),
      seller_id VARCHAR(64) NOT NULL,
      seller_name VARCHAR(120) NOT NULL,
      seller_rating NUMERIC(3, 1) DEFAULT 4.9,
      completed_exchanges_count INT DEFAULT 0,
      city VARCHAR(100) NOT NULL,
      district VARCHAR(100),
      latitude NUMERIC(10, 6) NOT NULL,
      longitude NUMERIC(10, 6) NOT NULL,
      type VARCHAR(20) NOT NULL DEFAULT 'both',
      price NUMERIC(10, 2),
      exchange_preferences TEXT,
      raw_json JSONB,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS messages (
      id VARCHAR(64) PRIMARY KEY,
      conversation_id VARCHAR(64) NOT NULL,
      sender_id VARCHAR(64) NOT NULL,
      sender_name VARCHAR(120) NOT NULL,
      text TEXT,
      is_me BOOLEAN DEFAULT false,
      proposal_data JSONB,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS users (
      id VARCHAR(64) PRIMARY KEY,
      email VARCHAR(180) UNIQUE NOT NULL,
      name VARCHAR(120) NOT NULL,
      city VARCHAR(100) NOT NULL DEFAULT 'Warszawa',
      bio TEXT,
      avatar_url TEXT,
      rating NUMERIC(3, 1) DEFAULT 5.0,
      completed_exchanges INT DEFAULT 0,
      raw_json JSONB,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
  `;
  try {
    await pool.query(sql);
    console.log('✅ Database tables initialized (listings, messages).');
  } catch (err) {
    console.error('❌ Error initializing tables:', err.message);
  }
}

// ── Healthcheck & DB Status Endpoints ───────────────────────────────────────────
app.get('/healthz', (req, res) => {
  res.status(200).send('healthy\n');
});

app.get('/api/db-check', async (req, res) => {
  if (!pool) {
    return res.status(503).json({
      status: 'error',
      connected: false,
      message: 'Brak zmiennej DATABASE_URL w konfiguracji środowiska.',
      hint: 'W panelu Railway dodaj Reference Variable -> DATABASE_URL z serwisu PostgreSQL.'
    });
  }

  try {
    const result = await pool.query(`
      SELECT 
        NOW() as server_time,
        current_database() as database_name,
        version() as pg_version,
        (SELECT COUNT(*) FROM listings) as listings_count
    `);
    const row = result.rows[0];
    res.json({
      status: 'success',
      connected: true,
      database: row.database_name,
      serverTime: row.server_time,
      postgresVersion: row.pg_version.split(' on ')[0],
      totalListingsInDb: parseInt(row.listings_count, 10),
      message: '🎉 Połączenie z bazą PostgreSQL na Railway działa prawidłowo!'
    });
  } catch (err) {
    res.status(500).json({
      status: 'error',
      connected: false,
      error: err.message,
      hint: 'Upewnij się, że serwis PostgreSQL na Railway jest aktywny i połączony.'
    });
  }
});

// ── Listings API ───────────────────────────────────────────────────────────────

// GET /api/listings
app.get('/api/listings', async (req, res) => {
  if (pool) {
    try {
      const { rows } = await pool.query('SELECT raw_json FROM listings ORDER BY created_at DESC');
      const listings = rows.map(r => r.raw_json).filter(Boolean);
      return res.json(listings);
    } catch (err) {
      console.error('Error fetching listings from DB:', err.message);
      return res.status(500).json({ error: 'Failed to fetch listings' });
    }
  }
  res.json(inMemoryListings);
});

// POST /api/listings
app.post('/api/listings', async (req, res) => {
  const listing = req.body;
  if (!listing || !listing.id) {
    return res.status(400).json({ error: 'Invalid listing object' });
  }

  if (pool) {
    try {
      const book = listing.book || {};
      const query = `
        INSERT INTO listings (
          id, title, author, isbn, cover_url, category, condition,
          seller_id, seller_name, seller_rating, completed_exchanges_count,
          city, district, latitude, longitude, type, price, exchange_preferences,
          raw_json, created_at
        ) VALUES (
          $1, $2, $3, $4, $5, $6, $7,
          $8, $9, $10, $11,
          $12, $13, $14, $15, $16, $17, $18,
          $19, $20
        )
        ON CONFLICT (id) DO UPDATE SET
          title = EXCLUDED.title,
          author = EXCLUDED.author,
          isbn = EXCLUDED.isbn,
          cover_url = EXCLUDED.cover_url,
          category = EXCLUDED.category,
          condition = EXCLUDED.condition,
          city = EXCLUDED.city,
          district = EXCLUDED.district,
          latitude = EXCLUDED.latitude,
          longitude = EXCLUDED.longitude,
          type = EXCLUDED.type,
          price = EXCLUDED.price,
          exchange_preferences = EXCLUDED.exchange_preferences,
          raw_json = EXCLUDED.raw_json;
      `;
      const values = [
        listing.id,
        book.title || 'Bez tytułu',
        book.author || 'Nieznany',
        book.isbn,
        book.coverUrl,
        book.category,
        book.condition,
        listing.sellerId || 'unknown',
        listing.sellerName || 'Anonimowy Czytelnik',
        listing.sellerRating || 4.9,
        listing.completedExchangesCount || 0,
        listing.city || 'Warszawa',
        listing.district,
        listing.latitude || 52.2297,
        listing.longitude || 21.0122,
        listing.type || 'both',
        listing.price,
        listing.exchangePreferences,
        JSON.stringify(listing),
        listing.createdAt ? new Date(listing.createdAt) : new Date()
      ];

      await pool.query(query, values);
      return res.status(201).json(listing);
    } catch (err) {
      console.error('Error saving listing to DB:', err.message);
      return res.status(500).json({ error: 'Failed to save listing: ' + err.message });
    }
  }

  inMemoryListings = inMemoryListings.filter(l => l.id !== listing.id);
  inMemoryListings.unshift(listing);
  res.status(201).json(listing);
});

// PUT /api/listings/:id
app.put('/api/listings/:id', async (req, res) => {
  const { id } = req.params;
  const listing = req.body;

  if (pool) {
    try {
      const book = listing.book || {};
      const query = `
        UPDATE listings SET
          title = $2,
          author = $3,
          isbn = $4,
          cover_url = $5,
          category = $6,
          condition = $7,
          city = $8,
          district = $9,
          latitude = $10,
          longitude = $11,
          type = $12,
          price = $13,
          exchange_preferences = $14,
          raw_json = $15
        WHERE id = $1
      `;
      const values = [
        id,
        book.title || 'Bez tytułu',
        book.author || 'Nieznany',
        book.isbn,
        book.coverUrl,
        book.category,
        book.condition,
        listing.city || 'Warszawa',
        listing.district,
        listing.latitude || 52.2297,
        listing.longitude || 21.0122,
        listing.type || 'both',
        listing.price,
        listing.exchangePreferences,
        JSON.stringify(listing)
      ];
      await pool.query(query, values);
      return res.json(listing);
    } catch (err) {
      console.error('Error updating listing in DB:', err.message);
      return res.status(500).json({ error: 'Failed to update listing' });
    }
  }

  const idx = inMemoryListings.findIndex(l => l.id === id);
  if (idx !== -1) inMemoryListings[idx] = listing;
  res.json(listing);
});

// DELETE /api/listings/:id
app.delete('/api/listings/:id', async (req, res) => {
  const { id } = req.params;
  if (pool) {
    try {
      await pool.query('DELETE FROM listings WHERE id = $1', [id]);
      return res.json({ success: true, id });
    } catch (err) {
      console.error('Error deleting listing from DB:', err.message);
      return res.status(500).json({ error: 'Failed to delete listing' });
    }
  }

  inMemoryListings = inMemoryListings.filter(l => l.id !== id);
  res.json({ success: true, id });
});

// ── Google Search Console Verification ─────────────────────────────────────────
app.get('/googleaf4f33ce5f01eea5.html', (req, res) => {
  res.type('text/html');
  res.status(200).send('google-site-verification: googleaf4f33ce5f01eea5.html\n');
});

// ── Users & Profiles API ───────────────────────────────────────────────────────

// GET /api/users/:email
app.get('/api/users/:email', async (req, res) => {
  const email = decodeURIComponent(req.params.email).toLowerCase().trim();
  if (pool) {
    try {
      const { rows } = await pool.query('SELECT raw_json FROM users WHERE LOWER(email) = $1 LIMIT 1', [email]);
      if (rows.length > 0 && rows[0].raw_json) {
        return res.json(rows[0].raw_json);
      }
      return res.status(404).json({ error: 'User not found' });
    } catch (err) {
      console.error('Error fetching user from DB:', err.message);
      return res.status(500).json({ error: 'Database error fetching user' });
    }
  }
  const user = inMemoryUsers[email];
  if (user) return res.json(user);
  res.status(404).json({ error: 'User not found' });
});

// POST /api/users (upsert profile)
app.post('/api/users', async (req, res) => {
  const profile = req.body;
  if (!profile || !profile.email || !profile.name) {
    return res.status(400).json({ error: 'Missing required user profile fields (email, name)' });
  }

  const email = profile.email.toLowerCase().trim();
  const id = profile.id || `user_${Date.now()}`;
  const name = profile.name.trim();
  const city = (profile.city || 'Warszawa').trim();
  const bio = profile.bio ? profile.bio.trim() : null;
  const avatarUrl = profile.avatarUrl || null;
  const rating = profile.rating || 5.0;
  const completedExchanges = profile.completedExchanges || 0;

  const normalizedProfile = {
    ...profile,
    id,
    email,
    name,
    city,
    bio,
    avatarUrl,
    rating,
    completedExchanges,
  };

  if (pool) {
    try {
      const query = `
        INSERT INTO users (
          id, email, name, city, bio, avatar_url, rating, completed_exchanges, raw_json, updated_at
        ) VALUES (
          $1, $2, $3, $4, $5, $6, $7, $8, $9, NOW()
        )
        ON CONFLICT (email) DO UPDATE SET
          name = EXCLUDED.name,
          city = EXCLUDED.city,
          bio = EXCLUDED.bio,
          avatar_url = EXCLUDED.avatar_url,
          rating = EXCLUDED.rating,
          completed_exchanges = EXCLUDED.completed_exchanges,
          raw_json = EXCLUDED.raw_json,
          updated_at = NOW()
        RETURNING raw_json;
      `;
      const values = [
        id, email, name, city, bio, avatarUrl, rating, completedExchanges,
        JSON.stringify(normalizedProfile)
      ];
      const { rows } = await pool.query(query, values);

      // Sync seller name and city to existing listings of this seller
      try {
        await pool.query(
          'UPDATE listings SET seller_name = $1, city = $2 WHERE seller_id = $3',
          [name, city, id]
        );
      } catch (listErr) {
        console.warn('Could not update listings seller name:', listErr.message);
      }

      return res.status(200).json(rows[0].raw_json || normalizedProfile);
    } catch (err) {
      console.error('Error saving user profile to DB:', err.message);
      return res.status(500).json({ error: 'Failed to save profile: ' + err.message });
    }
  }

  inMemoryUsers[email] = normalizedProfile;
  res.status(200).json(normalizedProfile);
});

// ── Static Flutter Web Serving & SPA Fallback ──────────────────────────────────
const publicPath = path.join(__dirname, 'public');
app.use(express.static(publicPath, {
  maxAge: '1d',
  setHeaders: (res, filePath) => {
    if (filePath.endsWith('.html')) {
      res.setHeader('Cache-Control', 'no-cache');
    }
  }
}));

app.get('*', (req, res) => {
  const indexPath = path.join(publicPath, 'index.html');
  res.sendFile(indexPath, err => {
    if (err) {
      res.status(200).send('Czytella API Backend is running. Deploy frontend assets to public/ to view web app.');
    }
  });
});

app.listen(port, () => {
  console.log(`🚀 Czytella server listening on port ${port}`);
});
