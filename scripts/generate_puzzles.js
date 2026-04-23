require('dotenv').config();
const { OpenAI } = require('openai');
const fs = require('fs');

const openai = new OpenAI({
    apiKey: process.env.OPENAI_API_KEY,
    baseURL: 'https://integrate.api.nvidia.com/v1',
});

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
const MAX_RETRIES = 3;

// Friendly, relatable guidance for the AI
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
- CRITICAL: The "items" array must contain the NAMES of platforms or people (e.g. ["TikTok", "Facebook"]), NOT just numbers.`,

    'Science': `
- Fun, observable facts! 
- Animals: Who is faster? Who lives longer? Who is heavier? (Cheetah, Snail, Elephant, etc.)
- Space: Planet sizes, how hot they are, or distance from the sun.
- CRITICAL: The "items" array must contain the NAMES of animals or planets, NOT the numbers.`,

    'Math': `
- Fun everyday math with "High Stakes"!
- Big Money: Rank total costs of expensive items, or approximate budgets (e.g. cost of 5 iPhones vs a used car).
- CRITICAL: The "items" array must contain the actual entities or simple expressions (e.g. ["5 iPhones", "Used Car"]), NOT just the final dollar value.`,

    'Tech': `
- "Tech Wars" and the Power of Silicon!
- The Billionaires: Rank tech CEOs by net worth or companies by Market Cap.
- The Speed Race: Rank devices by processor speed, internet tech (3G to 6G), or charging watts.
- Impact & Reach: Rank the "Big 5" apps by total global users or annual revenue.
- Future Tech: Rank storage sizes or data speeds (Mbps vs Gbps).
- NO social media drama—keep it about the power and scale of technology.`,

    'World Facts': `
- "Around the World" trivia!
- Geography: Tallest buildings, longest rivers, biggest countries by land.
- Languages: Most spoken languages in the world or in Africa.
- History: Famous kings/leaders, independence years for African countries.
- Interesting records that make people go "wow!"`,
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
    console.log(`\n[${category}] Generating ${count} fun, relatable puzzles...`);

    const categoryHint = CATEGORY_HINTS[category] || '';

    const userPrompt = `Generate exactly ${count} "Sorta" ranking puzzles for the category: "${category}".

Rules:
- Each puzzle must have a "prompt" and an "items" array of exactly 5 strings in CORRECT sorted order (lowest/earliest to highest/latest).
- CRITICAL: The "items" array MUST contain the NAMES or ENTITIES being ranked (e.g. ["Nigeria", "Ghana", "Egypt"] or ["iPhone 13", "iPhone 14", "iPhone 15"]). 
- NEVER output just numbers or metrics (like "10 million", "2004", "$500") as the items unless the items themselves ARE the objective numbers (e.g. a Math category ranking [10, 50, 100]).
- Category: "${category}".
- Difficulty: FUN and ACCESSIBLE.
- Topic Focus: ${categoryHint}

Format:
{"puzzles":[{"prompt":"Rank these platforms by monthly users...","items":["Snapchat","TikTok","Instagram","YouTube","Facebook"],"category":"${category}"}]}`;

    for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
        try {
            const response = await openai.chat.completions.create({
                model: 'meta/llama-3.3-70b-instruct',
                messages: [
                    { role: 'system', content: 'You are a fun and helpful puzzle generator. You only output valid JSON.' },
                    { role: 'user', content: userPrompt },
                ],
                response_format: { type: 'json_object' },
                temperature: 0.8,
                max_tokens: 8192,
            });

            const raw = response.choices[0].message.content;
            const parsed = extractJSON(raw);
            if (!parsed) continue;

            const puzzles = Array.isArray(parsed) ? parsed : (parsed.puzzles || []);
            const valid = puzzles.filter(p => p.prompt && Array.isArray(p.items) && p.items.length === 5);

            const fileName = `generated_puzzles_${category.toLowerCase().replace(/ /g, '_')}.json`;
            fs.writeFileSync(fileName, JSON.stringify(valid, null, 2));
            console.log(`  ✓ Created ${valid.length} fun puzzles in ${fileName}`);
            return;
        } catch (err) {
            console.error(`  Attempt ${attempt} error:`, err.message);
        }
    }
}

const args = process.argv.slice(2);
const selectedCategory = args[0];
const count = parseInt(args[1], 10) || 60;

if (selectedCategory === 'REDO_NEW') {
    (async () => {
        const newCats = ['Science', 'Math', 'Tech', 'World Facts'];
        for (const cat of newCats) {
            await generateBatch(cat, 60);
            await new Promise(r => setTimeout(r, 2000));
        }
        console.log('\nFresh generation complete.');
    })();
} else if (CATEGORIES.includes(selectedCategory)) {
    generateBatch(selectedCategory, count);
} else {
    console.log('Use REDO_NEW to regenerate the 4 new categories.');
}
