/*

SIM_DISPLAY.C

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

 -Modified:

  void DSPInitialize ()

 -Added:

 void DSPRenderMenu (int screen_width, int screen_height, int index)
 void DSPRenderLogo (int screen_width, int screen_height)
 void DSPRenderImage (int screen_width, int screen_height)
 void DSPRenderText (int screen_width, int screen_height)
 void DSPLogoShutdown ()
 void DSPMenuShutdown ()
 void DSPLogoInitialize ()
 void DSPMenuInitialize ()

*/

#include "sim_common.h"
#include "SDL2/SDL_ttf.h"


//-------------------------------------------------------------------------------------------------------

#define FONT_HEIGHT      24
#define FONT_WIDTH       16
#define IMAGE_WIDTH     174
#define FRAME_WIDTH     200
#define FRAME_SPACE       5
#define MENU_WIDTH      815 //4x200 + 3x 5px spacing

//-------------------------------------------------------------------------------------------------------
//
// HARDCODED DATA


static const char *menuText[7] = {
  "PMD-85 Retro console",
  "1] Vyber hru pomoci sipek <- -> a stiskni [ Enter ].",
  "2] Hra se nahraje sama (prikaz MGLD se napise automaticky).",
  "3] Dalsi hry: sipka nahoru [ E ] otevre seznam vsech her.",
  "4] Pro ukonceni hry stiskni [ Esc ].",
  "5] Pro konec stiskni [ Esc ].",
  "Richard Bruna (c) 2019"
};

static const char *pmdLogo[1] = {PMD_SHARE "pmd85_830_570.bmp"};

static const char *gameLogo[4] = {
  PMD_SHARE "flappy.bmp",
  PMD_SHARE "boulder.bmp",
  PMD_SHARE "manic.bmp",
  PMD_SHARE "fred.bmp"
};

static const char *gameText[4] = {"FLAPPY", "BOULDER", "MANIC", "FRED"};

static const char *gameFont[1] = {PMD_SHARE "atari-classic.ttf"};


//--------------------------------------------------------------------------
// Command Line Options

/// Screen refresh. How many milliseconds per screen refresh.
static int iArgRefresh = 40;


//--------------------------------------------------------------------------
// Data

/// Singleton screen window.
static SDL_Window *pWindow;
/// Singleton screen renderer;
static SDL_Renderer *pRenderer;
/// Singleton screen texture.
static SDL_Texture *pTexture;
/// Singleton menu window.
static SDL_Window *mWindow;
/// Singleton menu renderer.
static SDL_Renderer *mRenderer;
/// Singleton logo window.
static SDL_Window *lWindow;
/// Singleton logo renderer.
static SDL_Renderer *lRenderer;
/// Paint timer.
static SDL_TimerID iPaintTimer;

// Display colors.
#define DSP_COLOR_BLACK 0b00000000
#define DSP_COLOR_WHITE 0b11111111
#define DSP_COLOR_GRAY  0b10010010

/// Base address of the video memory.
#define PMD_VRAM_BASE           0xC000
/// Width of the visible video memory line in bytes.
#define PMD_VRAM_WIDTH          48
/// Width of the invisible video memory line in bytes.
#define PMD_VRAM_BLANK          16
/// Height of the video memory area in lines.
#define PMD_VRAM_HEIGHT         256

/// Number of pixels in one byte.
#define PMD_PIXEL_COUNT         6
/// Gray attribute mask.
#define PMD_PIXEL_GRAY          (1 << 6)
/// Blinking attribute bask.
#define PMD_PIXEL_BLINK         (1 << 7)

/// Blinking rate in miliseconds.
#define PMD_BLINK_RATE          512


/// Rendered screen data.
static byte abScreenData [PMD_VRAM_WIDTH * PMD_PIXEL_COUNT * PMD_VRAM_HEIGHT];


//--------------------------------------------------------------------------
// Screen paint

