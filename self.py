from pyrogram import Client, idle,filters,enums
from pyrogram.types import Message
from pyrogram.raw import functions
from pyrogram.filters import command
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from pytz import timezone
import json,psutil,requests,os,subprocess,sys,random
from plugins import is_installed,create_time,read_json,delete_permision,write_json
from datetime import datetime
from re import match
from hurry.filesize import size
from time import sleep



try:
    if is_installed("pyrogram"):
        subprocess.run([sys.executable, "-m", "pip", "uninstall", "pyrogram", "-y"], check=True)

    if not is_installed("kurigram"):
        subprocess.run([sys.executable, "-m", "pip", "install", "kurigram"], check=True)

except subprocess.CalledProcessError as e:
    print(f"An error occurred during the installation or uninstallation: {e}")





if not os.path.isfile("Setting.json"):
    with open("Setting.json", "w") as f:
        json.dump({"timename": "off", "timebio": "off","online":"off","playing":"off","typing":"off"}, f, indent=6)

api_id = 26418454 # <- API-ID
api_hash = '8f23d087ad6db0d5e02263e771087a0f' # <- API-HASH

app = Client("CodeCraftersTeam",api_id,api_hash)






def update_profile():
    current_time = datetime.now(timezone("Asia/Tehran")).strftime("%H:%M")
    if not os.path.isfile("time.txt") or open("time.txt").read().strip() != current_time:
        try:
            hey = create_time()
            if data["timebio"] == "on":
                app.invoke(functions.account.UpdateProfile(about=f'فضولی شما در تایم {hey} ثبت شد'))
            if data["timename"] == "on":
                app.invoke(functions.account.UpdateProfile(last_name=hey))
            with open("time.txt", "w") as f:
                f.write(current_time)
        except Exception as e:
            print(f"Error in update_profile: {e}")
            
def online():
    if data['online'] == 'on':
        try:
            x = app.send_message("me","Develop By : @DevErfi\nChannel : @CodeCraftersTeam")
            sleep(2)
            app.delete_messages("me",x.id)
        except Exception as e:
            print(f"Error in online: {e}")
    else:
        pass
                
@app.on_message(~filters.me & ((filters.private & ~filters.bot) | (filters.mentioned & filters.group)))       
async def Actions(app, message):
    actions = {
        'playing': enums.ChatAction.PLAYING,
        'typing': enums.ChatAction.TYPING
    }
    for key, action in actions.items():
        if data.get(key) == 'on':
            try:
                await app.send_chat_action(chat_id=message.chat.id, action=action)
            except Exception as e:
                print(f"Error in {key} action: {e}")
            
    

            
@app.on_message(filters.photo, group=200)
async def onphoto(c: Client, m: Message):
    try:
        if m.photo.ttl_seconds:
            rand = random.randint(1, 999)
            local = f"downloads/aks-{rand}.png"
            await app.download_media(message=m, file_name=f"aks-{rand}.png")
            
            user_id = m.from_user.id if m.from_user else m.chat.id
            username = m.from_user.username if m.from_user and m.from_user.username else f"ID: {user_id}"
            
            await app.send_photo(
                chat_id="me",
                photo=local,
                caption=f"🔥 New timed image {m.photo.date} | time: {m.photo.ttl_seconds}s | User: @{username}"
            )
            os.remove(local)
    except Exception as e:
        print(f"An error occurred: {e}")
        

HELP_TEXT = """**Hi {mention} 👍🏻
  • Ping: [`.ping`] or [`/ping`]
  • TimeName: [`.timename`] <`on`|`off`>
  • TimeBio: [`.timebio`] <`on`|`off`>
  • Online: [`.online`] <`on`|`off`>
  • Playing : [`.playing`] <`on`|`off`>
  • Typing : [`.typing`] <`on`|`off`>
  • Delete : [`.delete`] <`int ( عدد )`>
  • GPT: [`.gpt`] <`سلام`>
  • Status : [`.status`]**"""
  
data = read_json("Setting.json")
@app.on_message(filters.text & filters.me)
def handle(_,m:Message):
    text = m.text
    if text in {".help", "/help"}:
        mention = (app.get_me()).mention
        m.edit_text(HELP_TEXT.format(mention=mention))
    
    elif text in {".ping","/ping"}:
        try:
         ping = psutil.getloadavg()
         process = psutil.Process(os.getpid())
         ram = size(process.memory_info().rss)
         m.edit("❅ **Ping**: `%s`\n❅ Ram:`%s`" % (ping[0], ram))
        except Exception as e:
            m.edit(f"Error in ping: {e}")
            
    
            
    elif text.startswith(".gpt"):
        try:
            gpt = text.replace(".gpt ","")
            api = requests.get(f"https://erfan.s93.fun/ProjecT/API/ChatGP/gpt.php?text={gpt}")
            app.send_message(m.chat.id, api.text, reply_to_message_id=m.id)
        except Exception as e:
            m.edit(f"Error in gpt: {e}")
    
    settings = {
        ".timename ": "timename",
        ".timebio ": "timebio",
        ".online ": "online",
        ".playing ": "playing",
        ".typing ": "typing"
    }
    for prefix, setting_key in settings.items():
        if text.startswith(prefix):
            replace = text.replace(prefix, "")
            if replace in ["on", "off"]:
                try:
                    data[setting_key] = replace
                    write_json("Setting.json", data)
                    m.edit(f"**• {setting_key.replace('_', ' ').capitalize()} is {replace}**")
                except Exception as e:
                    m.edit(f"Error in {setting_key}: {e}")
            break
#________________________Delete Message________________________________
    if text.startswith(".delete"):
        try:
            user =  app.get_chat_member(m.chat.id, "me")
            
            if delete_permision(user):
                try:
                    num_messages = int(text.replace(".delete", "").strip())
                    if num_messages <= 0:
                        m.reply("❌ **Please provide a valid number of messages to delete.**", quote=False)
                        return
                    
                    deleted_count = 0
                    for msg in app.get_chat_history(m.chat.id):
                        if deleted_count < num_messages:
                            msg.delete(revoke=True)
                            deleted_count += 1
                        else:
                            break
                    
                    m.reply(f"✅ **Successfully deleted {deleted_count} message(s)!**", quote=False)

                except ValueError:
                    m.reply("❌ **Please enter a valid number after the command.**", quote=False)

            else:
                m.reply("❌ **You don't have permission to delete messages.**", quote=False)

        except Exception as e:
            m.reply(f"❌ **An error occurred**: `{str(e)}`", quote=False)
            
    elif text == ".status":
     pl = ""
     md = data.items()
     lines = [f"❖ {key} -> {value}" for key, value in md]
     pl = "\n".join(lines)
     m.edit_text(f"{pl}") 
     
#________________________End________________________________
        
        

scheduler = AsyncIOScheduler()
scheduler.add_job(update_profile, "interval", seconds=10)
scheduler.add_job(online,"interval",seconds=45)
scheduler.start()




if __name__ == "__main__":
    app.start()
    print("Started ...")
    app.send_message("me", "🟢 **Bot is up and running!**")
    idle()
    app.stop()

