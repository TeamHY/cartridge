import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient, SupabaseClient } from "jsr:@supabase/supabase-js@2";

async function checkSeed(
  supabase: SupabaseClient<any, "public", any>,
  seed: string,
) {
  const today = new Date(Date.now() + 9 * 60 * 60 * 1000);

  const { data, error } = await supabase.from("daily_challenges").select().eq(
    "date",
    today.toISOString().split("T")[0],
  ).eq(
    "seed",
    seed,
  );

  if (data && !error) {
    return true;
  }

  return false;
}

async function create(req: Request) {
  const { time, seed, data: reqData } = await req.json();

  if (!time || !seed || !reqData) {
    return new Response("누락된 필드가 존재합니다", { status: 400 });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const authHeader = req.headers.get("Authorization")!;
    const token = authHeader.replace("Bearer ", "");
    const { data: { user } } = await supabase.auth.getUser(token);

    if (!user) {
      return new Response("사용자 정보를 찾을 수 없습니다", { status: 401 });
    }

    if (!checkSeed(supabase, seed)) {
      return new Response("seed가 올바르지 않습니다", { status: 400 });
    }

    const { data, error } = await supabase
      .from("daily_challenge_records")
      .insert([
        { user_id: user.id, data: reqData, time },
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

Deno.serve(async (req) => {
  switch (req.method) {
    case "POST":
      return await create(req);
  }

  return new Response(null, { status: 405 });
});
