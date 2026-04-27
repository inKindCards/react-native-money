// TypeScript spec for codegen
// This file is used by React Native codegen to generate native glue code

export interface Spec {
  readonly initializeMoneyInput: (reactNode: number, options: Object) => void;
  readonly cleanupMoneyInput: (reactNode: number) => void;
  readonly formatMoney: (value: number, locale?: string) => string;
  readonly extractValue: (label: string, locale?: string) => number;
}

// Runtime implementation
// Try to get TurboModule, fall back to null (will use NativeModules)
declare const global: any;

let module: Spec | null = null;

try {
  // @ts-ignore - TurboModuleRegistry may not be available in older RN
  const TurboModuleRegistry = require('react-native').TurboModuleRegistry;
  if (TurboModuleRegistry) {
    module = TurboModuleRegistry.get('RNMoneyInput') as Spec | null;
  }
} catch (e) {
  // TurboModuleRegistry not available, will fall back to NativeModules
}

export default module;

