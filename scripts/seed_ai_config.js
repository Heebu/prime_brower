const PROJECT_ID = 'prime-news-media';
const BASE_URL = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

// Default AI configuration for Prime Browser
const aiConfig = {
  id: 'ai',
  model: 'gemini-1.5-flash',
  provider: 'google_gemini',
  active: true,
  description: 'Prime Browser Cloud AI Copilot default backend configuration',
  temperature: 0.5,
  maxOutputTokens: 1000,
  updatedAt: new Date().toISOString()
};

function toFirestoreFields(obj) {
  const fields = {};
  for (const [key, val] of Object.entries(obj)) {
    if (key === 'id') continue;
    if (typeof val === 'string') {
      if (key === 'updatedAt') {
        fields[key] = { timestampValue: val };
      } else {
        fields[key] = { stringValue: val };
      }
    } else if (typeof val === 'number') {
      if (Number.isInteger(val)) {
        fields[key] = { integerValue: val.toString() };
      } else {
        fields[key] = { doubleValue: val };
      }
    } else if (typeof val === 'boolean') {
      fields[key] = { booleanValue: val };
    }
  }
  return { fields };
}

async function seedAiConfig() {
  console.log('=======================================================');
  console.log(`🔥 Seeding /app_config/ai for Project: ${PROJECT_ID}`);
  console.log('=======================================================');

  // Allow passing key via CLI argument: node scripts/seed_ai_config.js <apiKey>
  const cliKey = process.argv[2];
  if (cliKey) {
    aiConfig.geminiApiKey = cliKey;
    console.log(`🔑 Attached API key from CLI arguments.`);
  }

  const url = `${BASE_URL}/app_config/${aiConfig.id}`;
  const body = JSON.stringify(toFirestoreFields(aiConfig));

  try {
    const res = await fetch(url, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body
    });

    if (!res.ok) {
      const errText = await res.text();
      console.error(`❌ Failed to seed /app_config/ai: ${res.status} ${errText}`);
    } else {
      console.log(`✅ Successfully seeded /app_config/ai document into Firestore!`);
      const result = await res.json();
      console.log('Document path:', result.name);
    }
  } catch (err) {
    console.error('❌ Network error during seeding:', err.message);
  }
}

seedAiConfig().catch(console.error);
