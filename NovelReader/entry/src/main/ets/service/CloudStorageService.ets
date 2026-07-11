import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { Book, ReadingProgress, Bookmark } from '../model/Book';
import { getGlobalContext } from '../utils/GlobalContext';

const TAG: string = 'CloudStorageService';
const STORE_NAME: string = 'CloudSyncStore';
const KEY_SYNC_DATA: string = 'sync_data';
const KEY_SYNC_TIME: string = 'sync_time';

export interface SyncData {
  books: Book[];
  progresses: Record<string, ReadingProgress>;
  bookmarks: Record<string, Bookmark[]>;
  syncTime: number;
}

export class CloudStorageService {
  private static instance: CloudStorageService;
  private preferences: preferences.Preferences | null = null;
  private isEnabled: boolean = false;
  private isConnected: boolean = false;
  private onSyncChange: ((data: SyncData) => void) | null = null;

  private constructor() {}

  public static getInstance(): CloudStorageService {
    if (!CloudStorageService.instance) {
      CloudStorageService.instance = new CloudStorageService();
    }
    return CloudStorageService.instance;
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

  public setOnSyncChange(callback: ((data: SyncData) => void) | null): void {
    this.onSyncChange = callback;
  }

  public async enableSync(): Promise<boolean> {
    if (this.isEnabled) {
      return true;
    }
    try {
      this.initPreferences();
      this.isEnabled = true;
      this.isConnected = true;
      console.log(TAG, 'Cloud sync enabled successfully');
      return true;
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `Failed to enable sync: code=${err.code}, message=${err.message}`);
      this.isEnabled = false;
      return false;
    }
  }

  public disableSync(): void {
    this.isEnabled = false;
    this.isConnected = false;
    console.log(TAG, 'Cloud sync disabled');
  }