/** Determine whether blinking pixels are visible.
 *
 *  Visibility of blinking pixels is based on actual time.
 *
 *  @return Flag determining blinking pixel visibility.
 */
bool DSPBlinkVisible ()
{
  return ((SDL_GetTicks () / PMD_BLINK_RATE) & 1);
}


/** Decode the screen content in 1:1 zoom.
 *
 *  Decodes the memory content of the simulated machine using
 *  direct writing to screen texture. Optimized for 1:1 zoom.
 */
void DSPDecodeScreen ()
{
  bool bBlinkVisible = DSPBlinkVisible ();

  // Traverse the memory content line by line and byte by byte
  // and paint the screen content as we go.
  byte *pSource = abMemoryData + PMD_VRAM_BASE;
  byte *pTarget = abScreenData;
  for (int iLine = 0 ; iLine < PMD_VRAM_HEIGHT ; iLine ++)
  {
    for (int iByte = 0 ; iByte < PMD_VRAM_WIDTH ; iByte ++)
    {
      byte iData = *pSource;

      // Determine the drawing color. All pixels in one byte share color.
      byte iColor = (iData & PMD_PIXEL_GRAY) ? iColor = DSP_COLOR_GRAY
                                             : iColor = DSP_COLOR_WHITE;
      if ((iData & PMD_PIXEL_BLINK) && !bBlinkVisible) iColor = DSP_COLOR_BLACK;

      // The inner cycle is unrolled for speed.

#define DSPPaintPixel                                           \
  *pTarget = (iData & 1) ? iColor : DSP_COLOR_BLACK;            \
  iData >>= 1;                                                  \
  pTarget ++;

      DSPPaintPixel
      DSPPaintPixel
      DSPPaintPixel
      DSPPaintPixel
      DSPPaintPixel
      DSPPaintPixel

#undef DSPPaintPixel

      pSource ++;
    }

    pSource += PMD_VRAM_BLANK;
  }
}


//--------------------------------------------------------------------------
// Event handlers

/** Handler for painting the screen content.
 *
 *  Decodes the memory content of the simulated machine
 *  and paints the screen content accordingly, using
 *  direct writing and double buffering.
 */
void DSPPaintHandler ()
{
  // TODO Consider using HQX ?

  DSPDecodeScreen ();

  // TODO Check if render clear is really needed ?

  SDL_CheckZero (SDL_SetRenderDrawColor (pRenderer, 0, 0, 0, SDL_ALPHA_OPAQUE));
  SDL_CheckZero (SDL_RenderClear (pRenderer));
  SDL_CheckZero (SDL_UpdateTexture (pTexture, NULL, &abScreenData, PMD_VRAM_WIDTH * PMD_PIXEL_COUNT));
  SDL_CheckZero (SDL_RenderCopy (pRenderer, pTexture, NULL, NULL));
  SDL_RenderPresent (pRenderer);
}


/** Saves the current screen content as a BMP file.
 *
 *  Reads back the renderer output, so it works without a connected display.
 *
 *  @arg pPath Target file name.
 */
void DSPSaveScreenshot (const char *pPath)
{
  int iWidth, iHeight;
  SDL_CheckZero (SDL_GetRendererOutputSize (pRenderer, &iWidth, &iHeight));
  SDL_Surface *pSurface;
  SDL_CheckNotNull (pSurface = SDL_CreateRGBSurfaceWithFormat (0, iWidth, iHeight, 32, SDL_PIXELFORMAT_ARGB8888));
  SDL_CheckZero (SDL_RenderReadPixels (pRenderer, NULL, SDL_PIXELFORMAT_ARGB8888, pSurface->pixels, pSurface->pitch));
  SDL_CheckZero (SDL_SaveBMP (pSurface, pPath));
  SDL_FreeSurface (pSurface);
}


//--------------------------------------------------------------------------
// Callback handlers

/** Handler for painting the screen content.
 *
 *  Pushes an event corresponding to the timer on the
 *  event queue to maintain the threading rules.
 */
