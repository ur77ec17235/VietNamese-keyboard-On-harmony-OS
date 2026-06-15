/**
 * ClipboardManager.ets
 * Quản lý clipboard - đọc text và ảnh từ pasteboard của HarmonyOS
 */

import pasteboard from '@ohos.pasteboard';
import image from '@ohos.multimedia.image';

export interface ClipboardItem {
  type: 'text' | 'image' | 'html';
  text?: string;
  html?: string;
  pixelMap?: image.PixelMap;
  timestamp: number;
}

export class ClipboardManager {
  private history: ClipboardItem[] = [];
  private maxHistory: number = 20;

  /**
   * Lấy nội dung text từ clipboard
   */
  async getClipboardText(): Promise<string> {
    try {
      const pb = pasteboard.getSystemPasteboard();
      const data = await pb.getData();
      if (!data) return '';

      const mimeTypes = data.getMimeTypes();
      if (mimeTypes.includes(pasteboard.MIMETYPE_TEXT_PLAIN)) {
        return data.getPrimaryText() || '';
      }
      if (mimeTypes.includes(pasteboard.MIMETYPE_TEXT_HTML)) {
        return data.getPrimaryHtml() || '';
      }
      return '';
    } catch (err) {
      console.error('ClipboardManager: getClipboardText failed:', err);
      return '';
    }
  }

  /**
   * Lấy ảnh từ clipboard (nếu có)
   */
  async getClipboardImage(): Promise<image.PixelMap | null> {
    try {
      const pb = pasteboard.getSystemPasteboard();
      const data = await pb.getData();
      if (!data) return null;

      const mimeTypes = data.getMimeTypes();
      if (mimeTypes.includes(pasteboard.MIMETYPE_PIXELMAP)) {
        return data.getPrimaryPixelMap() || null;
      }
      return null;
    } catch (err) {
      console.error('ClipboardManager: getClipboardImage failed:', err);
      return null;
    }
  }

  /**
   * Lấy tất cả nội dung clipboard (text + ảnh)
   */
  async getClipboardContent(): Promise<ClipboardItem | null> {
    try {
      const pb = pasteboard.getSystemPasteboard();
      const data = await pb.getData();
      if (!data) return null;

      const mimeTypes = data.getMimeTypes();
      const item: ClipboardItem = { type: 'text', timestamp: Date.now() };

      if (mimeTypes.includes(pasteboard.MIMETYPE_TEXT_HTML)) {
        item.type = 'html';
        item.html = data.getPrimaryHtml() || '';
        item.text = item.html.replace(/<[^>]*>/g, ''); // strip HTML tags
      } else if (mimeTypes.includes(pasteboard.MIMETYPE_TEXT_PLAIN)) {
        item.type = 'text';
        item.text = data.getPrimaryText() || '';
      } else if (mimeTypes.includes(pasteboard.MIMETYPE_PIXELMAP)) {
        item.type = 'image';
        item.pixelMap = data.getPrimaryPixelMap() || undefined;
      }

      if (item.text || item.pixelMap) {
        // Thêm vào lịch sử nếu chưa có
        const isDuplicate = this.history.some(h =>
          h.type === item.type &&
          h.text === item.text &&
          h.type !== 'image'
        );
        if (!isDuplicate) {
          this.history.unshift(item);
          if (this.history.length > this.maxHistory) {
            this.history.pop();
          }
        }
        return item;
      }
      return null;
    } catch (err) {
      console.error('ClipboardManager: getClipboardContent failed:', err);
      return null;
    }
  }

  /**
   * Kiểm tra clipboard có nội dung text không
   */
  async hasText(): Promise<boolean> {
    try {
      const pb = pasteboard.getSystemPasteboard();
      const data = await pb.getData();
      return data !== null && data !== undefined;
    } catch {
      return false;
    }
  }

  /**
   * Lấy lịch sử clipboard
   */
  getHistory(): ClipboardItem[] {
    return [...this.history];
  }

  /**
   * Xóa lịch sử clipboard
   */
  clearHistory(): void {
    this.history = [];
  }
}
