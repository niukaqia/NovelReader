export interface Book {
  id: string;
  name: string;
  author: string;
  filePath: string;
  fileType: 'txt' | 'epub';
  cover?: string;
  totalChapters: number;
  lastReadChapter: number;
  lastReadProgress: number;
  lastReadTime: number;
  description?: string;
  category: string;
}

export type BookCategory = '全部' | '小说' | '文学' | '科技' | '历史' | '其他';

export const BOOK_CATEGORIES: BookCategory[] = ['全部', '小说', '文学', '科技', '历史', '其他'];

export interface Chapter {
  bookId: string;
  chapterIndex: number;
  title: string;
  content: string;
  startOffset: number;
  endOffset: number;
}

export interface ReadingProgress {
  bookId: string;
  chapterIndex: number;
  progress: number;
  readTime: number;
}

export interface Bookmark {
  id: string;
  bookId: string;
  chapterIndex: number;
  paragraphIndex: number;
  content: string;
  createTime: number;
}

export interface ReaderConfig {
  fontSize: number;
  lineSpacing: number;
  theme: 'light' | 'dark' | 'sepia' | 'green';
  pageTurnMode: 'slide' | 'flip' | 'scroll';
  brightness: number;
  keepScreenOn: boolean;
  textToSpeechEnabled: boolean;
}

export interface ThemeConfig {
  backgroundColor: string;
  textColor: string;
  titleColor: string;
}