Uint32 DSPPaintTimerCallback (Uint32 iInterval, void *pArgs)
{
  SDL_Event sEvent;
  sEvent.type = SDL_USEREVENT;
  sEvent.user.code = 0;
  sEvent.user.data1 = NULL;
  sEvent.user.data2 = NULL;
  SDL_PushEvent (&sEvent);

  return (iArgRefresh);
}


//--------------------------------------------------------------------------
// Initialization and shutdown


/** Window size multiplier, PMD_SCALE environment variable (default 3). */
static int DSPWindowScale ()
{
  const char *pScale = getenv ("PMD_SCALE");
  int iScale = pScale ? atoi (pScale) : 3;
  return (iScale > 0 ? iScale : 1);
}


/** Screen resolution used by the menu, logo and fullscreen, PMD_RES=<w>x<h> (default desktop mode).
 *
 *  A lower resolution makes the slow Raspberry Pi paint faster.
 *
 *  @return True if the resolution comes from PMD_RES (real video mode change).
 */
bool DSPResolution (int *pWidth, int *pHeight)
{
  const char *pRes = getenv ("PMD_RES");
  if (pRes && sscanf (pRes, "%dx%d", pWidth, pHeight) == 2 && *pWidth > 0 && *pHeight > 0)
    return (true);
  SDL_DisplayMode sMode;
  SDL_CheckZero (SDL_GetCurrentDisplayMode (0, &sMode));
  *pWidth = sMode.w;
  *pHeight = sMode.h;
  return (false);
}


/** Window flags: fullscreen on the console (KMSDRM), resizable elsewhere. */
static Uint32 DSPWindowFlags ()
{
  const char *pDriver = SDL_GetCurrentVideoDriver ();
  if (pDriver && strcmp (pDriver, "KMSDRM") == 0)
  {
    int iWidth, iHeight;
    return (DSPResolution (&iWidth, &iHeight) ? SDL_WINDOW_FULLSCREEN : SDL_WINDOW_FULLSCREEN_DESKTOP);
  }
  return (SDL_WINDOW_RESIZABLE);
}


void DSPInitialize ()
{
  // Initialize the video resources.
  int iWindowW = PMD_VRAM_WIDTH * PMD_PIXEL_COUNT * DSPWindowScale ();
  int iWindowH = PMD_VRAM_HEIGHT * DSPWindowScale ();
  if (DSPWindowFlags () == SDL_WINDOW_FULLSCREEN)
    DSPResolution (&iWindowW, &iWindowH);
  SDL_CheckNotNull (pWindow = SDL_CreateWindow ("SimPMD", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
                                                iWindowW, iWindowH, DSPWindowFlags ()));
  SDL_CheckNotNull (pRenderer = SDL_CreateRenderer (pWindow, -1, SDL_RENDERER_ACCELERATED));
  SDL_CheckNotNull (pTexture = SDL_CreateTexture (pRenderer, SDL_PIXELFORMAT_RGB332, SDL_TEXTUREACCESS_STREAMING,
                                                  PMD_VRAM_WIDTH * PMD_PIXEL_COUNT, PMD_VRAM_HEIGHT));
  //SDL_CheckTrue (SDL_SetHint (SDL_HINT_RENDER_SCALE_QUALITY, 0));

  // Clear screen.
  SDL_CheckZero (SDL_SetRenderDrawColor (pRenderer, 0, 0, 0, SDL_ALPHA_OPAQUE));
  SDL_CheckZero (SDL_RenderClear (pRenderer));
  SDL_RenderPresent (pRenderer);
  // Start the timer that paints the screen repeatedly ...
  iPaintTimer = SDL_AddTimer (iArgRefresh, DSPPaintTimerCallback, NULL);
}


