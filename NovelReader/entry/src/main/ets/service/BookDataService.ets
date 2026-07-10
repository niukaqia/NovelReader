import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import fileIo from '@ohos.file.fs';
import { Book, ReadingProgress, Bookmark } from '../model/Book';
import { getGlobalContext } from '../utils/GlobalContext';

const TAG: string = 'BookDataService';
const STORE_NAME: string = 'NovelReaderStore';
const KEY_BOOKS: string = 'books';
const KEY_PROGRESS_PREFIX: string = 'progress_';
const KEY_BOOKMARK_PREFIX: string = 'bookmark_';

export class BookDataService {
  private static instance: BookDataService;
  private preferences: preferences.Preferences | null = null;

  private constructor() {}

  public static getInstance(): BookDataService {
    if (!BookDataService.instance) {
      BookDataService.instance = new BookDataService();
    }
    return BookDataService.instance;
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

  addBook(book: Book): boolean {
    this.initPreferences();
    if (!this.preferences) {
      return false;
    }
    try {
      const books = this.getAllBooks();
      const existingBook = books.find(b => b.id === book.id);
      if (!existingBook) {
        books.push(book);
        this.preferences.putSync(KEY_BOOKS, JSON.stringify(books));
        this.flush();
        return true;
      }
      return false;
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
      return true;
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `deleteBook failed, error code=${err.code}, message=${err.message}`);
      return false;
    }
  }

  saveProgress(progress: ReadingProgress): boolean {
    this.initPreferences();
    if (!this.preferences) {
      return false;
    }
    try {
      const key = `${KEY_PROGRESS_PREFIX}${progress.bookId}`;
      this.preferences.putSync(key, JSON.stringify(progress));
      this.flush();
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
      return true;
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `clearAllBooks failed, error code=${err.code}, message=${err.message}`);
      return false;
    }
  }
}