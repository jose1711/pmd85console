/*

SIM_CORE.C

Copyright 2008 Petr Tuma

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

*/

/* MODIFIED

 -Added:
 
 static void FlushMemory (int iFrom, int iSize)
 static void EmulationInitialize (int gameIndex)
 static void EmulationShutdown ()

 -Heavily modified main loop.

*/

#include "sim_common.h"
#include <fstream>
#include <map>

//--------------------------------------------------------------------------
// System Status Variables

// If we were to be entirely correct, the memory arrays
// should be declared volatile. However, this just
// leads to more complex display code and is
// otherwise unlikely to change anything.

/// Simulated memory array.
byte abMemoryData [65536] __attribute__ ((aligned (SAFE_ALIGNMENT)));
/// Simulator memory mask.
/// Distinguishes readable and writable memory.
bool abMemoryMask [65536] __attribute__ ((aligned (SAFE_ALIGNMENT)));

/// Processor clock counter.
/// Note that access to clock is not ordered !!!
relaxed_int iProcessorClock (0);

/// Simulator shutdown flag.
static relaxed_bool bShutdown (false);

/// Predefined Games
static std::string gameSelect[4] = {
  PMD_SHARE "FLAPPY",
  PMD_SHARE "BOULDER",
  PMD_SHARE "MANIC+",
  PMD_SHARE "FRED"
};

/// Game Tape IN
std::vector <std::string> gameIn;
/// Screen resolution
SDL_DisplayMode fullscreen;
/// Menu
bool inMenu = true;
/// Game Index
int gameIndex = 0;

/// Game from the games list (games.lst in the share directory).
struct tGame
{
  /// Tape file name.
  std::string sTape;
  /// PMD 85 model, 1 or 2.
  int iModel;
  /// Note shown in the list, the commands to type.
  std::string sNote;
  /// Keys of the game remapped to other PMD 85 keys, "Left=Left Shift,Right=V" (SDL key names).
  std::string sRemap;
  /// Buttons of the web remote control, "Label:key,..." (SDL key names), empty for the default set.
  std::string sPad;
};
/// Buttons of the web remote control for the running game and in the menus.
static const char *pPadGame = "E up:e,Y down:z,Left:Left,Right:Right,Space:Space,Enter:Return,H:h,I:i,Shift:Left Shift,RCL:Keypad +,Esc:Escape";
static const char *pPadMenu = "E up:e,Y down:z,Left:Left,Right:Right,Enter:Return,Esc:Escape";
static std::string sPad = pPadMenu;
/// Keys remapped for the running game, host key to PMD 85 key.
static std::map <SDL_Keycode, SDL_Keycode> oRemap;
/// Keys typed on the simulated keyboard after the start of a game (the load command, PMD_KEYS in test mode).
static std::string sKeys;
/// Position in the keys, key press or release.
static int iKeyPos;
static bool bKeyDown;
/// Time of the next key event.
static Uint32 iKeyTime;
/// Key press and release time.
static int iKeyMs = 150;
/// All games of the list menu.
static std::vector <tGame> oGames;
/// The list menu is shown instead of the four games.
static bool inList = false;
/// Selected game of the list.
static int listIndex = 0;


//--------------------------------------------------------------------------
// Simulator Control

/// Request simulator shutdown.
void SIMRequestShutdown ()
{
  // No active notification is needed since the main
  // event loop delivers messages periodically and
  // is therefore bound to observe the variable.

  bShutdown = true;
}


bool SIMQueryShutdown ()
{
  return (bShutdown);
}


//--------------------------------------------------------------------------
// Model Initialization


/** Flush memory.
 *
 *  @arg iFrom From which address.
 *  @arg iSize How large block.
 */
static void FlushMemory (int iFrom, int iSize)
{
  for (int iAddr = iFrom ; iAddr < iFrom + iSize ; iAddr ++)
  {
    abMemoryData [iAddr] = 0;
  }
}


/** Mark a memory area as read write.
 *
 *  @arg iFrom From which address.
 *  @arg iSize How large block.
 */