void DSPMenuInitialize ()
{
  // Menu and logo are laid out for the display resolution, keep it as logical size.
  int iDisplayW, iDisplayH;
  DSPResolution (&iDisplayW, &iDisplayH);
  // Initialize the video resources.
  SDL_CheckNotNull (mWindow = SDL_CreateWindow ("SimPMD - Menu", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
                                                iDisplayW, iDisplayH, DSPWindowFlags ()));
  SDL_CheckNotNull (mRenderer = SDL_CreateRenderer (mWindow, -1, SDL_RENDERER_ACCELERATED));
  SDL_CheckZero (SDL_RenderSetLogicalSize (mRenderer, iDisplayW, iDisplayH));
  //TTF
  TTF_Init();
  // Clear screen.
  SDL_CheckZero (SDL_SetRenderDrawColor (mRenderer, 0, 0, 0, SDL_ALPHA_OPAQUE));
  SDL_CheckZero (SDL_RenderClear (mRenderer));
  SDL_RenderPresent (mRenderer);
}


void DSPLogoInitialize ()
{
  // Menu and logo are laid out for the display resolution, keep it as logical size.
  int iDisplayW, iDisplayH;
  DSPResolution (&iDisplayW, &iDisplayH);
  // Initialize the video resources.
  SDL_CheckNotNull (lWindow = SDL_CreateWindow ("SimPMD - Logo", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
                                                iDisplayW, iDisplayH, DSPWindowFlags ()));
  SDL_CheckNotNull (lRenderer = SDL_CreateRenderer (lWindow, -1, SDL_RENDERER_ACCELERATED));
  SDL_CheckZero (SDL_RenderSetLogicalSize (lRenderer, iDisplayW, iDisplayH));
  // Clear screen.
  SDL_CheckZero (SDL_SetRenderDrawColor (lRenderer, 0, 0, 0, SDL_ALPHA_OPAQUE));
  SDL_CheckZero (SDL_RenderClear (lRenderer));
  SDL_RenderPresent (lRenderer);
}


void DSPShutdown ()
{
  // Stop the timer that paints the screen repeatedly ...
  SDL_RemoveTimer (iPaintTimer);

  SDL_DestroyTexture (pTexture);
  pTexture = NULL;
  SDL_DestroyRenderer (pRenderer);
  pRenderer = NULL;
  SDL_DestroyWindow (pWindow);
  pWindow = NULL;
}


void DSPMenuShutdown ()
{
  SDL_DestroyRenderer (mRenderer);
  mRenderer = NULL;
  SDL_DestroyWindow (mWindow);
  mWindow = NULL;
}


void DSPLogoShutdown ()
{
  SDL_DestroyRenderer (lRenderer);
  lRenderer = NULL;
  SDL_DestroyWindow (lWindow);
  lWindow = NULL;
}


