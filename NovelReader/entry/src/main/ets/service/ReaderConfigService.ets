import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { ReaderConfig, ThemeConfig } from '../model/Book';
import { getGlobalContext } from '../utils/GlobalContext';

const TAG: string = 'ReaderConfigService';
const STORE_NAME: string = 'ReaderConfigStore';
const KEY_CONFIG: string = 'reader_config';

interface ThemeOption {
  value: string;
  label: string;
}

interface PageTurnOption {
  value: string;
  label: string;
}

const LIGHT_THEME: ThemeConfig = {
  backgroundColor: '#FFFFFF',
  textColor: '#333333',
  titleColor: '#111111'
};

const DARK_THEME: ThemeConfig = {
  backgroundColor: '#1A1A1A',
  textColor: '#E0E0E0',
  titleColor: '#FFFFFF'
};

const SEPIA_THEME: ThemeConfig = {
  backgroundColor: '#F5E6D3',
  textColor: '#4A3728',
  titleColor: '#2D1F14'
};

const GREEN_THEME: ThemeConfig = {
  backgroundColor: '#E8F5E9',
  textColor: '#2E7D32',
  titleColor: '#1B5E20'
};

export class ReaderConfigService {
  private static instance: ReaderConfigService;
  private preferences: preferences.Preferences | null = null;
  private config: ReaderConfig = {
    fontSize: 16,
    lineSpacing: 1.5,
    theme: 'light',
    pageTurnMode: 'slide',
    brightness: 100,
    keepScreenOn: false,
    textToSpeechEnabled: false
  };

  private constructor() {}

  public static getInstance(): ReaderConfigService {
    if (!ReaderConfigService.instance) {
      ReaderConfigService.instance = new ReaderConfigService();
    }
    return ReaderConfigService.instance;
  }

  private initPreferences(): void {
    if (!this.preferences) {
      try {
        const context = getGlobalContext();
        this.preferences = preferences.getPreferencesSync(context, { name: STORE_NAME });
      } catch (error) {
        const err = error as BusinessError;
        console.error(TAG, `initPreferences failed, error code=${err.code}, message=${err.message}`);
      }
    }
  }

  private flush(): void {
    if (this.preferences) {
      this.preferences.flush((err: BusinessError) => {
        if (err) {
          console.error(TAG, `Failed to flush. Code:${err.code}, message:${err.message}`);
        }
      });
    }
  }

  private copyConfig(source: ReaderConfig): ReaderConfig {
    return {
      fontSize: source.fontSize,
      lineSpacing: source.lineSpacing,
      theme: source.theme,
      pageTurnMode: source.pageTurnMode,
      brightness: source.brightness,
      keepScreenOn: source.keepScreenOn,
      textToSpeechEnabled: source.textToSpeechEnabled
    };
  }

  private createDefaultConfig(): ReaderConfig {
    return {
      fontSize: 16,
      lineSpacing: 1.5,
      theme: 'light',
      pageTurnMode: 'slide',
      brightness: 100,
      keepScreenOn: false,
      textToSpeechEnabled: false
    };
  }

  loadConfig(): ReaderConfig {
    this.initPreferences();
    if (!this.preferences) {
      return this.createDefaultConfig();
    }
    try {
      const configData = this.preferences.getSync(KEY_CONFIG, '') as string;
      if (configData) {
        const savedConfig = JSON.parse(configData) as ReaderConfig;
        this.config = this.copyConfig(savedConfig);
        if (!this.config.fontSize) this.config.fontSize = 16;
        if (!this.config.lineSpacing) this.config.lineSpacing = 1.5;
        if (!this.config.theme) this.config.theme = 'light';
        if (!this.config.pageTurnMode) this.config.pageTurnMode = 'slide';
        if (this.config.brightness === undefined) this.config.brightness = 100;
        if (this.config.keepScreenOn === undefined) this.config.keepScreenOn = false;
        if (this.config.textToSpeechEnabled === undefined) this.config.textToSpeechEnabled = false;
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `loadConfig failed, error code=${err.code}, message=${err.message}`);
      this.config = this.createDefaultConfig();
    }
    return this.copyConfig(this.config);
  }

