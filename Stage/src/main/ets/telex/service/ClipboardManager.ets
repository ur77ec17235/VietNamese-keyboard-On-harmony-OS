/**
 * ClipboardManager.ets
 * Reader tối giản cho system clipboard. Không lưu history nền.
 */

import { pasteboard } from '@kit.BasicServicesKit';

export interface ClipboardItem {
  kind: string;
  text: string;
  timestamp: number;
}

export interface ClipboardReadResult {
  items: ClipboardItem[];
  message: string;
}

export class ClipboardManager {
  async writeItemToSystemPasteboard(item: ClipboardItem): Promise<void> {
    const pb = pasteboard.getSystemPasteboard();
    await pb.setData(pasteboard.createPlainTextData(item.text));
  }

  // private stripHtml(htmlText: string): string {
  //   return htmlText
  //     .replace(/<script[\s\S]*?<\/script>/gi, '')
  //     .replace(/<style[\s\S]*?<\/style>/gi, '')
  //     .replace(/<[^>]*>/g, ' ')
  //     .replace(/&nbsp;/g, ' ')
  //     .replace(/&amp;/g, '&')
  //     .replace(/&lt;/g, '<')
  //     .replace(/&gt;/g, '>')
  //     .replace(/&quot;/g, '"')
  //     .replace(/&#39;/g, "'")
  //     .replace(/\s+/g, ' ')
  //     .trim();
  // }

  private pushText(items: ClipboardItem[], value: string | undefined | null, timestamp: number): void {
    const text = (value || '').trim();
    if (text.length === 0 || this.hasItemValue(items, text)) {
      return;
    }

    items.push({
      kind: 'text',
      text: text,
      timestamp: timestamp
    });
  }

  // private pushHtml(items: ClipboardItem[], value: string | undefined | null, timestamp: number): void {
  //   const htmlText = (value || '').trim();
  //   if (htmlText.length === 0) {
  //     return;
  //   }
  //   const stripped = this.stripHtml(htmlText);
  //   this.pushText(items, stripped.length > 0 ? stripped : htmlText, timestamp);
  // }

  private hasItemValue(items: ClipboardItem[], value: string): boolean {
    return items.some((item: ClipboardItem) => {
      return item.text === value;
    });
  }

  private pushUri(items: ClipboardItem[], value: string | undefined | null, mimeType: string, timestamp: number): void {
    const uri = (value || '').trim();

    if (uri.length === 0 || this.hasItemValue(items, uri)) {
      return;
    }

    // Không phân biệt ảnh/file/link nữa.
    // Clipboard có URI gì thì lưu URI đó vào list.
    this.pushText(items, uri, timestamp);
  }
  //
  //   if (mimeType.toLowerCase().startsWith('image/') || this.isImageUri(uri)) {
  //     return;
  //   }
  //
  //   this.pushText(items, uri, timestamp);
  // }

  private getPrimaryText(data: pasteboard.PasteData): string {
    try {
      return data.getPrimaryText();
    } catch (_) {
      return '';
    }
  }

  // private getPrimaryHtml(data: pasteboard.PasteData): string {
  //   try {
  //     return data.getPrimaryHtml();
  //   } catch (_) {
  //     return '';
  //   }
  // }

  // private getPrimaryUri(data: pasteboard.PasteData): string {
  //   try {
  //     return data.getPrimaryUri();
  //   } catch (_) {
  //     return '';
  //   }
  // }

  private getPrimaryMimeType(data: pasteboard.PasteData): string {
    try {
      return data.getPrimaryMimeType();
    } catch (_) {
      return '';
    }
  }

  private getPasteTimestamp(data: pasteboard.PasteData): number {
    try {
      const property = data.getProperty();
      return property.timestamp > 0 ? property.timestamp : Date.now();
    } catch (_) {
      return Date.now();
    }
  }

  async readTextItems(): Promise<ClipboardReadResult> {
    try {
      const pb = pasteboard.getSystemPasteboard();
      const hasData = await pb.hasData();
      if (!hasData) {
        return { items: [], message: 'Clipboard đang trống.' };
      }

      const data = await pb.getData();
      if (!data) {
        return { items: [], message: 'Không đọc được dữ liệu clipboard.' };
      }

      const now = this.getPasteTimestamp(data);
      const items: ClipboardItem[] = [];
      this.pushText(items, this.getPrimaryText(data), now);
      // this.pushHtml(items, this.getPrimaryHtml(data), now);
      const primaryMimeType = this.getPrimaryMimeType(data);
      // this.pushUri(items, this.getPrimaryUri(data), primaryMimeType, now);

      const count = Math.min(data.getRecordCount(), 5);
      for (let i = 0; i < count; i++) {
        const record = data.getRecord(i);
        this.pushText(items, record.plainText, now);
        // this.pushHtml(items, record.htmlText, now);
        // this.pushUri(items, record.uri, record.mimeType, now);
        if (items.length >= 5) {
          break;
        }
      }

      if (items.length === 0) {
        return { items: [], message: 'Clipboard có dữ liệu nhưng chưa hỗ trợ loại này.' };
      }
      return { items, message: '' };
    } catch (err) {
      console.error('ClipboardManager: readTextItems failed:', err);
      return {
        items: [],
        message: 'Không đọc được clipboard. Hãy kiểm tra quyền READ_PASTEBOARD.'
      };
    }
  }
}
