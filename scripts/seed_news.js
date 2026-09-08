const PROJECT_ID = 'prime-news-media';
const BASE_URL = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

const newsItems = [
  {
    id: 'news_tech_01',
    title: 'Breakthrough Quantum Processor Operates at Ambient Temperature',
    description: 'Researchers have unveiled a novel topological qubit architecture that maintains quantum coherence without cryogenic cooling, paving the way for desktop quantum acceleration.',
    source: 'TechCrunch',
    url: 'https://techcrunch.com',
    imageUrl: 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=800',
    category: 'Tech',
    readTimeMinutes: 4,
    publishedAt: new Date(Date.now() - 15 * 60 * 1000).toISOString()
  },
  {
    id: 'news_tech_02',
    title: 'WebAssembly GC 2.0 Delivers Native C++ Execution Speeds Inside Browsers',
    description: 'The World Wide Web Consortium finalizes the next-generation WASM standard, enabling browser-based game engines and complex toolkits to run with near-zero overhead.',
    source: 'Ars Technica',
    url: 'https://arstechnica.com',
    imageUrl: 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=800',
    category: 'Tech',
    readTimeMinutes: 3,
    publishedAt: new Date(Date.now() - 45 * 60 * 1000).toISOString()
  },
  {
    id: 'news_ai_01',
    title: 'On-Device Reasoning Models Match Frontier Multi-Trillion Parameter Clouds',
    description: 'A new distilled 7B neural reasoning architecture achieves 92% on MATH and HumanEval benchmarks while running entirely within mobile device RAM.',
    source: 'MIT Technology Review',
    url: 'https://technologyreview.com',
    imageUrl: 'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=800',
    category: 'AI',
    readTimeMinutes: 5,
    publishedAt: new Date(Date.now() - 30 * 60 * 1000).toISOString()
  },
  {
    id: 'news_ai_02',
    title: 'Autonomous AI Agents Form Real-Time Collaborative Research Networks',
    description: 'Simulated multi-agent software engineering ecosystems solve complex zero-day vulnerability audits in minutes through decentralized peer reviews.',
    source: 'Wired',
    url: 'https://wired.com',
    imageUrl: 'https://images.unsplash.com/photo-1620712943543-bcc4688e7485?w=800',
    category: 'AI',
    readTimeMinutes: 4,
    publishedAt: new Date(Date.now() - 90 * 60 * 1000).toISOString()
  },
  {
    id: 'news_privacy_01',
    title: 'Post-Quantum Lattice Cryptography Standards Deployed Globally Across Browsers',
    description: 'Global cybersecurity alliances enforce ML-KEM and SLH-DSA encryption for all TLS handshakes to future-proof internet traffic against quantum deciphering.',
    source: 'The Hacker News',
    url: 'https://thehackernews.com',
    imageUrl: 'https://images.unsplash.com/photo-1563986768609-322da13575f3?w=800',
    category: 'Privacy',
    readTimeMinutes: 4,
    publishedAt: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString()
  },
  {
    id: 'news_privacy_02',
    title: 'Global Regulators Ban Clandestine Audio & Canvas Hardware Fingerprinting',
    description: 'Strict enforcement penalties target covert cross-site trackers tracking users without explicit per-origin biometric consent.',
    source: 'Electronic Frontier Foundation',
    url: 'https://eff.org',
    imageUrl: 'https://images.unsplash.com/photo-1510511459019-5dda7724fd87?w=800',
    category: 'Privacy',
    readTimeMinutes: 3,
    publishedAt: new Date(Date.now() - 3 * 60 * 60 * 1000).toISOString()
  },
  {
    id: 'news_world_01',
    title: 'Renewable Clean Energy Surpasses 45% of Global Electrical Grid Consumption',
    description: 'Offshore wind arrays and community solar installations reach an unprecedented generation tipping point across both hemispheres.',
    source: 'Reuters',
    url: 'https://reuters.com',
    imageUrl: 'https://images.unsplash.com/photo-1466611653911-95081537e5b7?w=800',
    category: 'World',
    readTimeMinutes: 3,
    publishedAt: new Date(Date.now() - 4 * 60 * 60 * 1000).toISOString()
  },
  {
    id: 'news_world_02',
    title: 'Deep Space Observatory Confirms Atmospheric Water Vapor on Habitable Exoplanet',
    description: 'Spectroscopic analysis reveals clear ozone and atmospheric aerosol profiles on an Earth-sized rocky exoplanet in the habitable zone.',
    source: 'BBC News',
    url: 'https://bbc.com/news',
    imageUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=800',
    category: 'World',
    readTimeMinutes: 5,
    publishedAt: new Date(Date.now() - 5 * 60 * 60 * 1000).toISOString()
  },
  {
    id: 'news_crypto_01',
    title: 'Zero-Knowledge Rollup Networks Reach 50,000 Transactions Per Second',
    description: 'Novel recursive STARK provers compress cryptographic verification into single-block proofs, reducing cross-chain transaction fees to sub-cent levels.',
    source: 'CoinDesk',
    url: 'https://coindesk.com',
    imageUrl: 'https://images.unsplash.com/photo-1621416894569-0f39ed31d247?w=800',
    category: 'Crypto',
    readTimeMinutes: 3,
    publishedAt: new Date(Date.now() - 6 * 60 * 60 * 1000).toISOString()
  },
  {
    id: 'news_crypto_02',
    title: 'Central Banks Pilot Interoperable Cross-Border Digital Currency Clearing',
    description: 'International settlement networks eliminate multi-day correspondent banking delays using instant atomic token swaps.',
    source: 'Bloomberg',
    url: 'https://bloomberg.com',
    imageUrl: 'https://images.unsplash.com/photo-1559526324-4b87b5e36e44?w=800',
    category: 'Crypto',
    readTimeMinutes: 4,
    publishedAt: new Date(Date.now() - 7 * 60 * 60 * 1000).toISOString()
  },
  {
    id: 'news_gaming_01',
    title: 'Neural Path Tracing Brings Cinematic Ray Tracing to Mobile Handhelds',
    description: 'Machine-learning denoising algorithms synthesize infinite bounce global illumination in real-time at 120 frames per second on mobile GPUs.',
    source: 'IGN',
    url: 'https://ign.com',
    imageUrl: 'https://images.unsplash.com/photo-1538481199705-c710c4e965fc?w=800',
    category: 'Gaming',
    readTimeMinutes: 3,
    publishedAt: new Date(Date.now() - 8 * 60 * 60 * 1000).toISOString()
  },
  {
    id: 'news_gaming_02',
    title: 'Next-Generation Spatial Audio Engine Recreates Physical Acoustic Resonance',
    description: 'Developers integrate dynamic room-impulse modeling that adapts audio reflections to the players real and virtual environments.',
    source: 'Polygon',
    url: 'https://polygon.com',
    imageUrl: 'https://images.unsplash.com/photo-1511512578047-dfb367046420?w=800',
    category: 'Gaming',
    readTimeMinutes: 4,
    publishedAt: new Date(Date.now() - 9 * 60 * 60 * 1000).toISOString()
  },
  {
    id: 'news_tech_03',
    title: 'Lithium-Sulfur Solid-State Batteries Enter Mass Vehicle Production',
    description: 'Next-gen solid-state energy cells achieve 600Wh/kg energy density with non-flammable ceramic electrolytes and 10-minute full charge cycles.',
    source: 'The Verge',
    url: 'https://theverge.com',
    imageUrl: 'https://images.unsplash.com/photo-1558441719-8b489c652756?w=800',
    category: 'Tech',
    readTimeMinutes: 4,
    publishedAt: new Date(Date.now() - 10 * 60 * 60 * 1000).toISOString()
  },
  {
    id: 'news_ai_03',
    title: 'Synthetic Biology AI Accurately Designs Novel Carbon-Capturing Enzymes',
    description: 'Generative protein design models synthesize novel catalyst enzymes capable of sequestering atmospheric carbon 15 times faster than natural chlorophyll.',
    source: 'Nature Biotechnology',
    url: 'https://nature.com',
    imageUrl: 'https://images.unsplash.com/photo-1532187863486-abf9dbad1b69?w=800',
    category: 'AI',
    readTimeMinutes: 5,
    publishedAt: new Date(Date.now() - 11 * 60 * 60 * 1000).toISOString()
  },
  {
    id: 'news_world_03',
    title: 'High-Speed Hyperloop Test Track Reaches Record 780 km/h in Low-Pressure Tube',
    description: 'Magnetic levitation passenger pod completes full-scale vacuum corridor test with passenger comfort and acoustic isolation verified.',
    source: 'Financial Times',
    url: 'https://ft.com',
    imageUrl: 'https://images.unsplash.com/photo-1513836279014-a89f7a76ae86?w=800',
    category: 'World',
    readTimeMinutes: 3,
    publishedAt: new Date(Date.now() - 12 * 60 * 60 * 1000).toISOString()
  },
  {
    id: 'news_privacy_03',
    title: 'Decentralized Identity Wallets Replace Traditional Passwords in Enterprise Standards',
    description: 'Zero-knowledge verifiable credentials eliminate server-side credential databases, rendering database breaches ineffective against user secrets.',
    source: 'ZDNet',
    url: 'https://zdnet.com',
    imageUrl: 'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=800',
    category: 'Privacy',
    readTimeMinutes: 4,
    publishedAt: new Date(Date.now() - 13 * 60 * 60 * 1000).toISOString()
  }
];

