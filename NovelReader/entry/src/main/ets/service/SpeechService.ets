import { textToSpeech } from '@kit.CoreSpeechKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG: string = 'SpeechService';

export class SpeechService {
  private static instance: SpeechService;
  private isPlaying: boolean = false;
  private currentText: string = '';
  private speechRate: number = 1.0;
  private speechVolume: number = 1.0;
  private speechPitch: number = 1.0;
  private timer: number | null = null;
  private stopTime: number = 0;
  private onStop: (() => void) | null = null;
  private ttsEngine: textToSpeech.TextToSpeechEngine | null = null;
  private isInitialized: boolean = false;
  private requestId: number = 0;

  private constructor() {}

  public static getInstance(): SpeechService {
    if (!SpeechService.instance) {
      SpeechService.instance = new SpeechService();
    }
    return SpeechService.instance;
  }

  private async initEngine(): Promise<void> {
    if (this.isInitialized && this.ttsEngine) {
      return;
    }
    return new Promise((resolve) => {
      try {
        const extraParam: Record<string, Object> = {
          'style': 'interaction-broadcast',
          'locate': 'CN',
          'name': 'NovelReaderEngine'
        };
        const initParamsInfo: textToSpeech.CreateEngineParams = {
          language: 'zh-CN',
          person: 0,
          online: 1,
          extraParams: extraParam
        };
        textToSpeech.createEngine(initParamsInfo, (err: BusinessError, engine: textToSpeech.TextToSpeechEngine) => {
          if (err) {
            console.error(TAG, `Failed to create engine. Code: ${err.code}, message: ${err.message}.`);
            this.isInitialized = false;
            resolve();
            return;
          }
          this.ttsEngine = engine;
          this.ttsEngine.setListener({
            onStart: (requestId: string) => {
              this.isPlaying = true;
              console.log(TAG, `Speech started, requestId: ${requestId}`);
            },
            onStop: (requestId: string) => {
              this.isPlaying = false;
              console.log(TAG, `Speech stopped, requestId: ${requestId}`);
              if (this.onStop) {
                this.onStop();
              }
            },
            onComplete: (requestId: string) => {
              this.isPlaying = false;
              console.log(TAG, `Speech completed, requestId: ${requestId}`);
              if (this.onStop) {
                this.onStop();
              }
            },
            onError: (requestId: string, errorCode: number, errorMessage: string) => {
              this.isPlaying = false;
              console.error(TAG, `Speech error, requestId: ${requestId}, errorCode: ${errorCode}, errorMessage: ${errorMessage}`);
            }
          });
          this.isInitialized = true;
          console.log(TAG, 'TTS engine initialized');
          resolve();
        });
      } catch (error) {
        const err = error as BusinessError;
        console.error(TAG, `Failed to init TTS engine: code=${err.code}, message=${err.message}`);
        this.isInitialized = false;
        resolve();
      }
    });
  }

  async startSpeech(text: string): Promise<boolean> {
    try {
      await this.initEngine();
      if (!this.ttsEngine) {
        console.error(TAG, 'TTS engine not initialized');
        return false;
      }
      if (this.isPlaying) {
        this.isPlaying = false;
        try {
          await this.ttsEngine.stop();
        } catch (err) {
          console.warn(TAG, `Failed to stop previous speech: ${(err as BusinessError).message}`);
        }
      }
      this.currentText = text;
      this.isPlaying = true;
      this.requestId++;
      const extraParam: Record<string, Object> = {
        'queueMode': 0,
        'speed': this.speechRate,
        'volume': this.speechVolume,
        'pitch': this.speechPitch,
        'languageContext': 'zh-CN',
        'audioType': 'pcm',
        'soundChannel': 3,
        'playType': 1
      };
      const speakParams: textToSpeech.SpeakParams = {
        requestId: `request_${this.requestId}`,
        extraParams: extraParam
      };
      this.ttsEngine.speak(text, speakParams);
      return true;
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `Failed to start speech: code=${err.code}, message=${err.message}`);
      this.isPlaying = false;
      return false;
    }
  }

  async pauseSpeech(): Promise<boolean> {
    try {
      if (!this.ttsEngine) {
        return false;
      }
      await this.ttsEngine.stop();
      this.isPlaying = false;
      console.log(TAG, 'Speech paused');
      return true;
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `Failed to pause speech: code=${err.code}, message=${err.message}`);
      return false;
    }
  }

  async resumeSpeech(): Promise<boolean> {
    return await this.startSpeech(this.currentText);
  }

  async stopSpeech(): Promise<boolean> {
    try {
      if (!this.ttsEngine) {
        return false;
      }
      await this.ttsEngine.stop();
      this.isPlaying = false;
      console.log(TAG, 'Speech stopped');
      return true;
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `Failed to stop speech: code=${err.code}, message=${err.message}`);
      return false;
    }
  }

  setSpeechRate(rate: number): void {
    this.speechRate = Math.max(0.5, Math.min(2.0, rate));
  }

  getSpeechRate(): number {
    return this.speechRate;
  }

  setSpeechVolume(volume: number): void {
    this.speechVolume = Math.max(0, Math.min(1, volume));
  }

  getSpeechVolume(): number {
    return this.speechVolume;
  }

  setSpeechPitch(pitch: number): void {
    this.speechPitch = Math.max(0.5, Math.min(2.0, pitch));
  }

  getSpeechPitch(): number {
    return this.speechPitch;
  }

  isPlayingStatus(): boolean {
    return this.isPlaying;
  }

  getCurrentText(): string {
    return this.currentText;
  }

  setTimer(duration: number): void {
    if (this.timer !== null) {
      clearTimeout(this.timer);
    }
    this.stopTime = Date.now() + duration * 60 * 1000;
    this.timer = setTimeout(() => {
      this.stopSpeech();
      if (this.onStop) {
        this.onStop();
      }
    }, duration * 60 * 1000);
    console.log(TAG, `Timer set for ${duration} minutes`);
  }

  cancelTimer(): void {
    if (this.timer !== null) {
      clearTimeout(this.timer);
      this.timer = null;
      this.stopTime = 0;
      console.log(TAG, 'Timer cancelled');
    }
  }

  getRemainingTime(): number {
    if (this.stopTime === 0) {
      return 0;
    }
    const remaining = Math.max(0, this.stopTime - Date.now());
    return Math.ceil(remaining / 60000);
  }

  setOnStop(callback: (() => void) | null): void {
    this.onStop = callback;
  }

  async release(): Promise<void> {
    this.isPlaying = false;
    this.currentText = '';
    this.cancelTimer();
    this.onStop = null;
    if (this.ttsEngine) {
      try {
        await this.ttsEngine.shutdown();
        this.ttsEngine = null;
        this.isInitialized = false;
      } catch (error) {
        const err = error as BusinessError;
        console.error(TAG, `Failed to shutdown TTS engine: code=${err.code}, message=${err.message}`);
      }
    }
    console.log(TAG, 'Speech engine released');
  }
}