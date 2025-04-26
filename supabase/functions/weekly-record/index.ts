import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient, SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { day, getTodayString } from "../common/helper.ts";

async function getChallengeId(
  supabase: SupabaseClient<any, "public", any>,
  seed: string,
) {
  const today = day(getTodayString());
  const year = today.isoWeekYear();
  const week = today.isoWeek();

  const { data, error } = await supabase.from("weekly_challenges").select().eq(
    "year",
    year,
  ).eq(
    "week",
    week,
  ).eq(
    "seed",
    seed,
  );

  if (data && data[0] && !error) {
    return data[0].id;
  }

  return null;
}

async function find(challengeId: string) {
  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const { data, error } = await supabase
      .from("weekly_challenge_records")
      .select("id, time, character, users(id, email), data")
      .eq("challenge_id", Number(challengeId));

    if (error) {
      throw error;
    }

    data.map((record: any) => {
      record.users.email = record.users.email.replace(
        /(?<=.{2}).(?=.*@)/g,
        "*",
      );
      record.nickname = record.users.email;
    })

    const userBestRecords = new Map<string, any>();
    
    data.forEach((record: any) => {
      const userId = record.users.id;
      
      if (!userBestRecords.has(userId) || record.time < userBestRecords.get(userId).time) {
        userBestRecords.set(userId, record);
        delete record.users;
      }
    });

    return new Response(JSON.stringify({ data: Array.from(userBestRecords.values()) }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });
  } catch (err) {
    return new Response(String(err?.message ?? err), { status: 500 });
  }
}

async function create(req: Request) {
  const { time, seed, character, data: reqData } = await req.json();

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

    const challengeId = await getChallengeId(supabase, seed);

    if (!challengeId) {
      return new Response("위클리 챌린지를 찾을 수 없습니다", { status: 400 });
    }

    const { data, error } = await supabase
      .from("weekly_challenge_records")
      .insert([
        {
          user_id: user.id,
          challenge_id: challengeId,
          data: reqData,
          time,
          character,
        },
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
  const url = new URL(req.url);
  const command = url.pathname.split("/").pop();
  const id = command;

  switch (req.method) {
    case "GET":
      if (id) {
        return await find(id);
      }
      break;
    case "POST":
      return await create(req);
  }

  return new Response(null, { status: 405 });
});
