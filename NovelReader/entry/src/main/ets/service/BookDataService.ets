/**
 * 书籍数据服务
 * 负责书籍信息、阅读进度、书签的数据持久化存储
 * 使用 Preferences API 进行本地存储，支持增删改查操作
 * 集成分布式数据管理实现跨设备云同步
 */
import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import fileIo from '@ohos.file.fs';
import { Book, ReadingProgress, Bookmark } from '../model/Book';
import { getGlobalContext } from '../utils/GlobalContext';
import { CloudStorageService } from './CloudStorageService';

const TAG: string = 'BookDataService';
const STORE_NAME: string = 'NovelReaderStore';
const KEY_BOOKS: string = 'books';
const KEY_PROGRESS_PREFIX: string = 'progress_';
const KEY_BOOKMARK_PREFIX: string = 'bookmark_';

export class BookDataService {
  private static instance: BookDataService;
  private preferences: preferences.Preferences | null = null;
  private cloudStorage: CloudStorageService = CloudStorageService.getInstance();

  private constructor() {}

  public static getInstance(): BookDataService {
    if (!BookDataService.instance) {
      BookDataService.instance = new BookDataService();
    }
    return BookDataService.instance;
  }

  async syncFromCloud(): Promise<void> {
    if (!this.cloudStorage.isSyncEnabled()) {
      return;
    }
    try {
      const syncData = this.cloudStorage.getSyncData();
      if (syncData.books.length > 0) {
        for (const book of syncData.books) {
          this.addBook(book);
        }
      }
      const progressKeys = Object.keys(syncData.progresses);
      for (let i = 0; i < progressKeys.length; i++) {
        const bookId = progressKeys[i];
        const progress = syncData.progresses[bookId];
        this.saveProgress(progress);
      }
      const bookmarkKeys = Object.keys(syncData.bookmarks);
      for (let i = 0; i < bookmarkKeys.length; i++) {
        const bookId = bookmarkKeys[i];
        const bookmarks = syncData.bookmarks[bookId];
        for (let j = 0; j < bookmarks.length; j++) {
          this.addBookmark(bookmarks[j]);
        }
      }
      console.log(TAG, 'Sync from cloud completed');
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `syncFromCloud failed: code=${err.code}, message=${err.message}`);
    }
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

