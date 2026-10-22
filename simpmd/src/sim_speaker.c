/*

SIM_SPEAKER.C

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

 - Removed options.
 - Larger buffers, thread safe sound generation, bounded latency.

*/


#include "sim_common.h"


//--------------------------------------------------------------------------
// Command Line Options

/// Sampling rate. What sampling rate to use for the audio output.
static int iArgSamplingRate = 48000;

/// Software buffer size. What buffer size to use for software storing the samples, expressed in milliseconds.
static int iArgSoftwareBuffer = 200;

/// Hardware buffer size. What buffer size to use for hardware playing the samples, expressed in milliseconds.
static int iArgHardwareBuffer = 50;


//--------------------------------------------------------------------------
// Data

/// Singleton audio specification.
static SDL_AudioSpec sAudioSpec;

/// Singleton cyclic audio buffer.
static byte *pAudioBuffer;
/// Size of the cyclic audio buffer.
static int iAudioBufferSize;
/// Head of the cyclic audio buffer.
static byte *volatile pAudioBufferHead;
/// Tail of the cyclic audio buffer.
static byte *volatile pAudioBufferTail;
/// Mutex protecting the cyclic audio buffer.
static pthread_mutex_t sAudioBufferLock;

/// Last generated value of simulated clock
static int iLastClock;
/// Last written value of simulated speaker.
static byte iLastSpeaker;
/// Last sample played, repeated on buffer underrun.
static byte bLastSample;
/// Maximum number of buffered samples, excess is dropped to bound latency.
static int iMaxBuffered;

/// Statistics, printed on shutdown when PMD_SNDSTATS is set.
static int iStatCallbacks;
static int iStatUnderruns;
static long iStatUnderrunSamples;
static long iStatDroppedSamples;

/// Speaker frequency mask.
#define PMD_SPEAKER_FREQUENCY   (3 << 0)
/// Speaker enable mask.
#define PMD_SPEAKER_ENABLE      (1 << 2)


//--------------------------------------------------------------------------
// Buffer operations

/// Increments pointer in the cyclic audio buffer.
byte *SNDIncrementInBuffer (byte *pPosition)
{
  byte *pResult = pPosition + 1;
  if (pResult >= pAudioBuffer + iAudioBufferSize)
  {
    pResult -= iAudioBufferSize;
  }
  return (pResult);
}


/** Flushes the cyclic audio buffer.
 *
 *  Must be called with the buffer lock held.
 */
void SNDFlushBuffer ()
{
  pAudioBufferHead = pAudioBufferTail;
}


/** Drops oldest samples above the latency limit.
 *
 *  Must be called with the buffer lock held.
 */
void SNDTrimBuffer ()
{
  int iBuffered = pAudioBufferTail - pAudioBufferHead;
  if (iBuffered < 0) iBuffered += iAudioBufferSize;
  int iExcess = iBuffered - iMaxBuffered;
  if (iExcess > 0)
  {
    iStatDroppedSamples += iExcess;
    pAudioBufferHead += iExcess;
    if (pAudioBufferHead >= pAudioBuffer + iAudioBufferSize)
    {
      pAudioBufferHead -= iAudioBufferSize;
    }
  }
}


/** Reads pattern from the cyclic audio buffer.
 *
 *  Must be called with the buffer lock held.
 *
 *  @arg pBuffer The buffer to fill.
 *  @arg iCount  The number of samples.
 */
void SNDReadBuffer (byte *pBuffer, int iCount)
{
  int iMissing = 0;
  for (int i = 0 ; i < iCount ; i ++)
  {
    if (pAudioBufferHead != pAudioBufferTail)
    {
      bLastSample = *pAudioBufferHead;
      pAudioBufferHead = SNDIncrementInBuffer (pAudioBufferHead);
    }
    else
    {
      iMissing ++;
    }
    *pBuffer = bLastSample;
    pBuffer ++;
  }
  iStatCallbacks ++;
  if (iMissing > 0)
  {
    iStatUnderruns ++;
    iStatUnderrunSamples += iMissing;
  }
}


/** Writes pattern to the cyclic audio buffer.
 *
 *  Must be called with the buffer lock held.
 *
 *  @arg iSample The value to put.
 *  @arg iCount  The number of samples.
 */
void SNDWriteBuffer (byte bSample, int iCount)
{
  for (int i = 0 ; i < iCount ; i ++)
  {
    (*pAudioBufferTail) = bSample;
    pAudioBufferTail = SNDIncrementInBuffer (pAudioBufferTail);
    if (pAudioBufferTail == pAudioBufferHead)
    {
      pAudioBufferHead = SNDIncrementInBuffer (pAudioBufferHead);
    }
  }
}


//--------------------------------------------------------------------------
// Sound generation

/** Synchronizes simulated clock with real time.
 */
void SNDSynchronize ()
{
  CheckZero (pthread_mutex_lock (&sAudioBufferLock));
  // Synchronize the time.
  iLastClock = iProcessorClock;
  // Synchronize the buffer.
  SNDFlushBuffer ();
  CheckZero (pthread_mutex_unlock (&sAudioBufferLock));
}


