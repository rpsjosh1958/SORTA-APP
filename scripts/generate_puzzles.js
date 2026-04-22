require('dotenv').config();
const { OpenAI } = require('openai');
const fs = require('fs');

const openai = new OpenAI({
    apiKey: process.env.OPENAI_API_KEY,
    baseURL: 'https://integrate.api.nvidia.com/v1',
});

const CATEGORIES = ['Sports', 'Entertainment', 'Pop Culture', 'Social Media'];
const MAX_RETRIES = 3;

// Extra guidance injected per category
const CATEGORY_HINTS = {
    'Sports': `
- Focus heavily on football/soccer: Premier League, Champions League, World Cup, AFCON, Ghana Black Stars, top African players.
- Include a good amount of NBA basketball: points records, titles, famous players.
- Add a small amount of Formula 1: world championships, race wins, famous drivers.
- Avoid hockey, baseball, cricket, and other sports not widely followed in West Africa.`,

    'Pop Culture': `
- Mix mainstream topics: music, movies, celebrities, internet/meme culture, viral moments.
- Include widely-known mythology — easy Greek/Roman myths everyone knows (e.g. ranking gods by domain power, heroes by number of labours, myths by how well-known they are). Keep these very accessible.
- Nothing obscure or academic — if a 16-year-old in Accra with a phone would know it, it's fair game.`,

    'Entertainment': `
- Focus on Afrobeats, global pop music, streaming numbers, box office hits, TV shows, award records.
- Include African artists and global crossover hits alongside Hollywood and streaming culture.`,

    'Social Media': `
- Focus on platform stats, viral trends, follower counts, launch years, usage in Africa and globally.
- Ghana-relevant hashtag moments, African influencers, and global Twitter/TikTok/Instagram culture.`,
};

// Extract JSON from a response that may contain prose, markdown fences, or raw JSON.
function extractJSON(raw) {
    let cleaned = raw.replace(/```json/gi, '').replace(/```/g, '').trim();

    try { return JSON.parse(cleaned); } catch (_) {}

    const firstBrace   = cleaned.indexOf('{');
    const firstBracket = cleaned.indexOf('[');
    let start = -1;
    let openChar, closeChar;

    if (firstBrace === -1 && firstBracket === -1) return null;

    if (firstBrace === -1 || (firstBracket !== -1 && firstBracket < firstBrace)) {
        start = firstBracket; openChar = '['; closeChar = ']';
    } else {
        start = firstBrace; openChar = '{'; closeChar = '}';
    }

    let depth = 0, end = -1;
    for (let i = start; i < cleaned.length; i++) {
        if (cleaned[i] === openChar) depth++;
        else if (cleaned[i] === closeChar) { depth--; if (depth === 0) { end = i; break; } }
    }

    if (end === -1) return null;
    try { return JSON.parse(cleaned.substring(start, end + 1)); } catch (_) { return null; }
}

async function generateBatch(category, count = 60) {
    console.log(`\n[${category}] Generating ${count} puzzles...`);

    const categoryHint = CATEGORY_HINTS[category] || '';

    const userPrompt = `Generate exactly ${count} "Sorta" ranking puzzles for the category: "${category}".

Rules:
- Each puzzle has a "prompt" string and an "items" array of exactly 5 strings in the CORRECT sorted order.
- The "category" field must be "${category}".
- Difficulty: Easy-Medium. The player should immediately know the obvious first and last items, and only have to reason about the middle three.
- Gaps: Ensure the metrics between the 5 items have wide, obvious gaps. Avoid items that are too close to call.
- Audience & Topics: Make questions highly relatable, heavily focusing on a West African / Ghanaian audience. Draw from everyday conversations, Twitter/X debates, Afrobeats, local and global sports, lifestyle, and popular culture.
- Good examples: "Rank these Afrobeats artists by Spotify monthly listeners", "Rank these Premier League teams by total league titles", "Rank these social media platforms by launch year".
- Bad examples: obscure historical dates, academic science, complex math, US-only pop culture, items with differences too small to reasonably guess.
${categoryHint}
- Output ONLY a JSON object with a "puzzles" key. No explanation, no markdown, no prose.

Format:
{"puzzles":[{"prompt":"Rank these...","items":["First","Second","Third","Fourth","Fifth"],"category":"${category}"}]}`;

    for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
        try {
            if (attempt > 1) console.log(`  Retry ${attempt}/${MAX_RETRIES}...`);

            const response = await openai.chat.completions.create({
                model: 'meta/llama-3.3-70b-instruct',
                messages: [
                    { role: 'system', content: 'You are a JSON API. You output only valid JSON, never prose or markdown.' },
                    { role: 'user', content: userPrompt },
                ],
                response_format: { type: 'json_object' },
                temperature: 0.8,
                top_p: 1,
                max_tokens: 8192,
            });

            const raw = response.choices[0].message.content;
            const parsed = extractJSON(raw);

            if (!parsed) {
                console.error(`  Attempt ${attempt}: could not extract JSON.`);
                console.error(`  Raw (first 200 chars): ${raw.substring(0, 200)}`);
                continue;
            }

            const puzzles = Array.isArray(parsed) ? parsed : (parsed.puzzles || []);

            if (!Array.isArray(puzzles) || puzzles.length === 0) {
                console.error(`  Attempt ${attempt}: parsed JSON but found no puzzles array.`);
                continue;
            }

            const valid = puzzles.filter(p =>
                p.prompt && Array.isArray(p.items) && p.items.length === 5
            );
            const dropped = puzzles.length - valid.length;
            if (dropped > 0) console.log(`  Dropped ${dropped} malformed puzzle(s).`);

            // Merge with existing file so previous generations aren't lost
            const fileName = `generated_puzzles_${category.toLowerCase().replace(/ /g, '_')}.json`;
            let existing = [];
            if (fs.existsSync(fileName)) {
                try {
                    const raw = JSON.parse(fs.readFileSync(fileName, 'utf8'));
                    existing = Array.isArray(raw) ? raw : (raw.puzzles || []);
                } catch (_) {}
            }

            const existingPrompts = new Set(existing.map(p => p.prompt.trim().toLowerCase()));
            const newUnique = valid.filter(p => !existingPrompts.has(p.prompt.trim().toLowerCase()));
            const merged = [...existing, ...newUnique];

            fs.writeFileSync(fileName, JSON.stringify(merged, null, 2));
            console.log(`  ✓ ${newUnique.length} new added, ${existing.length} kept → ${merged.length} total in ${fileName}`);
            return;

        } catch (err) {
            console.error(`  Attempt ${attempt} error:`, err.message);
        }
    }

    console.error(`  ✗ Failed after ${MAX_RETRIES} attempts for category: ${category}`);
}

const args = process.argv.slice(2);
const selectedCategory = args[0];
const count = parseInt(args[1], 10) || 60;

if (!selectedCategory) {
    console.log('Usage: node generate_puzzles.js <CATEGORY|ALL> [count]');
    console.log('Categories:', CATEGORIES.join(', '));
    console.log('Example:  node generate_puzzles.js Sports 60');
} else if (selectedCategory === 'ALL') {
    (async () => {
        for (const cat of CATEGORIES) {
            await generateBatch(cat, count);
            await new Promise(r => setTimeout(r, 2000));
        }
        console.log('\nDone.');
    })();
} else if (CATEGORIES.includes(selectedCategory)) {
    generateBatch(selectedCategory, count).then(() => console.log('\nDone.'));
} else {
    console.error(`Unknown category: "${selectedCategory}"`);
    console.log('Valid options:', CATEGORIES.join(', '), 'or ALL');
    process.exit(1);
}