static void SetMemoryReadWrite (int iFrom, int iSize)
{
  for (int iAddr = iFrom ; iAddr < iFrom + iSize ; iAddr ++)
  {
    abMemoryMask [iAddr] = true;
  }
}


/** Mark a memory area as read only.
 *
 *  @arg iFrom From which address.
 *  @arg iSize How large block.
 */
static void SetMemoryReadOnly (int iFrom, int iSize)
{
  for (int iAddr = iFrom ; iAddr < iFrom + iSize ; iAddr ++)
  {
    abMemoryMask [iAddr] = false;
  }
}


/** Fill a memory area with content from file.
 *
 *  @arg iFrom From which address.
 *  @arg iSize How large block.
 *  @arg pFile What file.
 */
static void FillMemoryFromFile (int iFrom, int iSize, const char *pFile)
{
  std::ifstream oFile;
  oFile.open (pFile);
  oFile.read (reinterpret_cast <char *> (abMemoryData + iFrom), iSize);
  oFile.close ();
  assert (oFile.good ());
}


/// Initialize a PMD 85-1 model.
static void InitializePMD1 ()
{
  // Read the monitor image.
  FillMemoryFromFile (0x8000, 4096, PMD_SHARE "M1");
  FillMemoryFromFile (0xA000, 4096, PMD_SHARE "M1");
  // The first 32k is read write.
  // The next 16k is read only.
  // The last 16k is read write.
  SetMemoryReadWrite (0x0000, 32768);
  SetMemoryReadOnly  (0x8000, 16384);
  SetMemoryReadWrite (0xC000, 16384);
}


/// Initialize a PMD 85-2 model.
static void InitializePMD2 ()
{
  // Read the monitor image, patched to read the tape the PMD 85-1 way (the only way the tape port is simulated).
  FillMemoryFromFile (0x8000, 4096, PMD_SHARE "M2-Patched-Tape");
  // The entire 64k is read write.
  SetMemoryReadWrite (0x0000, 65536);
}


/** Keys that load a game: the commands of the note of games.lst, "MGLD 00, JUMP 2000" is typed as
 *  "MGLD 00|" and, after the tape stops loading ('~'), "JUMP 2000|".
 */
static std::string AutoloadKeys (const std::string &sNote)
{
  std::string sResult;
  size_t iPos = 0;
  while (iPos < sNote.size ())
  {
    size_t iEnd = sNote.find (',', iPos);
    if (iEnd == std::string::npos)
      iEnd = sNote.size ();
    std::string sPart = sNote.substr (iPos, iEnd - iPos);
    iPos = iEnd + 1;
    while (!sPart.empty () && sPart [0] == ' ')
      sPart.erase (0, 1);
    if (sPart.compare (0, 4, "MGLD") == 0)
      sResult += sPart + "|";
    else if (sPart.compare (0, 4, "JUMP") == 0)
      sResult += "~" + sPart + "|";
  }
  return (sResult);
}


/** State for the web remote control, JSON: mode (menu, list or game), selected index, names of the games.
 */
static std::string WebState ()
{
  std::string sState = std::string ("{\"mode\":\"") + (!inMenu ? "game" : inList ? "list" : "menu") + "\",\"index\":" +
                       std::to_string (inList ? listIndex : gameIndex) + ",\"pad\":\"" + (inMenu ? pPadMenu : sPad.c_str ()) +
                       "\",\"featured\":[\"FLAPPY\",\"BOULDER\",\"MANIC\",\"FRED\"],\"games\":[";
  for (size_t i = 0 ; i < oGames.size () ; i ++)
    sState += std::string (i ? "," : "") + "\"" + oGames [i].sTape + "\"";
  return (sState + "]}");
}


/** Remap keys of the game from the games list (4th column REMAP), none for the other games.
 */