  public getSyncData(): SyncData {
    this.initPreferences();
    if (!this.preferences) {
      return {
        books: [],
        progresses: {},
        bookmarks: {},
        syncTime: Date.now()
      };
    }
    try {
      const dataStr = this.preferences.getSync(KEY_SYNC_DATA, '{}') as string;
      const data = JSON.parse(dataStr) as Partial<SyncData>;
      return {
        books: data.books || [],
        progresses: data.progresses || {},
        bookmarks: data.bookmarks || {},
        syncTime: data.syncTime || Date.now()
      };
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `Failed to get sync data: code=${err.code}, message=${err.message}`);
      return {
        books: [],
        progresses: {},
        bookmarks: {},
        syncTime: Date.now()
      };
    }
  }

  private saveSyncData(data: SyncData): void {
    this.initPreferences();
    if (!this.preferences) {
      return;
    }
    try {
      this.preferences.putSync(KEY_SYNC_DATA, JSON.stringify(data));
      this.preferences.putSync(KEY_SYNC_TIME, data.syncTime.toString());
      this.flush();
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `Failed to save sync data: code=${err.code}, message=${err.message}`);
    }
  }

  public async syncBooks(books: Book[]): Promise<boolean> {
    if (!this.isEnabled) {
      return false;
    }
    try {
      const data = this.getSyncData();
      data.books = books;
      data.syncTime = Date.now();
      this.saveSyncData(data);
      console.log(TAG, `Synced ${books.length} books`);
      if (this.onSyncChange) {
        this.onSyncChange(data);
      }
      return true;
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `Failed to sync books: code=${err.code}, message=${err.message}`);
      return false;
    }
  }

  public async syncProgress(bookId: string, progress: ReadingProgress): Promise<boolean> {
    if (!this.isEnabled) {
      return false;
    }
    try {
      const data = this.getSyncData();
      data.progresses = data.progresses || {};
      data.progresses[bookId] = progress;
      data.syncTime = Date.now();
      this.saveSyncData(data);
      console.log(TAG, `Synced progress for book: ${bookId}`);
      if (this.onSyncChange) {
        this.onSyncChange(data);
      }
      return true;
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `Failed to sync progress: code=${err.code}, message=${err.message}`);
      return false;
    }
  }

  public async syncBookmarks(bookId: string, bookmarks: Bookmark[]): Promise<boolean> {
    if (!this.isEnabled) {
      return false;
    }
    try {
      const data = this.getSyncData();
      data.bookmarks = data.bookmarks || {};
      data.bookmarks[bookId] = bookmarks;
      data.syncTime = Date.now();
      this.saveSyncData(data);
      console.log(TAG, `Synced ${bookmarks.length} bookmarks for book: ${bookId}`);
      if (this.onSyncChange) {
        this.onSyncChange(data);
      }
      return true;
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `Failed to sync bookmarks: code=${err.code}, message=${err.message}`);
      return false;
    }
  }

  public async syncAllData(data: SyncData): Promise<boolean> {
    if (!this.isEnabled) {
      return false;
    }
    try {
      data.syncTime = Date.now();
      this.saveSyncData(data);
      console.log(TAG, 'Synced all data');
      if (this.onSyncChange) {
        this.onSyncChange(data);
      }
      return true;
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `Failed to sync all data: code=${err.code}, message=${err.message}`);
      return false;
    }
  }

  public isSyncEnabled(): boolean {
    return this.isEnabled;
  }

  public isSyncConnected(): boolean {
    return this.isConnected;
  }

  public getSyncTime(): number {
    this.initPreferences();
    if (!this.preferences) {
      return 0;
    }
    try {
      const timeStr = this.preferences.getSync(KEY_SYNC_TIME, '0') as string;
      return parseInt(timeStr, 10);
    } catch (error) {
      return 0;
    }
  }

  public async mergeRemoteData(remoteData: SyncData): Promise<void> {
    const localData = this.getSyncData();

    const mergedBooks = this.mergeBooks(localData.books, remoteData.books);
    const mergedProgresses = this.mergeProgresses(localData.progresses, remoteData.progresses);
    const mergedBookmarks = this.mergeBookmarks(localData.bookmarks, remoteData.bookmarks);

    const mergedData: SyncData = {
      books: mergedBooks,
      progresses: mergedProgresses,
      bookmarks: mergedBookmarks,
      syncTime: Date.now()
    };

    await this.syncAllData(mergedData);
  }

  private mergeBooks(localBooks: Book[], remoteBooks: Book[]): Book[] {
    const bookMap = new Map<string, Book>();
    for (let i = 0; i < localBooks.length; i++) {
      bookMap.set(localBooks[i].id, localBooks[i]);
    }
    for (let i = 0; i < remoteBooks.length; i++) {
      const remoteBook = remoteBooks[i];
      const existing = bookMap.get(remoteBook.id);
      if (!existing || remoteBook.lastReadTime > existing.lastReadTime) {
        bookMap.set(remoteBook.id, remoteBook);
      }
    }
    return Array.from(bookMap.values());
  }

  private mergeProgresses(localProgresses: Record<string, ReadingProgress>, remoteProgresses: Record<string, ReadingProgress>): Record<string, ReadingProgress> {
    const merged: Record<string, ReadingProgress> = {};
    const localKeys = Object.keys(localProgresses);
    for (let i = 0; i < localKeys.length; i++) {
      const key = localKeys[i];
      merged[key] = localProgresses[key];
    }
    const remoteKeys = Object.keys(remoteProgresses);
    for (let i = 0; i < remoteKeys.length; i++) {
      const key = remoteKeys[i];
      const remoteProgress = remoteProgresses[key];
      const localProgress = merged[key];
      if (!localProgress || remoteProgress.readTime > localProgress.readTime) {
        merged[key] = remoteProgress;
      }
    }
    return merged;
  }

  private mergeBookmarks(localBookmarks: Record<string, Bookmark[]>, remoteBookmarks: Record<string, Bookmark[]>): Record<string, Bookmark[]> {
    const merged: Record<string, Bookmark[]> = {};
    const localKeys = Object.keys(localBookmarks);
    for (let i = 0; i < localKeys.length; i++) {
      const key = localKeys[i];
      merged[key] = localBookmarks[key];
    }
    const remoteKeys = Object.keys(remoteBookmarks);
    for (let i = 0; i < remoteKeys.length; i++) {
      const key = remoteKeys[i];
      const remoteList = remoteBookmarks[key];
      const localList = merged[key] || [];
      const bookmarkMap = new Map<string, Bookmark>();
      for (let j = 0; j < localList.length; j++) {
        bookmarkMap.set(localList[j].id, localList[j]);
      }
      for (let j = 0; j < remoteList.length; j++) {
        const remoteBm = remoteList[j];
        const existing = bookmarkMap.get(remoteBm.id);
        if (!existing || remoteBm.createTime > existing.createTime) {
          bookmarkMap.set(remoteBm.id, remoteBm);
        }
      }
      merged[key] = Array.from(bookmarkMap.values());
    }
    return merged;
  }
}