/**
 * InputEngineBase.ets
 * Interface chung cho tất cả engine gõ tiếng Việt
 */

export interface ProcessResult {
  /** Văn bản cần chèn vào editor */
  commitText: string;
  /** Văn bản đang compose (chưa hoàn thành) */
  composingText: string;
  /** Số ký tự cần xóa trước con trỏ */
  deleteCount: number;
  /** Danh sách gợi ý từ */
  candidates: string[];
  /** Đã hoàn thành từ (commit) chưa */
  committed: boolean;
}

export interface InputEngineBase {
  /** Tên phương pháp gõ */
  readonly name: string;
  /** Xử lý khi người dùng nhấn một phím */
  processInput(key: string): ProcessResult;
  /** Reset trạng thái khi bắt đầu nhập từ mới */
  reset(): void;
  /** Lấy text đang compose hiện tại */
  getComposingText(): string;
}

export enum InputMode {
  TELEX = 'telex',
  VNI = 'vni',
  ENGLISH = 'en'
}
