import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

// https://www.reddit.com/r/bindingofisaac/comments/2wvp6h/comment/csdppvx/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
function getChecksum(seed: number): number {
  let checksum = 0;

  while (true) {
      checksum = (checksum + (seed & 0xFF)) & 0xFF;
      checksum = (2 * checksum + (checksum >>> 7)) & 0xFF;
      seed = seed >>> 5;
      if (seed === 0) break;
  }
  
  return checksum;
}

function generateSeed(): string {
  const randomSeed = Math.floor(Math.random() * 0xFFFFFFFF);
  
  const checksum = getChecksum(randomSeed);

  const combined = ((BigInt(randomSeed) ^ 0xFEF7FFDn) << 8n) | BigInt(checksum);

  const lookupTable = "ABCDEFGHJKLMNPQRSTWXYZ01234V6789";
  const result: string[] = [];
  for (let i = 0; i < 8; i++) {
      const charIndex = (combined >> BigInt(35 - i * 5)) & 0x1Fn;
      result.push(lookupTable[Number(charIndex)]);
  }

  return result.join("");
}

const bosses = ["blue_baby", "the_lamb", "mega_satan", "mother", "the_beast", "delirium"];

function getRandomBoss(): string {
  const randomIndex = Math.floor(Math.random() * bosses.length);
  return bosses[randomIndex];
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(null, { status: 405 });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
      },
    );

    const tomorrow = new Date(Date.now() + (24 + 9) * 60 * 60 * 1000);
    
    const seed = generateSeed();
    const boss = getRandomBoss();

    const { data, error } = await supabase
      .from("daily_challenges")
      .insert([
        { date: tomorrow, seed, boss },
      ])
      .select();

    if (error) {
      throw error;
    }

    return new Response(JSON.stringify({ data }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });
  } catch (err) {
    return new Response(String(err?.message ?? err), { status: 500 });
  }
});
