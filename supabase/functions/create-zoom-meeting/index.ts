Deno.serve(async (req) => {
  try {
    const { topic, start_time, duration = 60 } = await req.json();

    const accountId = Deno.env.get("ZOOM_ACCOUNT_ID");
    const clientId = Deno.env.get("ZOOM_CLIENT_ID");
    const clientSecret = Deno.env.get("ZOOM_CLIENT_SECRET");

    const credentials = btoa(`${clientId}:${clientSecret}`);

    const tokenResponse = await fetch(
      `https://zoom.us/oauth/token?grant_type=account_credentials&account_id=${accountId}`,
      {
        method: "POST",
        headers: {
          Authorization: `Basic ${credentials}`,
        },
      }
    );

    const tokenData = await tokenResponse.json();

    const accessToken = tokenData.access_token;

    const meetingResponse = await fetch(
      "https://api.zoom.us/v2/users/me/meetings",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          topic,
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

    const meetingData = await meetingResponse.json();

    return new Response(JSON.stringify(meetingData), {
      headers: {
        "Content-Type": "application/json",
      },
      status: 200,
    });
  } catch (e) {
    return new Response(
      JSON.stringify({
        error: e.toString(),
      }),
      {
        status: 500,
        headers: {
          "Content-Type": "application/json",
        },
      }
    );
  }
});