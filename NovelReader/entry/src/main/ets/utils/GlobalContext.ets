import { Context } from '@kit.AbilityKit';

let globalContext: Context | null = null;

export function setGlobalContext(context: Context): void {
  globalContext = context;
}

export function getGlobalContext(): Context {
  if (!globalContext) {
    throw new Error('Global context is not initialized');
  }
  return globalContext;
}