const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      status: 200,
      headers: corsHeaders,
    });
  }

  try {
    const { topic, start_time, duration = 60 } = await req.json();

    const accountId = Deno.env.get("ZOOM_ACCOUNT_ID");
    const clientId = Deno.env.get("ZOOM_CLIENT_ID");
    const clientSecret = Deno.env.get("ZOOM_CLIENT_SECRET");

    if (!accountId || !clientId || !clientSecret) {
      return new Response(
        JSON.stringify({ error: "Zoom secrets eksik" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const tokenResponse = await fetch(
      `https://zoom.us/oauth/token?grant_type=account_credentials&account_id=${accountId}`,
      {
        method: "POST",
        headers: {
          Authorization: "Basic " + btoa(`${clientId}:${clientSecret}`),
        },
      }
    );

    const tokenText = await tokenResponse.text();

    if (!tokenResponse.ok) {
      return new Response(
        JSON.stringify({
          error: "Zoom token alınamadı",
          detail: tokenText,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const tokenData = JSON.parse(tokenText);

    const meetingResponse = await fetch(
      "https://api.zoom.us/v2/users/me/meetings",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${tokenData.access_token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          topic: topic || "Neura Telerehabilitasyon Görüşmesi",
          type: 2,
          start_time,
          duration,
          timezone: "Europe/Istanbul",
          settings: {
            join_before_host: false,
            waiting_room: true,
          },
        }),
      }
    );

    const meetingText = await meetingResponse.text();

    if (!meetingResponse.ok) {
      return new Response(
        JSON.stringify({
          error: "Zoom meeting oluşturulamadı",
          detail: meetingText,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const meetingData = JSON.parse(meetingText);

    return new Response(
      JSON.stringify({
        join_url: meetingData.join_url,
        start_url: meetingData.start_url,
        id: meetingData.id,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (e) {
    return new Response(
      JSON.stringify({
        error: "Function exception",
        detail: e.toString(),
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});