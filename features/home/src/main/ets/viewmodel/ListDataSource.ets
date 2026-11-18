export class ListDataSource<T> implements IDataSource {
  private items: T[] = [];
  private listeners: Set<DataChangeListener> = new Set<DataChangeListener>();

  totalCount(): number {
    return this.items.length;
  }

  getData(index: number): T {
    return this.items[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    this.listeners.add(listener);
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    this.listeners.delete(listener);
  }

  append(items: T[]): void {
    items.forEach((item: T) => {
      const index = this.items.length;
      this.items.push(item);
      this.listeners.forEach((listener: DataChangeListener) => listener.onDataAdd(index));
    });
  }

  reset(items: T[]): void {
    this.items = items.slice();
    this.listeners.forEach((listener: DataChangeListener) => listener.onDataReloaded());
  }
}
