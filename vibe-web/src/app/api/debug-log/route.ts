import { NextResponse } from "next/server"

export async function POST(req: Request) {
  try {
    const data = await req.json()
    console.log("\n[BROWSER CRASH LOG]");
    console.log("Message:", data.message);
    console.log("Stack:", data.stack);
    console.log("URL:", data.url);
    console.log("===================\n");
    return NextResponse.json({ success: true })
  } catch (err) {
    console.error("Failed to log client debug log:", err)
    return NextResponse.json({ success: false })
  }
}
