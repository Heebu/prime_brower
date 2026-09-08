const PROJECT_ID = 'prime-news-media';
const BASE_URL = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

const suggestions = [
  {
    id: 'sug_flutter_docs',
    query: 'Flutter 3.44 official documentation',
    category: 'Development',
    targetUrl: 'https://docs.flutter.dev',
    popularity: 99
  },
  {
    id: 'sug_prime_privacy',
    query: 'Prime Browser built-in privacy shields',
    category: 'Privacy',
    targetUrl: 'prime://shields',
    popularity: 98
  },
  {
    id: 'sug_github',
    query: 'GitHub open source repositories',
    category: 'Development',
    targetUrl: 'https://github.com',
    popularity: 95
  },
  {
    id: 'sug_quantum_qubit',
    query: 'Ambient temperature quantum computing',
    category: 'Trending',
    popularity: 94
  },
  {
    id: 'sug_ai_reasoning',
    query: 'On-device neural reasoning models for mobile',
    category: 'AI',
    popularity: 92
  },
  {
    id: 'sug_hacker_news',
    query: 'Hacker News tech community discussions',
    category: 'Tech',
    targetUrl: 'https://news.ycombinator.com',
    popularity: 90
  },
  {
    id: 'sug_dart_devtools',
    query: 'Dart devtools inspect element tutorial',
    category: 'Development',
    popularity: 88
  },
  {
    id: 'sug_wasm_gc',
    query: 'WebAssembly GC 2.0 native execution',
    category: 'Tech',
    popularity: 87
  },
  {
    id: 'sug_wikipedia',
    query: 'Wikipedia the free encyclopedia',
    category: 'Quick Links',
    targetUrl: 'https://wikipedia.org',
    popularity: 86
  },
  {
    id: 'sug_exoplanet_water',
    query: 'Habitable exoplanet atmospheric water discovery',
    category: 'Science',
    popularity: 85
  },
  {
    id: 'sug_post_quantum',
    query: 'Post-quantum lattice cryptography TLS standard',
    category: 'Privacy',
    popularity: 84
  },
  {
    id: 'sug_techcrunch',
    query: 'TechCrunch mobile and startup news',
    category: 'News',
    targetUrl: 'https://techcrunch.com',
    popularity: 83
  },
  {
    id: 'sug_zk_rollups',
    query: 'Zero-knowledge STARK rollup transactions',
    category: 'Crypto',
    popularity: 82
  },
  {
    id: 'sug_ars_technica',
    query: 'Ars Technica in-depth analysis',
    category: 'Tech',
    targetUrl: 'https://arstechnica.com',
    popularity: 80
  },
  {
    id: 'sug_nature_protein',
    query: 'Generative AI protein design for carbon capture',
    category: 'Science',
    popularity: 79
  },
  {
    id: 'sug_solid_state_battery',
    query: 'Solid-state vehicle batteries 10-minute charging',
    category: 'Tech',
    popularity: 78
  },
  {
    id: 'sug_reuters',
    query: 'Reuters global business and world news',
    category: 'News',
    targetUrl: 'https://reuters.com',
    popularity: 77
  },
  {
    id: 'sug_multi_agent_ai',
    query: 'Collaborative multi-agent software auditing',
    category: 'AI',
    popularity: 76
  },
  {
    id: 'sug_hyperloop',
    query: 'Hyperloop low pressure vacuum transit trials',
    category: 'Trending',
    popularity: 75
  },
  {
    id: 'sug_decentralized_id',
    query: 'Decentralized identity zero-knowledge credentials',
    category: 'Privacy',
    popularity: 74
  }
];

function toFirestoreFields(obj) {
  const fields = {};
  for (const [key, val] of Object.entries(obj)) {
    if (key === 'id') continue;
    if (typeof val === 'string') {
      fields[key] = { stringValue: val };
    } else if (typeof val === 'number') {
      fields[key] = { integerValue: val.toString() };
    } else if (typeof val === 'boolean') {
      fields[key] = { booleanValue: val };
    }
  }
  return { fields };
}

async function seedCollection(collectionName, items) {
  console.log(`\n🌱 Seeding collection: '${collectionName}' (${items.length} items)...`);
  let successCount = 0;
  for (const item of items) {
    const url = `${BASE_URL}/${collectionName}/${item.id}`;
    const body = JSON.stringify(toFirestoreFields(item));
    try {
      const res = await fetch(url, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body
      });
      if (!res.ok) {
        const txt = await res.text();
        console.error(`  ❌ Failed '${item.id}': ${res.status} ${txt}`);
      } else {
        successCount++;
        console.log(`  ✅ Seeded '${item.id}' [${item.category}] -> "${item.query}"`);
      }
    } catch (e) {
      console.error(`  ❌ Error on '${item.id}':`, e.message);
    }
  }
  console.log(`✨ Successfully seeded ${successCount}/${items.length} items into '${collectionName}'.`);
}

async function main() {
  console.log('=======================================================');
  console.log(`🔥 Seeding Suggestions for Project: ${PROJECT_ID}`);
  console.log('=======================================================');

  await seedCollection('search_suggestions', suggestions);
  await seedCollection('suggestions', suggestions);

  console.log('\n🎉 Seeding complete! Search suggestions are live in Firebase Firestore.');
}

main().catch(console.error);
