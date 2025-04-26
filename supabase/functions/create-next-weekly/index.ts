import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { day, generateSeed, getRandomBoss, getRandomCharacter, getTodayString } from "../common/helper.ts";

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(null, { status: 405 });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const nextWeek = day(getTodayString()).add(1, "week");
    
    const seed = generateSeed();
    // const boss = getRandomBoss();
    const boss = "perfection";
    const character = getRandomCharacter();

    const { data, error } = await supabase
      .from("weekly_challenges")
      .insert([
        { year: nextWeek.isoWeekYear(), week: nextWeek.isoWeek(), seed, boss, character },
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