static void KeysRemap (const std::string &sTape)
{
  oRemap.clear ();
  sPad = pPadGame;
  std::string sName = sTape;
  size_t iShare = strlen (PMD_SHARE);
  if (sName.compare (0, iShare, PMD_SHARE) == 0)
    sName.erase (0, iShare);
  for (size_t i = 0 ; i < oGames.size () ; i ++)
  {
    if (oGames [i].sTape != sName)
      continue;
    if (!oGames [i].sPad.empty ())
      sPad = oGames [i].sPad;
    const std::string &sRemap = oGames [i].sRemap;
    size_t iPos = 0;
    while (iPos < sRemap.size ())
    {
      size_t iEnd = sRemap.find (',', iPos);
      if (iEnd == std::string::npos)
        iEnd = sRemap.size ();
      std::string sPair = sRemap.substr (iPos, iEnd - iPos);
      iPos = iEnd + 1;
      size_t iEqual = sPair.find ('=');
      if (iEqual == std::string::npos)
        continue;
      SDL_Keycode iFrom = SDL_GetKeyFromName (sPair.substr (0, iEqual).c_str ());
      SDL_Keycode iTo = SDL_GetKeyFromName (sPair.substr (iEqual + 1).c_str ());
      if (iFrom != SDLK_UNKNOWN && iTo != SDLK_UNKNOWN)
        oRemap [iFrom] = iTo;
    }
  }
}


/** Start typing the keys of a game: PMD_KEYS in test mode, otherwise the load command from the games list
 *  (PMD_AUTOLOAD=0 turns it off).
 */
static void KeysStart (const std::string &sTape)
{
  sKeys.clear ();
  const char *pKeys = getenv ("PMD_KEYS");
  const char *pAutoload = getenv ("PMD_AUTOLOAD");
  if (pKeys)
    sKeys = pKeys;
  else if (!pAutoload || atoi (pAutoload) != 0)
  {
    std::string sName = sTape;
    size_t iShare = strlen (PMD_SHARE);
    if (sName.compare (0, iShare, PMD_SHARE) == 0)
      sName.erase (0, iShare);
    for (size_t i = 0 ; i < oGames.size () ; i ++)
      if (oGames [i].sTape == sName)
        sKeys = AutoloadKeys (oGames [i].sNote);
  }
  KeysRemap (sTape);
  iKeyPos = 0;
  bKeyDown = false;
  iKeyTime = SDL_GetTicks () + 1500;
}


/** Load the games list, lines NAME;MODEL;NOTE, '#' starts a comment.
 */
static void GamesLoad ()
{
  std::ifstream oFile (PMD_SHARE "games.lst");
  std::string sLine;
  while (std::getline (oFile, sLine))
  {
    if (sLine.empty () || sLine [0] == '#')
      continue;
    size_t iFirst = sLine.find (';');
    size_t iSecond = iFirst == std::string::npos ? iFirst : sLine.find (';', iFirst + 1);
    if (iSecond == std::string::npos)
      continue;
    tGame sGame;
    sGame.sTape = sLine.substr (0, iFirst);
    sGame.iModel = atoi (sLine.substr (iFirst + 1, iSecond - iFirst - 1).c_str ()) == 2 ? 2 : 1;
    sGame.sNote = sLine.substr (iSecond + 1);
    size_t iThird = sGame.sNote.find (';');
    if (iThird != std::string::npos)
    {
      sGame.sRemap = sGame.sNote.substr (iThird + 1);
      sGame.sNote.erase (iThird);
      size_t iFourth = sGame.sRemap.find (';');
      if (iFourth != std::string::npos)
      {
        sGame.sPad = sGame.sRemap.substr (iFourth + 1);
        sGame.sRemap.erase (iFourth);
      }
    }
    oGames.push_back (sGame);
  }
}


/// Draw the main menu or the games list.
static void MenuRender ()
{
  if (!inList)
  {
    DSPRenderMenu (fullscreen.w, fullscreen.h, gameIndex);
    return;
  }
  std::vector <std::string> oNames, oNotes;
  for (size_t i = 0 ; i < oGames.size () ; i ++)
  {
    oNames.push_back (oGames [i].sTape);
    oNotes.push_back ((oGames [i].iModel == 2 ? "PMD 85-2  " : "PMD 85-1  ") + oGames [i].sNote);
  }
  DSPRenderGameList (fullscreen.w, fullscreen.h, listIndex, oNames, oNotes);
}


