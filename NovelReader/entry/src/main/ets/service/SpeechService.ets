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

  private constructor() {}

  public static getInstance(): SpeechService {
    if (!SpeechService.instance) {
      SpeechService.instance = new SpeechService();
    }
    return SpeechService.instance;
  }

  startSpeech(text: string): boolean {
    try {
      this.currentText = text;
      this.isPlaying = true;
      console.log(TAG, `Start speech: ${text.substring(0, 50)}...`);
      return true;
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `Failed to start speech: code=${err.code}, message=${err.message}`);
      return false;
    }
  }

  pauseSpeech(): boolean {
    try {
      this.isPlaying = false;
      console.log(TAG, 'Speech paused');
      return true;
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `Failed to pause speech: code=${err.code}, message=${err.message}`);
      return false;
    }
  }

  resumeSpeech(): boolean {
    try {
      this.isPlaying = true;
      console.log(TAG, 'Speech resumed');
      return true;
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `Failed to resume speech: code=${err.code}, message=${err.message}`);
      return false;
    }
  }

  stopSpeech(): boolean {
    try {
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

  release(): void {
    this.isPlaying = false;
    this.currentText = '';
    this.cancelTimer();
    this.onStop = null;
    console.log(TAG, 'Speech engine released');
  }
}