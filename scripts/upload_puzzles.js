require('dotenv').config();
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// ---------------------------------------------------------------------------
// Firebase init — requires service-account.json in this directory.
// Get it from: Firebase Console → Project Settings → Service Accounts → Generate new private key
// ---------------------------------------------------------------------------
const SERVICE_ACCOUNT_PATH = path.join(__dirname, 'service-account.json');
if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
  console.error('\nERROR: service-account.json not found in scripts/');
  console.error('Download it from Firebase Console → Project Settings → Service Accounts → Generate new private key\n');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(require(SERVICE_ACCOUNT_PATH)),
});

const db = admin.firestore();

const CATEGORIES = [
  'Sports',
  'Entertainment',
  'Pop Culture',
  'Social Media',
  'Science',
  'Math',
  'Tech',
  'World Facts'
];
const FIRESTORE_BATCH_LIMIT = 490; // Stay under 500 op limit

// Stable, content-derived document ID — natural deduplication.
// Same prompt text always maps to the same Firestore doc ID,
// so re-running the upload never creates duplicates.
function deriveDocId(prompt) {
  return crypto
    .createHash('sha256')
    .update(prompt.trim().toLowerCase())
    .digest('hex')
    .substring(0, 24);
}

function loadPuzzleFile(category) {
  const fileName = `generated_puzzles_${category.toLowerCase().replace(/ /g, '_')}.json`;
  const filePath = path.join(__dirname, fileName);
  if (!fs.existsSync(filePath)) return null;
  try {
    const raw = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    // The generator wraps in { puzzles: [...] } or returns an array directly
    return Array.isArray(raw) ? raw : (raw.puzzles || []);
  } catch (e) {
    console.error(`  [ERROR] Could not parse ${fileName}:`, e.message);
    return null;
  }
}

function validatePuzzle(puzzle) {
  if (!puzzle.prompt || typeof puzzle.prompt !== 'string') return 'missing prompt';
  if (!Array.isArray(puzzle.items) || puzzle.items.length !== 5) return 'items must be array of 5';
  if (puzzle.items.some(i => typeof i !== 'string' || !i.trim())) return 'items contain empty strings';
  return null;
}

async function uploadCategory(category, dryRun) {
  const puzzles = loadPuzzleFile(category);
  if (!puzzles) {
    console.log(`  No file found — run: node generate_puzzles.js ${category}`);
    return { uploaded: 0, skipped: 0, invalid: 0 };
  }

  console.log(`  Loaded ${puzzles.length} puzzles from file`);

  // Validate all puzzles first
  const valid = [];
  let invalid = 0;
  for (const p of puzzles) {
    const err = validatePuzzle(p);
    if (err) {
      console.log(`  [INVALID] ${err}: "${String(p.prompt || '').substring(0, 60)}"`);
      invalid++;
    } else {
      valid.push(p);
    }
  }

  // Check which doc IDs already exist in Firestore
  const entries = valid.map(p => ({ puzzle: p, docId: deriveDocId(p.prompt) }));
  const existingSnapshots = await Promise.all(
    entries.map(e => db.collection('questions').doc(e.docId).get())
  );

  const toUpload = entries.filter((_, i) => !existingSnapshots[i].exists);
  const skipped = entries.length - toUpload.length;

  console.log(`  ${toUpload.length} new | ${skipped} already exist | ${invalid} invalid`);

  if (dryRun) {
    console.log('  [DRY RUN] No writes made.');
    return { uploaded: 0, skipped, invalid };
  }

  if (toUpload.length === 0) return { uploaded: 0, skipped, invalid };

  // Write in Firestore batch chunks
  let uploaded = 0;
  for (let i = 0; i < toUpload.length; i += FIRESTORE_BATCH_LIMIT) {
    const chunk = toUpload.slice(i, i + FIRESTORE_BATCH_LIMIT);
    const batch = db.batch();
    for (const { puzzle, docId } of chunk) {
      batch.set(db.collection('questions').doc(docId), {
        id: docId,
        prompt: puzzle.prompt.trim(),
        items: puzzle.items.map(item => String(item).trim()),
        category: puzzle.category || category,
        difficulty: puzzle.difficulty || 'medium',
        isActive: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    uploaded += chunk.length;
    console.log(`  Committed batch of ${chunk.length}`);
  }

  return { uploaded, skipped, invalid };
}

async function main() {
  const args = process.argv.slice(2);
  const dryRun = args.includes('--dry-run');
  const categoryArg = args.find(a => !a.startsWith('--'));

  const targets =
    !categoryArg || categoryArg === 'ALL'
      ? CATEGORIES
      : CATEGORIES.includes(categoryArg)
      ? [categoryArg]
      : null;

  if (!targets) {
    console.error(`\nUnknown category: "${categoryArg}"`);
    console.error(`Valid options: ALL, ${CATEGORIES.join(', ')}\n`);
    process.exit(1);
  }

  console.log(`\nSORTA — Puzzle Upload ${dryRun ? '[DRY RUN] ' : ''}→ Firestore`);
  console.log(`Categories: ${targets.join(', ')}\n`);

  let totalUploaded = 0;
  let totalSkipped = 0;
  let totalInvalid = 0;

  for (const cat of targets) {
    console.log(`[${cat}]`);
    const { uploaded, skipped, invalid } = await uploadCategory(cat, dryRun);
    totalUploaded += uploaded;
    totalSkipped += skipped;
    totalInvalid += invalid;
    console.log();
  }

  console.log('─'.repeat(50));
  console.log(`Total uploaded : ${totalUploaded}`);
  console.log(`Total skipped  : ${totalSkipped} (already in Firestore)`);
  console.log(`Total invalid  : ${totalInvalid} (malformed, not uploaded)`);
  console.log();

  process.exit(0);
}

main().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
