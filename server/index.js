const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
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

    // Schema updates for users table (admin & blocking)
    try {
      await pool.query(`
        ALTER TABLE users ADD COLUMN IF NOT EXISTS is_blocked BOOLEAN DEFAULT false;
        ALTER TABLE users ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT false;
        UPDATE users SET is_admin = true WHERE LOWER(email) = 'aucikkosmonaucik@gmail.com';
      `);
      console.log('✅ Admin and blocking columns initialized in users table.');
    } catch (colErr) {
      console.warn('Users table column note:', colErr.message);
    }

    // Harmonize listings raw_json with column values for seller_name, city, and seller_id
    try {
      await pool.query(`
        UPDATE listings
        SET raw_json = jsonb_set(
          jsonb_set(
            jsonb_set(raw_json, '{sellerName}', to_jsonb(seller_name::text)),
            '{city}', to_jsonb(city::text)
          ),
          '{sellerId}', to_jsonb(seller_id::text)
        )
        WHERE raw_json IS NOT NULL
          AND (
            (raw_json->>'sellerName') IS DISTINCT FROM seller_name
            OR (raw_json->>'city') IS DISTINCT FROM city
            OR (raw_json->>'sellerId') IS DISTINCT FROM seller_id
          );
      `);
      console.log('✅ Synchronized listings raw_json with column values.');
    } catch (syncErr) {
      console.warn('Listing column sync note:', syncErr.message);
    }
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

// Helper to look up a listing by ID from PostgreSQL or in-memory
async function findListingById(listingId) {
  if (!listingId) return null;
  const cleanId = String(listingId).trim();

  if (pool) {
    try {
      const { rows } = await pool.query('SELECT * FROM listings WHERE id = $1 LIMIT 1', [cleanId]);
      if (rows.length > 0) {
        const row = rows[0];
        const raw = row.raw_json || {};
        return {
          id: row.id,
          title: raw.book?.title || row.title || 'Książka',
          author: raw.book?.author || row.author || 'Autor nieznany',
          isbn: raw.book?.isbn || row.isbn || '',
          coverUrl: raw.book?.coverUrl || row.cover_url || null,
          category: raw.book?.category || row.category || '',
          condition: raw.book?.condition || row.condition || 'veryGood',
          description: raw.book?.description || '',
          sellerName: raw.sellerName || row.seller_name || 'Użytkownik Czytella',
          sellerRating: raw.sellerRating || Number(row.seller_rating) || 4.9,
          completedExchangesCount: raw.completedExchangesCount || row.completed_exchanges_count || 0,
          city: raw.city || row.city || 'Warszawa',
          district: raw.district || row.district || null,
          type: raw.type || row.type || 'both',
          price: raw.price != null ? raw.price : (row.price != null ? Number(row.price) : null),
          exchangePreferences: raw.exchangePreferences || row.exchange_preferences || '',
          rawJson: row.raw_json || null
        };
      }
    } catch (err) {
      console.error('Error fetching listing from DB for OG tags:', err.message);
    }
  }

  const mem = inMemoryListings.find(l => l.id === cleanId);
  if (mem) {
    return {
      id: mem.id,
      title: mem.book?.title || 'Książka',
      author: mem.book?.author || 'Nieznany',
      isbn: mem.book?.isbn || '',
      coverUrl: mem.book?.coverUrl || null,
      category: mem.book?.category || '',
      condition: mem.book?.condition || 'veryGood',
      description: mem.book?.description || '',
      sellerName: mem.sellerName || 'Użytkownik Czytella',
      sellerRating: mem.sellerRating || 4.9,
      completedExchangesCount: mem.completedExchangesCount || 0,
      city: mem.city || 'Warszawa',
      district: mem.district || null,
      type: mem.type || 'both',
      price: mem.price != null ? mem.price : null,
      exchangePreferences: mem.exchangePreferences || '',
      rawJson: mem
    };
  }

  return null;
}

