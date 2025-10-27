declare module '@mlc-ai/web-llm' {
  export interface MLCEngine {
    appConfig?: any;
    chat: any;
    reload(modelId: string): Promise<void>;
    unload(): Promise<void>;
    setAppConfig?(cfg: any): void;
  }

  export const MLCEngine: {
    new (opts?: any): MLCEngine;
  };

  export interface InitProgressReport {}
  export interface ChatCompletionMessageParam { role: string; content: string }
  export interface ChatCompletionChoiceDelta { content?: string }

  export interface ChatCompletionsCreateResult extends AsyncIterable<any> {}

  export const ArtifactCache: any;
  export const ArtifactIndexedDBCache: any;

  export function CreateMLCEngine(opts?: any): Promise<MLCEngine>;
}