  saveConfig(config: ReaderConfig): boolean {
    this.initPreferences();
    if (!this.preferences) {
      return false;
    }
    try {
      this.config = this.copyConfig(config);
      this.preferences.putSync(KEY_CONFIG, JSON.stringify(this.config));
      this.flush();
      return true;
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `saveConfig failed, error code=${err.code}, message=${err.message}`);
      return false;
    }
  }

  getFontSize(): number {
    return this.config.fontSize;
  }

  setFontSize(fontSize: number): boolean {
    this.config.fontSize = fontSize;
    return this.saveConfig(this.config);
  }

  getLineSpacing(): number {
    return this.config.lineSpacing;
  }

  setLineSpacing(lineSpacing: number): boolean {
    this.config.lineSpacing = lineSpacing;
    return this.saveConfig(this.config);
  }

  getTheme(): string {
    return this.config.theme;
  }

  setTheme(theme: 'light' | 'dark' | 'sepia' | 'green'): boolean {
    this.config.theme = theme;
    return this.saveConfig(this.config);
  }

  getThemeConfig(theme?: 'light' | 'dark' | 'sepia' | 'green'): ThemeConfig {
    const themeValue = theme || this.config.theme;
    if (themeValue === 'dark') {
      return DARK_THEME;
    } else if (themeValue === 'sepia') {
      return SEPIA_THEME;
    } else if (themeValue === 'green') {
      return GREEN_THEME;
    }
    return LIGHT_THEME;
  }

  getPageTurnMode(): string {
    return this.config.pageTurnMode;
  }

  setPageTurnMode(mode: 'slide' | 'flip' | 'scroll'): boolean {
    this.config.pageTurnMode = mode;
    return this.saveConfig(this.config);
  }

  getBrightness(): number {
    return this.config.brightness;
  }

  setBrightness(brightness: number): boolean {
    this.config.brightness = brightness;
    return this.saveConfig(this.config);
  }

  getKeepScreenOn(): boolean {
    return this.config.keepScreenOn;
  }

  setKeepScreenOn(keepScreenOn: boolean): boolean {
    this.config.keepScreenOn = keepScreenOn;
    return this.saveConfig(this.config);
  }

  getTextToSpeechEnabled(): boolean {
    return this.config.textToSpeechEnabled;
  }

  setTextToSpeechEnabled(enabled: boolean): boolean {
    this.config.textToSpeechEnabled = enabled;
    return this.saveConfig(this.config);
  }

  resetToDefault(): boolean {
    this.config = this.createDefaultConfig();
    return this.saveConfig(this.config);
  }

  getDefaultConfig(): ReaderConfig {
    return this.createDefaultConfig();
  }

  getAvailableThemes(): ThemeOption[] {
    const themes: ThemeOption[] = [];
    const theme1: ThemeOption = { value: 'light', label: '明亮' };
    const theme2: ThemeOption = { value: 'dark', label: '暗黑' };
    const theme3: ThemeOption = { value: 'sepia', label: '护眼' };
    const theme4: ThemeOption = { value: 'green', label: '绿色' };
    themes.push(theme1);
    themes.push(theme2);
    themes.push(theme3);
    themes.push(theme4);
    return themes;
  }

  getAvailablePageTurnModes(): PageTurnOption[] {
    const modes: PageTurnOption[] = [];
    const mode1: PageTurnOption = { value: 'slide', label: '滑动翻页' };
    const mode2: PageTurnOption = { value: 'flip', label: '翻页效果' };
    const mode3: PageTurnOption = { value: 'scroll', label: '滚动模式' };
    modes.push(mode1);
    modes.push(mode2);
    modes.push(mode3);
    return modes;
  }
}