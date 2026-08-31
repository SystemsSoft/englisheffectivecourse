// AudioWorkletProcessor que acumula amostras Float32 do microfone e as
// converte para PCM 16-bit em chunks de ~100ms (1600 amostras a 16kHz),
// repassando cada chunk pro Dart via port.postMessage.
class PcmCaptureProcessor extends AudioWorkletProcessor {
  constructor() {
    super();
    this._buffer = [];
    this._chunkSize = 1600; // ~100ms @ 16kHz
  }
  process(inputs) {
    const input = inputs[0][0];
    if (input) {
      for (let i = 0; i < input.length; i++) this._buffer.push(input[i]);
      while (this._buffer.length >= this._chunkSize) {
        const chunk = this._buffer.splice(0, this._chunkSize);
        const pcm16 = new Int16Array(chunk.length);
        for (let i = 0; i < chunk.length; i++) {
          const s = Math.max(-1, Math.min(1, chunk[i]));
          pcm16[i] = s < 0 ? s * 0x8000 : s * 0x7fff;
        }
        this.port.postMessage(pcm16.buffer, [pcm16.buffer]);
      }
    }
    return true;
  }
}
registerProcessor('pcm-capture-processor', PcmCaptureProcessor);