// GET /api/listings
app.get('/api/listings', async (req, res) => {
  if (pool) {
    try {
      const { rows } = await pool.query('SELECT raw_json, seller_name, city, seller_id FROM listings ORDER BY created_at DESC');
      const listings = rows.map(r => {
        const raw = r.raw_json;
        if (!raw) return null;
        if (r.seller_name && raw.sellerName !== r.seller_name) {
          raw.sellerName = r.seller_name;
        }
        if (r.city && raw.city !== r.city) {
          raw.city = r.city;
        }
        if (r.seller_id && raw.sellerId !== r.seller_id) {
          raw.sellerId = r.seller_id;
        }
        return raw;
      }).filter(Boolean);
      return res.json(listings);
    } catch (err) {
      console.error('Error fetching listings from DB:', err.message);
      return res.status(500).json({ error: 'Failed to fetch listings' });
    }
  }
  res.json(inMemoryListings);
});

// GET /api/listings/:id
app.get('/api/listings/:id', async (req, res) => {
  const listing = await findListingById(req.params.id);
  if (listing) {
    if (listing.rawJson) {
      return res.json(listing.rawJson);
    }
    return res.json({
      id: listing.id,
      book: {
        id: listing.id,
        isbn: listing.isbn,
        title: listing.title,
        author: listing.author,
        description: listing.description,
        coverUrl: listing.coverUrl,
        category: listing.category,
        condition: listing.condition,
      },
      sellerId: 'unknown',
      sellerName: listing.sellerName,
      sellerRating: listing.sellerRating,
      completedExchangesCount: listing.completedExchangesCount,
      city: listing.city,
      district: listing.district,
      latitude: 52.2297,
      longitude: 21.0122,
      type: listing.type,
      price: listing.price,
      exchangePreferences: listing.exchangePreferences,
      createdAt: new Date().toISOString(),
      isUserListing: false,
    });
  }
  res.status(404).json({ error: 'Listing not found' });
});

// GET /api/listings/:id/cover
app.get('/api/listings/:id/cover', async (req, res) => {
  try {
    const listing = await findListingById(req.params.id);
    if (!listing || !listing.coverUrl) {
      return res.redirect('/icons/og-image.png');
    }

    const coverUrl = listing.coverUrl.trim();
    if (coverUrl.startsWith('data:image/')) {
      const matches = coverUrl.match(/^data:([a-zA-Z0-9]+\/[a-zA-Z0-9-.+]+);base64,(.+)$/);
      if (matches && matches[1] && matches[2]) {
        const mimeType = matches[1];
        const buffer = Buffer.from(matches[2], 'base64');
        res.setHeader('Content-Type', mimeType);
        res.setHeader('Cache-Control', 'public, max-age=86400');
        return res.send(buffer);
      }
    }

    if (coverUrl.startsWith('http://') || coverUrl.startsWith('https://')) {
      return res.redirect(coverUrl);
    }

    return res.redirect('/icons/og-image.png');
  } catch (err) {
    console.error('Error serving cover image:', err.message);
    return res.redirect('/icons/og-image.png');
  }
});

