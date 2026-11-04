import { describe, it, expect } from 'vitest';
import { ArgumentMetadata } from '@nestjs/common';
import { SanitizationPipe } from './sanitization.pipe.js';

class FakeSocket {
  id = 'sock_1';
  server: any;
  nsp: any;
  data: Record<string, unknown> = {};
  constructor() {
    // Mimic Socket.IO circular references (socket -> nsp -> sockets -> socket)
    this.nsp = { sockets: new Map([[this.id, this]]), server: null as any };
    this.server = { of: () => this.nsp, root: this };
    this.nsp.server = this.server;
  }
}

describe('SanitizationPipe', () => {
  const pipe = new SanitizationPipe();

  it('does not traverse @ConnectedSocket() (WsParamtype.SOCKET = 0)', () => {
    const socket = new FakeSocket();
    const meta = { type: 0 as any } as ArgumentMetadata;
    expect(pipe.transform(socket, meta)).toBe(socket);
  });

  it('does not overflow on circular class instances even without metadata', () => {
    const socket = new FakeSocket();
    expect(() => pipe.transform(socket)).not.toThrow();
  });

  it('does not overflow on circular plain objects', () => {
    const a: any = { text: '  hi  ' };
    a.self = a;
    const meta = { type: 'body' } as ArgumentMetadata;
    const result = pipe.transform(a, meta);
    expect(result.text).toBe('hi');
  });

  it('sanitizes WebSocket @MessageBody() payload (WsParamtype.PAYLOAD = 3)', () => {
    const meta = { type: 3 as any } as ArgumentMetadata;
    const result = pipe.transform(
      { matchId: ' T9R-BDB ', text: 'ok<script>alert(1)</script><|im_start|>' },
      meta,
    );
    expect(result).toEqual({ matchId: 'T9R-BDB', text: 'ok' });
  });

  it('sanitizes HTTP body nested arrays', () => {
    const meta = { type: 'body' } as ArgumentMetadata;
    const result = pipe.transform({ list: ['<script>x</script>a', { b: ' c ' }] }, meta);
    expect(result).toEqual({ list: ['a', { b: 'c' }] });
  });

  it('ignores custom param decorators', () => {
    const user = { username: '  bob  ' };
    const meta = { type: 'custom' } as ArgumentMetadata;
    expect(pipe.transform(user, meta)).toBe(user);
  });
});
