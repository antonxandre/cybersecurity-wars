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
import { JwtService } from '@nestjs/jwt';
import { Logger } from '@nestjs/common';
import { MatchesService } from './matches.service.js';
import { UserRole } from '../common/decorators/roles.decorator.js';

@WebSocketGateway({
  cors: {
    origin: (origin: string, callback: (err: Error | null, allow?: boolean) => void) => {
      const configured = (process.env.CORS_ORIGIN || '*').split(',').map((s) => s.trim());
      if (configured.includes('*') || !origin || configured.includes(origin)) {
        callback(null, true);
      } else {
        callback(null, false);
      }
    },
    credentials: true,
  },
  namespace: '/arena',
})
export class MatchesGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(MatchesGateway.name);

  constructor(
    private readonly jwtService: JwtService,
    private readonly matchesService: MatchesService,
  ) {}

  async handleConnection(client: Socket) {
    try {
      const token =
        client.handshake.auth?.token ??
        client.handshake.headers?.authorization?.split(' ')[1];

      if (!token) {
        this.logger.debug(`Client ${client.id} connected anonymously. Read-only caster mode.`);
        client.data.user = { sub: 0, username: 'anonymous_caster', role: UserRole.CASTER };
        return;
      }

      const payload = await this.jwtService.verifyAsync(token, {
        secret: process.env.JWT_ACCESS_SECRET || 'promptsec-arena-access-secret-key-32chars',
      });
      client.data.user = payload;
      this.logger.log(`Client authenticated: ${payload.username} (${payload.role})`);
    } catch {
      this.logger.warn(`Client ${client.id} failed handshake auth`);
      client.disconnect();
    }
  }

  handleDisconnect(client: Socket) {
    this.logger.log(`Client disconnected: ${client.id}`);
  }

  @SubscribeMessage('join_match')
  async handleJoinMatch(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { matchId: string; team?: UserRole },
  ) {
    const user = client.data.user;
    const match = await this.matchesService.joinMatch(
      data.matchId,
      { sub: user.sub, username: user.username, role: user.role },
      data.team,
    );

    const roomName = `match:${data.matchId}`;
    await client.join(roomName);

    this.server.to(roomName).emit('match:state_changed', match);
    this.logger.log(`Socket ${client.id} joined match room ${roomName}`);
    return { success: true, match };
  }

  @SubscribeMessage('submit_prompt')
  async handlePrompt(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { matchId: string; prompt: string },
  ) {
    const user = client.data.user;
    const result = await this.matchesService.submitPromptAttack(
      data.matchId,
      { sub: user.sub, username: user.username, role: user.role },
      data.prompt,
    );

    const roomName = `match:${data.matchId}`;
    this.server.to(roomName).emit('match:state_changed', result.match);
    this.server.to(roomName).emit('match:event', result.event);

    if (result.attackSuccess) {
      this.server.to(roomName).emit('match:flag_captured', {
        winner: UserRole.RED_TEAM,
        flag: result.flagLeaked,
      });
    }

    return result;
  }

  @SubscribeMessage('submit_patch')
  async handlePatch(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { matchId: string; patch: string },
  ) {
    const user = client.data.user;
    const result = await this.matchesService.submitSystemPatch(
      data.matchId,
      { sub: user.sub, username: user.username, role: user.role },
      data.patch,
    );

    const roomName = `match:${data.matchId}`;
    this.server.to(roomName).emit('match:state_changed', result.match);
    this.server.to(roomName).emit('match:event', result.event);
    return result;
  }

  @SubscribeMessage('update_port')
  async handleUpdatePort(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { matchId: string; port: number; action: 'OPEN' | 'RESTRICTED' | 'CLOSED' | 'HONEYPOT' },
  ) {
    const user = client.data.user;
    const result = await this.matchesService.updatePortRule(
      data.matchId,
      { sub: user.sub, username: user.username, role: user.role },
      data.port,
      data.action,
    );

    const roomName = `match:${data.matchId}`;
    this.server.to(roomName).emit('match:state_changed', result.match);
    this.server.to(roomName).emit('match:event', result.event);
    return result;
  }

  @SubscribeMessage('virus:send')
  async handleVirusSend(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { matchId: string; virus: Record<string, unknown> },
  ) {
    const user = client.data.user;
    const roomName = `match:${data.matchId}`;
    client.to(roomName).emit('opponent:viruses_queued', [data.virus]);
    this.logger.log(`Tactical virus sent by ${user?.username ?? 'operator'} in room ${roomName}`);
    return { success: true };
  }

  @SubscribeMessage('chat:send')
  async handleChatSend(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { matchId: string; channel?: string; text: string; senderName?: string; senderTeam?: string },
  ) {
    const user = client.data.user;
    const roomName = `match:${data.matchId}`;
    const message = {
      id: `msg_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
      channel: data.channel ?? 'team',
      senderName: data.senderName ?? user?.username ?? 'Operador',
      senderTeam: data.senderTeam ?? (user?.role === UserRole.BLUE_TEAM ? 'blue' : 'red'),
      text: data.text,
      timestamp: new Date().toISOString(),
    };
    this.server.to(roomName).emit('chat:message', message);
    return { success: true, message };
  }

  @SubscribeMessage('tactical:action')
  async handleTacticalAction(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { matchId: string; type: string; payload: Record<string, unknown> },
  ) {
    const user = client.data.user;
    const roomName = `match:${data.matchId}`;
    this.server.to(roomName).emit('tactical:action_applied', {
      user: user?.username ?? 'operator',
      type: data.type,
      payload: data.payload,
      timestamp: Date.now(),
    });
    return { success: true };
  }

  @SubscribeMessage('match:leave')
  async handleMatchLeave(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { matchId: string },
  ) {
    const roomName = `match:${data.matchId}`;
    await client.leave(roomName);
    this.server.to(roomName).emit('match:player_left', {
      user: client.data.user?.username,
    });
    return { success: true };
  }
}
