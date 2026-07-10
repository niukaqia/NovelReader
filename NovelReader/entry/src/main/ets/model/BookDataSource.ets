import { Book } from './Book';

export class BookDataSource {
  private books: Book[] = [];
  private listeners: Array<() => void> = [];

  public getCount(): number {
    return this.books.length;
  }

  public getItem(index: number): Book | undefined {
    return this.books[index];
  }

  public addData(book: Book): void {
    this.books.push(book);
    this.notifyDataChanged();
  }

  public addDataArray(books: Book[]): void {
    const len: number = books.length;
    for (let i: number = 0; i < len; i++) {
      this.books.push(books[i]);
    }
    this.notifyDataChanged();
  }

  public removeData(index: number): void {
    if (index >= 0 && index < this.books.length) {
      this.books.splice(index, 1);
      this.notifyDataChanged();
    }
  }

  public updateData(index: number, book: Book): void {
    if (index >= 0 && index < this.books.length) {
      this.books[index] = book;
      this.notifyDataChanged();
    }
  }

  public replaceData(books: Book[]): void {
    this.books = [];
    const len: number = books.length;
    for (let i: number = 0; i < len; i++) {
      this.books.push(books[i]);
    }
    this.notifyDataChanged();
  }

  public clearData(): void {
    this.books = [];
    this.notifyDataChanged();
  }

  public registerDataChangeListener(listener: () => void): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  public unregisterDataChangeListener(listener: () => void): void {
    const index: number = this.listeners.indexOf(listener);
    if (index >= 0) {
      this.listeners.splice(index, 1);
    }
  }

  private notifyDataChanged(): void {
    const len: number = this.listeners.length;
    for (let i: number = 0; i < len; i++) {
      this.listeners[i]();
    }
  }

  public getIndexById(bookId: string): number {
    const len: number = this.books.length;
    for (let i: number = 0; i < len; i++) {
      if (this.books[i].id === bookId) {
        return i;
      }
    }
    return -1;
  }

  public getAllBooks(): Book[] {
    return this.books;
  }
}