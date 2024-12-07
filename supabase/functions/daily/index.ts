import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

function isFutureDate(date: string) {
  const today = new Date(Date.now() + 9 * 60 * 60 * 1000);
  const targetDate = new Date(date);

  return today.getFullYear() < targetDate.getFullYear() ||
    (today.getFullYear() === targetDate.getFullYear() &&
      today.getMonth() < targetDate.getMonth()) ||
    (today.getFullYear() === targetDate.getFullYear() &&
      today.getMonth() === targetDate.getMonth() &&
      today.getDate() < targetDate.getDate());
}

function validateSeed(seed: string): boolean {
  const allowedCharacters = "ABCDEFGHJKLMNPQRSTWXYZ01234V6789";

  if (seed.length !== 8) {
    return false;
  }

  for (const char of seed) {
    if (!allowedCharacters.includes(char)) {
      return false;
    }
  }

  return true;
}

async function create(req: Request) {
  const { date, seed, boss } = await req.json();

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

    if (!date || !seed || !boss) {
      return new Response("누락된 필드가 존재합니다", { status: 400 });
    }

    if (!isFutureDate) {
      return new Response("과거와 오늘은 등록할 수 없습니다", {
        status: 400,
      });
    }

    if (!validateSeed(seed)) {
      return new Response("seed가 올바르지 않습니다", {
        status: 400,
      });
    }

    const { data, error } = await supabase
      .from("daily_challenges")
      .insert([
        { date, seed, boss },
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
}

async function update(req: Request) {
  const { id, date, seed, boss } = await req.json();

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

    if (!isFutureDate) {
      return new Response("과거와 오늘은 수정할 수 없습니다", {
        status: 400,
      });
    }

    const { data, error } = await supabase
      .from("daily_challenges")
      .update({
        date,
        seed,
        boss,
      })
      .eq("id", id)
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
}

Deno.serve(async (req) => {
  switch (req.method) {
    case "POST":
      return await create(req);
    case "PUT":
      return await update(req);
  }

  return new Response(null, { status: 405 });
});
