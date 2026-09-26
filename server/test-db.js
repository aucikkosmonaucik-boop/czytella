const { Pool } = require('pg');
require('dotenv').config();

const connectionString = process.argv[2] || process.env.DATABASE_URL;

if (!connectionString) {
  console.log('\n❌ Brak parametru connectionString ani zmiennej DATABASE_URL.');
  console.log('Użycie:');
  console.log('  node server/test-db.js "twoj_connection_string_z_railway"\n');
  process.exit(1);
}

console.log('🔌 Próba połączenia z bazą danych PostgreSQL...');
const pool = new Pool({
  connectionString,
  ssl: connectionString.includes('railway') || connectionString.includes('localhost')
    ? false
    : { rejectUnauthorized: false }
});

pool.connect()
  .then(async client => {
    console.log('✅ Połączenie nawiązane pomyślnie!');
    const res = await client.query('SELECT current_database() as db, version() as ver, NOW() as time;');
    console.log('📊 Informacje o bazie danych:');
    console.log('  - Nazwa bazy:', res.rows[0].db);
    console.log('  - Czas bazy:', res.rows[0].time);
    console.log('  - Wersja PostgreSQL:', res.rows[0].ver.split(' on ')[0]);
    client.release();
    pool.end();
    process.exit(0);
  })
  .catch(err => {
    console.error('❌ Błąd połączenia z bazą:', err.message);
    pool.end();
    process.exit(1);
  });