// POST /api/listings
app.post('/api/listings', async (req, res) => {
  const listing = req.body;
  if (!listing || !listing.id) {
    return res.status(400).json({ error: 'Invalid listing object' });
  }

  if (pool) {
    try {
      if (listing.sellerId) {
        const checkBlocked = await pool.query(
          'SELECT is_blocked FROM users WHERE (id = $1 OR name = $2) AND is_blocked = true LIMIT 1',
          [listing.sellerId, listing.sellerName || '']
        );
        if (checkBlocked.rows.length > 0) {
          return res.status(403).json({ error: 'Konto zostało zablokowane przez administratora.' });
        }
      }
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
      const sellerName = listing.sellerName || 'Anonimowy Czytelnik';
      const sellerId = listing.sellerId || 'unknown';
      const cleanListing = { ...listing, sellerName, sellerId };
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
          seller_name = $15,
          seller_id = $16,
          raw_json = $17
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
        sellerName,
        sellerId,
        JSON.stringify(cleanListing)
      ];
      await pool.query(query, values);
      return res.json(cleanListing);
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
  const isSuperAdminEmail = email === 'aucikkosmonaucik@gmail.com';

  if (pool) {
    try {
      const { rows } = await pool.query('SELECT raw_json, is_blocked, is_admin FROM users WHERE LOWER(email) = $1 LIMIT 1', [email]);
      if (rows.length > 0 && rows[0].raw_json) {
        const userJson = rows[0].raw_json;
        userJson.isBlocked = isSuperAdminEmail ? false : !!rows[0].is_blocked;
        userJson.isAdmin = isSuperAdminEmail || !!rows[0].is_admin || !!userJson.isAdmin;
        return res.json(userJson);
      }
      return res.status(404).json({ error: 'User not found' });
    } catch (err) {
      console.error('Error fetching user from DB:', err.message);
      return res.status(500).json({ error: 'Database error fetching user' });
    }
  }
  const user = inMemoryUsers[email];
  if (user) {
    user.isAdmin = isSuperAdminEmail || !!user.isAdmin;
    user.isBlocked = isSuperAdminEmail ? false : !!user.isBlocked;
    return res.json(user);
  }
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
  const previousName = profile.previousName ? profile.previousName.trim() : null;
  const city = (profile.city || 'Warszawa').trim();
  const bio = profile.bio ? profile.bio.trim() : null;
  const avatarUrl = profile.avatarUrl || null;
  const rating = profile.rating || 5.0;
  const completedExchanges = profile.completedExchanges || 0;
  const isSuperAdminEmail = email === 'aucikkosmonaucik@gmail.com';
  const isAdmin = isSuperAdminEmail || !!profile.isAdmin;
  const isBlocked = isSuperAdminEmail ? false : !!profile.isBlocked;

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
    isAdmin,
    isBlocked,
  };

  if (pool) {
    try {
      let oldName = previousName;
      let oldId = null;
      try {
        const existing = await pool.query(
          'SELECT id, name, is_admin, is_blocked FROM users WHERE LOWER(email) = $1 LIMIT 1',
          [email]
        );
        if (existing.rows.length > 0) {
          if (!oldName) oldName = existing.rows[0].name;
          oldId = existing.rows[0].id;
          if (existing.rows[0].is_admin) normalizedProfile.isAdmin = true;
          if (existing.rows[0].is_blocked && !isSuperAdminEmail) normalizedProfile.isBlocked = true;
        }
      } catch (_) {}

      const query = `
        INSERT INTO users (
          id, email, name, city, bio, avatar_url, rating, completed_exchanges, is_admin, is_blocked, raw_json, updated_at
        ) VALUES (
          $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, NOW()
        )
        ON CONFLICT (email) DO UPDATE SET
          name = EXCLUDED.name,
          city = EXCLUDED.city,
          bio = EXCLUDED.bio,
          avatar_url = EXCLUDED.avatar_url,
          rating = EXCLUDED.rating,
          completed_exchanges = EXCLUDED.completed_exchanges,
          is_admin = (users.is_admin OR EXCLUDED.is_admin),
          is_blocked = (CASE WHEN LOWER(users.email) = 'aucikkosmonaucik@gmail.com' THEN false ELSE EXCLUDED.is_blocked END),
          raw_json = EXCLUDED.raw_json,
          updated_at = NOW()
        RETURNING raw_json;
      `;
      const values = [
        id, email, name, city, bio, avatarUrl, rating, completedExchanges,
        normalizedProfile.isAdmin, normalizedProfile.isBlocked,
        JSON.stringify(normalizedProfile)
      ];
      const { rows } = await pool.query(query, values);

      // Sync seller name, city, and seller_id to existing listings of this seller (updating columns AND raw_json)
      try {
        await pool.query(
          `UPDATE listings
           SET seller_name = $1,
               city = $2,
               seller_id = $3,
               raw_json = jsonb_set(
                 jsonb_set(
                   jsonb_set(raw_json, '{sellerName}', to_jsonb($1::text)),
                   '{city}', to_jsonb($2::text)
                 ),
                 '{sellerId}', to_jsonb($3::text)
               )
           WHERE seller_id = $3
              OR ($4::text IS NOT NULL AND (seller_name = $4 OR raw_json->>'sellerName' = $4))
              OR ($5::text IS NOT NULL AND seller_id = $5)
              OR (seller_id = 'current_user' AND ($4::text IS NOT NULL AND (seller_name = $4 OR raw_json->>'sellerName' = $4)))
              OR (seller_id = 'current_user' AND (seller_name = 'Grun' OR raw_json->>'sellerName' = 'Grun'))
              OR (seller_name = 'Grun' AND $1 != 'Grun');`,
          [name, city, id, oldName, oldId]
        );
        console.log(`✅ Synchronized listings seller details for user ${name} (previous: ${oldName || 'none'})`);
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
  inMemoryListings = inMemoryListings.map(l => {
    if (l.sellerId === id ||
        (oldName && (l.sellerName === oldName || l.sellerId === oldId)) ||
        (l.sellerName === 'Grun' && name !== 'Grun') ||
        l.sellerId === 'current_user') {
      return {
        ...l,
        sellerName: name,
        city: city,
        sellerId: id,
      };
    }
    return l;
  });
  res.status(200).json(normalizedProfile);
});

// ── Admin API Endpoints ────────────────────────────────────────────────────────

// GET /api/admin/stats
app.get('/api/admin/stats', async (req, res) => {
  if (pool) {
    try {
      const listingsRes = await pool.query('SELECT COUNT(*) as count FROM listings');
      const usersRes = await pool.query('SELECT COUNT(*) as count, COUNT(*) FILTER (WHERE is_blocked = true) as blocked FROM users');
      const messagesRes = await pool.query('SELECT COUNT(*) as count FROM messages');
      return res.json({
        totalListings: parseInt(listingsRes.rows[0].count, 10),
        totalUsers: parseInt(usersRes.rows[0].count, 10),
        blockedUsers: parseInt(usersRes.rows[0].blocked || 0, 10),
        totalMessages: parseInt(messagesRes.rows[0].count, 10),
        dbConnected: true,
      });
    } catch (err) {
      console.error('Error fetching admin stats:', err.message);
      return res.status(500).json({ error: 'Failed to fetch admin stats' });
    }
  }
  return res.json({
    totalListings: inMemoryListings.length,
    totalUsers: Object.keys(inMemoryUsers).length,
    blockedUsers: Object.values(inMemoryUsers).filter(u => u.isBlocked).length,
    totalMessages: 0,
    dbConnected: false,
  });
});

// GET /api/admin/users
app.get('/api/admin/users', async (req, res) => {
  if (pool) {
    try {
      const { rows } = await pool.query(`
        SELECT 
          u.id, 
          u.email, 
          u.name, 
          u.city, 
          u.bio, 
          u.rating, 
          u.completed_exchanges,
          u.is_blocked,
          (u.is_admin OR LOWER(u.email) = 'aucikkosmonaucik@gmail.com') as is_admin,
          u.created_at,
          (SELECT COUNT(*) FROM listings l WHERE l.seller_id = u.id OR l.seller_name = u.name) as listings_count
        FROM users u
        ORDER BY u.created_at DESC
      `);
      return res.json(rows.map(r => ({
        id: r.id,
        email: r.email,
        name: r.name,
        city: r.city,
        bio: r.bio,
        rating: Number(r.rating) || 5.0,
        completedExchanges: parseInt(r.completed_exchanges || 0, 10),
        isBlocked: !!r.is_blocked,
        isAdmin: !!r.is_admin,
        createdAt: r.created_at,
        listingsCount: parseInt(r.listings_count || 0, 10),
      })));
    } catch (err) {
      console.error('Error fetching admin users:', err.message);
      return res.status(500).json({ error: 'Failed to fetch admin users' });
    }
  }
  const users = Object.values(inMemoryUsers).map(u => ({
    id: u.id,
    email: u.email,
    name: u.name,
    city: u.city,
    bio: u.bio,
    rating: u.rating || 5.0,
    completedExchanges: u.completedExchanges || 0,
    isBlocked: !!u.isBlocked,
    isAdmin: u.email.toLowerCase() === 'aucikkosmonaucik@gmail.com' || !!u.isAdmin,
    createdAt: u.createdAt || new Date().toISOString(),
    listingsCount: inMemoryListings.filter(l => l.sellerId === u.id || l.sellerName === u.name).length,
  }));
  return res.json(users);
});

// POST /api/admin/users/:email/toggle-block
app.post('/api/admin/users/:email/toggle-block', async (req, res) => {
  const targetEmail = decodeURIComponent(req.params.email).toLowerCase().trim();
  if (targetEmail === 'aucikkosmonaucik@gmail.com') {
    return res.status(400).json({ error: 'Nie można zablokować głównego konta administratora.' });
  }

  if (pool) {
    try {
      const userRes = await pool.query('SELECT is_blocked, raw_json FROM users WHERE LOWER(email) = $1 LIMIT 1', [targetEmail]);
      if (userRes.rows.length === 0) {
        return res.status(404).json({ error: 'Użytkownik nie istnieje w bazie.' });
      }
      const currentBlocked = !!userRes.rows[0].is_blocked;
      const newStatus = !currentBlocked;

      await pool.query(`
        UPDATE users
        SET is_blocked = $1,
            raw_json = jsonb_set(COALESCE(raw_json, '{}'::jsonb), '{isBlocked}', to_jsonb($1::boolean)),
            updated_at = NOW()
        WHERE LOWER(email) = $2
      `, [newStatus, targetEmail]);

      return res.json({ success: true, email: targetEmail, isBlocked: newStatus });
    } catch (err) {
      console.error('Error toggling user block:', err.message);
      return res.status(500).json({ error: 'Błąd podczas zmiany statusu blokady' });
    }
  }

  if (inMemoryUsers[targetEmail]) {
    inMemoryUsers[targetEmail].isBlocked = !inMemoryUsers[targetEmail].isBlocked;
    return res.json({ success: true, email: targetEmail, isBlocked: inMemoryUsers[targetEmail].isBlocked });
  }
  return res.status(404).json({ error: 'Użytkownik nie istnieje.' });
});

// DELETE /api/admin/listings/:id
app.delete('/api/admin/listings/:id', async (req, res) => {
  const { id } = req.params;
  if (pool) {
    try {
      await pool.query('DELETE FROM listings WHERE id = $1', [id]);
      return res.json({ success: true, id, message: 'Ogłoszenie zostało usunięte przez administratora.' });
    } catch (err) {
      console.error('Error admin deleting listing:', err.message);
      return res.status(500).json({ error: 'Błąd podczas usuwania ogłoszenia' });
    }
  }
  inMemoryListings = inMemoryListings.filter(l => l.id !== id);
  return res.json({ success: true, id, message: 'Ogłoszenie zostało usunięte przez administratora.' });
});

// ── Dynamic Open Graph & Static Flutter Web Serving ────────────────────────────
const publicPath = path.join(__dirname, 'public');

function getIndexHtmlTemplate() {
  const possiblePaths = [
    path.join(publicPath, 'index.html'),
    path.join(__dirname, '..', 'build', 'web', 'index.html'),
    path.join(__dirname, '..', 'web', 'index.html')
  ];
  for (const p of possiblePaths) {
    if (fs.existsSync(p)) {
      try {
        return fs.readFileSync(p, 'utf8');
      } catch (e) {
        console.error('Error reading index.html from ' + p, e.message);
      }
    }
  }
  return null;
}

function injectOpenGraphTags(html, { title, description, imageUrl, pageUrl }) {
  const escapeHtml = (str) => String(str || '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');

  const safeTitle = escapeHtml(title);
  const safeDesc = escapeHtml(description);
  const safeImage = escapeHtml(imageUrl);
  const safeUrl = escapeHtml(pageUrl);

  let updated = html;

  // Replace <title>
  updated = updated.replace(/<title>.*?<\/title>/i, `<title>${safeTitle}</title>`);

  // Replace <meta name="title">
  if (/<meta\s+name=["']title["']/i.test(updated)) {
    updated = updated.replace(/<meta\s+name=["']title["']\s+content=["'][^"']*["']\s*\/?>/i,
      `<meta name="title" content="${safeTitle}">`);
  }

  // Replace <meta name="description">
  if (/<meta\s+name=["']description["']/i.test(updated)) {
    updated = updated.replace(/<meta\s+name=["']description["']\s+content=["'][^"']*["']\s*\/?>/i,
      `<meta name="description" content="${safeDesc}">`);
  }

  // Replace og:title
  if (/<meta\s+property=["']og:title["']/i.test(updated)) {
    updated = updated.replace(/<meta\s+property=["']og:title["']\s+content=["'][^"']*["']\s*\/?>/i,
      `<meta property="og:title" content="${safeTitle}">`);
  }

  // Replace og:description
  if (/<meta\s+property=["']og:description["']/i.test(updated)) {
    updated = updated.replace(/<meta\s+property=["']og:description["']\s+content=["'][^"']*["']\s*\/?>/i,
      `<meta property="og:description" content="${safeDesc}">`);
  }

  // Replace og:url
  if (/<meta\s+property=["']og:url["']/i.test(updated)) {
    updated = updated.replace(/<meta\s+property=["']og:url["']\s+content=["'][^"']*["']\s*\/?>/i,
      `<meta property="og:url" content="${safeUrl}">`);
  }

  // Replace canonical link
  if (/<link\s+rel=["']canonical["']/i.test(updated)) {
    updated = updated.replace(/<link\s+rel=["']canonical["']\s+href=["'][^"']*["']\s*\/?>/i,
      `<link rel="canonical" href="${safeUrl}">`);
  }

  // Replace og:image
  if (/<meta\s+property=["']og:image["']/i.test(updated)) {
    updated = updated.replace(/<meta\s+property=["']og:image["']\s+content=["'][^"']*["']\s*\/?>/i,
      `<meta property="og:image" content="${safeImage}">`);
  }

  // Replace og:image:secure_url
  if (/<meta\s+property=["']og:image:secure_url["']/i.test(updated)) {
    updated = updated.replace(/<meta\s+property=["']og:image:secure_url["']\s+content=["'][^"']*["']\s*\/?>/i,
      `<meta property="og:image:secure_url" content="${safeImage}">`);
  }

  // Strip static image dimensions so communicators and social apps preserve book cover aspect ratio
  updated = updated.replace(/<meta\s+property=["']og:image:width["'][^>]*\/?>\s*/gi, '');
  updated = updated.replace(/<meta\s+property=["']og:image:height["'][^>]*\/?>\s*/gi, '');

  // Replace twitter:title
  if (/<meta\s+name=["']twitter:title["']/i.test(updated)) {
    updated = updated.replace(/<meta\s+name=["']twitter:title["']\s+content=["'][^"']*["']\s*\/?>/i,
      `<meta name="twitter:title" content="${safeTitle}">`);
  }

  // Replace twitter:description
  if (/<meta\s+name=["']twitter:description["']/i.test(updated)) {
    updated = updated.replace(/<meta\s+name=["']twitter:description["']\s+content=["'][^"']*["']\s*\/?>/i,
      `<meta name="twitter:description" content="${safeDesc}">`);
  }

  // Replace twitter:image
  if (/<meta\s+name=["']twitter:image["']/i.test(updated)) {
    updated = updated.replace(/<meta\s+name=["']twitter:image["']\s+content=["'][^"']*["']\s*\/?>/i,
      `<meta name="twitter:image" content="${safeImage}">`);
  }

  // Replace twitter:url
  if (/<meta\s+name=["']twitter:url["']/i.test(updated)) {
    updated = updated.replace(/<meta\s+name=["']twitter:url["']\s+content=["'][^"']*["']\s*\/?>/i,
      `<meta name="twitter:url" content="${safeUrl}">`);
  }

  return updated;
}

// Serve static compiled assets (.js, .wasm, icons, css, etc.)
// index: false ensures root '/' and SPA URLs reach our dynamic handler below
app.use(express.static(publicPath, {
  index: false,
  maxAge: '1d',
  setHeaders: (res, filePath) => {
    if (filePath.endsWith('.html')) {
      res.setHeader('Cache-Control', 'no-cache');
    }
  }
}));

app.get('*', async (req, res) => {
  // If requesting a static resource with an extension that wasn't found in publicPath, return 404
  const ext = path.extname(req.path);
  if (ext && ext !== '.html') {
    return res.status(404).send('Not found');
  }

  const rawHtml = getIndexHtmlTemplate();
  if (!rawHtml) {
    return res.status(200).send('Czytella API Backend is running. Deploy frontend assets to public/ to view web app.');
  }

  // Check if a listing was requested
  // Supports ?listing=ID, ?id=ID, /ogloszenie/ID, /listing/ID, /ksiazka/ID
  let listingId = req.query.listing || req.query.id;
  if (!listingId) {
    const pathMatch = req.path.match(/^\/(?:ogloszenie|listing|ksiazka)\/([^/?#]+)/i);
    if (pathMatch) {
      listingId = decodeURIComponent(pathMatch[1]);
    }
  }

  if (listingId) {
    const listing = await findListingById(listingId);
    if (listing) {
      const forwardedProto = req.headers['x-forwarded-proto'];
      const protocol = forwardedProto ? forwardedProto.split(',')[0].trim() : (req.secure ? 'https' : 'http');
      const forwardedHost = req.headers['x-forwarded-host'];
      const host = forwardedHost ? forwardedHost.split(',')[0].trim() : (req.get('host') || 'czytella.pl');
      const baseUrl = host.includes('railway.app') ? 'https://czytella.pl' : `${protocol}://${host}`;
      const pageUrl = `${baseUrl}/?listing=${encodeURIComponent(listing.id)}`;

      let effectiveCoverUrl = listing.coverUrl ? listing.coverUrl.trim() : '';
      if (effectiveCoverUrl.startsWith('data:image/')) {
        effectiveCoverUrl = `${baseUrl}/api/listings/${encodeURIComponent(listing.id)}/cover`;
      } else if (effectiveCoverUrl.startsWith('//')) {
        effectiveCoverUrl = 'https:' + effectiveCoverUrl;
      } else if (effectiveCoverUrl.startsWith('http://')) {
        effectiveCoverUrl = effectiveCoverUrl.replace('http://', 'https://');
      } else if (!effectiveCoverUrl.startsWith('http')) {
        effectiveCoverUrl = `${baseUrl}/icons/og-image.png`;
      }

      const conditionLabels = {
        asNew: 'Jak nowa',
        veryGood: 'Bardzo dobry',
        good: 'Dobry',
        acceptable: 'Ślady używania'
      };
      const conditionText = conditionLabels[listing.condition] || listing.condition || 'Dobry';

      let typeText = 'Wymiana lub sprzedaż';
      if (listing.type === 'exchange') {
        typeText = 'Tylko wymiana';
      } else if (listing.type === 'sale') {
        typeText = `Sprzedaż: ${listing.price ? listing.price + ' zł' : ''}`;
      } else if (listing.price) {
        typeText = `Wymiana lub sprzedaż (${listing.price} zł)`;
      }

      const locParts = [listing.city, listing.district].filter(Boolean);
      const locText = locParts.length > 0 ? locParts.join(', ') : 'Polska';

      const title = `📚 ${listing.title} – ${listing.author} | Czytella`;
      const description = `${typeText} • Lokalizacja: ${locText} • Stan: ${conditionText}. Kliknij, aby przejść do ogłoszenia w aplikacji Czytella!`;

      const injectedHtml = injectOpenGraphTags(rawHtml, {
        title,
        description,
        imageUrl: effectiveCoverUrl,
        pageUrl
      });

      res.setHeader('Content-Type', 'text/html; charset=utf-8');
      res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
      return res.send(injectedHtml);
    }
  }

  // Normal request without listing: serve index.html
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.setHeader('Cache-Control', 'no-cache');
  return res.send(rawHtml);
});

app.listen(port, () => {
  console.log(`🚀 Czytella server listening on port ${port}`);
});
