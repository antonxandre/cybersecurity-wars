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
import { corsOriginCallback } from '../common/utils/cors.util.js';

@WebSocketGateway({
  cors: {
    origin: corsOriginCallback,
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

  async handleDisconnect(client: Socket) {
    this.logger.log(`Client disconnected: ${client.id}`);
    const matchId = client.data?.matchId;
    const username = client.data?.user?.username;
    if (matchId && username && username !== 'anonymous_caster') {
      try {
        const updated = await this.matchesService.leaveMatch(matchId, username);
        const rooms = this.getMatchRooms(matchId);
        for (const r of rooms) {
          this.server.to(r).emit('match:player_left', { user: username });
        }
        if (updated) {
          this.broadcastRoomUpdated(updated);
        }
      } catch (err) {
        this.logger.debug(`Erro ao processar desconexão do socket ${client.id}: ${String(err)}`);
      }
    }
  }

  private getMatchRooms(matchId: string, match?: any): Set<string> {
    const rooms = new Set<string>();
    if (matchId) {
      rooms.add(`match:${matchId}`);
      rooms.add(`match:${matchId.toUpperCase()}`);
      rooms.add(`match:${matchId.toLowerCase()}`);
    }
    const id = match?.id;
    if (id) {
      rooms.add(`match:${id}`);
      rooms.add(`match:${id.toUpperCase()}`);
      rooms.add(`match:${id.toLowerCase()}`);
    }
    const code = match?.code;
    if (code) {
      rooms.add(`match:${code}`);
      rooms.add(`match:${code.toUpperCase()}`);
      rooms.add(`match:${code.toLowerCase()}`);
    }
    return rooms;
  }

  broadcastRoomUpdated(match: any) {
    const rooms = this.getMatchRooms(match.id, match);
    for (const r of rooms) {
      this.server.to(r).emit('match:room_updated', match);
      this.server.to(r).emit('match:state_changed', match);
    }
    this.server.emit('lobby:room_updated', match);
  }

  broadcastRoomCreated(match: any) {
    this.server.emit('lobby:room_created', match);
  }

  broadcastMatchStarted(matchId: string, match: any) {
    const rooms = this.getMatchRooms(matchId, match);
    const code = match.code || match.id || matchId;
    for (const r of rooms) {
      this.server.to(r).emit('match:started', { matchId: code, match });
    }
    this.server.emit('lobby:room_updated', match);
  }

  broadcastRoomDeleted(match: { id: string; code?: string }, reason: string = 'EXPIRED_AFTER_1_HOUR') {
    const code = match.code || match.id;
    const payload = {
      id: match.id,
      code,
      reason,
      message: 'A sala expirou após 1 hora de criação e foi encerrada automaticamente.',
    };

    if (this.server) {
      this.server.emit('lobby:room_deleted', payload);
      const rooms = this.getMatchRooms(match.id, match);
      for (const r of rooms) {
        this.server.to(r).emit('match:expired', payload);
        this.server.to(r).emit('match:deleted', payload);
        try {
          this.server.in(r)?.socketsLeave(r);
        } catch (err) {
          this.logger.debug(`Erro ao desvincular sockets da sala excluída ${match.id}: ${String(err)}`);
        }
      }
    }
  }

  @SubscribeMessage('join_match')
  async handleJoinMatch(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { matchId: string; team?: UserRole },
  ) {
    let user = client.data.user;
    if (!user) {
      const token =
        client.handshake.auth?.token ??
        client.handshake.headers?.authorization?.split(' ')[1];
      if (token) {
        try {
          user = await this.jwtService.verifyAsync(token, {
            secret: process.env.JWT_ACCESS_SECRET || 'promptsec-arena-access-secret-key-32chars',
          });
          client.data.user = user;
        } catch {
          // anonymous
        }
      }
    }
    const safeUser = user || { sub: 0, username: 'anonymous_caster', role: UserRole.CASTER };

    const match = await this.matchesService.joinMatch(
      data.matchId,
      { sub: safeUser.sub, username: safeUser.username, role: safeUser.role },
      data.team,
    );

    const rooms = this.getMatchRooms(data.matchId, match);
    for (const r of rooms) {
      await client.join(r);
    }
    client.data.matchId = match.id;

    this.broadcastRoomUpdated(match);
    this.logger.log(`Socket ${client.id} joined match room match:${match.id} (${safeUser.username})`);
    return { success: true, match };
  }

  @SubscribeMessage('start_match')
  async handleStartMatch(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { matchId: string },
  ) {
    const user = client.data.user;
    const match = await this.matchesService.startMatch(data.matchId, {
      sub: user?.sub ?? 0,
      username: user?.username ?? 'Host',
    });

    this.broadcastMatchStarted(data.matchId, match);
    this.logger.log(`Socket ${client.id} started match ${data.matchId} (${user?.username})`);
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
    const rooms = this.getMatchRooms(data.matchId);
    for (const r of rooms) {
      client.to(r).emit('opponent:viruses_queued', [data.virus]);
    }
    this.logger.log(`Tactical virus sent by ${user?.username ?? 'operator'} in rooms ${Array.from(rooms).join(', ')}`);
    return { success: true };
  }

  @SubscribeMessage('chat:send')
  async handleChatSend(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { matchId: string; channel?: string; text: string; senderName?: string; senderTeam?: string },
  ) {
    const user = client.data.user;
    const rooms = this.getMatchRooms(data.matchId);
    const message = {
      id: `msg_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
      channel: data.channel ?? 'team',
      senderName: data.senderName ?? user?.username ?? 'Operador',
      senderTeam: data.senderTeam ?? (user?.role === UserRole.BLUE_TEAM ? 'blue' : 'red'),
      text: data.text,
      timestamp: new Date().toISOString(),
    };
    for (const r of rooms) {
      this.server.to(r).emit('chat:message', message);
    }
    return { success: true, message };
  }

  @SubscribeMessage('tactical:action')
  async handleTacticalAction(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { matchId: string; type: string; payload: Record<string, unknown> },
  ) {
    const user = client.data.user;
    const rooms = this.getMatchRooms(data.matchId);
    for (const r of rooms) {
      client.to(r).emit('tactical:action_applied', {
        user: user?.username ?? 'operator',
        type: data.type,
        payload: data.payload,
        timestamp: Date.now(),
      });
    }
    return { success: true };
  }

  @SubscribeMessage('match:leave')
  async handleMatchLeave(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { matchId: string },
  ) {
    const rooms = this.getMatchRooms(data.matchId);
    for (const r of rooms) {
      await client.leave(r);
    }
    client.data.matchId = undefined;
    const updated = await this.matchesService.leaveMatch(data.matchId, client.data.user?.username);
    for (const r of rooms) {
      this.server.to(r).emit('match:player_left', {
        user: client.data.user?.username,
      });
    }
    if (updated) {
      this.broadcastRoomUpdated(updated);
    }
    return { success: true };
  }
}