void DSPRenderText (int screen_width, int screen_height)
{
  TTF_Font *textFont;
  SDL_Surface* textSurface;
  SDL_Texture* textTexture;
  SDL_Rect textRectangle;
  SDL_Rect gameTextRectangle;
  SDL_Color textColor = {255,255,255};// white

  textFont = TTF_OpenFont (gameFont[0], FONT_HEIGHT);

  // Copyright
  textSurface = TTF_RenderText_Solid (textFont, menuText[6], textColor);
  textTexture = SDL_CreateTextureFromSurface (mRenderer, textSurface);

  textRectangle.h = FONT_HEIGHT;
  textRectangle.w = FONT_WIDTH * strlen(menuText[6]);
  textRectangle.x = (screen_width - MENU_WIDTH)/2 + (MENU_WIDTH - textRectangle.w)/2;
  textRectangle.y = 665;
 
  SDL_RenderCopy (mRenderer, textTexture, NULL, &textRectangle);
  // About
  textSurface = TTF_RenderText_Solid (textFont, menuText[0], textColor);
  textTexture = SDL_CreateTextureFromSurface (mRenderer, textSurface);

  textRectangle.h = FONT_HEIGHT;
  textRectangle.w = FONT_WIDTH * strlen(menuText[0]);
  textRectangle.x = (screen_width - MENU_WIDTH)/2 + (MENU_WIDTH - textRectangle.w)/2;
  textRectangle.y = 100;
 
  SDL_RenderCopy (mRenderer, textTexture, NULL, &textRectangle);
  // Help text
  for (int i = 1; i < 6; i++) {
    textSurface = TTF_RenderText_Solid (textFont, menuText[i], textColor);
    textTexture = SDL_CreateTextureFromSurface (mRenderer, textSurface);

    textRectangle.h = FONT_HEIGHT;
    textRectangle.w = FONT_WIDTH * strlen(menuText[i]);
    textRectangle.x = (screen_width - MENU_WIDTH)/2;
    textRectangle.y = 100 + FONT_HEIGHT + 2 + i * (FONT_HEIGHT + 2);// 2-px v-spacing 

    SDL_RenderCopy (mRenderer, textTexture, NULL, &textRectangle);
  }
  // Game text
  for (int i = 0; i < 4; i++) {
    textSurface = TTF_RenderText_Solid (textFont, gameText[i], textColor);
    textTexture = SDL_CreateTextureFromSurface (mRenderer, textSurface);

    textRectangle.h = FONT_HEIGHT;
    textRectangle.w = FONT_WIDTH * strlen(gameText[i]);
    textRectangle.x = (screen_width - MENU_WIDTH)/2 + (FRAME_WIDTH - textRectangle.w)/2 + i * (FRAME_WIDTH + FRAME_SPACE);
    textRectangle.y = 310 + FRAME_WIDTH + 15;// 15px text spacing

    SDL_RenderCopy (mRenderer, textTexture, NULL, &textRectangle);
  }

  SDL_FreeSurface (textSurface);
  SDL_DestroyTexture (textTexture);
}


void DSPRenderImage (int screen_width, int screen_height)
{
  SDL_Surface* imageSurface;
  SDL_Texture* imageTexture;
  SDL_Rect imageRectangle;

  for (int i = 0; i < 4; i++) {
    imageSurface = SDL_LoadBMP (gameLogo[i]);
    imageTexture = SDL_CreateTextureFromSurface (mRenderer, imageSurface);
 
    imageRectangle.w = IMAGE_WIDTH;
    imageRectangle.h = imageRectangle.w;
    imageRectangle.x = (screen_width - MENU_WIDTH)/2 + 13 + i * (IMAGE_WIDTH + 26 + FRAME_SPACE);// 13-px spacing
    imageRectangle.y = 320 + 13;
  
    SDL_RenderCopy (mRenderer, imageTexture, NULL, &imageRectangle);
  }
  SDL_FreeSurface (imageSurface);
  SDL_DestroyTexture (imageTexture);
}


void DSPRenderLogo (int screen_width, int screen_height)
{
  SDL_Surface* logoSurface;
  SDL_Texture* logoTexture;
  SDL_Rect logoRectangle;

  logoSurface = SDL_LoadBMP (pmdLogo[0]);
  logoTexture = SDL_CreateTextureFromSurface (lRenderer, logoSurface);
  
  logoRectangle.w = 830;
  logoRectangle.h = 570;
  logoRectangle.x = (screen_width - 830)/2;
  logoRectangle.y = (screen_height - 570)/2;

  SDL_RenderCopy (lRenderer, logoTexture, NULL, &logoRectangle);
  SDL_RenderPresent (lRenderer);
  SDL_Delay(6000);// wait 6 sec.
 
  SDL_DestroyTexture (logoTexture);
  SDL_FreeSurface (logoSurface);
}