/// Initialize emulation
static void EmulationInitialize (const std::string &sTape, int iModel)
{
  // Flush garbage
  FlushMemory(0x0000, 65536);
  // Reset processor clock
  iProcessorClock = 0;
  // Set Tape
  gameIn.clear();
  gameIn.push_back(sTape);
  TAPNextInputFile(gameIn);

  KeysStart (sTape);

  if (iModel == 2)
    InitializePMD2();
  else
    InitializePMD1();
  printf("Model initializing..\n");
  CPUInitialize ();
  printf("CPU initializing..\n");
  DSPInitialize();
  printf("DSP initializing..\n");
  KBDInitialize ();
  printf("KBD initializing..\n");
  SNDInitialize ();
  printf("SND initializing..\n");
  TAPInitialize ();
  printf("Tape initializing..\n");
 
  CPUStartThread ();
  printf("CPU Thread initializing..\n");
}


/// Shutdown emulation
static void EmulationShutdown ()
{
  sKeys.clear ();
  CPUTerminateThread ();
  printf("CPU Thread shutdown..\n");

  TAPShutdown ();
  printf("TAP shutdown..\n");
  SNDShutdown ();
  printf("SND shutdown..\n");
  KBDShutdown ();
  printf("KBD shutdown..\n");
  DSPShutdown();
  printf("DSP shutdown..\n");
  CPUShutdown ();
  printf("CPU shutdown..\n");
}


//--------------------------------------------------------------------------
// Main

