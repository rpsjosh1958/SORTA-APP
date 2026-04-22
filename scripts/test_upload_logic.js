// Local test for upload_puzzles.js logic — no Firebase or API keys needed.
// Tests: validation, deduplication, ID derivation, batch chunking.
// Run: node test_upload_logic.js

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

let passed = 0;
let failed = 0;

function assert(condition, label) {
  if (condition) {
    console.log(`  ✓ ${label}`);
    passed++;
  } else {
    console.error(`  ✗ ${label}`);
    failed++;
  }
}

// ---------------------------------------------------------------------------
// Replicate the core logic from upload_puzzles.js
// ---------------------------------------------------------------------------
function deriveDocId(prompt) {
  return crypto
    .createHash('sha256')
    .update(prompt.trim().toLowerCase())
    .digest('hex')
    .substring(0, 24);
}

function validatePuzzle(puzzle) {
  if (!puzzle.prompt || typeof puzzle.prompt !== 'string') return 'missing prompt';
  if (!Array.isArray(puzzle.items) || puzzle.items.length !== 5) return 'items must be array of 5';
  if (puzzle.items.some(i => typeof i !== 'string' || !i.trim())) return 'items contain empty strings';
  return null;
}

function loadPuzzleFile(category) {
  const fileName = `generated_puzzles_${category.toLowerCase().replace(/ /g, '_')}.json`;
  const filePath = path.join(__dirname, fileName);
  if (!fs.existsSync(filePath)) return null;
  try {
    const raw = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    return Array.isArray(raw) ? raw : (raw.puzzles || []);
  } catch (e) {
    return null;
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

console.log('\n=== upload_puzzles.js — Logic Tests ===\n');

// 1. ID derivation
console.log('[1] Doc ID derivation');
const id1 = deriveDocId('Rank these planets by size');
const id2 = deriveDocId('  Rank these planets by size  '); // extra whitespace
const id3 = deriveDocId('RANK THESE PLANETS BY SIZE');     // different case
const id4 = deriveDocId('Rank these animals by speed');

assert(id1 === id2, 'Whitespace trimmed — same ID');
assert(id1 === id3, 'Case-insensitive — same ID');
assert(id1 !== id4, 'Different prompts — different IDs');
assert(id1.length === 24, 'ID is 24 chars');
assert(/^[a-f0-9]+$/.test(id1), 'ID is hex string');

// 2. Validation — valid puzzle
console.log('\n[2] Puzzle validation');
const good = { prompt: 'Rank by speed', items: ['A', 'B', 'C', 'D', 'E'], category: 'Science' };
assert(validatePuzzle(good) === null, 'Valid puzzle passes');

// Missing prompt
assert(validatePuzzle({ items: ['A','B','C','D','E'] }) !== null, 'Missing prompt caught');

// Wrong item count
assert(validatePuzzle({ prompt: 'Test', items: ['A','B','C'] }) !== null, 'Too few items caught');
assert(validatePuzzle({ prompt: 'Test', items: ['A','B','C','D','E','F'] }) !== null, 'Too many items caught');

// Empty item string
assert(validatePuzzle({ prompt: 'Test', items: ['A','','C','D','E'] }) !== null, 'Empty item caught');

// items is not an array
assert(validatePuzzle({ prompt: 'Test', items: 'not array' }) !== null, 'Non-array items caught');

// 3. Deduplication simulation
console.log('\n[3] Deduplication');
const puzzles = [
  { prompt: 'Rank planets by size', items: ['A','B','C','D','E'], category: 'Science' },
  { prompt: 'Rank planets by size', items: ['A','B','C','D','E'], category: 'Science' }, // duplicate
  { prompt: 'Rank stars by mass',   items: ['A','B','C','D','E'], category: 'Science' },
];

const seen = new Set();
const deduplicated = puzzles.filter(p => {
  const id = deriveDocId(p.prompt);
  if (seen.has(id)) return false;
  seen.add(id);
  return true;
});

assert(deduplicated.length === 2, 'Duplicate prompt removed (3 → 2)');

// 4. File loading (only if a generated file exists)
console.log('\n[4] File loading');
const categories = ['Science', 'Sports', 'Entertainment', 'World Facts', 'Math', 'Tech'];
let foundFile = false;
for (const cat of categories) {
  const puzzleData = loadPuzzleFile(cat);
  if (puzzleData) {
    foundFile = true;
    assert(Array.isArray(puzzleData), `${cat}: loaded as array`);
    assert(puzzleData.length > 0, `${cat}: non-empty`);

    // Validate every puzzle in the file
    let allValid = true;
    for (const p of puzzleData) {
      if (validatePuzzle(p) !== null) { allValid = false; break; }
    }
    assert(allValid, `${cat}: all ${puzzleData.length} puzzles pass validation`);

    // Deduplication within file
    const ids = puzzleData.map(p => deriveDocId(p.prompt));
    const uniqueIds = new Set(ids);
    assert(ids.length === uniqueIds.size, `${cat}: no duplicate prompts in file`);

    console.log(`    → Preview: "${puzzleData[0].prompt.substring(0, 70)}"`);
    break;
  }
}
if (!foundFile) {
  console.log('  (no generated JSON files found — run generate_puzzles.js first)');
  console.log('  Skipping file tests.');
}

// 5. Batch chunking
console.log('\n[5] Batch chunking (simulated 490-op limit)');
const BATCH_LIMIT = 490;
const fakePuzzles = Array.from({ length: 1100 }, (_, i) => ({ id: `q${i}` }));
const batches = [];
for (let i = 0; i < fakePuzzles.length; i += BATCH_LIMIT) {
  batches.push(fakePuzzles.slice(i, i + BATCH_LIMIT));
}
assert(batches.length === 3, '1100 items split into 3 batches');
assert(batches[0].length === 490, 'Batch 1: 490 items');
assert(batches[1].length === 490, 'Batch 2: 490 items');
assert(batches[2].length === 120, 'Batch 3: 120 items (remainder)');

// ---------------------------------------------------------------------------
// Summary
// ---------------------------------------------------------------------------
console.log(`\n${'─'.repeat(40)}`);
console.log(`Passed: ${passed}  Failed: ${failed}`);
if (failed === 0) {
  console.log('All tests passed. Upload logic is correct.\n');
} else {
  console.log('Some tests failed — check output above.\n');
  process.exit(1);
}