void DSPRenderMenu (int screen_width, int screen_height, int index)
{
  SDL_Rect frameRectangle;
  SDL_Rect frameRectangleInner;

  for (int i = 0; i < 4; i++) {
    frameRectangle.w = 200;
    frameRectangle.h = 260;
    frameRectangle.x = (screen_width - MENU_WIDTH)/2 + i *(FRAME_WIDTH + FRAME_SPACE);
    frameRectangle.y = 320;

    frameRectangleInner.w = 198;
    frameRectangleInner.h = 258;
    frameRectangleInner.x = (screen_width - MENU_WIDTH)/2 + 1 + i *(FRAME_WIDTH + FRAME_SPACE);
    frameRectangleInner.y = 320 + 1;

    if (i == index) { SDL_SetRenderDrawColor (mRenderer, 255, 255, 255, SDL_ALPHA_OPAQUE);
    } else { SDL_SetRenderDrawColor (mRenderer, 0, 0, 0, SDL_ALPHA_OPAQUE); }

    SDL_RenderDrawRect (mRenderer, &frameRectangle);
    SDL_RenderDrawRect (mRenderer, &frameRectangleInner);
  }
  DSPRenderText (screen_width, screen_height);
  DSPRenderImage (screen_width, screen_height);
 
  SDL_RenderPresent (mRenderer);
}


/** Draw a text line on the menu renderer.
 */
static void DSPDrawText (TTF_Font *pFont, const std::string &sText, int iX, int iY)
{
  if (sText.empty ())
    return;
  SDL_Color sColor = {255, 255, 255, SDL_ALPHA_OPAQUE};
  SDL_Surface *pSurface = TTF_RenderText_Solid (pFont, sText.c_str (), sColor);
  if (!pSurface)
    return;
  SDL_Texture *pText = SDL_CreateTextureFromSurface (mRenderer, pSurface);
  SDL_Rect sRect = {iX, iY, FONT_WIDTH * (int) sText.size (), FONT_HEIGHT};
  SDL_RenderCopy (mRenderer, pText, NULL, &sRect);
  SDL_DestroyTexture (pText);
  SDL_FreeSurface (pSurface);
}


void DSPRenderGameList (int screen_width, int screen_height, int index, const std::vector <std::string> &oNames, const std::vector <std::string> &oNotes)
{
  const int iRowHeight = FONT_HEIGHT + 8;
  const int iTop = 140;
  const int iBottom = screen_height - 110;
  int iRows = (iBottom - iTop) / iRowHeight;
  if (iRows < 5)
    iRows = 5;
  int iCount = (int) oNames.size ();
  int iFirst = index - iRows / 2;
  if (iFirst > iCount - iRows)
    iFirst = iCount - iRows;
  if (iFirst < 0)
    iFirst = 0;

  TTF_Font *pFont = TTF_OpenFont (gameFont[0], FONT_HEIGHT);
  if (!pFont)
    return;
  SDL_SetRenderDrawColor (mRenderer, 0, 0, 0, SDL_ALPHA_OPAQUE);
  SDL_RenderClear (mRenderer);
  SDL_SetRenderDrawColor (mRenderer, 255, 255, 255, SDL_ALPHA_OPAQUE);

  int iX = (screen_width - MENU_WIDTH) / 2;
  DSPDrawText (pFont, "Vsechny hry " + std::to_string (index + 1) + "/" + std::to_string (iCount), iX, 60);
  for (int i = iFirst ; i < iCount && i < iFirst + iRows ; i ++)
  {
    int iY = iTop + (i - iFirst) * iRowHeight;
    if (i == index)
    {
      SDL_Rect sFrame = {iX - 12, iY - 4, MENU_WIDTH + 24, iRowHeight};
      SDL_RenderDrawRect (mRenderer, &sFrame);
      SDL_Rect sInner = {sFrame.x + 1, sFrame.y + 1, sFrame.w - 2, sFrame.h - 2};
      SDL_RenderDrawRect (mRenderer, &sInner);
    }
    DSPDrawText (pFont, oNames [i], iX, iY);
    DSPDrawText (pFont, oNotes [i], iX + FONT_WIDTH * 14, iY);
  }
  DSPDrawText (pFont, "Sipky nebo [ E ] [ Y ]: vyber  <- -> strana  [ Enter ]: spust  [ Esc ]: zpet", iX, screen_height - 70);
  TTF_CloseFont (pFont);
  SDL_RenderPresent (mRenderer);
}

//-------------------------------------------------------------------------------------------------------