int main (int iArgC, const char *apArgV [])
{

  // SDL Init
  SDL_CheckZero (SDL_Init (SDL_INIT_AUDIO | SDL_INIT_TIMER | SDL_INIT_VIDEO));
  printf("SDL Initializing..\n");
  // Gamepads, their buttons arrive as key events (PMD_PAD overrides the keys)
  GPDInitialize ();
  //Disable cursor
  SDL_ShowCursor (0);
  // Get fullscreen resolution
  SDL_CheckZero (SDL_GetCurrentDisplayMode(0, &fullscreen));
  DSPResolution (&fullscreen.w, &fullscreen.h);
  // Test mode: PMD_AUTOSTART=<0-3> skips logo and menu, PMD_KEYS=<text> types
  // the text on the simulated keyboard ('|' is Enter, '_' a 2 s pause), PMD_SCREENSHOT=<file>
  // saves the screen after PMD_SCREENSHOT_MS (default 3000) and exits.
  // PMD_KEY_MS is the key press and release time of PMD_KEYS (default 150).
  const char *pKeyMs = getenv ("PMD_KEY_MS");
  iKeyMs = pKeyMs ? atoi (pKeyMs) : 150;
  const char *pAutostart = getenv ("PMD_AUTOSTART");
  const char *pGame = getenv ("PMD_GAME");
  GamesLoad ();
  // Remote control from a browser: PMD_WEB=<port>, PMD_WEB_TOKEN=<secret> is required in the URL (?t=<secret>).
  const char *pWeb = getenv ("PMD_WEB");
  if (pWeb)
    WEBInitialize (atoi (pWeb), getenv ("PMD_WEB_TOKEN"), WebState);
  const char *pScreenshot = getenv ("PMD_SCREENSHOT");
  const char *pScreenshotMs = getenv ("PMD_SCREENSHOT_MS");
  Uint32 iScreenshotTime = SDL_GetTicks () + (pScreenshotMs ? atoi (pScreenshotMs) : 3000);
  if (pAutostart)
  {
    gameIndex = atoi (pAutostart) & 3;
    EmulationInitialize (gameSelect[gameIndex], 1);
    inMenu = false;
  }
  else if (pGame)
  {
    // Test mode: PMD_GAME=<name> starts a game of the games list.
    size_t iFound = 0;
    while (iFound < oGames.size () && oGames [iFound].sTape != pGame)
      iFound ++;
    if (iFound == oGames.size ())
    {
      fprintf (stderr, "PMD_GAME: '%s' is not in games.lst\n", pGame);
      SDL_Quit ();
      return (1);
    }
    EmulationInitialize (PMD_SHARE + oGames [iFound].sTape, oGames [iFound].iModel);
    inMenu = false;
  }
  else
  {
    //Logo
    DSPLogoInitialize ();
    DSPRenderLogo (fullscreen.w, fullscreen.h);
    DSPLogoShutdown ();
    // Menu
    DSPMenuInitialize ();
    MenuRender ();
  }
  // Event loop
  SDL_Event sEvent;
  // Debug: PMD_KEYLOG=<file> logs keyboard and window events.
  const char *pKeyLog = getenv ("PMD_KEYLOG");
  FILE *pLog = pKeyLog ? fopen (pKeyLog, "a") : NULL;

  while (!SIMQueryShutdown ())
  {
    SDL_WaitEvent (&sEvent);
    if (pLog && sEvent.type != SDL_USEREVENT)
    {
      fprintf (pLog, "%u type=0x%x inMenu=%d focus=%p", SDL_GetTicks (), sEvent.type, inMenu, (void *) SDL_GetKeyboardFocus ());
      if (sEvent.type == SDL_KEYDOWN || sEvent.type == SDL_KEYUP)
        fprintf (pLog, " sym=%d (%s) repeat=%d", sEvent.key.keysym.sym, SDL_GetKeyName (sEvent.key.keysym.sym), sEvent.key.repeat);
      if (sEvent.type == SDL_WINDOWEVENT)
        fprintf (pLog, " win=%d", sEvent.window.event);
      fprintf (pLog, "\n");
      fflush (pLog);
    }
    GPDEventHandler (&sEvent);
    switch (sEvent.type)
    {
      case SDL_KEYUP:
      case SDL_KEYDOWN:
        if (inMenu) {
           if (sEvent.type == SDL_KEYDOWN) {
             SDL_Keycode iSym = sEvent.key.keysym.sym;
             // [E] and [Y] are the PMD 85 up and down, the gamepad sends them
             bool bUp = (iSym == SDLK_UP || iSym == SDLK_e);
             bool bDown = (iSym == SDLK_DOWN || iSym == SDLK_z);
             if (inList) {
               int iCount = (int) oGames.size ();
               if (iSym == SDLK_ESCAPE) {
                 inList = false;
                 MenuRender ();
               }
               if (bUp || bDown || iSym == SDLK_LEFT || iSym == SDLK_RIGHT || iSym == SDLK_PAGEUP || iSym == SDLK_PAGEDOWN) {
                 int iStep = bUp ? -1 : bDown ? 1 : (iSym == SDLK_LEFT || iSym == SDLK_PAGEUP) ? -10 : 10;
                 // Single steps wrap around, pages stop at the ends.
                 if (iStep == -1 || iStep == 1)
                   listIndex = (listIndex + iStep + iCount) % iCount;
                 else
                   listIndex = std::max (0, std::min (iCount - 1, listIndex + iStep));
                 MenuRender ();
               }
               if (iSym == SDLK_RETURN) {
                 DSPMenuShutdown ();
                 EmulationInitialize (PMD_SHARE + oGames [listIndex].sTape, oGames [listIndex].iModel);
                 inMenu = false;
               }
             } else {
               if (iSym == SDLK_ESCAPE) { 
                SIMRequestShutdown ();
               }
               if (iSym == SDLK_LEFT) {
                 (gameIndex == 0) ? gameIndex = 3 : gameIndex--;
                 MenuRender ();
               }
               if (iSym == SDLK_RIGHT) { 
                 (gameIndex == 3) ? gameIndex = 0 : gameIndex++;
                 MenuRender ();
               }
               if (bUp && !oGames.empty ()) {
                 inList = true;
                 MenuRender ();
               }
               if (iSym == SDLK_RETURN) {
                 DSPMenuShutdown ();
                 EmulationInitialize (gameSelect[gameIndex], 1);
                 inMenu = false;	
               }
             }
           }
        } else {
          if (sEvent.key.keysym.sym == SDLK_ESCAPE) {
            EmulationShutdown ();
            DSPMenuInitialize ();
            MenuRender ();
            inMenu = true;
          } else {
            std::map <SDL_Keycode, SDL_Keycode>::const_iterator xRemap = oRemap.find (sEvent.key.keysym.sym);
            if (xRemap != oRemap.end ())
              sEvent.key.keysym.sym = xRemap->second;
            KBDEventHandler ((SDL_KeyboardEvent *) &sEvent);
          }
        }
        break;
      case SDL_USEREVENT:
        if (!inMenu) {
          KBDPoll ();
          Uint32 iPaintStart = SDL_GetTicks ();
          DSPPaintHandler ();
          // Drop paint events queued while painting, a slow machine would fall behind and delay the keys.
          SDL_FlushEvent (SDL_USEREVENT);
          if (pLog)
          {
            // Debug: paint duration and queue lag (events pending) every 25th frame.
            static int iFrame = 0;
            if (++iFrame % 25 == 0)
            {
              SDL_PumpEvents ();
              fprintf (pLog, "%u paint=%ums pending=%d\n", SDL_GetTicks (), SDL_GetTicks () - iPaintStart, SDL_PeepEvents (NULL, 0, SDL_PEEKEVENT, SDL_FIRSTEVENT, SDL_LASTEVENT));
              fflush (pLog);
            }
          }
          // The first key waits until the simulated processor ran for 2 s, the monitor is not ready sooner and
          // a slow machine (Raspberry Pi) loses the first keys when the time is only counted in real time.
          bool bKeysReady = iKeyPos > 0 || bKeyDown || iProcessorClock >= 2 * PMD_CLOCK;
          if (iKeyPos < (int) sKeys.size () && bKeysReady && SDL_GetTicks () >= iKeyTime) {
            SDL_KeyboardEvent sKey = {};
            char cKey = sKeys [iKeyPos];
            if (cKey == '_') {
              iKeyPos ++;
              iKeyTime = SDL_GetTicks () + 2000;
            } else if (cKey == '~') {
              // Wait until the tape stops loading, nothing was read for 2 s.
              Uint32 iLastRead = TAPLastRead ();
              if (iLastRead != 0 && SDL_GetTicks () - iLastRead > 2000) {
                iKeyPos ++;
                iKeyTime = SDL_GetTicks () + 500;
              } else {
                iKeyTime = SDL_GetTicks () + 200;
              }
            } else {
            sKey.keysym.sym = (cKey == '|') ? SDLK_RETURN : (cKey == '<') ? SDLK_LEFT : (cKey == '>') ? SDLK_RIGHT : (cKey == '^') ? SDLK_LSHIFT
                            : (cKey >= 'A' && cKey <= 'Z') ? cKey + 32 : cKey;
            sKey.state = bKeyDown ? SDL_RELEASED : SDL_PRESSED;
            KBDEventHandler (&sKey);
            if (bKeyDown) iKeyPos ++;
            bKeyDown = !bKeyDown;
            iKeyTime = SDL_GetTicks () + iKeyMs;
            }
          }
          if (pScreenshot && SDL_GetTicks () >= iScreenshotTime) {
            DSPSaveScreenshot (pScreenshot);
            SIMRequestShutdown ();
          }
        }
        break;
      case SDL_QUIT:
        SIMRequestShutdown ();
        break;
    }
  }

  // Emulation or menu shutdown
  if (inMenu) {
    DSPMenuShutdown ();
  } else {
    EmulationShutdown ();
  }
  // Quit
  WEBShutdown ();
  GPDShutdown ();
  SDL_Quit ();

  return (0);
}


//--------------------------------------------------------------------------