const advertItems = [
  {
    id: 'ad_prime_sync',
    advertiserName: 'Prime Cloud Sync',
    headline: 'Sync Tabs & Bookmarks End-to-End',
    description: 'Never lose your research. Secure encrypted sync across all your phones, tablets, and desktop browsers.',
    ctaText: 'Enable Sync',
    targetUrl: 'prime://sync',
    imageUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=800',
    badge: 'Featured',
    adType: 'firebaseCustom'
  },
  {
    id: 'ad_prime_copilot',
    advertiserName: 'Prime AI Assistant',
    headline: 'Summarize Any Webpage in Seconds',
    description: 'Extract key takeaways, translate articles, and query page content directly with high-intelligence on-device AI.',
    ctaText: 'Try AI Copilot',
    targetUrl: 'prime://copilot',
    imageUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800',
    badge: 'Prime AI',
    adType: 'firebaseCustom'
  },
  {
    id: 'ad_cyber_shield',
    advertiserName: 'Prime Privacy Shields',
    headline: 'Block Ad Trackers & Fingerprinting',
    description: 'Browse the web at lightning speed with built-in defense against intrusive ads, cryptominers, and tracking cookies.',
    ctaText: 'View Shields',
    targetUrl: 'prime://shields',
    imageUrl: 'https://images.unsplash.com/photo-1563986768609-322da13575f3?w=800',
    badge: 'Protection',
    adType: 'firebaseCustom'
  }
];

function toFirestoreFields(obj) {
  const fields = {};
  for (const [key, val] of Object.entries(obj)) {
    if (key === 'id') continue;
    if (typeof val === 'string') {
      if (key === 'publishedAt') {
        fields[key] = { timestampValue: val };
      } else {
        fields[key] = { stringValue: val };
      }
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
        console.log(`  ✅ Seeded '${item.id}' [${item.category || item.badge || 'Ad'}] -> ${item.title || item.headline}`);
      }
    } catch (e) {
      console.error(`  ❌ Error on '${item.id}':`, e.message);
    }
  }
  console.log(`✨ Successfully seeded ${successCount}/${items.length} items into '${collectionName}'.`);
}

async function main() {
  console.log('=======================================================');
  console.log(`🔥 Seeding Firestore Database for Project: ${PROJECT_ID}`);
  console.log('=======================================================');

  await seedCollection('news_feeds', newsItems);
  await seedCollection('news', newsItems);
  await seedCollection('adverts', advertItems);

  console.log('\n🎉 Seeding complete! News data is now saved live in Firebase Firestore.');
}

main().catch(console.error);