  /**
   * 获取所有书籍列表
   * @returns 书籍数组
   */
  getAllBooks(): Book[] {
    this.initPreferences();
    if (!this.preferences) {
      return [];
    }
    try {
      const booksData = this.preferences.getSync(KEY_BOOKS, '[]') as string;
      return JSON.parse(booksData) as Book[];
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `getAllBooks failed, error code=${err.code}, message=${err.message}`);
      return [];
    }
  }

  getBookById(bookId: string): Book | undefined {
    const books = this.getAllBooks();
    return books.find(book => book.id === bookId);
  }

  /**
   * 按分类获取书籍列表
   * @param category 分类名称，'全部'表示获取所有书籍
   * @returns 对应分类的书籍数组
   */
  getBooksByCategory(category: string): Book[] {
    const books = this.getAllBooks();
    if (category === '全部') {
      return books;
    }
    return books.filter(book => book.category === category);
  }

  updateBookCategory(bookId: string, category: string): boolean {
    this.initPreferences();
    if (!this.preferences) {
      return false;
    }
    try {
      const books = this.getAllBooks();
      const index = books.findIndex(b => b.id === bookId);
      if (index !== -1) {
        books[index].category = category;
        this.preferences.putSync(KEY_BOOKS, JSON.stringify(books));
        this.flush();
        return true;
      }
      return false;
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `updateBookCategory failed, error code=${err.code}, message=${err.message}`);
      return false;
    }
  }

  /**
   * 添加书籍（避免重复）
   * @param book 书籍对象
   * @returns 是否添加成功
   */
  addBook(book: Book): boolean {
    this.initPreferences();
    if (!this.preferences) {
      return false;
    }
    try {
      const books = this.getAllBooks();
      const existingBook = books.find(b => b.name === book.name);
      if (!existingBook) {
        books.push(book);
        this.preferences.putSync(KEY_BOOKS, JSON.stringify(books));
        this.flush();
        this.cloudStorage.syncBooks(books);
        return true;
      } else {
        const index = books.findIndex(b => b.name === book.name);
        if (index !== -1) {
          if (book.cover && !existingBook.cover) {
            books[index].cover = book.cover;
          }
          if (book.category && !existingBook.category) {
            books[index].category = book.category;
          }
          if (book.totalChapters > 0 && existingBook.totalChapters === 0) {
            books[index].totalChapters = book.totalChapters;
          }
          this.preferences.putSync(KEY_BOOKS, JSON.stringify(books));
          this.flush();
          this.cloudStorage.syncBooks(books);
          return true;
        }
        return false;
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `addBook failed, error code=${err.code}, message=${err.message}`);
      return false;
    }
  }

  updateBook(book: Book): boolean {
    this.initPreferences();
    if (!this.preferences) {
      return false;
    }
    try {
      const books = this.getAllBooks();
      const index = books.findIndex(b => b.id === book.id);
      if (index !== -1) {
        books[index] = book;
        this.preferences.putSync(KEY_BOOKS, JSON.stringify(books));
        this.flush();
        this.cloudStorage.syncBooks(books);
        return true;
      }
      return false;
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `updateBook failed, error code=${err.code}, message=${err.message}`);
      return false;
    }
  }

  deleteBook(bookId: string): boolean {
    this.initPreferences();
    if (!this.preferences) {
      return false;
    }
    try {
      const books = this.getAllBooks();
      const filteredBooks = books.filter(b => b.id !== bookId);
      this.preferences.putSync(KEY_BOOKS, JSON.stringify(filteredBooks));
      this.deleteProgress(bookId);
      this.deleteAllBookmarks(bookId);
      this.flush();
      this.cloudStorage.syncBooks(filteredBooks);
      return true;
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `deleteBook failed, error code=${err.code}, message=${err.message}`);
      return false;
    }
  }

  /**
   * 保存阅读进度
   * @param progress 阅读进度对象
   * @returns 是否保存成功
   */
  saveProgress(progress: ReadingProgress): boolean {
    this.initPreferences();
    if (!this.preferences) {
      return false;
    }
    try {
      const key = `${KEY_PROGRESS_PREFIX}${progress.bookId}`;
      this.preferences.putSync(key, JSON.stringify(progress));
      this.flush();
      this.cloudStorage.syncProgress(progress.bookId, progress);
      return true;
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `saveProgress failed, error code=${err.code}, message=${err.message}`);
      return false;
    }
  }

  getProgress(bookId: string): ReadingProgress | undefined {
    this.initPreferences();
    if (!this.preferences) {
      return undefined;
    }
    try {
      const key = `${KEY_PROGRESS_PREFIX}${bookId}`;
      const progressData = this.preferences.getSync(key, '') as string;
      if (progressData) {
        return JSON.parse(progressData) as ReadingProgress;
      }
      return undefined;
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `getProgress failed, error code=${err.code}, message=${err.message}`);
      return undefined;
    }
  }

  deleteProgress(bookId: string): boolean {
    this.initPreferences();
    if (!this.preferences) {
      return false;
    }
    try {
      const key = `${KEY_PROGRESS_PREFIX}${bookId}`;
      if (this.preferences.hasSync(key)) {
        this.preferences.deleteSync(key);
        this.flush();
        return true;
      }
      return false;
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `deleteProgress failed, error code=${err.code}, message=${err.message}`);
      return false;
    }
  }

  /**
   * 添加书签
   * @param bookmark 书签对象
   * @returns 是否添加成功
   */
  addBookmark(bookmark: Bookmark): boolean {
    this.initPreferences();
    if (!this.preferences) {
      return false;
    }
    try {
      const bookmarks = this.getBookmarks(bookmark.bookId);
      bookmarks.push(bookmark);
      const key = `${KEY_BOOKMARK_PREFIX}${bookmark.bookId}`;
      this.preferences.putSync(key, JSON.stringify(bookmarks));
      this.flush();
      this.cloudStorage.syncBookmarks(bookmark.bookId, bookmarks);
      return true;
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `addBookmark failed, error code=${err.code}, message=${err.message}`);
      return false;
    }
  }

  getBookmarks(bookId: string): Bookmark[] {
    this.initPreferences();
    if (!this.preferences) {
      return [];
    }
    try {
      const key = `${KEY_BOOKMARK_PREFIX}${bookId}`;
      const bookmarkData = this.preferences.getSync(key, '[]') as string;
      return JSON.parse(bookmarkData) as Bookmark[];
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `getBookmarks failed, error code=${err.code}, message=${err.message}`);
      return [];
    }
  }

  deleteBookmark(bookId: string, bookmarkId: string): boolean {
    this.initPreferences();
    if (!this.preferences) {
      return false;
    }
    try {
      const bookmarks = this.getBookmarks(bookId);
      const filteredBookmarks = bookmarks.filter(b => b.id !== bookmarkId);
      const key = `${KEY_BOOKMARK_PREFIX}${bookId}`;
      this.preferences.putSync(key, JSON.stringify(filteredBookmarks));
      this.flush();
      this.cloudStorage.syncBookmarks(bookId, filteredBookmarks);
      return true;
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `deleteBookmark failed, error code=${err.code}, message=${err.message}`);
      return false;
    }
  }

  deleteAllBookmarks(bookId: string): boolean {
    this.initPreferences();
    if (!this.preferences) {
      return false;
    }
    try {
      const key = `${KEY_BOOKMARK_PREFIX}${bookId}`;
      if (this.preferences.hasSync(key)) {
        this.preferences.deleteSync(key);
        this.flush();
        return true;
      }
      return false;
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `deleteAllBookmarks failed, error code=${err.code}, message=${err.message}`);
      return false;
    }
  }

  clearAllBooks(): boolean {
    this.initPreferences();
    if (!this.preferences) {
      return false;
    }
    try {
      const books = this.getAllBooks();
      for (let i: number = 0; i < books.length; i++) {
        const book = books[i];
        try {
          fileIo.unlinkSync(book.filePath);
        } catch (fileErr) {
          console.warn(TAG, `Failed to delete file ${book.filePath}, error: ${(fileErr as BusinessError).message}`);
        }
        this.deleteProgress(book.id);
        this.deleteAllBookmarks(book.id);
      }
      this.preferences.putSync(KEY_BOOKS, '[]');
      this.flush();
      this.cloudStorage.syncBooks([]);
      return true;
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `clearAllBooks failed, error code=${err.code}, message=${err.message}`);
      return false;
    }
  }
}