---
name: nestjs-websocket-gateway
description: Real-time multiplayer synchronization, Socket.IO WebSockets, match rooms, JWT handshake validation, and turn-based event broadcasting in NestJS. Use when building or updating match gateways, live telemetry, and multiplayer state in PromptSec Arena.
---

# NestJS WebSocket Gateway & Real-Time Multiplayer Guide

This skill governs the WebSocket architecture connecting Flutter Web clients with the NestJS backend for real-time PromptSec Arena matches.

## 1. Gateway Setup & Handshake Authentication

```typescript
import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { UseGuards, UnauthorizedException } from '@nestjs/common';

@WebSocketGateway({
  cors: {
    origin: process.env.CORS_ORIGIN?.split(',') ?? ['http://localhost:8080'],
    credentials: true,
  },
  namespace: '/arena',
})
export class MatchesGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  async handleConnection(client: Socket) {
    try {
      const token = client.handshake.auth?.token ?? client.handshake.headers.authorization?.split(' ')[1];
      if (!token) throw new UnauthorizedException('Missing auth token');
      const payload = this.jwtService.verify(token);
      client.data.user = payload;
    } catch {
      client.disconnect();
    }
  }

  handleDisconnect(client: Socket) {
    // Notify room of player departure / disconnect
  }
}
```

## 2. Match Rooms and Event Architecture

1. **Room Partitioning**:
   - Each active match has a dedicated room: `match:${matchId}`.
   - Sockets join on `join_match` event after validating access permissions.

2. **Core Event Catalog**:
   - `match:joined`: Emitted when a Red/Blue/Caster joins.
   - `prompt:submitted`: Red Team submits an attack prompt.
   - `patch:applied`: Blue Team injects a dynamic system prompt patch.
   - `logprobs:update`: Broadcasts logprob probability score and tension meter value to Casters and players.
   - `match:resolved`: Emitted when a Flag is captured or time runs out.

3. **Guards & Payload Validation**:
   - Validate incoming WebSocket event payloads using DTO classes with `ValidationPipe`.
   - Ensure the emitting client's team matches the action (Red Team cannot emit `patch:applied`, Blue Team cannot emit `prompt:submitted`).
