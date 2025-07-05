import asyncio
import sys
import os
from pyrogram import Client
from pytgcalls import PyTgCalls, idle
from pytgcalls.types import Update
from pytgcalls.types.input_stream import InputStream
from pytgcalls.types.input_stream import AudioPiped

"""
Usage: python3 stream_helper.py <chat_id> <audio_path> <api_id> <api_hash> <session_string>
This helper joins voice chat in <chat_id> using PyTgCalls and plays <audio_path>.
It will leave after playback finishes.
"""

CHAT_ID      = int(sys.argv[1])
AUDIO_FILE   = sys.argv[2]
API_ID       = int(sys.argv[3])
API_HASH     = sys.argv[4]
SESSION_STR  = sys.argv[5]
FFMPEG_BIN   = os.getenv("FFMPEG_BIN", "ffmpeg")

app = Client("pytgcalls_session", api_id=API_ID, api_hash=API_HASH, session_string=SESSION_STR)

pytgcalls = PyTgCalls(app)

async def main():
    await app.start()
    await pytgcalls.start()

    # join group call (creates if not existing)
    try:
        await pytgcalls.join_group_call(
            CHAT_ID,
            InputStream(
                AudioPiped(
                    AUDIO_FILE,
                    ffmpeg_args=[
                        "-vn",
                        "-c:a", "libopus",
                        "-b:a", "128k",
                        "-f", "opus"
                    ],
                    executable=FFMPEG_BIN
                )
            )
        )
        print("[stream_helper] Streaming started…")
    except Exception as e:
        print("[stream_helper] join_group_call failed:", e)
        await app.stop()
        return

    # wait until playback finishes (simple: file length) then leave
    # pytgcalls handles ending automatically; we just idle.
    await idle()

if __name__ == "__main__":
    try:
        asyncio.get_event_loop().run_until_complete(main())
    finally:
        # Make sure everything stops
        asyncio.get_event_loop().run_until_complete(app.stop())