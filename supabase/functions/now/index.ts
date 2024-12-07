import "jsr:@supabase/functions-js/edge-runtime.d.ts"

Deno.serve((req) => {
  const data = new Date(Date.now() + 9 * 60 * 60 * 1000);

  return new Response(
    JSON.stringify(data),
    { headers: { "Content-Type": "application/json" } },
  )
})