/** Generate sound.
 *
 *  Calculates position and generates sound.
 *  Must be called with the buffer lock held.
 *
 *  @arg iSpeaker Speaker register value.
 */
void SNDGenerate (byte iSpeaker)
{
  // Calculate current position in the cyclic audio buffer
  // based on the known sampling rate and the known clock
  // frequency.
  // Use 64 bit arithmetic, the product overflows int after ~22 ms.
  int iDeltaInClocks = iProcessorClock - iLastClock;
  if (iDeltaInClocks <= 0) return;
  int iDeltaInSamples = ((int64_t) iDeltaInClocks * iArgSamplingRate) / PMD_CLOCK;

  // Writing more than the buffer holds is pointless.
  if (iDeltaInSamples > iAudioBufferSize) iDeltaInSamples = iAudioBufferSize;

  // Fill the buffer with the required number of samples.
  SNDWriteBuffer ((iSpeaker & PMD_SPEAKER_ENABLE) ? 255 : 0, iDeltaInSamples);

  // Avoid accumulative error by only advancing the clock by sample value.
  iDeltaInClocks = ((int64_t) iDeltaInSamples * PMD_CLOCK) / iArgSamplingRate;
  iLastClock += iDeltaInClocks;
}


//--------------------------------------------------------------------------
// Port operations

/** Write to speaker register.
 *
 *  Fills the cyclic audio buffer by data corresponding
 *  to the simulated speaker. Only the binary speaker
 *  output is simulated for now.
 *
 *  @arg iData The written value.
 */
void SNDWriteSpeaker (byte iData)
{
  CheckZero (pthread_mutex_lock (&sAudioBufferLock));
  // Generate whatever sound was heard until now.
  SNDGenerate (iLastSpeaker);
  // Set what sound is heard from now on.
  iLastSpeaker = iData;
  CheckZero (pthread_mutex_unlock (&sAudioBufferLock));
}


//--------------------------------------------------------------------------
// Callback handlers

/** Handler for filling the sound buffer.
 *
 *  @arg pParameters Callback parameters.
 *  @arg pBuffer Sound buffer address.
 *  @arg iLength Sound buffer length.
 */
void SNDFillBufferCallback (void *pParameters, byte *pBuffer, int iLength)
{
  // The callback runs in the audio thread, concurrently
  // with the processor thread writing the speaker.
  CheckZero (pthread_mutex_lock (&sAudioBufferLock));
  // Generate whatever sound was heard until now.
  SNDGenerate (iLastSpeaker);
  // Keep latency bounded when emulation runs ahead of audio clock.
  SNDTrimBuffer ();
  // Fill the buffer with the generated sound.
  SNDReadBuffer (pBuffer, iLength);
  CheckZero (pthread_mutex_unlock (&sAudioBufferLock));
}


//--------------------------------------------------------------------------
// Initialization and shutdown


void SNDInitialize ()
{
  // Initialize the cyclic audio buffer ...
  iAudioBufferSize = (iArgSoftwareBuffer * iArgSamplingRate) / 1000;
  pAudioBuffer = new byte [iAudioBufferSize];
  CheckZero (pthread_mutex_init (&sAudioBufferLock, NULL));
  CheckZero (pthread_mutex_lock (&sAudioBufferLock));
  pAudioBufferHead = pAudioBuffer;
  pAudioBufferTail = pAudioBuffer;
  iLastClock = iProcessorClock;
  iLastSpeaker = 0;
  bLastSample = 0;
  CheckZero (pthread_mutex_unlock (&sAudioBufferLock));

  // Prepare audio parameters ...
  sAudioSpec.freq = iArgSamplingRate;
  sAudioSpec.format = AUDIO_U8;
  sAudioSpec.samples = POT ((iArgHardwareBuffer * iArgSamplingRate) / 1000);
  sAudioSpec.channels = 1;
  sAudioSpec.userdata = NULL;
  sAudioSpec.callback = SNDFillBufferCallback;

  // Open the audio device ...
  SDL_CheckZero (SDL_OpenAudio (&sAudioSpec, NULL));

  // Check if audio parameters were granted ...
  assert (sAudioSpec.freq == iArgSamplingRate);
  assert (sAudioSpec.format == AUDIO_U8);

  // Allow two hardware buffers of samples to be queued ...
  iMaxBuffered = 2 * sAudioSpec.samples;

  // Start the callback ...
  SDL_PauseAudio (0);
}


void SNDShutdown ()
{
  // Close the audio device ...
  SDL_CloseAudio ();

  if (getenv ("PMD_SNDSTATS"))
  {
    printf ("SND stats: callbacks %d, underruns %d (%ld samples), dropped %ld samples\n",
            iStatCallbacks, iStatUnderruns, iStatUnderrunSamples, iStatDroppedSamples);
  }

  // Free the audio buffer mutex ...
  CheckZero (pthread_mutex_destroy (&sAudioBufferLock));
  delete [] (pAudioBuffer);
}


//--------------------------------------------------------------------------

