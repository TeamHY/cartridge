import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { day } from "../common/helper.ts";

Deno.serve((req) => {
  const data = day().tz().format('WW');

  return new Response(
    JSON.stringify(data),
    { headers: { "Content-Type": "application/json" } },
  )
})
