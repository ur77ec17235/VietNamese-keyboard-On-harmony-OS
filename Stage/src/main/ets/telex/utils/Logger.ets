/**
 * Logger.ets
 * Tiện ích logging có tag và cấp độ
 */

enum LogLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3
}

const CURRENT_LEVEL = LogLevel.DEBUG;
const APP_TAG = '[GoTiengViet]';

export class Logger {
  static debug(tag: string, message: string, ...args: object[]): void {
    if (CURRENT_LEVEL <= LogLevel.DEBUG) {
      console.debug(`${APP_TAG}[${tag}] ${message}`, ...args);
    }
  }

  static info(tag: string, message: string, ...args: object[]): void {
    if (CURRENT_LEVEL <= LogLevel.INFO) {
      console.info(`${APP_TAG}[${tag}] ${message}`, ...args);
    }
  }

  static warn(tag: string, message: string, ...args: object[]): void {
    if (CURRENT_LEVEL <= LogLevel.WARN) {
      console.warn(`${APP_TAG}[${tag}] ${message}`, ...args);
    }
  }

  static error(tag: string, message: string, err?: Error | object): void {
    if (CURRENT_LEVEL <= LogLevel.ERROR) {
      console.error(`${APP_TAG}[${tag}] ${message}`, err ? JSON.stringify(err) : '');
    }
  }
}
